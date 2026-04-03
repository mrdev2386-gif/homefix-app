
import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { assertAuthenticated } from '../shared/security';
import { calculateDistance } from '../shared/geoutils';
import { sendPushNotification } from '../shared/notifications';

const db = admin.firestore();

// --- MATCHING ENGINE ---

async function findMatchingTechnicians(subServiceId: string, location: admin.firestore.GeoPoint) {
    // 1. Get SubService Details to find Parent Service
    const subServiceDoc = await db.collection('subServices').doc(subServiceId).get();
    if (!subServiceDoc.exists) return [];

    const serviceId = subServiceDoc.data()!.serviceId;

    // 2. Query Technicians (Active + Online)
    // For scalability, index by `status` and `isOnline`.
    // In production, use Geohash for spatial query. Here we query all active/online and filter (MVP).
    // Or at least filter by City if available in booking data.
    const query = db.collection('technicians')
        .where('status', '==', 'active')
        .where('isOnline', '==', true);
    // .where(`skills.${serviceId}.subServiceIds`, 'array-contains', subServiceId); 
    // Array-contains on nested map keys is tricky. Better to have a top-level `skillIds` array.
    // Or fetch candidates and filter in memory if < 1000 per city.

    const snapshot = await query.get();
    const candidates: any[] = [];

    for (const doc of snapshot.docs) {
        const tech = doc.data();

        // 3. Filter by Skill (Manual check due to nested map flexibility)
        if (!tech.skills?.[serviceId]?.subServiceIds?.includes(subServiceId)) continue;

        // 4. Filter by Radius
        if (!tech.coordinates) continue;
        const techLoc = { lat: tech.coordinates.latitude, lng: tech.coordinates.longitude };
        const jobLoc = { lat: location.latitude, lng: location.longitude };
        const distance = calculateDistance(techLoc, jobLoc);

        if (distance <= (tech.serviceRadius || 10)) {
            candidates.push({ id: doc.id, distance, ...tech });
        }
    }

    // 5. Sort by Rating (High -> Low)
    candidates.sort((a, b) => (b.rating || 0) - (a.rating || 0));

    // Limit to Top 10
    return candidates.slice(0, 10);
}

// --- TRIGGERS ---

export const onBookingCreated = functions.firestore.document('bookings/{bookingId}')
    .onCreate(async (snap, context) => {
        const booking = snap.data();
        if (!booking || booking.status !== 'pending') return;

        const { subServiceId, location } = booking; // Ensure booking has `location` as GeoPoint or specific structure

        // Convert location if stored as object
        let geoPoint: admin.firestore.GeoPoint;
        if (location instanceof admin.firestore.GeoPoint) {
            geoPoint = location;
        } else if (location.latitude && location.longitude) {
            geoPoint = new admin.firestore.GeoPoint(location.latitude, location.longitude);
        } else if (location.coordinates) {
            geoPoint = new admin.firestore.GeoPoint(location.coordinates.latitude, location.coordinates.longitude);
        } else {
            console.error('Invalid location format in booking');
            return;
        }

        const matches = await findMatchingTechnicians(subServiceId, geoPoint);

        if (matches.length === 0) {
            // Updated status to `unfulfilled` or notify admin?
            console.log(`No technicians found for booking ${context.params.bookingId}`);
            return; // Or retry later
        }

        // Send Alerts (Broadcast Strategy)
        const batch = db.batch();
        const alertCollection = db.collection('booking_alerts');

        for (const tech of matches) {
            const alertRef = alertCollection.doc();
            batch.set(alertRef, {
                bookingId: context.params.bookingId,
                technicianId: tech.id,
                status: 'sent',
                expiresAt: admin.firestore.Timestamp.fromMillis(Date.now() + 5 * 60 * 1000), // 5 min expiry
                createdAt: admin.firestore.FieldValue.serverTimestamp()
            });

            // Send FCM
            // Using existing helper `sendPushNotification`
            await sendPushNotification(tech.id, 'technicians', {
                title: 'New Service Request',
                body: `New job available nearby! ${tech.distance.toFixed(1)}km away.`,
                data: { bookingId: context.params.bookingId, type: 'job_alert' }
            });
        }

        await batch.commit();
    });

// --- TECH RESPONSE ---

export const respondToBooking = functions.region('asia-south1').https.onCall(async (data, context) => {
    assertAuthenticated(context);
    const techId = context.auth!.uid;
    const { bookingId, action } = data; // 'accept' | 'reject'

    if (!['accept', 'reject'].includes(action)) {
        throw new functions.https.HttpsError('invalid-argument', 'Invalid action');
    }

    const bookingRef = db.collection('bookings').doc(bookingId);

    // Use transaction to prevent race conditions
    return db.runTransaction(async (transaction) => {
        const bookingDoc = await transaction.get(bookingRef);
        if (!bookingDoc.exists) {
            throw new functions.https.HttpsError('not-found', 'Booking not found');
        }

        const booking = bookingDoc.data()!;

        if (booking.status !== 'pending') {
            throw new functions.https.HttpsError('failed-precondition', 'Booking already assigned or cancelled');
        }

        if (action === 'accept') {
            // Assign Technician
            // 1. Get Technician Name
            const techDoc = await transaction.get(db.collection('technicians').doc(techId));
            if (!techDoc.exists) throw new functions.https.HttpsError('not-found', 'Technician profile missing');

            const techData = techDoc.data()!;
            if (techData.status !== 'active') throw new functions.https.HttpsError('permission-denied', 'Technician blocked or inactive');

            // 2. Update Booking
            transaction.update(bookingRef, {
                technicianId: techId,
                technicianName: techData.name,
                technicianPhoto: techData.photoUrl,
                status: 'accepted',
                acceptedAt: admin.firestore.FieldValue.serverTimestamp(),
                updatedAt: admin.firestore.FieldValue.serverTimestamp()
            });

            // 3. Delete Alerts? Or update them?
            // Usually we'd cleanup alerts in a separate trigger or batch, 
            // but for transaction speed, just update booking. 
            // Other technicians clicking will get "Already Assigned".

            // 4. Notify Customer? (Handled by Trigger on Booking Update)
        } else {
            // Reject - Log rejection
            const rejectionRef = db.collection('booking_rejections').doc();
            transaction.set(rejectionRef, {
                bookingId,
                technicianId: techId,
                reason: 'manual_reject',
                createdAt: admin.firestore.FieldValue.serverTimestamp()
            });
        }

        return { success: true, message: action === 'accept' ? 'Booking Accepted' : 'Booking Rejected' };
    });
});

/**
 * Helper to fetch technicians eligible for a specific service
 * Security: Requires authentication
 */
export const getEligibleTechnicians = functions.region('asia-south1').https.onCall(async (data, context) => {
    // 1. Security Check
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'Authentication required to fetch technicians.');
    }

    const { serviceId } = data;

    // 2. Validate Input
    if (!serviceId || typeof serviceId !== 'string') {
        throw new functions.https.HttpsError('invalid-argument', 'Valid serviceId is required.');
    }

    // Standardize slug format check if needed
    if (!/^[a-zA-Z0-9_-]+$/.test(serviceId)) {
        throw new functions.https.HttpsError('invalid-argument', 'Invalid serviceId format.');
    }

    try {
        console.log(`[Matching] Fetching eligible technicians for service: ${serviceId} (Requested by: ${context.auth.uid})`);

        // 3. Query approved technicians who have the serviceId in their flat array
        const snapshot = await db.collection('technicians')
            .where('status', '==', 'approved')
            .where('serviceIds', 'array-contains', serviceId)
            .limit(50) // Safeguard payload size
            .get();

        // 4. Transform to minimal safe fields
        const technicians = snapshot.docs.map(doc => {
            const data = doc.data();
            return {
                id: doc.id,
                name: data.name,
                rating: data.rating || 5.0,
                totalJobs: data.totalJobs || 0,
                isOnline: data.isOnline || false,
                // Do NOT return sensitive fields like phone, email, or full skills map here
            };
        });

        console.log(`[Matching] Found ${technicians.length} eligible technicians for ${serviceId}`);

        return {
            success: true,
            totalFound: technicians.length,
            technicians
        };

    } catch (error: any) {
        console.error(`[Matching] Error fetching technicians for ${serviceId}:`, error);
        throw new functions.https.HttpsError('internal', 'Failed to retrieve eligible technicians.');
    }
});


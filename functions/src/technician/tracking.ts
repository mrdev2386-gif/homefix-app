
import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { assertAuthenticated } from '../shared/security';
import { calculateDistance } from '../shared/geoutils';

const db = admin.firestore();

export const updateLocation = functions.region('asia-south1').https.onCall(async (data, context) => {
    assertAuthenticated(context);
    const uid = context.auth!.uid;
    const { location, timestamp } = data; // { lat, lng }

    if (!location || !location.lat || !location.lng) {
        throw new functions.https.HttpsError('invalid-argument', 'Invalid location data');
    }

    const techRef = db.collection('technicians').doc(uid);
    const techDoc = await techRef.get();

    if (!techDoc.exists) {
        throw new functions.https.HttpsError('not-found', 'Technician profile not found');
    }

    const techData = techDoc.data()!;

    // Anti-Spoofing Check: Speed Calculation
    if (techData.lastLocation && techData.lastSeen) {
        const lastCoords = { lat: techData.lastLocation.latitude, lng: techData.lastLocation.longitude };
        const newCoords = { lat: location.lat, lng: location.lng };

        const distanceKm = calculateDistance(lastCoords, newCoords);
        const timeDiffSec = (timestamp - techData.lastSeen.toMillis()) / 1000;

        if (timeDiffSec > 0) {
            const speedKmph = (distanceKm / (timeDiffSec / 3600));

            if (speedKmph > 200) { // Impossible speed
                console.warn(`Suspicious speed detected for ${uid}: ${speedKmph} km/h`);
                // Log suspicious activity
                await db.collection('fraud_alerts').add({
                    technicianId: uid,
                    type: 'speed_spoofing',
                    speedKmph,
                    location: newCoords,
                    timestamp: admin.firestore.FieldValue.serverTimestamp()
                });

                // Optional: Auto-suspend? No, just log for now.
            }
        }
    }

    await techRef.update({
        lastLocation: new admin.firestore.GeoPoint(location.lat, location.lng),
        lastSeen: admin.firestore.FieldValue.serverTimestamp(),
        // geohash: encodeGeohash(location.lat, location.lng) // If we had geohash lib
    });

    return { success: true };
});

export const toggleOnlineStatus = functions.region('asia-south1').https.onCall(async (data, context) => {
    assertAuthenticated(context);
    const uid = context.auth!.uid;
    const { isOnline } = data;

    await db.collection('technicians').doc(uid).update({
        isOnline: !!isOnline,
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
    });

    return { success: true };
});

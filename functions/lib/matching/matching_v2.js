"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.handleAssignmentResponse = exports.onBookingCreatedMatch = void 0;
exports.matchAndAssignBooking = matchAndAssignBooking;
const functions = __importStar(require("firebase-functions"));
const admin = __importStar(require("firebase-admin"));
const geoutils_1 = require("../shared/geoutils");
const notifications_1 = require("../shared/notifications");
const db = admin.firestore();
const DEFAULT_CONFIG = {
    weights: {
        rating: 0.25,
        distance: 0.20,
        completion: 0.15,
        risk: 0.15,
        availability: 0.10,
        serviceFit: 0.10,
        fatigue: 0.05
    },
    searchRadiusKm: 15,
    maxCandidates: 3,
    assignmentTimeoutSec: 60,
    heartbeatExpiryMinutes: 10,
    fatigueThresholdHours: 4,
};
// ==========================================
// CORE MATCHING LOGIC
// ==========================================
/**
 * Main function to find the best technician for a booking and initiate assignment.
 * Can be triggered via Cloud Function or manually.
 */
async function matchAndAssignBooking(bookingId, options) {
    console.log(`Starting matching process for booking: ${bookingId}`);
    // 1. Fetch Booking and Context
    const bookingRef = db.collection('bookings').doc(bookingId);
    const bookingDoc = await bookingRef.get();
    if (!bookingDoc.exists) {
        console.error(`Booking ${bookingId} not found.`);
        return { success: false, reason: 'booking_not_found' };
    }
    const booking = bookingDoc.data();
    // Check Status (unless forced)
    const terminalOrAssignedStatuses = ['assigned', 'started', 'completed', 'cancelled', 'accepted'];
    if (!options?.forceAssign && terminalOrAssignedStatuses.includes(booking.status)) {
        console.log(`Booking ${bookingId} already in terminal/assigned state: ${booking.status}`);
        return { success: false, reason: 'invalid_status' };
    }
    if (!booking.addressSnapshot || !booking.addressSnapshot.latitude || !booking.addressSnapshot.longitude) {
        console.error(`Booking ${bookingId} has no valid location.`);
        // Escalate to admin
        await handleAdminEscalation(bookingId, 'missing_location');
        return { success: false, reason: 'missing_location' };
    }
    const bookingLocation = {
        lat: booking.addressSnapshot.latitude,
        lng: booking.addressSnapshot.longitude
    };
    // 2. Fetch Candidates
    // Note: In a real large-scale system, we'd use GeoFire or separate geo-index.
    // Here we fetch 'available' techs and filter by distance in memory for simplicity/demo scale.
    const techsSnapshot = await db.collection('technicians')
        .where('status', '==', 'approved')
        .where('isAvailable', '==', true)
        .get();
    const candidates = [];
    const config = DEFAULT_CONFIG; // Predictable config for now
    // 3. Score & Filter Candidates
    for (const doc of techsSnapshot.docs) {
        const tech = doc.data();
        const techId = doc.id;
        // A. Basic Availability & Risk Checks
        if (!isValidCandidate(tech, booking, config))
            continue;
        // B. Geo Check
        if (!tech.geo || !tech.geo.lat || !tech.geo.lng)
            continue;
        const techLocation = { lat: tech.geo.lat, lng: tech.geo.lng };
        const distance = (0, geoutils_1.calculateDistance)(bookingLocation, techLocation);
        if (distance > config.searchRadiusKm)
            continue;
        // C. Check Previous Rejections
        // Optimisation: We could store rejected Tech IDs on the booking to skip query
        const hasRejected = await hasTechnicianRejected(bookingId, techId);
        if (hasRejected)
            continue;
        // D. Calculate Score
        const scoreResult = calculateScore(tech, booking, distance, config);
        candidates.push({
            techId,
            totalScore: scoreResult.totalScore,
            scoreBreakdown: scoreResult.breakdown,
            technician: tech,
            distanceKm: distance
        });
    }
    // 4. Rank Candidates
    candidates.sort((a, b) => b.totalScore - a.totalScore); // Descending
    if (candidates.length === 0) {
        console.warn(`No suitable candidates found for booking ${bookingId}`);
        // Safe fallback: set to searching_technician so user sees proper status
        try {
            await db.collection('bookings').doc(bookingId).update({
                status: 'searching_technician',
                technicianAssigned: false,
                updatedAt: admin.firestore.FieldValue.serverTimestamp(),
                adminNotes: 'No matching technician candidates found. Will retry.',
            });
        }
        catch (updateErr) {
            console.error(`[matchAndAssignBooking] Could not update booking to searching_technician: ${updateErr.message}`);
        }
        return { success: false, reason: 'no_candidates' };
    }
    // 5. Select Best Candidate (Cycle through top N)
    // We try to pick the *first* one that hasn't active pending request.
    // For simplicity in V2, we pick the top one. 
    // If top one is already pending (race condition), we skip.
    const bestCandidate = candidates[0]; // Simple top-1 selection for now
    // 6. Assignment Attempt (Transaction)
    try {
        await attemptAssignmentInTransaction(bookingId, bestCandidate, config);
        return { success: true, candidate: bestCandidate.techId, score: bestCandidate.totalScore };
    }
    catch (e) {
        console.error(`Assignment attempt failed: ${e.message}`);
        return { success: false, reason: 'transaction_failed' };
    }
}
// ==========================================
// SCORING ENGINE
// ==========================================
function calculateScore(tech, booking, distance, config) {
    const w = config.weights;
    // 1. Rating (0..1)
    const rating = tech.avgRating || 0;
    const rNorm = Math.min(Math.max(rating / 5.0, 0), 1);
    // 2. Distance (0..1, closer is better)
    const dNorm = Math.max(0, 1 - (distance / config.searchRadiusKm));
    // 3. Completion Rate (0..1)
    const cNorm = tech.completionRate !== undefined ? tech.completionRate : 1.0; // Default to 1 for new techs
    // 4. Risk (0..1, lower risk is better)
    // Assuming riskProfile might be attached or defaults. 
    // Ideally fetched, but if on tech doc:
    const riskScore = tech.riskScore || 0;
    const fNorm = Math.max(0, 1 - (riskScore / 100.0));
    // 5. Availability Freshness (0..1)
    // If heartbeat or last updated recent -> 1. Old -> 0.
    const lastUpdate = tech.updatedAt ? tech.updatedAt.toDate().getTime() : 0;
    const minutesSinceUpdate = (Date.now() - lastUpdate) / (1000 * 60);
    const aNorm = Math.max(0, 1 - (minutesSinceUpdate / 60.0)); // Decay over an hour
    // 6. Service Fit (0.5..1)
    // Check if tech matches ALL vs SOME services
    const bookingServices = (booking.services || []).map((s) => s.id);
    const techServices = tech.skills || []; // Assuming 'skills' or 'servicesOffered'
    const intersection = bookingServices.filter((s) => techServices.includes(s));
    let sNorm = 0.5;
    if (intersection.length === bookingServices.length)
        sNorm = 1.0;
    else if (intersection.length > 0)
        sNorm = 0.75;
    // 7. Fatigue (0..1, fresh is better)
    // Check lastJobEndedAt
    let tNorm = 1.0;
    if (tech.lastJobEndedAt) {
        const lastJobEnd = tech.lastJobEndedAt.toDate().getTime();
        const hoursSinceJob = (Date.now() - lastJobEnd) / (1000 * 60 * 60);
        if (hoursSinceJob < 1)
            tNorm = 0.5; // Just finished
        else if (hoursSinceJob < config.fatigueThresholdHours)
            tNorm = 0.8;
    }
    const totalScore = (w.rating * rNorm) +
        (w.distance * dNorm) +
        (w.completion * cNorm) +
        (w.risk * fNorm) +
        (w.availability * aNorm) +
        (w.serviceFit * sNorm) +
        (w.fatigue * tNorm);
    return {
        totalScore,
        breakdown: { rNorm, dNorm, cNorm, fNorm, aNorm, sNorm, tNorm }
    };
}
function isValidCandidate(tech, booking, config) {
    // 1. Status Check
    if (tech.status !== 'approved')
        return false;
    // 2. Risk Check
    // If tech doc has risk status, use it. Else assume ok.
    if (tech.riskStatus === 'suspended')
        return false;
    // Restricted techs might be filtered or scored low. Let's filter for now.
    if (tech.riskStatus === 'restricted')
        return false;
    // 3. Heartbeat (Freshness)
    if (tech.lastHeartbeatAt) {
        const hb = tech.lastHeartbeatAt.toDate().getTime();
        const mins = (Date.now() - hb) / (1000 * 60);
        if (mins > config.heartbeatExpiryMinutes)
            return false;
    }
    // 4. Overlapping Assignments
    // We check `currentAssignments`. If array not empty, skip?
    // Or check time slots. For V2 MVP, strictly single-tasking.
    if (tech.currentAssignments && tech.currentAssignments.length > 0) {
        // Double check they aren't actually finished.
        // Simplified: Block if any active assignment.
        return false;
    }
    return true;
}
async function hasTechnicianRejected(bookingId, techId) {
    const attempts = await db.collection('assignment_requests')
        .where('bookingId', '==', bookingId)
        .where('technicianId', '==', techId)
        .where('status', 'in', ['rejected', 'expired'])
        .limit(1)
        .get();
    return !attempts.empty;
}
async function attemptAssignmentInTransaction(bookingId, candidate, config) {
    await db.runTransaction(async (t) => {
        const bookingRef = db.collection('bookings').doc(bookingId);
        const bDoc = await t.get(bookingRef);
        if (!bDoc.exists)
            throw new Error('Booking missing');
        const bData = bDoc.data();
        const validAssignmentStatuses = ['confirmed', 'pending', 'pending_assignment', 'pending_payment', 'searching_technician'];
        if (!validAssignmentStatuses.includes(bData.status)) {
            throw new Error(`Booking ${bookingId} is in non-assignable state: ${bData.status}`);
        }
        // Check if there is already an active request
        const activeRequests = await db.collection('assignment_requests')
            .where('bookingId', '==', bookingId)
            .where('status', '==', 'pending')
            .get();
        if (!activeRequests.empty) {
            throw new Error('Active assignment request already exists');
        }
        const requestId = db.collection('assignment_requests').doc().id;
        const expiresAt = new Date(Date.now() + config.assignmentTimeoutSec * 1000);
        // Create Request
        t.set(db.collection('assignment_requests').doc(requestId), {
            id: requestId,
            bookingId,
            technicianId: candidate.techId,
            status: 'pending',
            score: candidate.totalScore,
            scoreBreakdown: candidate.scoreBreakdown,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            expiresAt: admin.firestore.Timestamp.fromDate(expiresAt)
        });
        // Update Booking Status to 'pending_acceptance' (intermediate state)
        // Or keep it 'confirmed' but mark 'lastAssignmentAttempt'.
        // Let's use 'pending_assignment'.
        t.update(bookingRef, {
            status: 'pending_assignment',
            lastAssignmentAttemptAt: admin.firestore.FieldValue.serverTimestamp(),
            currentCandidateId: candidate.techId // purely informational
        });
        // We can send notification AFTER transaction success, but commonly done in a trigger.
        // We'll do it here if possible or let the caller do it. 
        // Best practice: Trigger on assignment_requests.
    });
    // Post-Transaction Notification
    await (0, notifications_1.sendPushNotification)(candidate.techId, 'technicians', {
        title: 'New Job Offer! 🚀',
        body: 'You have been matched for a new job. Tap to accept.',
        data: { bookingId, type: 'job_offer', timeout: config.assignmentTimeoutSec.toString() }
    });
}
async function handleAdminEscalation(bookingId, reason) {
    await db.collection('bookings').doc(bookingId).update({
        status: 'pending_admin_review',
        adminNotes: `Matching failed: ${reason}. Escalated to manual review.`,
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
    });
    // Notify Admins
    // Fetch admins or send to generic topic
    // For MVP, just log
    console.warn(`Booking ${bookingId} escalated to admin. Reason: ${reason}`);
}
// ==========================================
// EXPORTS & HANDLERS
// ==========================================
exports.onBookingCreatedMatch = functions.firestore
    .document('bookings/{bookingId}')
    .onCreate(async (snap, context) => {
    const booking = snap.data();
    const bookingId = context.params.bookingId;
    const triggerStatuses = [
        'confirmed',
        'pending',
        'pending_payment',
        'searching_technician',
    ];
    if (triggerStatuses.includes(booking.status)) {
        console.log(`[onBookingCreatedMatch] Triggering matching for booking ${bookingId} (status=${booking.status})`);
        try {
            await matchAndAssignBooking(bookingId);
        }
        catch (err) {
            console.error(`[onBookingCreatedMatch] Matching failed for ${bookingId}: ${err.message}`);
            // Safe fallback: ensure booking stays in searching_technician
            try {
                await snap.ref.update({
                    status: 'searching_technician',
                    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
                    adminNotes: `Auto-matching error: ${err.message}`,
                });
            }
            catch (_) { /* ignore */ }
        }
    }
    else {
        console.log(`[onBookingCreatedMatch] Skipping matching for booking ${bookingId} (status=${booking.status})`);
    }
});
// Handle Acceptance/Rejection of Assignment
exports.handleAssignmentResponse = functions.region('asia-south1').https.onCall(async (data, context) => {
    if (!context.auth)
        throw new functions.https.HttpsError('unauthenticated', 'Auth required');
    const { assignmentId, action } = data; // action: 'accept' | 'reject'
    const assignRef = db.collection('assignment_requests').doc(assignmentId);
    await db.runTransaction(async (t) => {
        const doc = await t.get(assignRef);
        if (!doc.exists)
            throw new functions.https.HttpsError('not-found', 'Assignment request not found');
        const req = doc.data();
        if (req.technicianId !== context.auth.uid) {
            throw new functions.https.HttpsError('permission-denied', 'Not your assignment');
        }
        if (req.status !== 'pending') {
            throw new functions.https.HttpsError('failed-precondition', 'Request already processed');
        }
        // Check expiry
        const expiresAt = req.expiresAt.toDate();
        if (Date.now() > expiresAt.getTime()) {
            t.update(assignRef, { status: 'expired' });
            throw new functions.https.HttpsError('deadline-exceeded', 'Assignment offer expired');
        }
        if (action === 'accept') {
            t.update(assignRef, { status: 'accepted', respondedAt: admin.firestore.FieldValue.serverTimestamp() });
            // Finalize Booking
            const bookingRef = db.collection('bookings').doc(req.bookingId);
            t.update(bookingRef, {
                status: 'accepted',
                assignedTechnicianId: req.technicianId,
                assignedTechnicianName: (await db.collection('technicians').doc(req.technicianId).get()).data()?.name || 'Technician',
                acceptedAt: admin.firestore.FieldValue.serverTimestamp(),
                updatedAt: admin.firestore.FieldValue.serverTimestamp()
            });
            // Update Tech
            const techRef = db.collection('technicians').doc(req.technicianId);
            t.update(techRef, {
                currentAssignments: admin.firestore.FieldValue.arrayUnion(req.bookingId),
                updatedAt: admin.firestore.FieldValue.serverTimestamp()
            });
        }
        else if (action === 'reject') {
            t.update(assignRef, { status: 'rejected', respondedAt: admin.firestore.FieldValue.serverTimestamp() });
            // Trigger Rematch?
            // Usually we'd set booking back to 'confirmed' or trigger a function.
            const bookingRef = db.collection('bookings').doc(req.bookingId);
            t.update(bookingRef, {
                status: 'pending', // Reset for next match cycle
                lastRejectedTechId: req.technicianId
            });
        }
    });
    if (action === 'reject') {
        // Trigger rematch immediately
        const req = (await assignRef.get()).data();
        await matchAndAssignBooking(req.bookingId);
    }
    return { success: true };
});
//# sourceMappingURL=matching_v2.js.map
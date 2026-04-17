"use strict";
/**
 * Production-Grade Technician Matching Cloud Function
 *
 * Features:
 * - Haversine distance calculation
 * - Weighted ranking algorithm
 * - Fair distribution with cooldown
 * - Security validations
 * - Top 3 technician selection
 */
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
exports.cleanupStaleTechnicianStatus = exports.updateTechnicianAssignment = exports.matchTechnicians = void 0;
const functions = __importStar(require("firebase-functions"));
const admin = __importStar(require("firebase-admin"));
const db = admin.firestore();
// ==========================================
// CONFIGURATION & CONSTANTS
// ==========================================
const MATCHING_CONFIG = {
    maxDistanceKm: 25, // Maximum search radius
    maxResults: 3, // Return top 3 technicians
    cooldownMinutes: 30, // Recent assignment cooldown
    newTechnicianThreshold: 10, // Jobs threshold for "new" boost
    assignmentTimeoutSec: 90, // Assignment request timeout
    // Scoring weights
    weights: {
        rating: 0.35,
        completedOrders: 0.25,
        earningsNormalized: 0.15,
        reviewWeight: 0.10,
        newTechnicianBoost: 0.15,
    },
};
// ==========================================
// CORE MATCHING FUNCTION
// ==========================================
/**
 * Main function to find and rank technicians for a service request.
 * Called by the app when customer selects a service.
 */
exports.matchTechnicians = functions.region('asia-south1').https.onCall(async (data, context) => {
    // --- SECURITY VALIDATION ---
    // 1. Check authentication
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'Authentication required');
    }
    // 2. Validate input
    if (!data.serviceId || typeof data.serviceId !== 'string') {
        throw new functions.https.HttpsError('invalid-argument', 'Invalid serviceId');
    }
    if (!data.location ||
        typeof data.location.latitude !== 'number' ||
        typeof data.location.longitude !== 'number') {
        throw new functions.https.HttpsError('invalid-argument', 'Invalid location coordinates');
    }
    console.log(`[MATCH] Starting matching for service: ${data.serviceId}`);
    console.log(`[MATCH] Sub-service: ${data.subServiceId || 'none'}`);
    console.log(`[MATCH] Customer location: ${data.location.latitude}, ${data.location.longitude}`);
    try {
        // --- STEP 1: Query Eligible Technicians ---
        const eligibleTechnicians = await queryEligibleTechnicians(data.serviceId, data.subServiceId);
        if (eligibleTechnicians.length === 0) {
            console.log(`[MATCH] No eligible technicians found for service: ${data.serviceId}`);
            return { available: false };
        }
        console.log(`[MATCH] Found ${eligibleTechnicians.length} eligible technicians`);
        // --- STEP 2: Calculate Scores & Distance ---
        const scoredTechnicians = await scoreAndRankTechnicians(eligibleTechnicians, data.location);
        if (scoredTechnicians.length === 0) {
            console.log(`[MATCH] No technicians passed distance filter (${MATCHING_CONFIG.maxDistanceKm}km)`);
            return { available: false };
        }
        // --- STEP 3: Select Top 3 ---
        const topTechnicians = scoredTechnicians
            .slice(0, MATCHING_CONFIG.maxResults)
            .map((tech) => ({
            id: tech.id,
            name: tech.name || 'Technician',
            photoUrl: tech.photoUrl,
            rating: tech.rating,
            totalCompletedOrders: tech.totalCompletedOrders,
            distanceKm: Math.round(tech.distanceKm * 100) / 100,
            estimatedArrivalMinutes: Math.round(tech.estimatedArrivalMinutes),
            score: Math.round(tech.score * 100) / 100,
        }));
        console.log(`[MATCH] Returning ${topTechnicians.length} top technicians`);
        return {
            available: true,
            technicianCount: scoredTechnicians.length,
            topTechnicians,
        };
    }
    catch (error) {
        console.error(`[MATCH] Error during matching: ${error.message}`);
        throw new functions.https.HttpsError('internal', 'Failed to match technicians');
    }
});
// ==========================================
// HELPER FUNCTIONS
// ==========================================
/**
 * Query technicians with strict eligibility filters.
 * Uses Firestore indexes for performance.
 * Logs STRICT MATCH PASS / FAILED for debugging.
 */
async function queryEligibleTechnicians(serviceId, subServiceId) {
    // Query using compound index on isApproved + isOnline
    const snapshot = await db
        .collection('technicians')
        .where('isApproved', '==', true)
        .where('isOnline', '==', true)
        .get();
    const candidates = [];
    let checkedCount = 0;
    let passedCount = 0;
    let failedReasons = [];
    // Filter by services array with STRICT validation
    for (const doc of snapshot.docs) {
        const tech = doc.data();
        checkedCount++;
        // STRICT CHECK 1: Technician must have location
        if (!tech.location?.lat || !tech.location?.lng) {
            failedReasons.push(`[${doc.id}] No location`);
            continue;
        }
        // STRICT CHECK 2: Service must be in technician.services array
        if (!tech.services || !tech.services.includes(serviceId)) {
            failedReasons.push(`[${doc.id}] Service ${serviceId} not in services array`);
            continue;
        }
        // STRICT CHECK 3: If subServiceId provided, it MUST be in technician.subServices
        if (subServiceId != null) {
            if (!tech.subServices || !tech.subServices.includes(subServiceId)) {
                failedReasons.push(`[${doc.id}] SubService ${subServiceId} not in subServices array`);
                continue;
            }
        }
        // All strict checks passed
        passedCount++;
        candidates.push({ id: doc.id, data: tech });
    }
    // Debug logging
    console.log(`[MATCH] Checked: ${checkedCount}, Passed Strict Validation: ${passedCount}`);
    if (failedReasons.length > 0) {
        console.log(`[MATCH] STRICT MATCH FAILED for ${failedReasons.length} technicians:`);
        failedReasons.slice(0, 5).forEach((reason) => console.log(`[MATCH]   ${reason}`));
        if (failedReasons.length > 5) {
            console.log(`[MATCH]   ... and ${failedReasons.length - 5} more`);
        }
    }
    if (passedCount > 0) {
        console.log(`[MATCH] STRICT MATCH PASSED for ${passedCount} technicians`);
    }
    return candidates;
}
/**
 * Calculate scores for each technician based on weighted ranking algorithm.
 */
async function scoreAndRankTechnicians(candidates, customerLocation) {
    const scoredTechnicians = [];
    // Get max earnings for normalization (fetch from a doc or use reasonable default)
    const maxEarnings = await getMaxTechnicianEarnings();
    for (const candidate of candidates) {
        const tech = candidate.data;
        // --- DISTANCE CALCULATION (Haversine) ---
        const distanceKm = calculateHaversineDistance({ lat: tech.location.lat, lng: tech.location.lng }, { lat: customerLocation.latitude, lng: customerLocation.longitude });
        // Skip if too far
        if (distanceKm > MATCHING_CONFIG.maxDistanceKm) {
            continue;
        }
        // --- SCORE CALCULATION ---
        let score = 0;
        // 1. Rating score (0-1, normalized to 5)
        const ratingScore = (tech.rating || 0) / 5.0;
        score += ratingScore * MATCHING_CONFIG.weights.rating;
        // 2. Completed orders score (0-1, normalized to 100 orders)
        const ordersScore = Math.min((tech.totalCompletedOrders || 0) / 100, 1.0);
        score += ordersScore * MATCHING_CONFIG.weights.completedOrders;
        // 3. Earnings normalized (0-1)
        const earningsNormalized = maxEarnings > 0
            ? Math.min((tech.totalEarnings || 0) / maxEarnings, 1.0)
            : 0;
        score += earningsNormalized * MATCHING_CONFIG.weights.earningsNormalized;
        // 4. Review weight (bonus if > 10 reviews)
        const reviewWeight = (tech.totalReviews || 0) > 10 ? 1.0 : 0.5;
        score += reviewWeight * MATCHING_CONFIG.weights.reviewWeight;
        // 5. New technician boost
        const newTechnicianBoost = (tech.totalCompletedOrders || 0) < MATCHING_CONFIG.newTechnicianThreshold
            ? 1.0
            : 0.0;
        score += newTechnicianBoost * MATCHING_CONFIG.weights.newTechnicianBoost;
        // --- FAIR DISTRIBUTION RULE ---
        // Reduce score if recently assigned (cooldown)
        const cooldownReduction = calculateCooldownReduction(tech.lastAssignedAt);
        score = score * (1 - cooldownReduction);
        // --- ESTIMATED ARRIVAL TIME ---
        const estimatedArrivalMinutes = calculateETA(distanceKm);
        scoredTechnicians.push({
            id: candidate.id,
            name: tech.name,
            photoUrl: tech.photoUrl,
            rating: tech.rating || 0,
            totalCompletedOrders: tech.totalCompletedOrders || 0,
            distanceKm,
            estimatedArrivalMinutes,
            score,
        });
    }
    // Sort by:
    // 1. score DESC (primary)
    // 2. rating DESC (secondary)
    // 3. distance ASC (tertiary - closer is better)
    scoredTechnicians.sort((a, b) => {
        // Primary sort: score descending
        if (b.score !== a.score) {
            return b.score - a.score;
        }
        // Secondary sort: rating descending
        if (b.rating !== a.rating) {
            return b.rating - a.rating;
        }
        // Tertiary sort: distance ascending (closer is better)
        return a.distanceKm - b.distanceKm;
    });
    // Log filtered count
    console.log(`[MATCH] After distance filter (≤${MATCHING_CONFIG.maxDistanceKm}km): ${scoredTechnicians.length} technicians`);
    return scoredTechnicians;
}
/**
 * Calculate Haversine distance between two points.
 */
function calculateHaversineDistance(point1, point2) {
    const R = 6371; // Earth's radius in kilometers
    const dLat = toRadians(point2.lat - point1.lat);
    const dLng = toRadians(point2.lng - point1.lng);
    const a = Math.sin(dLat / 2) * Math.sin(dLat / 2) +
        Math.cos(toRadians(point1.lat)) *
            Math.cos(toRadians(point2.lat)) *
            Math.sin(dLng / 2) *
            Math.sin(dLng / 2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    return R * c;
}
function toRadians(degrees) {
    return degrees * (Math.PI / 180);
}
/**
 * Calculate cooldown reduction (20% if assigned within last 30 minutes).
 */
function calculateCooldownReduction(lastAssignedAt) {
    if (!lastAssignedAt)
        return 0;
    const thirtyMinutesAgo = Date.now() - 30 * 60 * 1000;
    const assignedAt = lastAssignedAt.toDate().getTime();
    if (assignedAt > thirtyMinutesAgo) {
        return 0.20; // 20% reduction
    }
    return 0;
}
/**
 * Calculate estimated arrival time based on distance.
 */
function calculateETA(distanceKm) {
    // Assume average speed of 30 km/h in urban areas
    const averageSpeedKmph = 30;
    // Base time: travel time + 5 min buffer
    const travelTimeMinutes = (distanceKm / averageSpeedKmph) * 60;
    const eta = travelTimeMinutes + 5;
    return Math.ceil(eta);
}
/**
 * Get maximum earnings for normalization.
 * In production, this should be cached or fetched from a config document.
 */
async function getMaxTechnicianEarnings() {
    try {
        const configDoc = await db.collection('config').doc('matching').get();
        if (configDoc.exists) {
            const config = configDoc.data();
            if (config?.maxEarningsForNormalization) {
                return config.maxEarningsForNormalization;
            }
        }
    }
    catch (error) {
        console.warn('[MATCH] Could not fetch max earnings config, using default');
    }
    // Default fallback (₹5,00,000)
    return 500000;
}
/**
 * Update technician's lastAssignedAt after successful assignment.
 * Called by the booking assignment function.
 */
exports.updateTechnicianAssignment = functions.region('asia-south1').https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'Auth required');
    }
    if (!data.technicianId || !data.bookingId) {
        throw new functions.https.HttpsError('invalid-argument', 'Invalid input');
    }
    await db.collection('technicians').doc(data.technicianId).update({
        lastAssignedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    console.log(`[MATCH] Updated lastAssignedAt for technician: ${data.technicianId}`);
    return { success: true };
});
/**
 * Batch job to clean up stale technician online status.
 * Runs every 5 minutes with maxInstances:1 to prevent parallel execution.
 */
exports.cleanupStaleTechnicianStatus = functions
    .runWith({ maxInstances: 1, timeoutSeconds: 540, memory: '256MB' })
    .pubsub.schedule('every 5 minutes')
    .onRun(async () => {
    console.log('Running cleanupStaleTechnicianStatus at', new Date().toISOString());
    // Firestore lock to prevent overlapping execution
    const lockRef = db.collection('system_locks').doc('cleanupStaleTechnicianStatus');
    const now = admin.firestore.Timestamp.now();
    const lockExpiry = admin.firestore.Timestamp.fromMillis(now.toMillis() - 4 * 60 * 1000); // 4 min lock
    const acquired = await db.runTransaction(async (t) => {
        const lockDoc = await t.get(lockRef);
        if (lockDoc.exists && lockDoc.data().lockedAt > lockExpiry) {
            return false; // still locked
        }
        t.set(lockRef, { lockedAt: now });
        return true;
    });
    if (!acquired) {
        console.log('[cleanupStaleTechnicianStatus] Skipped — previous run still active');
        return null;
    }
    try {
        const staleThreshold = Date.now() - 5 * 60 * 1000; // 5 minutes
        const snapshot = await db
            .collection('technicians')
            .where('isOnline', '==', true)
            .get();
        const batch = db.batch();
        let updateCount = 0;
        for (const doc of snapshot.docs) {
            const tech = doc.data();
            const lastHeartbeat = tech.lastHeartbeatAt;
            if (lastHeartbeat) {
                const heartbeatTime = lastHeartbeat.toDate().getTime();
                if (heartbeatTime < staleThreshold) {
                    batch.update(doc.ref, { isOnline: false });
                    updateCount++;
                }
            }
        }
        if (updateCount > 0) {
            await batch.commit();
            console.log(`[MATCH] Marked ${updateCount} technicians as offline`);
        }
    }
    finally {
        await lockRef.delete().catch(() => { });
    }
    return null;
});
//# sourceMappingURL=technician_matching.js.map
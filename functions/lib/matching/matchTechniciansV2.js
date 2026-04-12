"use strict";
/**
 * Production-Grade Technician Matching Cloud Function (2nd Gen)
 * Production-hardened with:
 * - Structured JSON logging
 * - Execution timing
 * - Detailed scoring breakdown
 * - Concurrency-safe queries
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
exports.matchTechniciansV2 = void 0;
const functions = __importStar(require("firebase-functions"));
const admin = __importStar(require("firebase-admin"));
if (!admin.apps.length) {
    admin.initializeApp();
}
const db = admin.firestore();
function createLogContext(customerId, serviceId) {
    return {
        customerId,
        serviceId,
        functionName: "matchTechniciansV1", // Renamed for clarity in logs
        startTime: Date.now()
    };
}
function logStructured(ctx, level, action, data) {
    const duration = Date.now() - ctx.startTime;
    const logEntry = {
        level,
        function: ctx.functionName,
        action,
        customerId: ctx.customerId,
        serviceId: ctx.serviceId,
        durationMs: duration,
        timestamp: new Date().toISOString(),
        ...data
    };
    console.log(JSON.stringify(logEntry));
}
// ==========================================
// CONFIGURATION
// ==========================================
const MATCHING_CONFIG = {
    maxDistanceKm: 25,
    maxResults: 3,
    cooldownMinutes: 30,
    newTechnicianThreshold: 10,
    assignmentTimeoutSec: 90,
    weights: {
        rating: 0.35,
        completedOrders: 0.25,
        earningsNormalized: 0.15,
        reviewWeight: 0.10,
        newTechnicianBoost: 0.15,
    },
};
exports.matchTechniciansV2 = functions.region('asia-south1').https.onCall(async (data, context) => {
    const ctx = createLogContext(context.auth?.uid, data?.serviceId);
    const startTime = Date.now();
    console.log('✅ [matchTechniciansV2] Auth UID:', context.auth?.uid);
    console.log('✅ [matchTechniciansV2] Context:', JSON.stringify({ auth: context.auth }, null, 2));
    // Authentication guard
    if (!context.auth) {
        console.error('❌ [matchTechniciansV2] context.auth is NULL');
        logStructured(ctx, "ERROR", "auth_failure", { error: "Authentication required" });
        throw new functions.https.HttpsError("unauthenticated", "Authentication required");
    }
    // Input validation
    if (!data.serviceId || typeof data.serviceId !== "string") {
        logStructured(ctx, "ERROR", "validation_failure", { error: "Invalid serviceId" });
        throw new functions.https.HttpsError("invalid-argument", "Invalid serviceId");
    }
    if (!data.location ||
        typeof data.location.latitude !== "number" ||
        typeof data.location.longitude !== "number") {
        logStructured(ctx, "ERROR", "validation_failure", { error: "Invalid location coordinates" });
        throw new functions.https.HttpsError("invalid-argument", "Invalid location coordinates");
    }
    logStructured(ctx, "INFO", "request_received", {
        serviceId: data.serviceId,
        subServiceId: data.subServiceId || "none",
        location: `${data.location.latitude}, ${data.location.longitude}`
    });
    try {
        // Query eligible technicians
        const eligibleStartTime = Date.now();
        const eligibleTechnicians = await queryEligibleTechnicians(data.serviceId, data.subServiceId);
        logStructured(ctx, "INFO", "eligible_query_complete", {
            count: eligibleTechnicians.length,
            durationMs: Date.now() - eligibleStartTime
        });
        if (eligibleTechnicians.length === 0) {
            logStructured(ctx, "INFO", "no_technicians_found", { serviceId: data.serviceId });
            return { available: false };
        }
        // Score and rank technicians
        const scoringStartTime = Date.now();
        const scoredTechnicians = await scoreAndRankTechnicians(eligibleTechnicians, data.location);
        logStructured(ctx, "INFO", "scoring_complete", {
            passedCount: scoredTechnicians.length,
            maxDistanceKm: MATCHING_CONFIG.maxDistanceKm,
            durationMs: Date.now() - scoringStartTime
        });
        if (scoredTechnicians.length === 0) {
            logStructured(ctx, "INFO", "no_technicians_in_range", {
                maxDistanceKm: MATCHING_CONFIG.maxDistanceKm
            });
            return { available: false };
        }
        // Select top technicians
        const topTechnicians = scoredTechnicians
            .slice(0, MATCHING_CONFIG.maxResults)
            .map((tech) => ({
            id: tech.id,
            name: tech.name || "Technician",
            photoUrl: tech.photoUrl,
            rating: tech.rating,
            totalCompletedOrders: tech.totalCompletedOrders,
            distanceKm: Math.round(tech.distanceKm * 100) / 100,
            estimatedArrivalMinutes: Math.round(tech.estimatedArrivalMinutes),
            score: Math.round(tech.score * 100) / 100,
        }));
        logStructured(ctx, "INFO", "success", {
            returnedCount: topTechnicians.length,
            totalScored: scoredTechnicians.length,
            durationMs: Date.now() - startTime
        });
        return {
            available: true,
            technicianCount: scoredTechnicians.length,
            topTechnicians,
        };
    }
    catch (error) {
        logStructured(ctx, "ERROR", "matching_failure", {
            error: error.message,
            stack: error.stack
        });
        throw new functions.https.HttpsError("internal", "Failed to match technicians");
    }
});
async function queryEligibleTechnicians(serviceId, subServiceId) {
    let query = db.collection("technicians")
        .where("isApproved", "==", true)
        .where("isOnline", "==", true);
    if (subServiceId) {
        query = query.where("subServices", "array-contains", subServiceId);
    }
    else {
        query = query.where("services", "array-contains", serviceId);
    }
    const snapshot = await query.get();
    const candidates = [];
    let checkedCount = 0;
    let passedCount = 0;
    let failedReasons = [];
    for (const doc of snapshot.docs) {
        const tech = doc.data();
        checkedCount++;
        if (!tech.location?.lat || !tech.location?.lng) {
            failedReasons.push(`[${doc.id}] No location`);
            continue;
        }
        if (!tech.services || !tech.services.includes(serviceId)) {
            failedReasons.push(`[${doc.id}] Service ${serviceId} not in services array`);
            continue;
        }
        if (subServiceId != null) {
            if (!tech.subServices || !tech.subServices.includes(subServiceId)) {
                failedReasons.push(`[${doc.id}] SubService ${subServiceId} not in subServices array`);
                continue;
            }
        }
        passedCount++;
        candidates.push({ id: doc.id, data: tech });
    }
    console.log(`[MATCH_V2] Checked: ${checkedCount}, Passed Strict Validation: ${passedCount}`);
    if (failedReasons.length > 0) {
        console.log(`[MATCH_V2] STRICT MATCH FAILED for ${failedReasons.length} technicians:`);
        failedReasons.slice(0, 5).forEach((reason) => console.log(`[MATCH_V2]   ${reason}`));
        if (failedReasons.length > 5) {
            console.log(`[MATCH_V2]   ... and ${failedReasons.length - 5} more`);
        }
    }
    if (passedCount > 0) {
        console.log(`[MATCH_V2] STRICT MATCH PASSED for ${passedCount} technicians`);
    }
    return candidates;
}
async function scoreAndRankTechnicians(candidates, customerLocation) {
    const scoredTechnicians = [];
    const maxEarnings = await getMaxTechnicianEarnings();
    for (const candidate of candidates) {
        const tech = candidate.data;
        const distanceKm = calculateHaversineDistance({ lat: tech.location.lat, lng: tech.location.lng }, { lat: customerLocation.latitude, lng: customerLocation.longitude });
        if (distanceKm > MATCHING_CONFIG.maxDistanceKm) {
            continue;
        }
        let score = 0;
        const ratingScore = (tech.rating || 0) / 5.0;
        score += ratingScore * MATCHING_CONFIG.weights.rating;
        const ordersScore = Math.min((tech.totalCompletedOrders || 0) / 100, 1.0);
        score += ordersScore * MATCHING_CONFIG.weights.completedOrders;
        const earningsNormalized = maxEarnings > 0
            ? Math.min((tech.totalEarnings || 0) / maxEarnings, 1.0)
            : 0;
        score += earningsNormalized * MATCHING_CONFIG.weights.earningsNormalized;
        const reviewWeight = (tech.totalReviews || 0) > 10 ? 1.0 : 0.5;
        score += reviewWeight * MATCHING_CONFIG.weights.reviewWeight;
        const newTechnicianBoost = (tech.totalCompletedOrders || 0) < MATCHING_CONFIG.newTechnicianThreshold
            ? 1.0
            : 0.0;
        score += newTechnicianBoost * MATCHING_CONFIG.weights.newTechnicianBoost;
        const cooldownReduction = calculateCooldownReduction(tech.lastAssignedAt);
        score = score * (1 - cooldownReduction);
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
    scoredTechnicians.sort((a, b) => {
        if (b.score !== a.score)
            return b.score - a.score;
        if (b.rating !== a.rating)
            return b.rating - a.rating;
        return a.distanceKm - b.distanceKm;
    });
    console.log(`[MATCH_V2] After distance filter (≤${MATCHING_CONFIG.maxDistanceKm}km): ${scoredTechnicians.length} technicians`);
    return scoredTechnicians;
}
function calculateHaversineDistance(point1, point2) {
    const R = 6371;
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
function calculateCooldownReduction(lastAssignedAt) {
    if (!lastAssignedAt)
        return 0;
    const thirtyMinutesAgo = Date.now() - 30 * 60 * 1000;
    const assignedAt = lastAssignedAt.toDate().getTime();
    if (assignedAt > thirtyMinutesAgo) {
        return 0.20;
    }
    return 0;
}
function calculateETA(distanceKm) {
    const averageSpeedKmph = 30;
    const travelTimeMinutes = (distanceKm / averageSpeedKmph) * 60;
    const eta = travelTimeMinutes + 5;
    return Math.ceil(eta);
}
async function getMaxTechnicianEarnings() {
    try {
        const configDoc = await db.collection("config").doc("matching").get();
        if (configDoc.exists) {
            const config = configDoc.data();
            if (config?.maxEarningsForNormalization) {
                return config.maxEarningsForNormalization;
            }
        }
    }
    catch (error) {
        console.warn("[MATCH_V2] Could not fetch max earnings config, using default");
    }
    return 500000;
}
//# sourceMappingURL=matchTechniciansV2.js.map
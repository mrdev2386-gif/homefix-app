
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

import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

const db = admin.firestore();

// ==========================================
// CONFIGURATION & CONSTANTS
// ==========================================

const MATCHING_CONFIG = {
  maxDistanceKm: 25,                    // Maximum search radius
  maxResults: 3,                        // Return top 3 technicians
  cooldownMinutes: 30,                  // Recent assignment cooldown
  newTechnicianThreshold: 10,           // Jobs threshold for "new" boost
  assignmentTimeoutSec: 90,             // Assignment request timeout
  
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
// TYPES & INTERFACES
// ==========================================

interface TechnicianDocument {
  isApproved: boolean;
  isOnline: boolean;
  services: string[];
  subServices: string[]; // Added for subService matching
  location: {
    lat: number;
    lng: number;
  };
  rating: number;
  totalReviews: number;
  totalCompletedOrders: number;
  totalEarnings: number;
  lastAssignedAt?: admin.firestore.Timestamp;
  createdAt: admin.firestore.Timestamp;
  name?: string;
  photoUrl?: string;
}

interface CustomerLocation {
  latitude: number;
  longitude: number;
}

interface MatchedTechnician {
  id: string;
  name: string;
  photoUrl?: string;
  rating: number;
  totalCompletedOrders: number;
  distanceKm: number;
  estimatedArrivalMinutes: number;
  score: number;
}

interface MatchingResponse {
  available: boolean;
  technicianCount?: number;
  topTechnicians?: MatchedTechnician[];
  error?: string;
}

// ==========================================
// CORE MATCHING FUNCTION
// ==========================================

/**
 * Main function to find and rank technicians for a service request.
 * Called by the app when customer selects a service.
 */
export const matchTechnicians = functions.https.onCall(
  async (
    data: { 
      serviceId: string; 
      subServiceId?: string;
      location: CustomerLocation 
    },
    context: functions.https.CallableContext
  ): Promise<MatchingResponse> => {
    
    // --- SECURITY VALIDATION ---
    
    // 1. Check authentication
    if (!context.auth) {
      throw new functions.https.HttpsError(
        'unauthenticated',
        'Authentication required'
      );
    }

    // 2. Validate input
    if (!data.serviceId || typeof data.serviceId !== 'string') {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'Invalid serviceId'
      );
    }

    if (
      !data.location ||
      typeof data.location.latitude !== 'number' ||
      typeof data.location.longitude !== 'number'
    ) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'Invalid location coordinates'
      );
    }

    console.log(`[MATCH] Starting matching for service: ${data.serviceId}`);
    console.log(`[MATCH] Sub-service: ${data.subServiceId || 'none'}`);
    console.log(`[MATCH] Customer location: ${data.location.latitude}, ${data.location.longitude}`);

    try {
      // --- STEP 1: Query Eligible Technicians ---
      
      const eligibleTechnicians = await queryEligibleTechnicians(
        data.serviceId, 
        data.subServiceId
      );

      if (eligibleTechnicians.length === 0) {
        console.log(`[MATCH] No eligible technicians found for service: ${data.serviceId}`);
        return { available: false };
      }

      console.log(`[MATCH] Found ${eligibleTechnicians.length} eligible technicians`);

      // --- STEP 2: Calculate Scores & Distance ---
      
      const scoredTechnicians = await scoreAndRankTechnicians(
        eligibleTechnicians,
        data.location
      );

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

    } catch (error: any) {
      console.error(`[MATCH] Error during matching: ${error.message}`);
      throw new functions.https.HttpsError(
        'internal',
        'Failed to match technicians'
      );
    }
  }
);

// ==========================================
// HELPER FUNCTIONS
// ==========================================

/**
 * Query technicians with strict eligibility filters.
 * Uses Firestore indexes for performance.
 * Logs STRICT MATCH PASS / FAILED for debugging.
 */
async function queryEligibleTechnicians(
  serviceId: string,
  subServiceId?: string
): Promise<{ id: string; data: TechnicianDocument }[]> {
  // Query using compound index on isApproved + isOnline
  const snapshot = await db
    .collection('technicians')
    .where('isApproved', '==', true)
    .where('isOnline', '==', true)
    .get();

  const candidates: { id: string; data: TechnicianDocument }[] = [];
  let checkedCount = 0;
  let passedCount = 0;
  let failedReasons: string[] = [];

  // Filter by services array with STRICT validation
  for (const doc of snapshot.docs) {
    const tech = doc.data() as TechnicianDocument;
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
async function scoreAndRankTechnicians(
  candidates: { id: string; data: TechnicianDocument }[],
  customerLocation: CustomerLocation
): Promise<ScoredTechnician[]> {
  const scoredTechnicians: ScoredTechnician[] = [];

  // Get max earnings for normalization (fetch from a doc or use reasonable default)
  const maxEarnings = await getMaxTechnicianEarnings();

  for (const candidate of candidates) {
    const tech = candidate.data;

    // --- DISTANCE CALCULATION (Haversine) ---
    const distanceKm = calculateHaversineDistance(
      { lat: tech.location.lat, lng: tech.location.lng },
      { lat: customerLocation.latitude, lng: customerLocation.longitude }
    );

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
function calculateHaversineDistance(
  point1: { lat: number; lng: number },
  point2: { lat: number; lng: number }
): number {
  const R = 6371; // Earth's radius in kilometers
  const dLat = toRadians(point2.lat - point1.lat);
  const dLng = toRadians(point2.lng - point1.lng);

  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(toRadians(point1.lat)) *
      Math.cos(toRadians(point2.lat)) *
      Math.sin(dLng / 2) *
      Math.sin(dLng / 2);

  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));

  return R * c;
}

function toRadians(degrees: number): number {
  return degrees * (Math.PI / 180);
}

/**
 * Calculate cooldown reduction (20% if assigned within last 30 minutes).
 */
function calculateCooldownReduction(
  lastAssignedAt?: admin.firestore.Timestamp
): number {
  if (!lastAssignedAt) return 0;

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
function calculateETA(distanceKm: number): number {
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
async function getMaxTechnicianEarnings(): Promise<number> {
  try {
    const configDoc = await db.collection('config').doc('matching').get();
    if (configDoc.exists) {
      const config = configDoc.data();
      if (config?.maxEarningsForNormalization) {
        return config.maxEarningsForNormalization;
      }
    }
  } catch (error) {
    console.warn('[MATCH] Could not fetch max earnings config, using default');
  }

  // Default fallback (₹5,00,000)
  return 500000;
}

// ==========================================
// SUPPORTING FUNCTIONS
// ==========================================

interface ScoredTechnician {
  id: string;
  name?: string;
  photoUrl?: string;
  rating: number;
  totalCompletedOrders: number;
  distanceKm: number;
  estimatedArrivalMinutes: number;
  score: number;
}

/**
 * Update technician's lastAssignedAt after successful assignment.
 * Called by the booking assignment function.
 */
export const updateTechnicianAssignment = functions.https.onCall(
  async (data: { technicianId: string; bookingId: string }, context) => {
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
  }
);

/**
 * Batch job to clean up stale technician online status.
 * Should be scheduled to run every minute.
 */
export const cleanupStaleTechnicianStatus = functions.pubsub
  .schedule('every 1 minutes')
  .onRun(async () => {
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
        const heartbeatTime = (lastHeartbeat as admin.firestore.Timestamp).toDate().getTime();
        
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

    return null;
  });

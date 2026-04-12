"use strict";
/**
 * Review Aggregation Trigger
 *
 * Automatically updates technician ratings and syncs to all their services
 * when a new review is created.
 *
 * CRITICAL: This ensures rating consistency across:
 * - technicians/{technicianId}
 * - technician_services/{serviceId}
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
exports.onReviewCreated = void 0;
const functions = __importStar(require("firebase-functions"));
const admin = __importStar(require("firebase-admin"));
const db = admin.firestore();
exports.onReviewCreated = functions.firestore
    .document('reviews/{reviewId}')
    .onCreate(async (snap, context) => {
    const reviewData = snap.data();
    if (!reviewData) {
        console.error('[REVIEW_TRIGGER] No review data found');
        return;
    }
    const technicianId = reviewData.technicianId;
    if (!technicianId) {
        console.error('[REVIEW_TRIGGER] No technicianId in review');
        return;
    }
    try {
        // 1. Fetch all reviews for this technician
        const reviewsSnapshot = await db
            .collection('reviews')
            .where('technicianId', '==', technicianId)
            .get();
        const totalReviews = reviewsSnapshot.size;
        if (totalReviews === 0) {
            console.warn('[REVIEW_TRIGGER] No reviews found for technician:', technicianId);
            return;
        }
        // 2. Calculate average rating
        let totalRating = 0;
        reviewsSnapshot.forEach((doc) => {
            const review = doc.data();
            totalRating += review.rating || 0;
        });
        const averageRating = Math.round((totalRating / totalReviews) * 10) / 10;
        console.log(`[REVIEW_TRIGGER] Technician ${technicianId}: ${averageRating} (${totalReviews} reviews)`);
        // 3. Update technician document
        await db.collection('technicians').doc(technicianId).update({
            averageRating,
            totalReviews,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        // 4. Update ALL services belonging to this technician
        const servicesSnapshot = await db
            .collection('technician_services')
            .where('technicianId', '==', technicianId)
            .get();
        if (servicesSnapshot.empty) {
            console.log(`[REVIEW_TRIGGER] No services found for technician ${technicianId}`);
            return;
        }
        // Batch update all services
        const batch = db.batch();
        servicesSnapshot.forEach((serviceDoc) => {
            batch.update(serviceDoc.ref, {
                averageRating,
                totalReviews,
                updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            });
        });
        await batch.commit();
        console.log(`[REVIEW_TRIGGER] ✅ Updated ${servicesSnapshot.size} services for technician ${technicianId}`);
    }
    catch (error) {
        console.error('[REVIEW_TRIGGER] Error updating ratings:', error);
        // Don't throw - allow review creation to succeed even if aggregation fails
    }
});
//# sourceMappingURL=review_triggers.js.map
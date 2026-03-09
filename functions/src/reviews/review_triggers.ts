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

import { onDocumentCreated } from "firebase-functions/v2/firestore";
import * as admin from "firebase-admin";

const db = admin.firestore();

/**
 * Trigger: Runs when a new review is created
 * 
 * Actions:
 * 1. Recalculate technician's average rating
 * 2. Update technician document
 * 3. Update ALL technician's services with new rating
 */
export const onReviewCreated = onDocumentCreated(
  {
    document: "reviews/{reviewId}",
    region: "us-central1",
    memory: "256MiB",
  },
  async (event) => {
    const reviewData = event.data?.data();
    
    if (!reviewData) {
      console.error("[REVIEW_TRIGGER] No review data found");
      return;
    }

    const technicianId = reviewData.technicianId;
    
    if (!technicianId) {
      console.error("[REVIEW_TRIGGER] No technicianId in review");
      return;
    }

    try {
      // 1. Fetch all reviews for this technician
      const reviewsSnapshot = await db
        .collection("reviews")
        .where("technicianId", "==", technicianId)
        .get();

      const totalReviews = reviewsSnapshot.size;
      
      if (totalReviews === 0) {
        console.warn("[REVIEW_TRIGGER] No reviews found for technician:", technicianId);
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
      await db.collection("technicians").doc(technicianId).update({
        averageRating,
        totalReviews,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      // 4. Update ALL services belonging to this technician
      const servicesSnapshot = await db
        .collection("technician_services")
        .where("technicianId", "==", technicianId)
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

    } catch (error) {
      console.error("[REVIEW_TRIGGER] Error updating ratings:", error);
      // Don't throw - allow review creation to succeed even if aggregation fails
    }
  }
);

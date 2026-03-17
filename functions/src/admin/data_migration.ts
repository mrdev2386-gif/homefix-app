/**
 * Technician Data Normalization Migration
 * Runs once to normalize all technician documents to standard schema
 */

import * as functions from "firebase-functions";

import * as admin from "firebase-admin";


const db = admin.firestore();

/**
 * Normalize Technician Data
 * Migrates legacy fields to standard schema
 */
export const normalizeTechnicianData = functions.https.onCall(
  async (request, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError("unauthenticated", "Authentication required");
    }

    // Verify admin access
    if (!context.auth.token?.admin) {
      throw new functions.https.HttpsError("permission-denied", "Admin access required");
    }

    console.log("[MIGRATION] Starting technician data normalization");

    let processedCount = 0;
    let migratedCount = 0;

    try {
      const techniciansRef = db.collection('technicians');
      const snapshot = await techniciansRef.get();

      const batch = db.batch();
      let batchCount = 0;
      const BATCH_SIZE = 500;

      for (const doc of snapshot.docs) {
        const data = doc.data();
        const updates: any = {};
        let needsUpdate = false;

        // 1. Normalize status field
        if (data.status === "active") {
          updates.status = "approved";
          needsUpdate = true;
          console.log(`[MIGRATION] ${doc.id}: status "active" -> "approved"`);
        }

        // 2. Normalize stepsCompleted fields
        if (data.stepsCompleted) {
          const steps = { ...data.stepsCompleted };
          
          // Convert bank -> portfolio
          if (steps.bank !== undefined) {
            steps.portfolio = steps.bank;
            delete steps.bank;
            needsUpdate = true;
            console.log(`[MIGRATION] ${doc.id}: bank -> portfolio`);
          }
          
          // Convert kyc -> verification
          if (steps.kyc !== undefined) {
            steps.verification = steps.kyc;
            delete steps.kyc;
            needsUpdate = true;
            console.log(`[MIGRATION] ${doc.id}: kyc -> verification`);
          }
          
          if (needsUpdate) {
            updates.stepsCompleted = steps;
          }

          // 3. Update profile completion if all steps complete
          const allStepsComplete = 
            steps.personalDetails === true &&
            steps.serviceCategories === true &&
            steps.portfolio === true &&
            steps.verification === true;

          if (allStepsComplete && data.profileCompletion !== 100) {
            updates.profileCompletion = 100;
            updates.onboardingCompleted = true;
            needsUpdate = true;
            console.log(`[MIGRATION] ${doc.id}: profileCompletion -> 100%`);
          }
        }

        // 4. Remove legacy fields
        const legacyFields = ['profileApproved', 'isApproved'];
        for (const field of legacyFields) {
          if (data[field] !== undefined) {
            updates[field] = admin.firestore.FieldValue.delete();
            needsUpdate = true;
            console.log(`[MIGRATION] ${doc.id}: removing legacy field ${field}`);
          }
        }

        if (needsUpdate) {
          updates.updatedAt = admin.firestore.FieldValue.serverTimestamp();
          updates.migrationVersion = 1; // Mark as migrated
          batch.update(doc.ref, updates);
          migratedCount++;
          batchCount++;

          // Commit batch if it reaches size limit
          if (batchCount >= BATCH_SIZE) {
            await batch.commit();
            console.log(`[MIGRATION] Committed batch of ${batchCount} updates`);
            batchCount = 0;
          }
        }

        processedCount++;
      }

      // Commit remaining updates
      if (batchCount > 0) {
        await batch.commit();
        console.log(`[MIGRATION] Committed final batch of ${batchCount} updates`);
      }

      console.log(`[MIGRATION] Completed: ${processedCount} processed, ${migratedCount} migrated`);

      return {
        success: true,
        processedCount,
        migratedCount,
        message: `Migration completed: ${migratedCount} documents updated`
      };

    } catch (error) {
      console.error("[MIGRATION] Error:", error);
      throw new functions.https.HttpsError("internal", `Migration failed: ${error}`);
    }
  }
);

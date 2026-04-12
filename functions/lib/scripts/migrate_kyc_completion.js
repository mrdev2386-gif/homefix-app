"use strict";
/**
 * ONE-TIME MIGRATION SCRIPT
 *
 * Fixes existing technicians where:
 * - stepsCompleted.kyc == true
 * - stepsCompleted.bank == true
 * - stepsCompleted.services == true
 * BUT isKycComplete == false
 *
 * Run this ONCE after deploying the fixed Cloud Function
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
const admin = __importStar(require("firebase-admin"));
// Initialize Firebase Admin (if not already initialized)
if (!admin.apps.length) {
    admin.initializeApp();
}
const db = admin.firestore();
async function migrateExistingTechnicians() {
    console.log('[MIGRATION] Starting technician KYC migration...');
    let fixedCount = 0;
    let skippedCount = 0;
    let errorCount = 0;
    try {
        // Query all technicians where isKycComplete is false or missing
        const snapshot = await db.collection('technicians')
            .where('isKycComplete', '==', false)
            .get();
        console.log(`[MIGRATION] Found ${snapshot.size} technicians with isKycComplete=false`);
        // Process in batches of 500 (Firestore limit)
        const batchSize = 500;
        let batch = db.batch();
        let batchCount = 0;
        for (const doc of snapshot.docs) {
            const data = doc.data();
            const stepsCompleted = data.stepsCompleted || {};
            // Check if all critical steps are complete
            const hasKyc = stepsCompleted.kyc === true;
            const hasBank = stepsCompleted.bank === true;
            const hasServices = stepsCompleted.services === true;
            if (hasKyc && hasBank && hasServices) {
                // This technician should have isKycComplete = true
                console.log(`[MIGRATION] Fixing technician ${doc.id}`);
                batch.set(doc.ref, {
                    isKycComplete: true,
                    onboardingCompleted: true,
                    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
                    migratedAt: admin.firestore.FieldValue.serverTimestamp()
                }, { merge: true });
                fixedCount++;
                batchCount++;
                // Commit batch if we hit the limit
                if (batchCount >= batchSize) {
                    await batch.commit();
                    console.log(`[MIGRATION] Committed batch of ${batchCount} updates`);
                    batch = db.batch();
                    batchCount = 0;
                }
            }
            else {
                skippedCount++;
            }
        }
        // Commit remaining batch
        if (batchCount > 0) {
            await batch.commit();
            console.log(`[MIGRATION] Committed final batch of ${batchCount} updates`);
        }
        console.log('[MIGRATION] ===== MIGRATION COMPLETE =====');
        console.log(`[MIGRATION] Fixed: ${fixedCount}`);
        console.log(`[MIGRATION] Skipped: ${skippedCount}`);
        console.log(`[MIGRATION] Errors: ${errorCount}`);
    }
    catch (error) {
        console.error('[MIGRATION] Fatal error:', error);
        throw error;
    }
}
// Run migration
migrateExistingTechnicians()
    .then(() => {
    console.log('[MIGRATION] Script completed successfully');
    process.exit(0);
})
    .catch((error) => {
    console.error('[MIGRATION] Script failed:', error);
    process.exit(1);
});
//# sourceMappingURL=migrate_kyc_completion.js.map
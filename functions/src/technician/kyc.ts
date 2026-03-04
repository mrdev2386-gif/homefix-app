import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import * as https from 'firebase-functions/v1/https';

const db = admin.firestore();

/**
 * Evaluate technician KYC completion status
 * 
 * SECURITY CRITICAL: Only Cloud Functions can set isKycComplete
 * Client cannot directly write this field
 * Firestore rules block direct writes to this field
 * 
 * This function:
 * 1. Checks all required KYC fields in technician document
 * 2. Determines if KYC is complete based on actual data
 * 3. Updates isKycComplete in technician document
 * 4. Returns the updated status
 * 
 * Required fields for KYC completion:
 * - fullName (non-empty)
 * - phone (non-empty)
 * - city (selected)
 * - experienceYears (selected)
 * - profile photo (uploaded)
 * - aadhaar documents (uploaded)
 * - services selected (at least 1)
 * - bank details (if payout enabled)
 */
export const evaluateTechnicianKyc = functions.https.onCall(
    async (data: any, context: functions.https.CallableContext) => {
        try {
            // 1. Authentication check
            if (!context.auth) {
                throw new https.HttpsError(
                    'unauthenticated',
                    'User must be authenticated to evaluate KYC'
                );
            }

            const uid = context.auth.uid;
            console.log(`[KYC_EVAL] Evaluating KYC for technician: ${uid}`);

            // 2. Fetch technician document
            const techDoc = await db.collection('technicians').doc(uid).get();

            if (!techDoc.exists) {
                throw new https.HttpsError(
                    'not-found',
                    'Technician profile not found'
                );
            }

            const tech = techDoc.data() as any;

            // 3. Check all required KYC fields
            const kycChecklist = {
                fullName: !!(tech.fullName && tech.fullName.trim().length >= 3),
                phone: !!(tech.phone && tech.phone.length >= 10),
                city: !!(tech.city && tech.city.trim().length > 0),
                experience: typeof tech.experienceYears === 'number' && tech.experienceYears >= 0,
                profilePhoto: !!(tech.profilePhotoUrl && tech.profilePhotoUrl.length > 0),
                
                // Aadhaar documents
                aadhaarNumber: !!(tech.aadhaarNumber && tech.aadhaarNumber.trim().length === 12),
                aadhaarFrontUrl: !!(tech.aadhaarFrontUrl && tech.aadhaarFrontUrl.length > 0),
                aadhaarBackUrl: !!(tech.aadhaarBackUrl && tech.aadhaarBackUrl.length > 0),
                
                // Services (check if at least 1 service category selected)
                services: !!(
                    tech.primaryCategoryId ||
                    (Array.isArray(tech.skills) && tech.skills.length > 0)
                ),
                
                // Bank details (required for payout)
                bankDetails: !!(
                    tech.bankName &&
                    tech.accountNumber &&
                    tech.ifscCode &&
                    tech.accountHolderName
                ),
            };

            // Log checklist for debugging
            console.log(`[KYC_EVAL] KYC Checklist for ${uid}:`, kycChecklist);

            // 4. Determine KYC complete status
            // Core required fields
            const coreComplete =
                kycChecklist.fullName &&
                kycChecklist.phone &&
                kycChecklist.city &&
                kycChecklist.experience &&
                kycChecklist.profilePhoto &&
                kycChecklist.aadhaarNumber &&
                kycChecklist.aadhaarFrontUrl &&
                kycChecklist.aadhaarBackUrl &&
                kycChecklist.services;

            // Bank details are secondary (nice-to-have, but let's require them for max features)
            // For MVP: KYC complete = core fields complete
            // For payment: Also require bank details
            const isKycComplete = coreComplete;

            console.log(
                `[KYC_EVAL] KYC Complete for ${uid}: ${isKycComplete} (coreComplete=${coreComplete}, bankReady=${kycChecklist.bankDetails})`
            );

            // 5. Update technician document with the evaluated status
            // This is the ONLY place where isKycComplete gets updated
            await db.collection('technicians').doc(uid).update({
                isKycComplete: isKycComplete,
                onboardingCompleted: isKycComplete,
                updatedAt: admin.firestore.FieldValue.serverTimestamp(),
                
                // Track which fields contributed to KYC status
                _kycChecklist: kycChecklist,
                _kycEvaluatedAt: admin.firestore.FieldValue.serverTimestamp(),
            });

            console.log(`[KYC_EVAL] Updated KYC status for ${uid}`);

            // 6. Return the result
            return {
                success: true,
                isKycComplete: isKycComplete,
                checklist: kycChecklist,
                message: isKycComplete
                    ? 'KYC requirements complete. Ready for approval.'
                    : 'KYC requirements incomplete. Please complete all fields.',
            };
        } catch (error) {
            console.error(`[KYC_EVAL] Error evaluating KYC:`, error);

            if (error instanceof https.HttpsError) {
                throw error;
            }

            throw new https.HttpsError(
                'internal',
                `Failed to evaluate KYC: ${error instanceof Error ? error.message : 'Unknown error'}`
            );
        }
    }
);

/**
 * Check if technician KYC is complete (read-only verification)
 * Client can call this to check current KYC status without modifying anything
 */
export const checkKycStatus = functions.https.onCall(
    async (data: any, context: functions.https.CallableContext) => {
        try {
            if (!context.auth) {
                throw new https.HttpsError(
                    'unauthenticated',
                    'User must be authenticated'
                );
            }

            const uid = context.auth.uid;

            const techDoc = await db.collection('technicians').doc(uid).get();

            if (!techDoc.exists) {
                return {
                    success: true,
                    isKycComplete: false,
                    message: 'Technician profile not found',
                };
            }

            const tech = techDoc.data() as any;

            return {
                success: true,
                isKycComplete: tech.isKycComplete || false,
                onboardingCompleted: tech.onboardingCompleted || false,
                kycChecklist: tech._kycChecklist || null,
                kycEvaluatedAt: tech._kycEvaluatedAt || null,
            };
        } catch (error) {
            console.error(`[KYC_CHECK] Error checking KYC:`, error);

            if (error instanceof https.HttpsError) {
                throw error;
            }

            throw new https.HttpsError(
                'internal',
                `Failed to check KYC: ${error instanceof Error ? error.message : 'Unknown error'}`
            );
        }
    }
);

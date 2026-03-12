import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

const db = admin.firestore();

/**
 * Create minimal technician document when Firebase Auth user is created
 * 
 * This is the SINGLE SOURCE OF TRUTH for technician account creation.
 * When any user is created in Firebase Auth with phone or email, this function
 * automatically creates a minimal technician profile to get them started.
 * 
 * IDEMPOTENT: Safe to call multiple times - won't overwrite existing documents
 */
export const createTechnicianOnAuthCreate = functions.auth.user().onCreate(async (user) => {
        if (!user || !user.uid) {
            console.error('[TECH_AUTH_TRIGGER] User object missing from event');
            return;
        }
        try {
            const uid = user.uid;
            const phone = user.phoneNumber || '';
            const email = user.email || '';
            const displayName = user.displayName || 'Technician';

            console.log(`[TECH_AUTH_TRIGGER] Creating minimal technician doc for user: ${uid}`);

            // Check if technician document already exists (idempotent)
            const existingDoc = await db.collection('technicians').doc(uid).get();

            if (existingDoc.exists) {
                console.log(`[TECH_AUTH_TRIGGER] Technician document already exists for ${uid}, skipping creation`);
                return;
            }

            // Create minimal technician document with ONLY required fields
            // All other fields are set to defaults or null
            const minimalTechnicianDoc = {
                uid: uid,
                phone: phone,
                email: email,
                name: displayName,
                
                // Onboarding flags
                onboardingCompleted: false,
                isKycComplete: false,
                isApproved: false,
                adminApproved: false,
                
                // Security & role (backend-only fields)
                role: 'technician',
                status: 'pending',
                
                // Audit fields
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
                updatedAt: admin.firestore.FieldValue.serverTimestamp(),
                
                // Default profile fields
                isOnline: false,
                isVerified: false,
                avgRating: 4.5,
                totalRatings: 0,
                ratingBreakdown: { '1': 0, '2': 0, '3': 0, '4': 0, '5': 0 },
                jobsDone: 0,
                skills: [],
            };

            // Write to Firestore
            await db.collection('technicians').doc(uid).set(
                minimalTechnicianDoc,
                { merge: true } // Merge in case doc was just created by another process
            );

            console.log(`[TECH_AUTH_TRIGGER] Minimal technician document created successfully for ${uid}`);

            // Audit log
            await db.collection('audit_logs').add({
                action: 'technician_auto_created_on_auth',
                userId: uid,
                userEmail: email,
                userPhone: phone,
                timestamp: admin.firestore.FieldValue.serverTimestamp(),
                source: 'firebase_auth_onCreate_trigger',
            });

        } catch (error) {
            console.error(`[TECH_AUTH_TRIGGER] Error creating technician document:`, error);
            // DO NOT rethrow - this is a user creation flow and we don't want auth to fail
            // The client can retry or use a Cloud Function fallback
        }
    });

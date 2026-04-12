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
exports.createTechnicianOnAuthCreate = void 0;
const functions = __importStar(require("firebase-functions"));
const admin = __importStar(require("firebase-admin"));
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
exports.createTechnicianOnAuthCreate = functions.auth.user().onCreate(async (user) => {
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
        await db.collection('technicians').doc(uid).set(minimalTechnicianDoc, { merge: true } // Merge in case doc was just created by another process
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
    }
    catch (error) {
        console.error(`[TECH_AUTH_TRIGGER] Error creating technician document:`, error);
        // DO NOT rethrow - this is a user creation flow and we don't want auth to fail
        // The client can retry or use a Cloud Function fallback
    }
});
//# sourceMappingURL=auth.js.map
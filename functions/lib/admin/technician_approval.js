"use strict";
/**
 * Admin Technician Approval Function
 * Properly sets technician status and ensures profile completion is 100%
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
exports.approveTechnician = void 0;
const functions = __importStar(require("firebase-functions"));
const admin = __importStar(require("firebase-admin"));
const security_1 = require("../shared/security");
const db = admin.firestore();
/**
 * Approve or Reject Technician
 * Sets proper status and profile completion
 */
exports.approveTechnician = functions.region('asia-south1').https.onCall((0, security_1.secureCallable)(async (request, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError("unauthenticated", "Authentication required");
    }
    // Verify admin access
    if (!context.auth.token?.admin) {
        throw new functions.https.HttpsError("permission-denied", "Admin access required");
    }
    const { technicianId, action, rejectionReason } = request.data;
    if (!technicianId || !action) {
        throw new functions.https.HttpsError("invalid-argument", "Technician ID and action are required");
    }
    const techRef = db.collection('technicians').doc(technicianId);
    const techDoc = await techRef.get();
    if (!techDoc.exists) {
        throw new functions.https.HttpsError("not-found", "Technician not found");
    }
    const updateData = {
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    };
    if (action === "approve") {
        // COMPLETE APPROVAL: Set all required fields for approved technician
        updateData.status = "approved";
        updateData.onboardingCompleted = true;
        updateData.profileCompletion = 100;
        updateData.profileApprovalRequested = true;
        updateData.profileRejected = false;
        updateData.stepsCompleted = {
            personalDetails: true,
            serviceCategories: true,
            portfolio: true,
            verification: true,
        };
        console.log(`[ADMIN APPROVAL] Fully approving technician ${technicianId} with all required fields`);
    }
    else if (action === "reject") {
        updateData.status = "rejected";
        updateData.profileRejected = true;
        if (rejectionReason) {
            updateData.rejectionReason = (0, security_1.sanitize)(rejectionReason);
        }
        console.log(`[ADMIN APPROVAL] Rejecting technician ${technicianId}: ${rejectionReason || 'No reason provided'}`);
    }
    await techRef.update(updateData);
    return {
        success: true,
        technicianId,
        action,
        message: `Technician ${action}d successfully`,
    };
}));
//# sourceMappingURL=technician_approval.js.map
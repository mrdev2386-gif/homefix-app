"use strict";
/**
 * Admin Service Management Cloud Functions
 *
 * Handles approval, rejection, and status management of technician services
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
exports.disableService = exports.rejectService = exports.approveService = void 0;
const functions = __importStar(require("firebase-functions"));
const admin = __importStar(require("firebase-admin"));
const db = admin.firestore();
/**
 * Approve a technician service
 * Changes status from 'pending' to 'active'
 */
exports.approveService = functions.region('asia-south1').https.onCall(async (request, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError("unauthenticated", "Admin authentication required");
    }
    const { serviceId } = request.data;
    if (!serviceId) {
        throw new functions.https.HttpsError("invalid-argument", "Service ID is required");
    }
    try {
        const serviceRef = db.collection('technician_services').doc(serviceId);
        const serviceDoc = await serviceRef.get();
        if (!serviceDoc.exists) {
            throw new functions.https.HttpsError("not-found", "Service not found");
        }
        const serviceData = serviceDoc.data();
        if (serviceData.status !== 'pending') {
            throw new functions.https.HttpsError("failed-precondition", `Service is not pending approval. Current status: ${serviceData.status}`);
        }
        await serviceRef.update({
            status: 'active',
            isPublished: true,
            technicianApproved: true,
            approvedAt: admin.firestore.Timestamp.now(),
            approvedBy: context.auth.uid,
            updatedAt: admin.firestore.Timestamp.now()
        });
        console.log(`Service ${serviceId} approved by admin ${context.auth.uid}`);
        return {
            success: true,
            message: 'Service approved successfully',
            serviceId,
            newStatus: 'active'
        };
    }
    catch (error) {
        console.error('Error approving service:', error);
        throw new functions.https.HttpsError("internal", error.message || "Failed to approve service");
    }
});
/**
 * Reject a technician service
 * Changes status from 'pending' to 'rejected'
 */
exports.rejectService = functions.region('asia-south1').https.onCall(async (request, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError("unauthenticated", "Admin authentication required");
    }
    const { serviceId, reason } = request.data;
    if (!serviceId) {
        throw new functions.https.HttpsError("invalid-argument", "Service ID is required");
    }
    try {
        const serviceRef = db.collection('technician_services').doc(serviceId);
        const serviceDoc = await serviceRef.get();
        if (!serviceDoc.exists) {
            throw new functions.https.HttpsError("not-found", "Service not found");
        }
        const serviceData = serviceDoc.data();
        if (serviceData.status !== 'pending') {
            throw new functions.https.HttpsError("failed-precondition", `Service is not pending approval. Current status: ${serviceData.status}`);
        }
        await serviceRef.update({
            status: 'rejected',
            isPublished: false,
            technicianApproved: false,
            rejectedAt: admin.firestore.Timestamp.now(),
            rejectedBy: context.auth.uid,
            rejectionReason: reason || 'No reason provided',
            updatedAt: admin.firestore.Timestamp.now()
        });
        console.log(`Service ${serviceId} rejected by admin ${context.auth.uid}`);
        return {
            success: true,
            message: 'Service rejected',
            serviceId,
            newStatus: 'rejected'
        };
    }
    catch (error) {
        console.error('Error rejecting service:', error);
        throw new functions.https.HttpsError("internal", error.message || "Failed to reject service");
    }
});
/**
 * Disable an active service
 * Changes status from 'active' to 'disabled'
 */
exports.disableService = functions.region('asia-south1').https.onCall(async (request, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError("unauthenticated", "Admin authentication required");
    }
    const { serviceId, reason } = request.data;
    if (!serviceId) {
        throw new functions.https.HttpsError("invalid-argument", "Service ID is required");
    }
    try {
        const serviceRef = db.collection('technician_services').doc(serviceId);
        const serviceDoc = await serviceRef.get();
        if (!serviceDoc.exists) {
            throw new functions.https.HttpsError("not-found", "Service not found");
        }
        await serviceRef.update({
            status: 'disabled',
            isPublished: false,
            disabledAt: admin.firestore.Timestamp.now(),
            disabledBy: context.auth.uid,
            disableReason: reason || 'Disabled by admin',
            updatedAt: admin.firestore.Timestamp.now()
        });
        console.log(`Service ${serviceId} disabled by admin ${context.auth.uid}`);
        return {
            success: true,
            message: 'Service disabled',
            serviceId,
            newStatus: 'disabled'
        };
    }
    catch (error) {
        console.error('Error disabling service:', error);
        throw new functions.https.HttpsError("internal", error.message || "Failed to disable service");
    }
});
//# sourceMappingURL=serviceApproval.js.map
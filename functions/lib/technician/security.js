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
exports.bindDevice = void 0;
const functions = __importStar(require("firebase-functions"));
const admin = __importStar(require("firebase-admin"));
const security_1 = require("../shared/security");
const db = admin.firestore();
exports.bindDevice = functions.region('asia-south1').https.onCall(async (data, context) => {
    (0, security_1.assertAuthenticated)(context);
    const uid = context.auth.uid;
    const { deviceId, deviceInfo } = data;
    if (!deviceId) {
        throw new functions.https.HttpsError('invalid-argument', 'Device ID required');
    }
    const techRef = db.collection('technicians').doc(uid);
    const techDoc = await techRef.get();
    if (!techDoc.exists) {
        throw new functions.https.HttpsError('not-found', 'Technician profile not found');
    }
    const techData = techDoc.data();
    // If deviceId already set and different, require admin approval (or re-login flow)
    if (techData.deviceId && techData.deviceId !== deviceId) {
        console.warn(`Device change attempt for ${uid}. Old: ${techData.deviceId}, New: ${deviceId}`);
        // Logic: Allow change if > 30 days? Or require admin?
        // For high security: Block and ask to contact support.
        // For UX: Maybe allow with OTP? (Not implemented here)
        // We will log a change request
        await db.collection('device_change_requests').add({
            technicianId: uid,
            oldDeviceId: techData.deviceId,
            newDeviceId: deviceId,
            newDeviceInfo: deviceInfo,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            status: 'pending'
        });
        throw new functions.https.HttpsError('permission-denied', 'New device detected. Please contact support to authorize this device.');
    }
    // Bind ID
    await techRef.update({
        deviceId,
        deviceInfo,
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
    });
    return { success: true };
});
//# sourceMappingURL=security.js.map
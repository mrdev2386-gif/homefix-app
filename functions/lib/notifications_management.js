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
exports.deleteAllNotificationsCallable = exports.deleteNotificationCallable = exports.markAllNotificationsRead = exports.markNotificationRead = void 0;
const functions = __importStar(require("firebase-functions"));
const admin = __importStar(require("firebase-admin"));
const security_1 = require("./shared/security");
const db = admin.firestore();
/**
 * Marks a specific notification as read
 */
exports.markNotificationRead = functions.region('asia-south1').https.onCall((0, security_1.secureCallable)(async (data, context) => {
    const uid = context.auth?.uid;
    if (!uid)
        throw new functions.https.HttpsError('unauthenticated', 'User not logged in');
    const { notificationId } = data;
    if (!notificationId)
        throw new functions.https.HttpsError('invalid-argument', 'Notification ID is required');
    const notifRef = db.collection('notifications').doc(notificationId);
    const notifDoc = await notifRef.get();
    if (!notifDoc.exists)
        throw new functions.https.HttpsError('not-found', 'Notification not found');
    if (notifDoc.data()?.userId !== uid)
        throw new functions.https.HttpsError('permission-denied', 'Unauthorized access');
    await notifRef.update({ isRead: true, updatedAt: admin.firestore.FieldValue.serverTimestamp() });
    return { success: true };
}));
/**
 * Marks all notifications for the current user as read
 */
exports.markAllNotificationsRead = functions.region('asia-south1').https.onCall((0, security_1.secureCallable)(async (data, context) => {
    const uid = context.auth?.uid;
    if (!uid)
        throw new functions.https.HttpsError('unauthenticated', 'User not logged in');
    const snapshot = await db.collection('notifications')
        .where('userId', '==', uid)
        .where('isRead', '==', false)
        .get();
    const batch = db.batch();
    snapshot.docs.forEach(doc => {
        batch.update(doc.ref, { isRead: true, updatedAt: admin.firestore.FieldValue.serverTimestamp() });
    });
    if (!snapshot.empty)
        await batch.commit();
    return { success: true, count: snapshot.size };
}));
/**
 * Deletes a specific notification
 */
exports.deleteNotificationCallable = functions.region('asia-south1').https.onCall((0, security_1.secureCallable)(async (data, context) => {
    const uid = context.auth?.uid;
    if (!uid)
        throw new functions.https.HttpsError('unauthenticated', 'User not logged in');
    const { notificationId } = data;
    if (!notificationId)
        throw new functions.https.HttpsError('invalid-argument', 'Notification ID is required');
    const notifRef = db.collection('notifications').doc(notificationId);
    const notifDoc = await notifRef.get();
    if (!notifDoc.exists)
        return { success: true }; // Already deleted
    if (notifDoc.data()?.userId !== uid)
        throw new functions.https.HttpsError('permission-denied', 'Unauthorized access');
    await notifRef.delete();
    return { success: true };
}));
/**
 * Deletes all notifications for the current user
 */
exports.deleteAllNotificationsCallable = functions.region('asia-south1').https.onCall((0, security_1.secureCallable)(async (data, context) => {
    const uid = context.auth?.uid;
    if (!uid)
        throw new functions.https.HttpsError('unauthenticated', 'User not logged in');
    const snapshot = await db.collection('notifications')
        .where('userId', '==', uid)
        .get();
    const batch = db.batch();
    snapshot.docs.forEach(doc => {
        batch.delete(doc.ref);
    });
    if (!snapshot.empty)
        await batch.commit();
    return { success: true, count: snapshot.size };
}));
//# sourceMappingURL=notifications_management.js.map
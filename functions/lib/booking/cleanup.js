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
exports.cleanupStaleBookings = void 0;
const functions = __importStar(require("firebase-functions"));
const admin = __importStar(require("firebase-admin"));
const notify = __importStar(require("../shared/notification_helper"));
const db = admin.firestore();
exports.cleanupStaleBookings = functions.pubsub
    .schedule('every 1 hours')
    .onRun(async (context) => {
    const now = Date.now();
    const twentyFourHoursAgo = now - (24 * 60 * 60 * 1000);
    // Cancel bookings stuck in technician_pending for 24+ hours
    const staleBookings = await db.collection('bookings')
        .where('status', '==', 'technician_pending')
        .where('adminApprovedAt', '<', admin.firestore.Timestamp.fromMillis(twentyFourHoursAgo))
        .get();
    for (const doc of staleBookings.docs) {
        await doc.ref.update({
            status: 'cancelled',
            cancellationReason: 'Technician did not respond within 24 hours',
            cancelledBy: 'system',
            cancelledAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        await notify.notifyCustomerBookingCancelled(doc.data().customerId, doc.id, 'Technician did not respond. Please try booking again.');
    }
    console.log(`Cancelled ${staleBookings.size} stale bookings`);
});
//# sourceMappingURL=cleanup.js.map
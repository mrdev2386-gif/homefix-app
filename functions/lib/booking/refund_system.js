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
exports.refundBookingPayment = void 0;
const functions = __importStar(require("firebase-functions"));
const admin = __importStar(require("firebase-admin"));
const security_1 = require("../shared/security");
const db = admin.firestore();
// ==========================================
// REFUND BOOKING PAYMENT
// FIX 4: Use functions.config() for Razorpay keys (consistent with all other payment functions)
// FIX 5: DEPRECATED - Use initiateRefund from razorpay.ts instead
// ==========================================
/**
 * @deprecated HARD DISABLED - Use initiateRefund from razorpay.ts instead
 * This function has been permanently disabled to prevent duplicate refund paths.
 * All refund requests MUST use the initiateRefund function from razorpay.ts.
 */
exports.refundBookingPayment = functions
    .region('asia-south1')
    .https.onCall((0, security_1.secureCallable)(async (data, context) => {
    // HARD DISABLED - Force migration to new refund system
    throw new functions.https.HttpsError('failed-precondition', 'DEPRECATED: This refund function is disabled. Use initiateRefund from razorpay.ts instead. Contact admin for migration.');
}));
//# sourceMappingURL=refund_system.js.map
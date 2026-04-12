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
exports.onBookingPaidGenerateInvoice = void 0;
const functions = __importStar(require("firebase-functions"));
const admin = __importStar(require("firebase-admin"));
const db = admin.firestore();
/**
 * Trigger: Generate Invoice Document when Booking is Paid
 */
exports.onBookingPaidGenerateInvoice = functions.firestore
    .document('bookings/{bookingId}')
    .onUpdate(async (change, context) => {
    const bookingId = context.params.bookingId;
    const before = change.before.data();
    const after = change.after.data();
    if (!before || !after)
        return;
    // Trigger only when paymentStatus transitions to 'paid'
    if (before.paymentStatus !== 'paid' && after.paymentStatus === 'paid') {
        console.log(`[INVOICE] Generating invoice for booking ${bookingId}`);
        try {
            const invoiceId = `INV-${Date.now()}-${bookingId.substring(0, 5)}`.toUpperCase();
            const invoiceRef = db.collection('invoices').doc(invoiceId);
            const amount = after.finalAmount || after.price || 0;
            const platformFee = after.platformCommission || (amount * 0.10);
            const technicianPayout = after.technicianPayout || (amount - platformFee);
            const invoiceData = {
                invoiceId,
                bookingId,
                customerId: after.customerId,
                technicianId: after.technicianId,
                serviceName: after.serviceName || 'Home Service',
                totalAmount: amount,
                discountAmount: after.discountAmount || 0,
                platformFee,
                technicianPayout,
                paymentMethod: after.paymentMethod || 'wallet',
                paidAt: after.paidAt || admin.firestore.FieldValue.serverTimestamp(),
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
                status: 'paid'
            };
            await invoiceRef.set(invoiceData);
            // Link invoice to booking
            await change.after.ref.update({
                invoiceId: invoiceId
            });
            console.log(`[INVOICE] Invoice ${invoiceId} created successfully.`);
        }
        catch (error) {
            console.error(`[INVOICE] Failed to generate invoice for ${bookingId}:`, error);
        }
    }
});
//# sourceMappingURL=invoice_logic.js.map
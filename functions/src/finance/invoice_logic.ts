
import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

const db = admin.firestore();

/**
 * Trigger: Generate Invoice Document when Booking is Paid
 */
export const onBookingPaidGenerateInvoice = functions.firestore
    .document('bookings/{bookingId}')
    .onUpdate(async (change, context) => {
        const bookingId = context.params.bookingId;
        const before = change.before.data();
        const after = change.after.data();

        if (!before || !after) return;

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
            } catch (error) {
                console.error(`[INVOICE] Failed to generate invoice for ${bookingId}:`, error);
            }
        }
    });

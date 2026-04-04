/**
 * COMPLETE BOOKING FLOW - Firebase Cloud Functions
 * 
 * FLOW:
 * 1. Customer creates booking → status: "pending_admin_approval"
 * 2. Admin approves → status: "approved_by_admin" 
 * 3. Technician sees job → accepts/rejects
 * 4. Payment options: "pay_before_work" or "pay_after_work"
 * 5. Service completion → QR payment for after_work mode
 * 6. Wallet transactions for technician earnings
 */

import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { updateBookingStatusStandalone } from '../shared/status_history_tracker';

const db = admin.firestore();

// ==========================================
// STEP 1: CREATE BOOKING REQUEST
// ==========================================

interface CreateBookingData {
    serviceId: string;
    technicianId: string;
    serviceName: string;
    category: string;
    price: number;
    address: Record<string, any>;
    description?: string;
    scheduledDate: string;
    scheduledTime: string;
    paymentMode?: 'pay_before_work' | 'pay_after_work';
}

export const createBookingRequest = functions.region('asia-south1').https.onCall(
    async (data: CreateBookingData, context) => {
        if (!context.auth) {
            throw new functions.https.HttpsError('unauthenticated', 'Authentication required');
        }

        const customerId = context.auth.uid;
        const { serviceId, technicianId, serviceName, category, price, address, description, scheduledDate, scheduledTime, paymentMode } = data;

        // Validate service exists
        const serviceDoc = await db.collection('technician_services').doc(serviceId).get();
        if (!serviceDoc.exists) {
            throw new functions.https.HttpsError('not-found', 'Service not found');
        }

        const serviceData = serviceDoc.data()!;
        if (serviceData.status !== 'approved') {
            throw new functions.https.HttpsError('failed-precondition', 'Service not available');
        }

        // Get technician info
        const techDoc = await db.collection('technicians').doc(technicianId).get();
        if (!techDoc.exists) {
            throw new functions.https.HttpsError('not-found', 'Technician not found');
        }

        const techData = techDoc.data()!;
        
        // Get customer info
        const customerDoc = await db.collection('customers').doc(customerId).get();
        const customerData = customerDoc.data();

        const bookingId = db.collection('bookings').doc().id;
        const now = admin.firestore.FieldValue.serverTimestamp();

        const bookingData = {
            bookingId,
            customerId,
            customerName: customerData?.name || 'Customer',
            technicianId,
            technicianName: techData.name || 'Technician',
            serviceId,
            serviceName,
            category,
            price,
            address,
            description: description || '',
            scheduledDate,
            scheduledTime,
            bookingStatus: 'pending_admin_approval',
            paymentMode: paymentMode || 'pay_after_work',
            paymentStatus: 'unpaid',
            createdAt: now,
            updatedAt: now
        };

        await db.collection('bookings').doc(bookingId).set(bookingData);

        // Notify admin
        const adminsSnapshot = await db.collection('admins').get();
        for (const adminDoc of adminsSnapshot.docs) {
            const adminData = adminDoc.data();
            if (adminData?.fcmToken) {
                await admin.messaging().send({
                    token: adminData.fcmToken,
                    notification: {
                        title: 'New Booking Request',
                        body: `${customerData?.name || 'Customer'} requested ${serviceName}`
                    },
                    data: {
                        bookingId,
                        type: 'new_booking_request'
                    }
                });
            }
        }

        return { success: true, bookingId, status: 'pending_admin_approval' };
    }
);

// ==========================================
// STEP 2: ADMIN APPROVE BOOKING
// ==========================================

export const approveBookingRequest = functions.region('asia-south1').https.onCall(
    async (data: { bookingId: string }, context) => {
        if (!context.auth) {
            throw new functions.https.HttpsError('unauthenticated', 'Authentication required');
        }

        // Verify admin role
        const adminDoc = await db.collection('admins').doc(context.auth.uid).get();
        if (!adminDoc.exists) {
            throw new functions.https.HttpsError('permission-denied', 'Admin access required');
        }

        const { bookingId } = data;
        const bookingRef = db.collection('bookings').doc(bookingId);
        const bookingDoc = await bookingRef.get();

        if (!bookingDoc.exists) {
            throw new functions.https.HttpsError('not-found', 'Booking not found');
        }

        const booking = bookingDoc.data()!;

        if (booking.bookingStatus !== 'pending_admin_approval') {
            throw new functions.https.HttpsError('failed-precondition', 'Booking already processed');
        }

        const now = admin.firestore.FieldValue.serverTimestamp();

        await updateBookingStatusStandalone(bookingId, 'approved_by_admin', {
            bookingStatus: 'approved_by_admin',
            approvedAt: now,
            approvedBy: context.auth.uid,
        });

        // Send notification to technician
        const techDoc = await db.collection('technicians').doc(booking.technicianId).get();
        const techData = techDoc.data();

        if (techData?.fcmToken) {
            await admin.messaging().send({
                token: techData.fcmToken,
                notification: {
                    title: 'New Job Available',
                    body: `Admin approved booking for ${booking.serviceName}`
                },
                data: {
                    bookingId,
                    type: 'job_approved'
                }
            });
        }

        return { success: true, status: 'approved_by_admin' };
    }
);

// ==========================================
// STEP 3: TECHNICIAN ACCEPT/REJECT JOB
// ==========================================

export const technicianRespondToJob = functions.region('asia-south1').https.onCall(
    async (data: { bookingId: string; action: 'accept' | 'reject'; reason?: string }, context) => {
        if (!context.auth) {
            throw new functions.https.HttpsError('unauthenticated', 'Authentication required');
        }

        const technicianId = context.auth.uid;
        const { bookingId, action, reason } = data;

        const bookingRef = db.collection('bookings').doc(bookingId);
        const bookingDoc = await bookingRef.get();

        if (!bookingDoc.exists) {
            throw new functions.https.HttpsError('not-found', 'Booking not found');
        }

        const booking = bookingDoc.data()!;

        if (booking.technicianId !== technicianId) {
            throw new functions.https.HttpsError('permission-denied', 'Not your booking');
        }

        if (booking.bookingStatus !== 'approved_by_admin') {
            throw new functions.https.HttpsError('failed-precondition', 'Booking not ready for response');
        }

        const now = admin.firestore.FieldValue.serverTimestamp();

        if (action === 'accept') {
            await updateBookingStatusStandalone(bookingId, 'technician_accepted', {
                bookingStatus: 'technician_accepted',
                acceptedAt: now,
            });

            // Notify customer
            const customerDoc = await db.collection('customers').doc(booking.customerId).get();
            const customerData = customerDoc.data();

            if (customerData?.fcmToken) {
                await admin.messaging().send({
                    token: customerData.fcmToken,
                    notification: {
                        title: 'Booking Accepted',
                        body: `${booking.technicianName} accepted your booking`
                    },
                    data: {
                        bookingId,
                        type: 'booking_accepted'
                    }
                });
            }

            return { success: true, status: 'technician_accepted' };
        } else {
            await updateBookingStatusStandalone(bookingId, 'technician_rejected', {
                bookingStatus: 'technician_rejected',
                rejectedAt: now,
                rejectionReason: reason || 'Technician unavailable',
            });

            // Notify customer and admin
            const customerDoc = await db.collection('customers').doc(booking.customerId).get();
            const customerData = customerDoc.data();

            if (customerData?.fcmToken) {
                await admin.messaging().send({
                    token: customerData.fcmToken,
                    notification: {
                        title: 'Booking Update',
                        body: 'Technician is unavailable. We will assign another technician.'
                    },
                    data: {
                        bookingId,
                        type: 'booking_rejected'
                    }
                });
            }

            return { success: true, status: 'technician_rejected' };
        }
    }
);

// ==========================================
// STEP 4: PAY BEFORE WORK
// ==========================================

export const payBeforeWork = functions.region('asia-south1').https.onCall(
    async (data: { bookingId: string; paymentDetails: any }, context) => {
        if (!context.auth) {
            throw new functions.https.HttpsError('unauthenticated', 'Authentication required');
        }

        const customerId = context.auth.uid;
        const { bookingId, paymentDetails } = data;

        const bookingRef = db.collection('bookings').doc(bookingId);
        const bookingDoc = await bookingRef.get();

        if (!bookingDoc.exists) {
            throw new functions.https.HttpsError('not-found', 'Booking not found');
        }

        const booking = bookingDoc.data()!;

        if (booking.customerId !== customerId) {
            throw new functions.https.HttpsError('permission-denied', 'Not your booking');
        }

        if (booking.paymentMode !== 'pay_before_work') {
            throw new functions.https.HttpsError('failed-precondition', 'Payment mode mismatch');
        }

        // TODO: Integrate with Razorpay for actual payment processing
        // For now, simulate successful payment

        const now = admin.firestore.FieldValue.serverTimestamp();

        await bookingRef.update({
            paymentStatus: 'paid',
            paymentCompletedAt: now,
            paymentDetails,
            updatedAt: now
        });

        // Notify technician
        const techDoc = await db.collection('technicians').doc(booking.technicianId).get();
        const techData = techDoc.data();

        if (techData?.fcmToken) {
            await admin.messaging().send({
                token: techData.fcmToken,
                notification: {
                    title: 'Payment Completed',
                    body: 'Customer has paid. You can start the work.'
                },
                data: {
                    bookingId,
                    type: 'payment_completed'
                }
            });
        }

        return { success: true, paymentStatus: 'paid' };
    }
);

// ==========================================
// STEP 5: COMPLETE SERVICE
// ==========================================

export const completeService = functions.region('asia-south1').https.onCall(
    async (data: { bookingId: string }, context) => {
        if (!context.auth) {
            throw new functions.https.HttpsError('unauthenticated', 'Authentication required');
        }

        const technicianId = context.auth.uid;
        const { bookingId } = data;

        const bookingRef = db.collection('bookings').doc(bookingId);
        const bookingDoc = await bookingRef.get();

        if (!bookingDoc.exists) {
            throw new functions.https.HttpsError('not-found', 'Booking not found');
        }

        const booking = bookingDoc.data()!;

        if (booking.technicianId !== technicianId) {
            throw new functions.https.HttpsError('permission-denied', 'Not your booking');
        }

        const now = admin.firestore.FieldValue.serverTimestamp();

        if (booking.paymentMode === 'pay_before_work') {
            await updateBookingStatusStandalone(bookingId, 'service_completed', {
                bookingStatus: 'service_completed',
                serviceCompletedAt: now,
                paymentStatus: 'paid',
            });

            // Create wallet transaction for technician
            await createTechnicianWalletTransaction(technicianId, bookingId, booking.price);

        } else {
            await updateBookingStatusStandalone(bookingId, 'service_completed', {
                bookingStatus: 'service_completed',
                serviceCompletedAt: now,
                paymentStatus: 'pending_after_work_payment',
            });
        }

        // Notify customer
        const customerDoc = await db.collection('customers').doc(booking.customerId).get();
        const customerData = customerDoc.data();

        if (customerData?.fcmToken) {
            const message = booking.paymentMode === 'pay_after_work' 
                ? 'Service completed! Please make payment via QR code.'
                : 'Service completed! Thank you for your business.';

            await admin.messaging().send({
                token: customerData.fcmToken,
                notification: {
                    title: 'Service Completed',
                    body: message
                },
                data: {
                    bookingId,
                    type: 'service_completed'
                }
            });
        }

        return { success: true, status: 'service_completed' };
    }
);

// ==========================================
// STEP 6: CONFIRM AFTER WORK PAYMENT
// ==========================================

export const confirmAfterWorkPayment = functions.region('asia-south1').https.onCall(
    async (data: { bookingId: string }, context) => {
        if (!context.auth) {
            throw new functions.https.HttpsError('unauthenticated', 'Authentication required');
        }

        const customerId = context.auth.uid;
        const { bookingId } = data;

        const bookingRef = db.collection('bookings').doc(bookingId);
        const bookingDoc = await bookingRef.get();

        if (!bookingDoc.exists) {
            throw new functions.https.HttpsError('not-found', 'Booking not found');
        }

        const booking = bookingDoc.data()!;

        if (booking.customerId !== customerId) {
            throw new functions.https.HttpsError('permission-denied', 'Not your booking');
        }

        if (booking.paymentStatus !== 'pending_after_work_payment') {
            throw new functions.https.HttpsError('failed-precondition', 'Payment not pending');
        }

        const now = admin.firestore.FieldValue.serverTimestamp();

        await updateBookingStatusStandalone(bookingId, booking.bookingStatus || 'service_completed', {
            paymentStatus: 'paid',
            paymentMode: 'pay_after_work',
            paidAt: now,
        });

        // Create wallet transaction for technician
        await createTechnicianWalletTransaction(booking.technicianId, bookingId, booking.price);

        return { success: true, paymentStatus: 'paid' };
    }
);

// ==========================================
// HELPER: CREATE TECHNICIAN WALLET TRANSACTION
// ==========================================

async function createTechnicianWalletTransaction(technicianId: string, bookingId: string, amount: number) {
    const txnId = db.collection('technician_wallet_transactions').doc().id;
    const now = admin.firestore.FieldValue.serverTimestamp();

    await db.collection('technician_wallet_transactions').doc(txnId).set({
        technicianId,
        bookingId,
        amount,
        type: 'service_payment',
        createdAt: now
    });

    // Update technician wallet balance
    const walletRef = db.collection('technician_wallets').doc(technicianId);
    const walletDoc = await walletRef.get();
    
    const currentBalance = walletDoc.exists ? (walletDoc.data()?.balance || 0) : 0;
    
    await walletRef.set({
        balance: currentBalance + amount,
        updatedAt: now
    }, { merge: true });
}

// ==========================================
// TECHNICIAN QR CODE GENERATION
// ==========================================

export const generateTechnicianQR = functions.region('asia-south1').https.onCall(
    async (data: { bookingId: string }, context) => {
        if (!context.auth) {
            throw new functions.https.HttpsError('unauthenticated', 'Authentication required');
        }

        const technicianId = context.auth.uid;
        const { bookingId } = data;

        // Get technician profile
        const techDoc = await db.collection('technicians').doc(technicianId).get();
        if (!techDoc.exists) {
            throw new functions.https.HttpsError('not-found', 'Technician not found');
        }

        const techData = techDoc.data()!;

        // Return QR data (UPI ID or wallet QR code)
        return {
            success: true,
            qrData: {
                upiId: techData.upiId || `${technicianId}@homefix`,
                walletQrCode: techData.walletQrCode || `homefix://pay/${technicianId}/${bookingId}`,
                technicianName: techData.name,
                bookingId
            }
        };
    }
);

// ==========================================
// UPDATE BOOKING STATUS (GENERIC)
// ==========================================

export const updateBookingStatus = functions.region('asia-south1').https.onCall(
    async (data: { bookingId: string; status: string }, context) => {
        if (!context.auth) {
            throw new functions.https.HttpsError('unauthenticated', 'Authentication required');
        }

        const { bookingId, status } = data;
        const now = admin.firestore.FieldValue.serverTimestamp();

        await updateBookingStatusStandalone(bookingId, status, {});

        return { success: true, status };
    }
);
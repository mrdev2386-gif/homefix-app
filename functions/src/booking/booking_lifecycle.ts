import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { sendNotificationToToken } from '../shared/notification_helper';

const db = admin.firestore();

// ==========================================
// NOTIFY ADMIN ON NEW BOOKING
// ==========================================
export const notifyAdminNewBooking = functions.firestore
  .document('bookings/{bookingId}')
  .onCreate(async (snapshot, context) => {
    const booking = snapshot.data();
    if (!booking) return;

    // Fetch customer, technician, and service details
    const [customerDoc, technicianDoc] = await Promise.all([
      db.collection('customers').doc(booking.customerId).get(),
      db.collection('technicians').doc(booking.technicianId).get(),
    ]);

    const customer = customerDoc.data();
    const technician = technicianDoc.data();

    // Get all admin tokens
    const adminsSnapshot = await db.collection('admins').get();
    
    for (const adminDoc of adminsSnapshot.docs) {
      const adminData = adminDoc.data();
      if (adminData?.fcmToken) {
        await sendNotificationToToken({
          token: adminData.fcmToken,
          title: 'New Booking Request',
          body: 'A customer has booked a service. Please review and approve.',
          data: {
            bookingId: context.params.bookingId,
            customerName: customer?.name || 'Unknown',
            technicianName: technician?.name || 'Unknown',
            serviceName: booking.serviceName || 'Service',
            type: 'new_booking',
          },
        });
      }
    }
  }
);

// ==========================================
// 1️⃣ ADMIN APPROVE BOOKING
// ==========================================
export const approveBookingByAdmin = functions.https.onCall(async (request) => {
  const { bookingId } = request.data;
  const uid = request.auth?.uid;

  if (!uid) throw new functions.https.HttpsError('unauthenticated', 'User not authenticated');
  if (!bookingId) throw new functions.https.HttpsError('invalid-argument', 'bookingId required');

  // Verify admin
  const adminDoc = await db.collection('admins').doc(uid).get();
  if (!adminDoc.exists) {
    throw new functions.https.HttpsError('permission-denied', 'Only admins can approve bookings');
  }

  // Get booking
  const bookingRef = db.collection('bookings').doc(bookingId);
  const bookingSnap = await bookingRef.get();

  if (!bookingSnap.exists) {
    throw new functions.https.HttpsError('not-found', 'Booking not found');
  }

  const booking = bookingSnap.data()!;

  // Validate status
  if (booking.status !== 'pending_admin_approval') {
    throw new functions.https.HttpsError(
      'failed-precondition',
      `Cannot approve booking with status: ${booking.status}`
    );
  }

  // Validate technician exists
  if (!booking.technicianId) {
    throw new functions.https.HttpsError('failed-precondition', 'No technician assigned to booking');
  }

  // Validate technician availability
  const techDoc = await db.collection('technicians').doc(booking.technicianId).get();
  if (!techDoc.exists) {
    throw new functions.https.HttpsError('not-found', 'Technician not found');
  }

  const techData = techDoc.data()!;

  // Check technician verification and availability
  if (techData.verificationStatus !== 'approved') {
    throw new functions.https.HttpsError(
      'failed-precondition',
      'Technician is not verified. Please select another technician.'
    );
  }

  if (techData.profileCompletion !== 100) {
    throw new functions.https.HttpsError(
      'failed-precondition',
      'Technician profile is incomplete. Please select another technician.'
    );
  }

  if (techData.isAvailable === false) {
    throw new functions.https.HttpsError(
      'failed-precondition',
      'Technician is currently unavailable. Please select another technician.'
    );
  }

  // Update booking
  await bookingRef.update({
    status: 'waiting_technician_acceptance',
    approvedAt: admin.firestore.FieldValue.serverTimestamp(),
    approvedBy: uid,
  });

  // Notify technician (use technicianId not assignedTechnicianId)
  if (booking.technicianId) {
    const techDoc = await db.collection('technicians').doc(booking.technicianId).get();
    const techData = techDoc.data();
    
    if (techData?.fcmToken) {
      await sendNotificationToToken({
        token: techData.fcmToken,
        title: 'New Booking Assigned',
        body: `Admin approved a booking for ${booking.serviceName || 'service'}. Please accept or reject.`,
        data: { bookingId, type: 'booking_approved' },
      });
    }
  }

  return { success: true, status: 'waiting_technician_acceptance' };
});

// ==========================================
// 1B️⃣ ADMIN REJECT BOOKING
// ==========================================
export const rejectBookingByAdmin = functions.https.onCall(async (request) => {
  const { bookingId, rejectionReason } = request.data;
  const uid = request.auth?.uid;

  if (!uid) throw new functions.https.HttpsError('unauthenticated', 'User not authenticated');
  if (!bookingId) throw new functions.https.HttpsError('invalid-argument', 'bookingId required');
  if (!rejectionReason) throw new functions.https.HttpsError('invalid-argument', 'rejectionReason required');

  // Verify admin
  const adminDoc = await db.collection('admins').doc(uid).get();
  if (!adminDoc.exists) {
    throw new functions.https.HttpsError('permission-denied', 'Only admins can reject bookings');
  }

  // Get booking
  const bookingRef = db.collection('bookings').doc(bookingId);
  const bookingSnap = await bookingRef.get();

  if (!bookingSnap.exists) {
    throw new functions.https.HttpsError('not-found', 'Booking not found');
  }

  const booking = bookingSnap.data()!;

  // Validate status
  if (booking.status !== 'pending_admin_approval') {
    throw new functions.https.HttpsError(
      'failed-precondition',
      `Cannot reject booking with status: ${booking.status}`
    );
  }

  // Update booking
  await bookingRef.update({
    status: 'rejected_by_admin',
    rejectedAt: admin.firestore.FieldValue.serverTimestamp(),
    rejectedBy: uid,
    rejectionReason,
  });

  // Notify customer
  const customerDoc = await db.collection('customers').doc(booking.customerId).get();
  const customerData = customerDoc.data();

  if (customerData?.fcmToken) {
    await sendNotificationToToken({
      token: customerData.fcmToken,
      title: 'Booking Rejected',
      body: 'Your booking request was rejected by admin. Please try another technician or service.',
      data: { bookingId, rejectionReason, type: 'booking_rejected_by_admin' },
    });
  }

  return { success: true, status: 'waiting_technician_acceptance' };
});

// ==========================================
// 2️⃣ TECHNICIAN ACCEPT BOOKING
// ==========================================
export const technicianAcceptBooking = functions.https.onCall(async (request) => {
  const { bookingId } = request.data;
  const uid = request.auth?.uid;

  if (!uid) throw new functions.https.HttpsError('unauthenticated', 'User not authenticated');
  if (!bookingId) throw new functions.https.HttpsError('invalid-argument', 'bookingId required');

  // Get booking
  const bookingRef = db.collection('bookings').doc(bookingId);
  const bookingSnap = await bookingRef.get();

  if (!bookingSnap.exists) {
    throw new functions.https.HttpsError('not-found', 'Booking not found');
  }

  const booking = bookingSnap.data()!;

  // Verify technician matches booking
  if (booking.technicianId !== uid) {
    throw new functions.https.HttpsError(
      'permission-denied',
      'Only the assigned technician can accept this booking'
    );
  }

  // Validate status
  if (booking.status !== 'waiting_technician_acceptance') {
    throw new functions.https.HttpsError(
      'failed-precondition',
      `Cannot accept booking with status: ${booking.status}`
    );
  }

  // Update booking
  await bookingRef.update({
    status: 'accepted',
    acceptedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  // Set technician as unavailable
  await db.collection('technicians').doc(uid).update({
    isAvailable: false,
  });

  // Notify customer
  const customerDoc = await db.collection('customers').doc(booking.customerId).get();
  const customerData = customerDoc.data();

  if (customerData?.fcmToken) {
    await sendNotificationToToken({
      token: customerData.fcmToken,
      title: 'Booking Accepted',
      body: 'Your booking has been accepted by the technician',
      data: { bookingId, type: 'booking_accepted' },
    });
  }

  return { success: true, status: 'accepted' };
});

// ==========================================
// 3️⃣ TECHNICIAN START JOB
// ==========================================
export const technicianStartJob = functions.https.onCall(async (request) => {
  const { bookingId } = request.data;
  const uid = request.auth?.uid;

  if (!uid) throw new functions.https.HttpsError('unauthenticated', 'User not authenticated');
  if (!bookingId) throw new functions.https.HttpsError('invalid-argument', 'bookingId required');

  // Get booking
  const bookingRef = db.collection('bookings').doc(bookingId);
  const bookingSnap = await bookingRef.get();

  if (!bookingSnap.exists) {
    throw new functions.https.HttpsError('not-found', 'Booking not found');
  }

  const booking = bookingSnap.data()!;

  // Verify technician matches booking
  if (booking.technicianId !== uid) {
    throw new functions.https.HttpsError(
      'permission-denied',
      'Only the assigned technician can start this job'
    );
  }

  // Validate status
  if (booking.status !== 'accepted') {
    throw new functions.https.HttpsError(
      'failed-precondition',
      `Cannot start job with status: ${booking.status}`
    );
  }

  // Update booking
  await bookingRef.update({
    status: 'in_progress',
    jobStartedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  // Notify customer
  const customerDoc = await db.collection('customers').doc(booking.customerId).get();
  const customerData = customerDoc.data();

  if (customerData?.fcmToken) {
    await sendNotificationToToken({
      token: customerData.fcmToken,
      title: 'Job Started',
      body: 'Your technician has started working on your service',
      data: { bookingId, type: 'job_started' },
    });
  }

  return { success: true, status: 'in_progress' };
});

// ==========================================
// 4️⃣ COMPLETE BOOKING
// ==========================================
export const completeBooking = functions.https.onCall(async (request) => {
  const { bookingId } = request.data;
  const uid = request.auth?.uid;

  if (!uid) throw new functions.https.HttpsError('unauthenticated', 'User not authenticated');
  if (!bookingId) throw new functions.https.HttpsError('invalid-argument', 'bookingId required');

  // Get booking
  const bookingRef = db.collection('bookings').doc(bookingId);
  const bookingSnap = await bookingRef.get();

  if (!bookingSnap.exists) {
    throw new functions.https.HttpsError('not-found', 'Booking not found');
  }

  const booking = bookingSnap.data()!;

  // Verify technician matches booking
  if (booking.technicianId !== uid) {
    throw new functions.https.HttpsError(
      'permission-denied',
      'Only the assigned technician can complete this booking'
    );
  }

  // Validate status
  if (booking.status !== 'in_progress') {
    throw new functions.https.HttpsError(
      'failed-precondition',
      `Cannot complete booking with status: ${booking.status}`
    );
  }

  // Update booking
  await bookingRef.update({
    status: 'completed',
    completedAt: admin.firestore.FieldValue.serverTimestamp(),
    paymentStatus: 'pending_customer_payment',
  });

  // Update technician stats and set as available
  const techRef = db.collection('technicians').doc(uid);
  await techRef.update({
    totalJobs: admin.firestore.FieldValue.increment(1),
    isAvailable: true,
  });

  // Notify customer
  const customerDoc = await db.collection('customers').doc(booking.customerId).get();
  const customerData = customerDoc.data();

  if (customerData?.fcmToken) {
    await sendNotificationToToken({
      token: customerData.fcmToken,
      title: 'Job Completed',
      body: 'Your service has been completed. Please make payment and leave a review.',
      data: { bookingId, type: 'job_completed' },
    });
  }

  return { success: true, status: 'completed' };
});

// ==========================================
// 5️⃣ CANCEL BOOKING
// ==========================================
export const cancelBooking = functions.https.onCall(async (request) => {
  const { bookingId, reason } = request.data;
  const uid = request.auth?.uid;

  if (!uid) throw new functions.https.HttpsError('unauthenticated', 'User not authenticated');
  if (!bookingId) throw new functions.https.HttpsError('invalid-argument', 'bookingId required');

  // Get booking
  const bookingRef = db.collection('bookings').doc(bookingId);
  const bookingSnap = await bookingRef.get();

  if (!bookingSnap.exists) {
    throw new functions.https.HttpsError('not-found', 'Booking not found');
  }

  const booking = bookingSnap.data()!;

  // Cannot cancel completed bookings
  if (booking.status === 'completed') {
    throw new functions.https.HttpsError(
      'failed-precondition',
      'Cannot cancel completed booking'
    );
  }

  // Verify permission (customer, technician, or admin)
  const isCustomer = booking.customerId === uid;
  const isTechnician = booking.technicianId === uid;
  const adminDoc = await db.collection('admins').doc(uid).get();
  const isAdmin = adminDoc.exists;

  if (!isCustomer && !isTechnician && !isAdmin) {
    throw new functions.https.HttpsError(
      'permission-denied',
      'You do not have permission to cancel this booking'
    );
  }

  // Update booking
  await bookingRef.update({
    status: 'cancelled',
    cancelledAt: admin.firestore.FieldValue.serverTimestamp(),
    cancelledBy: uid,
    cancellationReason: reason || 'No reason provided',
  });

  // Set technician as available if booking was accepted or in progress
  if (booking.technicianId && ['accepted', 'in_progress'].includes(booking.status)) {
    await db.collection('technicians').doc(booking.technicianId).update({
      isAvailable: true,
    });
  }

  // Notify other party
  let notifyUid: string | null = null;
  let notifyTitle = 'Booking Cancelled';
  let notifyBody = 'Your booking has been cancelled';

  if (isCustomer && booking.technicianId) {
    notifyUid = booking.technicianId;
    notifyBody = 'Customer has cancelled the booking';
  } else if (isTechnician) {
    notifyUid = booking.customerId;
    notifyBody = 'Technician has cancelled the booking';
  } else if (isAdmin) {
    notifyUid = booking.customerId;
    notifyBody = 'Admin has cancelled your booking';
  }

  if (notifyUid) {
    const userDoc = await db.collection('customers').doc(notifyUid).get();
    let userData = userDoc.data();
    
    if (!userData) {
      const techDoc = await db.collection('technicians').doc(notifyUid).get();
      userData = techDoc.data();
    }

    if (userData?.fcmToken) {
      await sendNotificationToToken({
        token: userData.fcmToken,
        title: notifyTitle,
        body: notifyBody,
        data: { bookingId, type: 'booking_cancelled', reason: reason || '' },
      });
    }
  }

  return { success: true, status: 'cancelled' };
});

// ==========================================
// 6️⃣ REJECT BOOKING (TECHNICIAN)
// ==========================================
export const technicianRejectBooking = functions.https.onCall(async (request) => {
  const { bookingId, reason } = request.data;
  const uid = request.auth?.uid;

  if (!uid) throw new functions.https.HttpsError('unauthenticated', 'User not authenticated');
  if (!bookingId) throw new functions.https.HttpsError('invalid-argument', 'bookingId required');

  // Get booking
  const bookingRef = db.collection('bookings').doc(bookingId);
  const bookingSnap = await bookingRef.get();

  if (!bookingSnap.exists) {
    throw new functions.https.HttpsError('not-found', 'Booking not found');
  }

  const booking = bookingSnap.data()!;

  // Verify technician matches booking
  if (booking.technicianId !== uid) {
    throw new functions.https.HttpsError(
      'permission-denied',
      'Only the assigned technician can reject this booking'
    );
  }

  // Can only reject if waiting for acceptance
  if (booking.status !== 'waiting_technician_acceptance') {
    throw new functions.https.HttpsError(
      'failed-precondition',
      `Cannot reject booking with status: ${booking.status}`
    );
  }

  // Update booking - back to pending admin approval
  await bookingRef.update({
    status: 'pending_admin_approval',
    rejectedBy: uid,
    rejectedAt: admin.firestore.FieldValue.serverTimestamp(),
    rejectionReason: reason || 'Technician unavailable',
  });

  // Notify admin to reassign
  const adminsSnapshot = await db.collection('admins').get();
  for (const adminDoc of adminsSnapshot.docs) {
    const adminData = adminDoc.data();
    if (adminData?.fcmToken) {
      await sendNotificationToToken({
        token: adminData.fcmToken,
        title: 'Booking Rejected',
        body: `Technician rejected booking. Please reassign to another technician.`,
        data: { bookingId, type: 'booking_rejected_by_tech' },
      });
    }
  }

  // Notify customer about rejection
  const customerDoc = await db.collection('customers').doc(booking.customerId).get();
  const customerData = customerDoc.data();

  if (customerData?.fcmToken) {
    await sendNotificationToToken({
      token: customerData.fcmToken,
      title: 'Booking Update',
      body: 'Technician is unavailable. Admin will assign another technician.',
      data: { bookingId, type: 'booking_rejected' },
    });
  }

  return { success: true, status: 'pending_admin_approval' };
});

// ==========================================
// 7️⃣ VERIFY BOOKING PAYMENT
// ==========================================
/**
 * Verify Booking Payment - RACE CONDITION FIXED
 * Uses transaction to prevent double payment
 */
export const verifyBookingPayment = functions.https.onCall(async (request) => {
  const { bookingId, paymentId, paymentGatewayResponse } = request.data;
  const uid = request.auth?.uid;

  if (!uid) throw new functions.https.HttpsError('unauthenticated', 'User not authenticated');
  if (!bookingId) throw new functions.https.HttpsError('invalid-argument', 'bookingId required');
  if (!paymentId) throw new functions.https.HttpsError('invalid-argument', 'paymentId required');

  const bookingRef = db.collection('bookings').doc(bookingId);

  try {
    // CRITICAL FIX: First transaction to validate booking state
    const bookingData = await db.runTransaction(async (transaction) => {
      const bookingSnap = await transaction.get(bookingRef);

      if (!bookingSnap.exists) {
        throw new functions.https.HttpsError('not-found', 'Booking not found');
      }

      const booking = bookingSnap.data()!;

      // Verify customer owns booking
      if (booking.customerId !== uid) {
        throw new functions.https.HttpsError('permission-denied', 'Only booking customer can make payment');
      }

      // Validate booking status
      if (booking.status !== 'completed') {
        throw new functions.https.HttpsError(
          'failed-precondition',
          'Payment can only be made for completed bookings'
        );
      }

      // CRITICAL: Duplicate payment protection INSIDE transaction
      if (booking.paymentStatus === 'paid') {
        throw new functions.https.HttpsError(
          'failed-precondition',
          'Payment already completed for this booking'
        );
      }

      // Validate payment status
      if (booking.paymentStatus !== 'pending_customer_payment') {
        throw new functions.https.HttpsError(
          'failed-precondition',
          `Invalid payment status: ${booking.paymentStatus}`
        );
      }

      return booking;
    });

    // Verify payment with Razorpay (outside transaction for API call)
    const crypto = await import('crypto');
    const razorpayKeySecret = process.env.RAZORPAY_KEY_SECRET || '';

    // Verify signature if provided
    if (paymentGatewayResponse?.razorpay_signature) {
      const { razorpay_order_id, razorpay_payment_id, razorpay_signature } = paymentGatewayResponse;
      
      const generatedSignature = crypto
        .createHmac('sha256', razorpayKeySecret)
        .update(`${razorpay_order_id}|${razorpay_payment_id}`)
        .digest('hex');

      if (generatedSignature !== razorpay_signature) {
        throw new functions.https.HttpsError('invalid-argument', 'Invalid payment signature');
      }
    }

    // Fetch payment details from Razorpay
    const Razorpay = (await import('razorpay')).default;
    const razorpay = new Razorpay({
      key_id: process.env.RAZORPAY_KEY_ID || '',
      key_secret: razorpayKeySecret,
    });

    const payment = await razorpay.payments.fetch(paymentId);

    // Verify payment status
    if (payment.status !== 'captured' && payment.status !== 'authorized') {
      throw new functions.https.HttpsError(
        'failed-precondition',
        `Payment not successful. Status: ${payment.status}`
      );
    }

    // SECURITY FIX: Verify payment amount from Firestore (never trust client)
    const paymentAmount = Number(payment.amount) / 100; // Razorpay amount is in paise
    if (Math.abs(paymentAmount - bookingData.price) > 0.01) {
      throw new functions.https.HttpsError(
        'failed-precondition',
        `Payment amount mismatch. Expected: ${bookingData.price}, Received: ${paymentAmount}`
      );
    }

    // CRITICAL FIX: Second transaction to update booking and wallet atomically
    await db.runTransaction(async (transaction) => {
      // Re-check payment status to prevent race condition
      const bookingSnap = await transaction.get(bookingRef);
      const booking = bookingSnap.data()!;

      if (booking.paymentStatus === 'paid') {
        throw new functions.https.HttpsError(
          'failed-precondition',
          'Payment already completed'
        );
      }

      // Update booking payment status
      transaction.update(bookingRef, {
        paymentStatus: 'paid',
        paidAt: admin.firestore.FieldValue.serverTimestamp(),
        transactionId: paymentId,
        paymentMethod: payment.method || 'razorpay',
      });

      // Update technician earnings atomically
      const techRef = db.collection('technicians').doc(booking.technicianId);
      transaction.update(techRef, {
        walletBalance: admin.firestore.FieldValue.increment(booking.price),
        totalEarnings: admin.firestore.FieldValue.increment(booking.price),
      });
    });

    console.log(`[PAYMENT] Verified and processed payment ${paymentId} for booking ${bookingId}`);

    // Send notifications (outside transaction)
    const customerDoc = await db.collection('customers').doc(bookingData.customerId).get();
    const customerData = customerDoc.data();

    if (customerData?.fcmToken) {
      await sendNotificationToToken({
        token: customerData.fcmToken,
        title: 'Payment Successful',
        body: `Your payment of ₹${bookingData.price} has been processed successfully.`,
        data: { bookingId, paymentId, type: 'payment_success' },
      });
    }

    const techDoc = await db.collection('technicians').doc(bookingData.technicianId).get();
    const techData = techDoc.data();

    if (techData?.fcmToken) {
      await sendNotificationToToken({
        token: techData.fcmToken,
        title: 'Payment Received',
        body: `You received ₹${bookingData.price} for completed service.`,
        data: { bookingId, amount: bookingData.price, type: 'payment_received' },
      });
    }

    return {
      success: true,
      paymentStatus: 'paid',
      amount: bookingData.price,
      transactionId: paymentId,
    };
  } catch (error: any) {
    console.error('Payment verification error:', error);
    
    if (error instanceof functions.https.HttpsError) {
      throw error;
    }
    
    throw new functions.https.HttpsError(
      'internal',
      `Payment verification failed: ${error.message}`
    );
  }
});



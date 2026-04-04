// ============================================
// BACKEND HARDENING - PRODUCTION READY
// ============================================
// Deploy to: functions/src/technician/booking_actions_hardened.ts

import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { updateBookingStatus } from '../shared/status_history_tracker';

const db = admin.firestore();

// ============================================
// FIX 1: SERVER-SIDE IDEMPOTENCY
// ============================================

interface IdempotencyRecord {
  key: string;
  result: any;
  createdAt: admin.firestore.FieldValue;
  expiresAt: admin.firestore.Timestamp;
}

async function checkIdempotency(key: string): Promise<any | null> {
  const doc = await db.collection('booking_idempotency').doc(key).get();
  if (doc.exists) {
    const data = doc.data();
    // Check if expired (24 hour TTL)
    if (data?.expiresAt && data.expiresAt.toDate() > new Date()) {
      return data.result;
    }
  }
  return null;
}

async function storeIdempotency(key: string, result: any): Promise<void> {
  const expiresAt = admin.firestore.Timestamp.fromDate(
    new Date(Date.now() + 24 * 60 * 60 * 1000) // 24 hours
  );
  
  await db.collection('booking_idempotency').doc(key).set({
    key,
    result,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    expiresAt,
  });
}

// ============================================
// FIX 2 & 3: ATOMIC BOOKING ACTIONS
// ============================================

export const technicianRespondBooking = functions.region('asia-south1').https.onCall(async (data, context) => {
  // Auth check
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Must be authenticated');
  }

  const { bookingId, action, idempotencyKey, rejectionReason } = data;
  const technicianId = context.auth.uid;

  // Validate inputs
  if (!bookingId || !action) {
    throw new functions.https.HttpsError('invalid-argument', 'Missing required fields');
  }

  if (!['accept', 'reject'].includes(action)) {
    throw new functions.https.HttpsError('invalid-argument', 'Invalid action');
  }

  // CRITICAL: Require idempotency key
  if (!idempotencyKey) {
    throw new functions.https.HttpsError('invalid-argument', 'idempotencyKey required');
  }

  // FIX 1: Check idempotency
  const cachedResult = await checkIdempotency(idempotencyKey);
  if (cachedResult) {
    console.log(`[Idempotency] Returning cached result for key: ${idempotencyKey}`);
    return cachedResult;
  }

  // FIX 3: Multi-device concurrency protection
  const result = await db.runTransaction(async (transaction) => {
    const bookingRef = db.collection('bookings').doc(bookingId);
    const bookingDoc = await transaction.get(bookingRef);

    if (!bookingDoc.exists) {
      throw new functions.https.HttpsError('not-found', 'Booking not found');
    }

    const booking = bookingDoc.data()!;

    // Verify technician ownership
    if (booking.technicianId !== technicianId) {
      throw new functions.https.HttpsError('permission-denied', 'Not your booking');
    }

    // Verify current status
    if (booking.status !== 'technician_pending') {
      throw new functions.https.HttpsError('failed-precondition', 
        `Booking already ${booking.status}`);
    }

    // FIX 3: Check if already accepted by another device
    if (booking.acceptedAt) {
      throw new functions.https.HttpsError('already-exists', 
        'ALREADY_ACCEPTED', { code: 'ALREADY_ACCEPTED' });
    }

    if (action === 'accept') {
      // FIX 5: Server-side availability validation
      const techDoc = await transaction.get(db.collection('technicians').doc(technicianId));
      const tech = techDoc.data();
      
      if (!tech) {
        throw new functions.https.HttpsError('not-found', 'Technician not found');
      }

      // Check availability
      const isAvailable = validateAvailability(tech, booking);
      if (!isAvailable) {
        throw new functions.https.HttpsError('failed-precondition', 
          'Outside working hours');
      }

      // Use status history tracker for atomic update
      updateBookingStatus(transaction, bookingRef, 'awaiting_payment', booking, {
        acceptedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      return { success: true, action: 'accepted', newStatus: 'awaiting_payment' };
    } else {
      // Use status history tracker for atomic update
      updateBookingStatus(transaction, bookingRef, 'rejected', booking, {
        rejectedAt: admin.firestore.FieldValue.serverTimestamp(),
        rejectionReason: rejectionReason || 'Technician declined',
      });

      return { success: true, action: 'rejected', newStatus: 'rejected' };
    }
  });

  // Store idempotency result
  await storeIdempotency(idempotencyKey, result);

  return result;
});

// ============================================
// FIX 2: ATOMIC WALLET TRANSACTION
// ============================================

export const updateBookingStatusNew = functions.region('asia-south1').https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Must be authenticated');
  }

  const { bookingId, status, idempotencyKey } = data;
  const technicianId = context.auth.uid;

  if (!bookingId || !status) {
    throw new functions.https.HttpsError('invalid-argument', 'Missing required fields');
  }

  // For complete action, require idempotency key
  if (status === 'completed' && !idempotencyKey) {
    throw new functions.https.HttpsError('invalid-argument', 'idempotencyKey required for completion');
  }

  // Check idempotency for completion
  if (status === 'completed' && idempotencyKey) {
    const cachedResult = await checkIdempotency(idempotencyKey);
    if (cachedResult) {
      return cachedResult;
    }
  }

  // FIX 2: Atomic wallet + booking update
  const result = await db.runTransaction(async (transaction) => {
    const bookingRef = db.collection('bookings').doc(bookingId);
    const bookingDoc = await transaction.get(bookingRef);

    if (!bookingDoc.exists) {
      throw new functions.https.HttpsError('not-found', 'Booking not found');
    }

    const booking = bookingDoc.data()!;

    // Verify ownership
    if (booking.technicianId !== technicianId) {
      throw new functions.https.HttpsError('permission-denied', 'Not your booking');
    }

    // Validate status transition
    const validTransitions: Record<string, string[]> = {
      'awaiting_payment': ['in_progress'],
      'in_progress': ['completed'],
      'started': ['completed'],
    };

    const currentStatus = booking.status;
    const allowedNext = validTransitions[currentStatus] || [];

    if (!allowedNext.includes(status)) {
      throw new functions.https.HttpsError('failed-precondition', 
        `Cannot transition from ${currentStatus} to ${status}`);
    }

    // Update booking
    updateBookingStatus(transaction, bookingRef, status, booking, {
      ...(status === 'in_progress' && { startedAt: admin.firestore.FieldValue.serverTimestamp() }),
      ...(status === 'completed' && { completedAt: admin.firestore.FieldValue.serverTimestamp() }),
    });

    // FIX 2: Atomic wallet credit on completion
    if (status === 'completed') {
      const technicianAmount = booking.quoteData?.technicianAmount || booking.finalAmount || 0;

      if (technicianAmount > 0) {
        const walletRef = db.collection('technician_wallets').doc(technicianId);
        const walletDoc = await transaction.get(walletRef);

        const currentBalance = walletDoc.exists ? (walletDoc.data()?.balance || 0) : 0;
        const newBalance = currentBalance + technicianAmount;

        // Update wallet
        transaction.set(walletRef, {
          technicianId,
          balance: newBalance,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        }, { merge: true });

        // Create transaction record
        const txnRef = walletRef.collection('transactions').doc();
        transaction.set(txnRef, {
          bookingId,
          amount: technicianAmount,
          type: 'credit',
          reason: 'booking_completed',
          balanceBefore: currentBalance,
          balanceAfter: newBalance,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      }
    }

    return { success: true, newStatus: status };
  });

  // Store idempotency for completion
  if (status === 'completed' && idempotencyKey) {
    await storeIdempotency(idempotencyKey, result);
  }

  return result;
});

// ============================================
// FIX 5: AVAILABILITY VALIDATION
// ============================================

function validateAvailability(technician: any, booking: any): boolean {
  // Check emergency flag
  if (technician.emergencyAvailable === true) {
    return true;
  }

  // Check availability object
  const availability = technician.availability;
  if (!availability) {
    return false; // No availability set
  }

  const scheduledAt = booking.scheduledAt?.toDate();
  if (!scheduledAt) {
    return true; // No scheduled time, allow
  }

  const dayOfWeek = scheduledAt.getDay(); // 0 = Sunday, 6 = Saturday
  const dayNames = ['sunday', 'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday'];
  const dayKey = dayNames[dayOfWeek];

  const dayAvailability = availability[dayKey];
  if (!dayAvailability || !dayAvailability.enabled) {
    return false;
  }

  // Check time window
  const bookingTime = scheduledAt.getHours() * 60 + scheduledAt.getMinutes();
  const [startHour, startMin] = (dayAvailability.startTime || '09:00').split(':').map(Number);
  const [endHour, endMin] = (dayAvailability.endTime || '18:00').split(':').map(Number);
  
  const startMinutes = startHour * 60 + startMin;
  const endMinutes = endHour * 60 + endMin;

  return bookingTime >= startMinutes && bookingTime <= endMinutes;
}

// ============================================
// FIX 6: WALLET INTEGRITY CRON JOB
// ============================================

export const validateWalletIntegrity = functions.pubsub
  .schedule('every 24 hours')
  .onRun(async (context) => {
    console.log('[Wallet Integrity] Starting daily validation');

    const walletsSnapshot = await db.collection('technician_wallets').get();
    let checkedCount = 0;
    let mismatchCount = 0;

    for (const walletDoc of walletsSnapshot.docs) {
      const wallet = walletDoc.data();
      const technicianId = walletDoc.id;
      const reportedBalance = wallet.balance || 0;

      // Calculate actual balance from transactions
      const txnsSnapshot = await walletDoc.ref.collection('transactions').get();
      let calculatedBalance = 0;

      txnsSnapshot.forEach((txnDoc) => {
        const txn = txnDoc.data();
        if (txn.type === 'credit') {
          calculatedBalance += txn.amount || 0;
        } else if (txn.type === 'debit') {
          calculatedBalance -= txn.amount || 0;
        }
      });

      checkedCount++;

      // Check for mismatch
      if (Math.abs(calculatedBalance - reportedBalance) > 0.01) {
        mismatchCount++;
        console.error(`[Wallet Integrity] MISMATCH for ${technicianId}: reported=${reportedBalance}, calculated=${calculatedBalance}`);

        // Log to suspicious_wallets
        await db.collection('suspicious_wallets').doc(technicianId).set({
          technicianId,
          reportedBalance,
          calculatedBalance,
          diff: calculatedBalance - reportedBalance,
          transactionCount: txnsSnapshot.size,
          detectedAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        // Alert admin
        await db.collection('admin_alerts').add({
          type: 'wallet_integrity_violation',
          severity: 'high',
          technicianId,
          reportedBalance,
          calculatedBalance,
          diff: calculatedBalance - reportedBalance,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      }
    }

    console.log(`[Wallet Integrity] Checked ${checkedCount} wallets, found ${mismatchCount} mismatches`);
    return { checkedCount, mismatchCount };
  });

// ============================================
// FIX 7: NOTIFICATION DUPLICATE PREVENTION
// ============================================

export const sendBookingNotification = functions.firestore
  .document('bookings/{bookingId}')
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();

    // Only send if status changed
    if (before.status === after.status) {
      return null;
    }

    const bookingId = context.params.bookingId;

    // FIX 7: Verify status is still valid before sending
    const freshBooking = await db.collection('bookings').doc(bookingId).get();
    if (!freshBooking.exists || freshBooking.data()?.status !== after.status) {
      console.log(`[Notification] Skipping stale notification for ${bookingId}`);
      return null;
    }

    // Send notification logic here
    const technicianId = after.technicianId;
    if (!technicianId) return null;

    const message = {
      notification: {
        title: `Booking ${after.status}`,
        body: `Your booking #${bookingId.substring(0, 8)} is now ${after.status}`,
      },
      data: {
        type: 'booking_update',
        bookingId,
        status: after.status,
      },
      topic: `technician_${technicianId}`,
    };

    await admin.messaging().send(message);
    return null;
  });

// ============================================
// FIX 9: RATE LIMITING
// ============================================

interface RateLimitWindow {
  userId: string;
  actionCount: number;
  windowStart: admin.firestore.Timestamp;
}

async function checkRateLimit(userId: string, action: string): Promise<void> {
  const windowId = `${userId}_${action}_${Math.floor(Date.now() / 10000)}`; // 10 second window
  const limitRef = db.collection('rate_limits').doc(windowId);

  await db.runTransaction(async (transaction) => {
    const doc = await transaction.get(limitRef);
    
    if (doc.exists) {
      const data = doc.data() as RateLimitWindow;
      if (data.actionCount >= 5) {
        // Log abuse
        await db.collection('abuse_logs').add({
          userId,
          action,
          timestamp: admin.firestore.FieldValue.serverTimestamp(),
          reason: 'rate_limit_exceeded',
        });
        
        throw new functions.https.HttpsError('resource-exhausted', 
          'Too many requests. Please wait 10 seconds.');
      }
      
      transaction.update(limitRef, {
        actionCount: admin.firestore.FieldValue.increment(1),
      });
    } else {
      transaction.set(limitRef, {
        userId,
        actionCount: 1,
        windowStart: admin.firestore.Timestamp.now(),
      });
    }
  });
}

// Apply rate limiting to critical functions
export const technicianRespondBookingRateLimited = functions.region('asia-south1').https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Must be authenticated');
  }

  // FIX 9: Check rate limit
  await checkRateLimit(context.auth.uid, 'respond_booking');

  // Call original function logic
  const { bookingId, action, idempotencyKey, rejectionReason } = data;
  const technicianId = context.auth.uid;

  if (!bookingId || !action) {
    throw new functions.https.HttpsError('invalid-argument', 'Missing required fields');
  }

  if (!['accept', 'reject'].includes(action)) {
    throw new functions.https.HttpsError('invalid-argument', 'Invalid action');
  }

  if (!idempotencyKey) {
    throw new functions.https.HttpsError('invalid-argument', 'idempotencyKey required');
  }

  const cachedResult = await checkIdempotency(idempotencyKey);
  if (cachedResult) {
    console.log(`[Idempotency] Returning cached result for key: ${idempotencyKey}`);
    return cachedResult;
  }

  const result = await db.runTransaction(async (transaction) => {
    const bookingRef = db.collection('bookings').doc(bookingId);
    const bookingDoc = await transaction.get(bookingRef);

    if (!bookingDoc.exists) {
      throw new functions.https.HttpsError('not-found', 'Booking not found');
    }

    const booking = bookingDoc.data()!;

    if (booking.technicianId !== technicianId) {
      throw new functions.https.HttpsError('permission-denied', 'Not your booking');
    }

    if (booking.status !== 'technician_pending') {
      throw new functions.https.HttpsError('failed-precondition', 
        `Booking already ${booking.status}`);
    }

    if (booking.acceptedAt) {
      throw new functions.https.HttpsError('already-exists', 
        'ALREADY_ACCEPTED', { code: 'ALREADY_ACCEPTED' });
    }

    if (action === 'accept') {
      const techDoc = await transaction.get(db.collection('technicians').doc(technicianId));
      const tech = techDoc.data();
      
      if (!tech) {
        throw new functions.https.HttpsError('not-found', 'Technician not found');
      }

      const isAvailable = validateAvailability(tech, booking);
      if (!isAvailable) {
        throw new functions.https.HttpsError('failed-precondition', 
          'Outside working hours');
      }

      // Use status history tracker for atomic update
      updateBookingStatus(transaction, bookingRef, 'awaiting_payment', booking, {
        acceptedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      return { success: true, action: 'accepted', newStatus: 'awaiting_payment' };
    } else {
      // Use status history tracker for atomic update
      updateBookingStatus(transaction, bookingRef, 'rejected', booking, {
        rejectedAt: admin.firestore.FieldValue.serverTimestamp(),
        rejectionReason: rejectionReason || 'Technician declined',
      });

      return { success: true, action: 'rejected', newStatus: 'rejected' };
    }
  });

  await storeIdempotency(idempotencyKey, result);
  return result;
});

// ============================================
// FIX 10: MONITORING ALERTS
// ============================================

export const monitorBookingHealth = functions.pubsub
  .schedule('every 1 hours')
  .onRun(async (context) => {
    console.log('[Monitoring] Starting booking health check');

    // Alert if booking stuck in in_progress > 24h
    const oneDayAgo = admin.firestore.Timestamp.fromDate(
      new Date(Date.now() - 24 * 60 * 60 * 1000)
    );

    const stuckBookings = await db.collection('bookings')
      .where('status', '==', 'in_progress')
      .where('startedAt', '<', oneDayAgo)
      .get();

    if (!stuckBookings.empty) {
      console.warn(`[Monitoring] Found ${stuckBookings.size} stuck bookings`);
      
      await db.collection('admin_alerts').add({
        type: 'stuck_bookings',
        severity: 'medium',
        count: stuckBookings.size,
        bookingIds: stuckBookings.docs.map(d => d.id),
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }

    // Alert if wallet negative
    const negativeWallets = await db.collection('technician_wallets')
      .where('balance', '<', 0)
      .get();

    if (!negativeWallets.empty) {
      console.error(`[Monitoring] Found ${negativeWallets.size} negative wallets`);
      
      await db.collection('admin_alerts').add({
        type: 'negative_wallet',
        severity: 'critical',
        count: negativeWallets.size,
        technicianIds: negativeWallets.docs.map(d => d.id),
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }

    // Alert if high idempotency collision rate
    const recentIdempotency = await db.collection('booking_idempotency')
      .where('createdAt', '>', oneDayAgo)
      .get();

    const collisionRate = recentIdempotency.size > 0 ? 
      (recentIdempotency.size / 1000) : 0; // Assume 1000 bookings/day baseline

    if (collisionRate > 0.1) { // >10% collision rate
      console.warn(`[Monitoring] High idempotency collision rate: ${collisionRate}`);
      
      await db.collection('admin_alerts').add({
        type: 'high_idempotency_collision',
        severity: 'medium',
        rate: collisionRate,
        count: recentIdempotency.size,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }

    return { success: true };
  });

// ============================================
// FIX 4: FIRESTORE RULES VALIDATION
// ============================================
// Deploy separately to firestore.rules

/*
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Booking idempotency - Cloud Functions only
    match /booking_idempotency/{key} {
      allow read, write: if false; // Functions only
    }
    
    // Rate limits - Cloud Functions only
    match /rate_limits/{windowId} {
      allow read, write: if false; // Functions only
    }
    
    // Abuse logs - Admin only
    match /abuse_logs/{logId} {
      allow read: if request.auth.token.admin == true;
      allow write: if false; // Functions only
    }
    
    // Admin alerts - Admin only
    match /admin_alerts/{alertId} {
      allow read: if request.auth.token.admin == true;
      allow write: if false; // Functions only
    }
    
    // Suspicious wallets - Admin only
    match /suspicious_wallets/{techId} {
      allow read: if request.auth.token.admin == true;
      allow write: if false; // Functions only
    }
    
    // Bookings - Enhanced validation
    match /bookings/{bookingId} {
      allow read: if request.auth != null && (
        request.auth.uid == resource.data.customerId ||
        request.auth.uid == resource.data.technicianId
      );
      
      // NO direct writes - only Cloud Functions
      allow create, update, delete: if false;
    }
    
    // Technician wallets - NO client writes
    match /technician_wallets/{techId} {
      allow read: if request.auth != null && request.auth.uid == techId;
      allow write: if false; // Functions only
      
      match /transactions/{txnId} {
        allow read: if request.auth != null && request.auth.uid == techId;
        allow write: if false; // Functions only
      }
    }
  }
}
*/

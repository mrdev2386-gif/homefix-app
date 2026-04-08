/**
 * OTP RATE LIMITING - Backend Protection
 * 
 * Prevents OTP spam at the backend level
 * Complements frontend rate limiting with server-side enforcement
 */

import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

const db = admin.firestore();

// Rate limiting configuration
const OTP_COOLDOWN_SECONDS = 60; // 60 seconds between OTP requests
const MAX_OTP_ATTEMPTS_PER_DAY = 10; // Maximum 10 OTP requests per phone per day
const MAX_OTP_ATTEMPTS_PER_HOUR = 5; // Maximum 5 OTP requests per phone per hour

interface OTPRateLimitRecord {
  phoneNumber: string;
  lastOtpSentAt: admin.firestore.Timestamp;
  attemptsToday: number;
  attemptsThisHour: number;
  lastResetDate: string; // YYYY-MM-DD format
  lastHourReset: admin.firestore.Timestamp;
  createdAt: admin.firestore.Timestamp;
  updatedAt: admin.firestore.Timestamp;
}

/**
 * Check if OTP request is allowed for a phone number
 * Returns { allowed: boolean, reason?: string, remainingSeconds?: number }
 */
export async function checkOTPRateLimit(phoneNumber: string): Promise<{
  allowed: boolean;
  reason?: string;
  remainingSeconds?: number;
  attemptsRemaining?: number;
}> {
  try {
    // Normalize phone number (remove spaces, dashes, etc.)
    const normalizedPhone = phoneNumber.replace(/[\s\-\(\)]/g, '');
    
    // Get or create rate limit record
    const rateLimitRef = db.collection('otp_rate_limits').doc(normalizedPhone);
    const rateLimitDoc = await rateLimitRef.get();
    
    const now = admin.firestore.Timestamp.now();
    const today = new Date().toISOString().split('T')[0]; // YYYY-MM-DD
    
    if (!rateLimitDoc.exists) {
      // First OTP request for this phone number
      await rateLimitRef.set({
        phoneNumber: normalizedPhone,
        lastOtpSentAt: now,
        attemptsToday: 1,
        attemptsThisHour: 1,
        lastResetDate: today,
        lastHourReset: now,
        createdAt: now,
        updatedAt: now,
      } as OTPRateLimitRecord);
      
      return { allowed: true, attemptsRemaining: MAX_OTP_ATTEMPTS_PER_DAY - 1 };
    }
    
    const record = rateLimitDoc.data() as OTPRateLimitRecord;
    
    // Check cooldown (60 seconds between requests)
    const timeSinceLastOtp = now.seconds - record.lastOtpSentAt.seconds;
    if (timeSinceLastOtp < OTP_COOLDOWN_SECONDS) {
      const remainingSeconds = OTP_COOLDOWN_SECONDS - timeSinceLastOtp;
      return {
        allowed: false,
        reason: `Please wait ${remainingSeconds} seconds before requesting another OTP`,
        remainingSeconds,
      };
    }
    
    // Reset daily counter if it's a new day
    let attemptsToday = record.attemptsToday;
    if (record.lastResetDate !== today) {
      attemptsToday = 0;
    }
    
    // Reset hourly counter if it's been more than an hour
    let attemptsThisHour = record.attemptsThisHour;
    const hoursSinceLastReset = (now.seconds - record.lastHourReset.seconds) / 3600;
    if (hoursSinceLastReset >= 1) {
      attemptsThisHour = 0;
    }
    
    // Check daily limit
    if (attemptsToday >= MAX_OTP_ATTEMPTS_PER_DAY) {
      return {
        allowed: false,
        reason: 'Maximum daily OTP attempts reached. Please try again tomorrow.',
        attemptsRemaining: 0,
      };
    }
    
    // Check hourly limit
    if (attemptsThisHour >= MAX_OTP_ATTEMPTS_PER_HOUR) {
      return {
        allowed: false,
        reason: 'Too many OTP requests. Please try again in an hour.',
        attemptsRemaining: 0,
      };
    }
    
    // Update counters
    await rateLimitRef.update({
      lastOtpSentAt: now,
      attemptsToday: attemptsToday + 1,
      attemptsThisHour: attemptsThisHour + 1,
      lastResetDate: today,
      lastHourReset: hoursSinceLastReset >= 1 ? now : record.lastHourReset,
      updatedAt: now,
    });
    
    return {
      allowed: true,
      attemptsRemaining: MAX_OTP_ATTEMPTS_PER_DAY - (attemptsToday + 1),
    };
  } catch (error: any) {
    console.error('[OTP_RATE_LIMIT] Error checking rate limit:', error.message);
    // On error, allow the request (fail open) but log for monitoring
    return { allowed: true };
  }
}

/**
 * Callable function to check OTP rate limit before sending
 * Called by frontend before initiating OTP flow
 */
export const checkOTPRateLimitCallable = functions
  .region('asia-south1')
  .https.onCall(async (data, context) => {
    const { phoneNumber } = data;
    
    if (!phoneNumber || typeof phoneNumber !== 'string') {
      throw new functions.https.HttpsError('invalid-argument', 'Phone number is required');
    }
    
    const result = await checkOTPRateLimit(phoneNumber);
    
    if (!result.allowed) {
      throw new functions.https.HttpsError('resource-exhausted', result.reason || 'Rate limit exceeded');
    }
    
    return {
      allowed: true,
      attemptsRemaining: result.attemptsRemaining,
    };
  });

/**
 * Scheduled cleanup of old OTP rate limit records
 * Runs daily to prevent collection from growing infinitely
 */
export const cleanupOTPRateLimits = functions
  .region('asia-south1')
  .pubsub.schedule('0 3 * * *') // Daily at 3 AM UTC
  .timeZone('UTC')
  .onRun(async (context) => {
    console.log('[OTP_RATE_LIMIT_CLEANUP] Starting cleanup...');
    
    try {
      // Delete records older than 30 days
      const cutoffTime = admin.firestore.Timestamp.fromDate(
        new Date(Date.now() - 30 * 24 * 60 * 60 * 1000)
      );
      
      const oldRecords = await db
        .collection('otp_rate_limits')
        .where('updatedAt', '<', cutoffTime)
        .limit(500)
        .get();
      
      if (oldRecords.empty) {
        console.log('[OTP_RATE_LIMIT_CLEANUP] No old records found');
        return null;
      }
      
      const batch = db.batch();
      oldRecords.docs.forEach((doc) => batch.delete(doc.ref));
      await batch.commit();
      
      console.log(`[OTP_RATE_LIMIT_CLEANUP] ✅ Deleted ${oldRecords.size} old records`);
      return null;
    } catch (error: any) {
      console.error('[OTP_RATE_LIMIT_CLEANUP] ❌ Error:', error.message);
      throw error;
    }
  });

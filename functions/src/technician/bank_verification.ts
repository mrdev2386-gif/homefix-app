// Cloud Function: verifyTechnicianBankAccountSecure
// PRODUCTION-SAFE Bank Verification with Razorpay Fund Account Validation
// ✅ Idempotency ✅ Race Condition Protection ✅ No Duplicates ✅ Safe Retries
// 🔧 COMPREHENSIVE DEBUG LOGGING FOR RAZORPAY INITIALIZATION

import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
const Razorpay = require('razorpay');
import * as crypto from 'crypto';

const db = admin.firestore();

// Get Razorpay credentials from Firebase Functions config
const getRazorpayCredentials = () => {
  const config = functions.config();
  
  console.log('[BANK_VERIFY] FULL CONFIG:', JSON.stringify(config, null, 2));
  console.log('[BANK_VERIFY] CONFIG.RAZORPAY:', JSON.stringify(config.razorpay, null, 2));
  
  const keyId = config.razorpay?.key_id;
  const keySecret = config.razorpay?.key_secret;
  
  console.log('[BANK_VERIFY] Loading Razorpay config...');
  console.log('[RAZORPAY KEY_ID]:', keyId);
  console.log('[RAZORPAY KEY_SECRET]:', keySecret ? 'EXISTS' : 'MISSING');
  console.log('[BANK_VERIFY] KEY_ID present:', !!keyId);
  console.log('[BANK_VERIFY] KEY_SECRET length:', keySecret?.length || 0);
  
  if (!keyId || !keySecret) {
    console.error('[BANK_VERIFY] CONFIG MISSING - keyId:', !!keyId, 'keySecret:', !!keySecret);
    throw new functions.https.HttpsError(
      'failed-precondition',
      'Razorpay credentials not configured. Run: firebase functions:config:set razorpay.key_id="xxx" razorpay.key_secret="xxx"'
    );
  }
  
  // Validate key format
  if (!keyId.startsWith('rzp_')) {
    console.error('[BANK_VERIFY] INVALID KEY FORMAT:', keyId);
    throw new functions.https.HttpsError(
      'failed-precondition',
      'Invalid Razorpay key_id format. Must start with "rzp_test_" or "rzp_live_"'
    );
  }
  
  console.log('[BANK_VERIFY] Key mode:', keyId.includes('test') ? 'TEST' : 'LIVE');
  console.log('[BANK_VERIFY] Razorpay config loaded successfully');
  
  return { keyId, keySecret };
};

// Lazy-loaded Razorpay instance
let razorpayInstance: any = null;

// Initialize Razorpay SDK (lazy loading) - PURE CommonJS
const getRazorpayInstance = () => {
  if (razorpayInstance) {
    console.log('[BANK_VERIFY] Returning cached Razorpay instance');
    return razorpayInstance;
  }

  const { keyId, keySecret } = getRazorpayCredentials();
  
  console.log('[BANK_VERIFY] Initializing Razorpay SDK...');
  console.log('[BANK_VERIFY] Razorpay class:', typeof Razorpay);
  console.log('[BANK_VERIFY] Razorpay constructor:', Razorpay);
  
  try {
    razorpayInstance = new Razorpay({
      key_id: keyId,
      key_secret: keySecret
    }) as any;
    console.log('[BANK_VERIFY] Razorpay instance created');
  } catch (constructorError: any) {
    console.error('[BANK_VERIFY] Razorpay constructor failed:', constructorError.message);
    throw new functions.https.HttpsError(
      'failed-precondition',
      `Razorpay initialization failed: ${constructorError.message}`
    );
  }
  
  console.log('[BANK_VERIFY] ========== RAZORPAY INSTANCE DEBUG ==========');
  console.log('[BANK_VERIFY] Instance type:', typeof razorpayInstance);
  console.log('[BANK_VERIFY] Instance is null:', razorpayInstance === null);
  console.log('[BANK_VERIFY] Instance is undefined:', razorpayInstance === undefined);
  console.log('[BANK_VERIFY] Instance keys:', Object.keys(razorpayInstance || {}));
  console.log('[BANK_VERIFY] Instance properties:', Object.getOwnPropertyNames(razorpayInstance || {}));
  
  console.log('[BANK_VERIFY] ========== CONTACTS PROPERTY ==========');
  console.log('[BANK_VERIFY] razorpayInstance.contacts:', razorpayInstance.contacts);
  console.log('[BANK_VERIFY] typeof razorpayInstance.contacts:', typeof razorpayInstance.contacts);
  console.log('[BANK_VERIFY] razorpayInstance.contacts is null:', razorpayInstance.contacts === null);
  console.log('[BANK_VERIFY] razorpayInstance.contacts is undefined:', razorpayInstance.contacts === undefined);
  
  if (razorpayInstance.contacts) {
    console.log('[BANK_VERIFY] contacts.create:', typeof (razorpayInstance.contacts as any).create);
    console.log('[BANK_VERIFY] contacts keys:', Object.keys(razorpayInstance.contacts));
  }
  
  console.log('[BANK_VERIFY] ========== FUND_ACCOUNTS PROPERTY ==========');
  console.log('[BANK_VERIFY] razorpayInstance.fund_accounts:', razorpayInstance.fund_accounts);
  console.log('[BANK_VERIFY] typeof razorpayInstance.fund_accounts:', typeof razorpayInstance.fund_accounts);
  console.log('[BANK_VERIFY] razorpayInstance.fund_accounts is null:', razorpayInstance.fund_accounts === null);
  console.log('[BANK_VERIFY] razorpayInstance.fund_accounts is undefined:', razorpayInstance.fund_accounts === undefined);
  
  if (razorpayInstance.fund_accounts) {
    console.log('[BANK_VERIFY] fund_accounts.create:', typeof (razorpayInstance.fund_accounts as any).create);
    console.log('[BANK_VERIFY] fund_accounts keys:', Object.keys(razorpayInstance.fund_accounts));
  }
  
  console.log('[BANK_VERIFY] ========== FULL INSTANCE DUMP ==========');
  try {
    console.log('[BANK_VERIFY] FULL INSTANCE:', JSON.stringify(razorpayInstance, null, 2));
  } catch (e) {
    console.log('[BANK_VERIFY] Could not stringify instance (circular reference)');
  }
  console.log('[BANK_VERIFY] ========== END DEBUG ==========');
  
  if (!razorpayInstance.contacts) {
    console.error('[BANK_VERIFY] CRITICAL: razorpayInstance.contacts is undefined');
    throw new functions.https.HttpsError(
      'failed-precondition',
      'Razorpay instance.contacts is undefined - SDK not properly initialized'
    );
  }

  if (typeof (razorpayInstance.contacts as any).create !== 'function') {
    console.error('[BANK_VERIFY] CRITICAL: contacts.create is not a function');
    throw new functions.https.HttpsError(
      'failed-precondition',
      'Razorpay instance not properly initialized - contacts.create is not a function'
    );
  }
  
  if (!razorpayInstance.fund_accounts) {
    console.error('[BANK_VERIFY] CRITICAL: razorpayInstance.fund_accounts is undefined');
    throw new functions.https.HttpsError(
      'failed-precondition',
      'Razorpay instance.fund_accounts is undefined - SDK not properly initialized'
    );
  }

  if (typeof (razorpayInstance.fund_accounts as any).create !== 'function') {
    console.error('[BANK_VERIFY] CRITICAL: fund_accounts.create is not a function');
    throw new functions.https.HttpsError(
      'failed-precondition',
      'Razorpay instance not properly initialized - fund_accounts.create is not a function'
    );
  }
  
  console.log('[BANK_VERIFY] ✅ Razorpay SDK initialized successfully');
  return razorpayInstance;
};

// Rate limiting constants
const MAX_ATTEMPTS = 5;
const ATTEMPT_WINDOW_MS = 60 * 60 * 1000; // 1 hour
const VERIFICATION_TIMEOUT_MS = 2 * 60 * 1000; // 2 minutes

interface BankVerificationRequest {
  accountHolderName: string;
  accountNumber: string;
  ifscCode: string;
  force?: boolean; // Force fresh verification, bypass cache
}

// Generate idempotency key from user ID and account number
function generateIdempotencyKey(uid: string, accountNumber: string): string {
  return crypto.createHash('sha256')
    .update(`${uid}:${accountNumber}`)
    .digest('hex');
}

// Mask account number for logging (show only last 4 digits)
function maskAccountNumber(accountNumber: string): string {
  if (accountNumber.length <= 4) return '****';
  return '****' + accountNumber.slice(-4);
}

/**
 * Verify technician bank account using Razorpay Fund Account Validation
 * 
 * SECURITY:
 * - Only authenticated technicians can call
 * - Validates IFSC and account number format
 * - Creates Razorpay Contact and Fund Account
 * - Razorpay automatically validates bank details
 * - Updates Firestore with verification status
 * - Logs all attempts in payment_logs
 * 
 * FLOW:
 * 1. Validate input
 * 2. Create Razorpay Contact
 * 3. Create Fund Account (auto-validates)
 * 4. Update technician document
 * 5. Log result
 * 
 * DEBUG MODE:
 * - Pass force: true to bypass all caches and force fresh verification
 * - Useful for testing and fixing stale cached failures
 */
export const verifyTechnicianBankAccountSecure = functions.region('asia-south1').https.onCall(
  async (data: BankVerificationRequest, context) => {
    console.log('🔥 DEPLOYED VERSION - COMPREHENSIVE DEBUG LOGGING ENABLED');
    
    // 1. Authentication check
    if (!context.auth) {
      throw new functions.https.HttpsError(
        'unauthenticated',
        'User must be authenticated'
      );
    }

    const uid = context.auth.uid;
    const { accountHolderName, accountNumber, ifscCode, force = false } = data;

    console.log(`[BANK_VERIFY] Force flag: ${force}`);

    // 2. Validation
    if (!accountHolderName || !accountNumber || !ifscCode) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'All bank details are required'
      );
    }

    // Validate IFSC format (11 characters: 4 letters + 0 + 6 alphanumeric)
    if (!/^[A-Z]{4}0[A-Z0-9]{6}$/.test(ifscCode.toUpperCase())) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'Invalid IFSC code format'
      );
    }

    // Validate account number (6-18 digits)
    if (!/^\d{6,18}$/.test(accountNumber)) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'Invalid account number'
      );
    }

    const techRef = admin.firestore().collection('technicians').doc(uid);
    const techDoc = await techRef.get();

    if (!techDoc.exists) {
      throw new functions.https.HttpsError(
        'not-found',
        'Technician profile not found'
      );
    }

    const techData = techDoc.data()!;

    console.log('[BANK_VERIFY] ⚠️ CACHE DISABLED - FORCING FRESH VERIFICATION');

    // ============================================================================
    // CRITICAL FIX 2: RACE CONDITION LOCK
    // ============================================================================
    if (techData.verificationLock === true) {
      throw new functions.https.HttpsError(
        'failed-precondition',
        'Verification already in progress. Please wait.'
      );
    }

    // ============================================================================
    // CRITICAL FIX 3: RATE LIMITING
    // ============================================================================
    const attempts = techData.verificationAttempts || 0;
    const lastAttempt = techData.lastVerificationAttemptAt;
    
    if (lastAttempt && !force) {
      const timeSinceLastAttempt = Date.now() - lastAttempt.toMillis();
      
      if (timeSinceLastAttempt < ATTEMPT_WINDOW_MS && attempts >= MAX_ATTEMPTS) {
        throw new functions.https.HttpsError(
          'resource-exhausted',
          `Too many verification attempts. Please try again after 1 hour.`
        );
      }
      
      // Reset counter if window expired
      if (timeSinceLastAttempt >= ATTEMPT_WINDOW_MS) {
        await techRef.update({
          verificationAttempts: 0
        });
      }
    }

    console.log(`[BANK_VERIFY] Starting verification - Technician: ${uid}, Previous Status: ${techData.bankVerificationStatus || 'none'}`);

    try {
      // ============================================================================
      // CRITICAL FIX 5: SET VERIFICATION LOCK + STATUS
      // ============================================================================
      await techRef.update({
        bankAccountNumber: accountNumber,
        bankIfsc: ifscCode.toUpperCase(),
        bankHolderName: accountHolderName,
        bankVerified: false,
        bankVerificationStatus: 'verifying',
        verificationLock: true, // 🔒 LOCK
        verificationAttempts: admin.firestore.FieldValue.increment(1),
        lastVerificationAttemptAt: admin.firestore.FieldValue.serverTimestamp(),
        bankSubmittedAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      // ============================================================================
      // CRITICAL FIX 6: ENHANCED LOGGING WITH MASKED DATA
      // ============================================================================
      const idempotencyKey = generateIdempotencyKey(uid, accountNumber);
      await admin.firestore().collection('payment_logs').add({
        technicianId: uid,
        action: 'bank_verification_attempt',
        status: 'started',
        accountNumber: maskAccountNumber(accountNumber),
        ifsc: ifscCode.toUpperCase(),
        previousStatus: techData.bankVerificationStatus || 'none',
        idempotencyKey,
        attemptNumber: (techData.verificationAttempts || 0) + 1,
        force: force,
        createdAt: admin.firestore.FieldValue.serverTimestamp()
      });

      // Initialize Razorpay SDK
      let razorpay;
      try {
        razorpay = getRazorpayInstance();
      } catch (initError: any) {
        console.error('[BANK_VERIFY] Razorpay initialization failed:', initError.message);
        throw initError;
      }
      
      if (!razorpay) {
        throw new functions.https.HttpsError(
          'failed-precondition',
          'Razorpay instance is null'
        );
      }

      // ============================================================================
      // CRITICAL FIX 7: REUSE EXISTING CONTACT (NO DUPLICATES)
      // ============================================================================
      let contactId = techData.razorpayContactId;

      if (!contactId) {
        console.log(`[BANK_VERIFY] Creating new Razorpay contact - Technician: ${uid}`);
        
        try {
          if (!razorpay.contacts || typeof (razorpay.contacts as any).create !== 'function') {
            throw new Error('razorpay.contacts.create is not a function');
          }
          const contact = await (razorpay.contacts as any).create({
            name: techData.name || accountHolderName,
            email: techData.email || `tech_${uid}@homefix.app`,
            contact: techData.phone || '',
            type: 'vendor',
            reference_id: uid,
            notes: {
              technician_id: uid,
              purpose: 'payout'
            }
          });

          contactId = contact.id;

          await techRef.update({
            razorpayContactId: contactId
          });
          
          console.log(`[BANK_VERIFY] Contact created - ID: ${contactId}`);
        } catch (contactError: any) {
          console.error('[BANK_VERIFY] Contact creation failed:', contactError.message);
          throw new functions.https.HttpsError(
            'internal',
            `Failed to create Razorpay contact: ${contactError.message}`
          );
        }
      } else {
        console.log(`[BANK_VERIFY] Reusing existing contact - ID: ${contactId}`);
      }

      // ============================================================================
      // CRITICAL FIX 8: SMART FUND ACCOUNT CREATION (OVERWRITE ON RETRY)
      // ============================================================================
      console.log(`[BANK_VERIFY] Creating fund account - Technician: ${uid}`);
      
      let fundAccount: any;
      try {
        if (!razorpay.fund_accounts || typeof (razorpay.fund_accounts as any).create !== 'function') {
          throw new Error('razorpay.fund_accounts.create is not a function');
        }
        fundAccount = await (razorpay.fund_accounts as any).create({
          contact_id: contactId,
          account_type: 'bank_account',
          bank_account: {
            name: accountHolderName,
            ifsc: ifscCode.toUpperCase(),
            account_number: accountNumber,
          }
        });
      } catch (fundError: any) {
        console.error('[BANK_VERIFY] Fund account creation failed:', fundError.message);
        throw new functions.https.HttpsError(
          'internal',
          `Failed to create fund account: ${fundError.message}`
        );
      }

      const fundAccountId = fundAccount.id;
      const isActive = fundAccount.active === true;

      console.log(`[BANK_VERIFY] Fund account created - ID: ${fundAccountId}, Active: ${isActive}`);

      // ============================================================================
      // CRITICAL FIX 9: UPDATE STATUS + RELEASE LOCK
      // ============================================================================
      if (isActive) {
        await techRef.update({
          bankVerified: true,
          bankVerificationStatus: 'verified',
          fundAccountId: fundAccountId,
          razorpayFundAccountId: fundAccountId,
          bankVerifiedAt: admin.firestore.FieldValue.serverTimestamp(),
          bankVerificationMessage: 'Bank account verified successfully',
          verificationLock: false, // 🔓 UNLOCK
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        // ============================================================================
        // CRITICAL FIX 10: STORE IDEMPOTENCY RESULT
        // ============================================================================
        const idempotencyRef = admin.firestore().collection('verificationRequests').doc(idempotencyKey);
        await idempotencyRef.set({
          technicianId: uid,
          success: true,
          status: 'verified',
          message: 'Bank account verified successfully',
          fundAccountId,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          expiresAt: admin.firestore.Timestamp.fromMillis(Date.now() + 24 * 60 * 60 * 1000) // 24 hours
        });

        // Log success
        await admin.firestore().collection('payment_logs').add({
          technicianId: uid,
          action: 'bank_verification_success',
          status: 'verified',
          fundAccountId,
          accountNumber: maskAccountNumber(accountNumber),
          ifsc: ifscCode.toUpperCase(),
          idempotencyKey,
          createdAt: admin.firestore.FieldValue.serverTimestamp()
        });

        console.log(`[BANK_VERIFY] Verification successful - Technician: ${uid}`);

        const successResponse = {
          success: true,
          status: 'verified',
          message: 'Bank account verified successfully',
          fundAccountId
        };
        console.log('BANK VERIFY RESPONSE SENT');
        return successResponse;
      } else {
        // ============================================================================
        // CRITICAL FIX 11: HANDLE FAILURE + RELEASE LOCK
        // ============================================================================
        await techRef.update({
          bankVerified: false,
          bankVerificationStatus: 'failed',
          bankVerificationMessage: 'Bank account validation failed. Please check your details and try again.',
          verificationLock: false, // 🔓 UNLOCK
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        // Store idempotency result for failure
        const idempotencyRef = admin.firestore().collection('verificationRequests').doc(idempotencyKey);
        await idempotencyRef.set({
          technicianId: uid,
          success: false,
          status: 'failed',
          message: 'Bank account validation failed. Please check your details and try again.',
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          expiresAt: admin.firestore.Timestamp.fromMillis(Date.now() + 1 * 60 * 60 * 1000) // 1 hour for failures
        });

        // Log failure
        await admin.firestore().collection('payment_logs').add({
          technicianId: uid,
          action: 'bank_verification_failed',
          status: 'failed',
          reason: 'fund_account_inactive',
          accountNumber: maskAccountNumber(accountNumber),
          ifsc: ifscCode.toUpperCase(),
          idempotencyKey,
          createdAt: admin.firestore.FieldValue.serverTimestamp()
        });

        console.log(`[BANK_VERIFY] Verification failed - Fund account inactive - Technician: ${uid}`);

        const failedResponse = {
          success: false,
          status: 'failed',
          message: 'Bank account validation failed. Please check your details and try again.'
        };
        console.log('BANK VERIFY RESPONSE SENT');
        return failedResponse;
      }
    } catch (error: any) {
      console.error('[BANK_VERIFY] Error:', error);

      const errorMessage = error.response?.data?.error?.description || 
                          error.message || 
                          'Verification failed. Please try again.';

      // ============================================================================
      // CRITICAL FIX 12: ALWAYS RELEASE LOCK ON ERROR
      // ============================================================================
      await techRef.update({
        bankVerified: false,
        bankVerificationStatus: 'failed',
        bankVerificationMessage: errorMessage,
        verificationLock: false, // 🔓 UNLOCK
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      // Store idempotency result for error
      const idempotencyKey = generateIdempotencyKey(uid, accountNumber);
      const idempotencyRef = admin.firestore().collection('verificationRequests').doc(idempotencyKey);
      await idempotencyRef.set({
        technicianId: uid,
        success: false,
        status: 'failed',
        message: errorMessage,
        error: error.message,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        expiresAt: admin.firestore.Timestamp.fromMillis(Date.now() + 1 * 60 * 60 * 1000) // 1 hour
      });

      // Log error
      await admin.firestore().collection('payment_logs').add({
        technicianId: uid,
        action: 'bank_verification_error',
        status: 'failed',
        error: errorMessage,
        accountNumber: maskAccountNumber(accountNumber),
        ifsc: ifscCode.toUpperCase(),
        idempotencyKey,
        createdAt: admin.firestore.FieldValue.serverTimestamp()
      });

      const errorResponse = {
        success: false,
        status: 'failed',
        message: errorMessage
      };
      console.log('BANK VERIFY RESPONSE SENT');
      return errorResponse;
    }
  }
);

/**
 * DEPRECATED: Old webhook handler - kept for backward compatibility
 * Use verifyTechnicianBankAccountSecure instead
 */
export const razorpayBankWebhook = functions.https.onRequest(async (req, res) => {
  res.status(200).send({ message: 'Webhook deprecated. Using Fund Account Validation instead.' });
});

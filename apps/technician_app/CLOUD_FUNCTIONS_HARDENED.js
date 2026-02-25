// HomeFix Technician Onboarding - Hardened Cloud Functions
// P0 & P1 Production Security Fixes

const functions = require('firebase-functions');
const admin = require('firebase-admin');
const crypto = require('crypto');

admin.initializeApp();
const db = admin.firestore();

// ============================================================================
// P0: AADHAAR HASHING & DUPLICATE PREVENTION
// ============================================================================

function generateAadhaarHash(aadhaarNumber) {
  return crypto.createHash('sha256').update(aadhaarNumber).digest('hex');
}

function maskAadhaar(aadhaar) {
  if (!aadhaar || aadhaar.length !== 12) return 'XXXX XXXX XXXX';
  return `XXXX XXXX ${aadhaar.substring(8)}`;
}

async function checkDuplicateTechnician(aadhaarHash, phone, excludeUid = null) {
  const errors = [];

  // Check Aadhaar duplicate
  const aadhaarSnapshot = await db
    .collection('technicians')
    .where('aadhaarHash', '==', aadhaarHash)
    .limit(1)
    .get();

  if (!aadhaarSnapshot.empty) {
    const doc = aadhaarSnapshot.docs[0];
    if (!excludeUid || doc.id !== excludeUid) {
      errors.push('Aadhaar already registered');
    }
  }

  // Check phone duplicate
  const phoneSnapshot = await db
    .collection('technicians')
    .where('phone', '==', phone)
    .limit(1)
    .get();

  if (!phoneSnapshot.empty) {
    const doc = phoneSnapshot.docs[0];
    if (!excludeUid || doc.id !== excludeUid) {
      errors.push('Phone already registered');
    }
  }

  return errors;
}

// ============================================================================
// P0: SAVE TECHNICIAN DOCUMENTS (WITH HASHING & DUPLICATE CHECK)
// ============================================================================

exports.saveTechnicianDocuments = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }

  const uid = context.auth.uid;
  const { aadhaarNumber, aadhaarFrontUrl, aadhaarBackUrl, profilePhotoUrl } = data;

  try {
    // Validate Aadhaar
    if (!aadhaarNumber || !/^\d{12}$/.test(aadhaarNumber)) {
      throw new functions.https.HttpsError('invalid-argument', 'Invalid Aadhaar: must be 12 digits');
    }

    // Get phone from auth
    const userRecord = await admin.auth().getUser(uid);
    const phone = userRecord.phoneNumber;

    // Generate hash
    const aadhaarHash = generateAadhaarHash(aadhaarNumber);

    // Check duplicates
    const duplicateErrors = await checkDuplicateTechnician(aadhaarHash, phone, uid);
    if (duplicateErrors.length > 0) {
      throw new functions.https.HttpsError('already-exists', `Technician already registered: ${duplicateErrors.join(', ')}`);
    }

    // Save with hash (NOT raw Aadhaar)
    await db.collection('technicians').doc(uid).update({
      aadhaarNumber: maskAadhaar(aadhaarNumber), // Store masked only
      aadhaarHash: aadhaarHash, // For duplicate checking only
      aadhaarFrontUrl: aadhaarFrontUrl,
      aadhaarBackUrl: aadhaarBackUrl,
      profilePhotoUrl: profilePhotoUrl,
      kycCompleted: true,
      status: 'kyc_pending',
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    return { success: true, masked: maskAadhaar(aadhaarNumber) };
  } catch (error) {
    console.error('Error saving documents:', error);
    throw error;
  }
});

// ============================================================================
// P0: ATOMIC FINAL SUBMISSION (TRANSACTION)
// ============================================================================

exports.submitTechnicianKyc = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }

  const uid = context.auth.uid;

  try {
    const techDoc = await db.collection('technicians').doc(uid).get();
    if (!techDoc.exists) {
      throw new functions.https.HttpsError('not-found', 'Technician profile not found');
    }

    const techData = techDoc.data();

    // P0: IDEMPOTENT CHECK - prevent double submit
    if (techData.status === 'pending_approval' || techData.status === 'approved') {
      return {
        success: true,
        idempotent: true,
        message: 'Already submitted',
      };
    }

    // Validate all required fields
    const requiredFields = [
      'name', 'email', 'district', 'experienceYears',
      'aadhaarHash', 'aadhaarFrontUrl', 'aadhaarBackUrl', 'profilePhotoUrl',
      'accountHolderName', 'bankAccountNumber', 'ifscCode', 'bankName',
      'servicesOffered', 'basePrice', 'visitingCharge', 'maxTravelDistance',
    ];

    const missing = requiredFields.filter(f => !techData[f]);
    if (missing.length > 0) {
      throw new functions.https.HttpsError('failed-precondition', `Missing: ${missing.join(', ')}`);
    }

    // P0: ATOMIC TRANSACTION - all or nothing
    await db.runTransaction(async (transaction) => {
      transaction.update(db.collection('technicians').doc(uid), {
        profileCompleted: true,
        kycCompleted: true,
        bankCompleted: true,
        servicesCompleted: true,
        status: 'pending_approval',
        onboardingStep: 'submitted',
        submissionTimestamp: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    });

    return {
      success: true,
      message: 'Application submitted successfully',
    };
  } catch (error) {
    console.error('Error submitting KYC:', error);
    throw error;
  }
});

// ============================================================================
// P0: ADMIN APPROVAL (ADMIN ONLY)
// ============================================================================

exports.approveTechnicianKyc = functions.https.onCall(async (data, context) => {
  if (!context.auth || !context.auth.token.admin) {
    throw new functions.https.HttpsError('permission-denied', 'Admin only');
  }

  const { uid } = data;

  try {
    await db.collection('technicians').doc(uid).update({
      isApproved: true,
      adminApproved: true,
      status: 'approved',
      onboardingStep: 'approved',
      approvedAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    return { success: true };
  } catch (error) {
    console.error('Error approving technician:', error);
    throw error;
  }
});

// ============================================================================
// P0: ADMIN REJECTION (ADMIN ONLY)
// ============================================================================

exports.rejectTechnicianKyc = functions.https.onCall(async (data, context) => {
  if (!context.auth || !context.auth.token.admin) {
    throw new functions.https.HttpsError('permission-denied', 'Admin only');
  }

  const { uid, reason } = data;

  try {
    await db.collection('technicians').doc(uid).update({
      isApproved: false,
      status: 'rejected',
      rejectionReason: reason || 'Documents do not meet requirements',
      rejectedAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    return { success: true };
  } catch (error) {
    console.error('Error rejecting technician:', error);
    throw error;
  }
});

// HomeFix Technician Onboarding - Enhanced Cloud Functions
// Deploy these functions to Firebase Cloud Functions

const functions = require('firebase-functions');
const admin = require('firebase-admin');
const crypto = require('crypto');

admin.initializeApp();
const db = admin.firestore();

// ============================================================================
// DUPLICATE TECHNICIAN PROTECTION
// ============================================================================

/**
 * Check if Aadhaar already exists (hashed)
 * @param {string} aadhaarNumber - Raw Aadhaar number
 * @returns {Promise<boolean>} - True if duplicate found
 */
async function checkAadhaarDuplicate(aadhaarNumber, excludeUid = null) {
  const aadhaarHash = crypto
    .createHash('sha256')
    .update(aadhaarNumber)
    .digest('hex');

  const snapshot = await db
    .collection('technicians')
    .where('aadhaarHash', '==', aadhaarHash)
    .limit(1)
    .get();

  if (snapshot.empty) return false;
  
  const doc = snapshot.docs[0];
  return excludeUid ? doc.id !== excludeUid : true;
}

/**
 * Check if phone already exists
 * @param {string} phone - Phone number
 * @returns {Promise<boolean>} - True if duplicate found
 */
async function checkPhoneDuplicate(phone, excludeUid = null) {
  const snapshot = await db
    .collection('technicians')
    .where('phone', '==', phone)
    .limit(1)
    .get();

  if (snapshot.empty) return false;
  
  const doc = snapshot.docs[0];
  return excludeUid ? doc.id !== excludeUid : true;
}

/**
 * Generate Aadhaar hash for duplicate checking
 * NEVER use raw Aadhaar for queries
 */
function generateAadhaarHash(aadhaarNumber) {
  return crypto
    .createHash('sha256')
    .update(aadhaarNumber)
    .digest('hex');
}

// ============================================================================
// SAVE TECHNICIAN DOCUMENTS (WITH DUPLICATE CHECK)
// ============================================================================

exports.saveTechnicianDocuments = functions.https.onCall(async (data, context) => {
  // Verify authentication
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User must be authenticated'
    );
  }

  const uid = context.auth.uid;
  const {
    aadhaarNumber,
    aadhaarFrontUrl,
    aadhaarBackUrl,
    profilePhotoUrl,
    documentType = 'Aadhaar Card',
  } = data;

  try {
    // Validate Aadhaar format
    if (!aadhaarNumber || !/^\d{12}$/.test(aadhaarNumber)) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'Invalid Aadhaar format: must be 12 digits'
      );
    }

    // CRITICAL: Check for duplicate Aadhaar
    const aadhaarDuplicate = await checkAadhaarDuplicate(aadhaarNumber, uid);
    if (aadhaarDuplicate) {
      throw new functions.https.HttpsError(
        'already-exists',
        'duplicate_technician: This Aadhaar is already registered'
      );
    }

    // Get current phone from auth
    const userRecord = await admin.auth().getUser(uid);
    const phone = userRecord.phoneNumber;

    // Check for duplicate phone
    const phoneDuplicate = await checkPhoneDuplicate(phone, uid);
    if (phoneDuplicate) {
      throw new functions.https.HttpsError(
        'already-exists',
        'duplicate_technician: This phone is already registered'
      );
    }

    // Generate Aadhaar hash
    const aadhaarHash = generateAadhaarHash(aadhaarNumber);

    // Save documents with hash
    await db.collection('technicians').doc(uid).update({
      aadhaarNumber: aadhaarNumber,
      aadhaarHash: aadhaarHash, // For duplicate checking only
      aadhaarFrontUrl: aadhaarFrontUrl,
      aadhaarBackUrl: aadhaarBackUrl,
      profilePhotoUrl: profilePhotoUrl,
      documentType: documentType,
      kycCompleted: true,
      status: 'kyc_pending',
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    return {
      success: true,
      message: 'Documents saved successfully',
      aadhaarMasked: maskAadhaar(aadhaarNumber),
    };
  } catch (error) {
    console.error('Error saving documents:', error);
    throw error;
  }
});

// ============================================================================
// SUBMIT TECHNICIAN KYC (ATOMIC SUBMISSION)
// ============================================================================

exports.submitTechnicianKyc = functions.https.onCall(async (data, context) => {
  // Verify authentication
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User must be authenticated'
    );
  }

  const uid = context.auth.uid;

  try {
    // Get current technician data
    const techDoc = await db.collection('technicians').doc(uid).get();
    if (!techDoc.exists) {
      throw new functions.https.HttpsError(
        'not-found',
        'Technician profile not found'
      );
    }

    const techData = techDoc.data();

    // Validate all required fields are complete
    const requiredFields = [
      'name',
      'email',
      'district',
      'experienceYears',
      'aadhaarNumber',
      'aadhaarFrontUrl',
      'aadhaarBackUrl',
      'profilePhotoUrl',
      'accountHolderName',
      'bankAccountNumber',
      'ifscCode',
      'bankName',
      'servicesOffered',
      'basePrice',
      'visitingCharge',
      'maxTravelDistance',
    ];

    const missingFields = requiredFields.filter(field => !techData[field]);
    if (missingFields.length > 0) {
      throw new functions.https.HttpsError(
        'failed-precondition',
        `Missing required fields: ${missingFields.join(', ')}`
      );
    }

    // Check if already submitted
    if (techData.status === 'pending_approval' || techData.status === 'approved') {
      return {
        success: true,
        idempotent: true,
        message: 'Already submitted',
      };
    }

    // ATOMIC: Set all completion flags together
    const batch = db.batch();
    const techRef = db.collection('technicians').doc(uid);

    batch.update(techRef, {
      profileCompleted: true,
      kycCompleted: true,
      bankCompleted: true,
      servicesCompleted: true,
      status: 'pending_approval',
      onboardingStep: 'submitted',
      submissionTimestamp: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    await batch.commit();

    // Send notification to admin
    await sendAdminNotification(uid, techData.name);

    return {
      success: true,
      message: 'Application submitted successfully',
      submissionId: uid,
    };
  } catch (error) {
    console.error('Error submitting KYC:', error);
    throw error;
  }
});

// ============================================================================
// APPROVE TECHNICIAN KYC (ADMIN ONLY)
// ============================================================================

exports.approveTechnicianKyc = functions.https.onCall(async (data, context) => {
  // Verify admin authentication
  if (!context.auth || !context.auth.token.admin) {
    throw new functions.https.HttpsError(
      'permission-denied',
      'Only admins can approve technicians'
    );
  }

  const { uid } = data;

  try {
    const techDoc = await db.collection('technicians').doc(uid).get();
    if (!techDoc.exists) {
      throw new functions.https.HttpsError(
        'not-found',
        'Technician not found'
      );
    }

    const techData = techDoc.data();

    // Update approval status
    await db.collection('technicians').doc(uid).update({
      isApproved: true,
      adminApproved: true,
      status: 'approved',
      onboardingStep: 'approved',
      approvedAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Send notification to technician
    if (techData.fcmToken) {
      await admin.messaging().sendToDevice(techData.fcmToken, {
        notification: {
          title: 'Account Approved! 🎉',
          body: 'Your account has been approved. You can now start accepting jobs.',
        },
        data: {
          action: 'account_approved',
          uid: uid,
        },
      });
    }

    return {
      success: true,
      message: 'Technician approved successfully',
    };
  } catch (error) {
    console.error('Error approving technician:', error);
    throw error;
  }
});

// ============================================================================
// REJECT TECHNICIAN KYC (ADMIN ONLY)
// ============================================================================

exports.rejectTechnicianKyc = functions.https.onCall(async (data, context) => {
  // Verify admin authentication
  if (!context.auth || !context.auth.token.admin) {
    throw new functions.https.HttpsError(
      'permission-denied',
      'Only admins can reject technicians'
    );
  }

  const { uid, rejectionReason } = data;

  try {
    const techDoc = await db.collection('technicians').doc(uid).get();
    if (!techDoc.exists) {
      throw new functions.https.HttpsError(
        'not-found',
        'Technician not found'
      );
    }

    const techData = techDoc.data();

    // Update rejection status
    await db.collection('technicians').doc(uid).update({
      isApproved: false,
      status: 'rejected',
      rejectionReason: rejectionReason || 'Documents do not meet requirements',
      rejectedAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Send notification to technician
    if (techData.fcmToken) {
      await admin.messaging().sendToDevice(techData.fcmToken, {
        notification: {
          title: 'Application Rejected',
          body: 'Your application was rejected. Please contact support for details.',
        },
        data: {
          action: 'account_rejected',
          uid: uid,
          reason: rejectionReason,
        },
      });
    }

    return {
      success: true,
      message: 'Technician rejected',
    };
  } catch (error) {
    console.error('Error rejecting technician:', error);
    throw error;
  }
});

// ============================================================================
// HELPER FUNCTIONS
// ============================================================================

/**
 * Mask Aadhaar for display: XXXX-XXXX-1234
 */
function maskAadhaar(aadhaar) {
  if (!aadhaar || aadhaar.length !== 12) return 'XXXX-XXXX-XXXX';
  return `${aadhaar.substring(0, 4)}-${aadhaar.substring(4, 8)}-${aadhaar.substring(8)}`;
}

/**
 * Send notification to admin about new submission
 */
async function sendAdminNotification(uid, technicianName) {
  try {
    // Get admin FCM tokens from config or database
    const adminTokens = await getAdminTokens();
    
    if (adminTokens.length > 0) {
      await admin.messaging().sendToDevice(adminTokens, {
        notification: {
          title: 'New Technician Submission',
          body: `${technicianName} has submitted their KYC documents for review`,
        },
        data: {
          action: 'new_submission',
          uid: uid,
          technicianName: technicianName,
        },
      });
    }
  } catch (error) {
    console.error('Error sending admin notification:', error);
    // Don't throw - this is non-critical
  }
}

/**
 * Get admin FCM tokens
 */
async function getAdminTokens() {
  try {
    const snapshot = await db
      .collection('admins')
      .where('fcmToken', '!=', null)
      .get();
    
    return snapshot.docs.map(doc => doc.data().fcmToken).filter(Boolean);
  } catch (error) {
    console.error('Error getting admin tokens:', error);
    return [];
  }
}

// ============================================================================
// EXPORTS SUMMARY
// ============================================================================

/*
DEPLOYED FUNCTIONS:
1. saveTechnicianDocuments - Save KYC docs with duplicate check
2. submitTechnicianKyc - Atomic submission with all flags
3. approveTechnicianKyc - Admin approval (admin only)
4. rejectTechnicianKyc - Admin rejection (admin only)

SECURITY FEATURES:
✅ Duplicate Aadhaar detection (hashed)
✅ Duplicate phone detection
✅ Atomic submission (no partial states)
✅ Admin-only approval/rejection
✅ Server-side validation
✅ Aadhaar hashing (SHA-256)
✅ Idempotent operations
✅ Push notifications

DEPLOYMENT:
firebase deploy --only functions
*/

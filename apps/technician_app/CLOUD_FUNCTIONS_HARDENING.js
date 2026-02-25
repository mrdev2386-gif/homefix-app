// UPDATED Cloud Functions with Aadhaar Hashing & Duplicate Prevention
// Deploy these functions to Firebase Cloud Functions

const functions = require('firebase-functions');
const admin = require('firebase-admin');
const crypto = require('crypto');

admin.initializeApp();
const db = admin.firestore();

// ============================================
// HELPER: Hash Aadhaar (SHA-256)
// ============================================
function hashAadhaar(aadhaar) {
  const cleaned = aadhaar.replace(/\s-/g, '');
  return crypto.createHash('sha256').update(cleaned).digest('hex');
}

// ============================================
// 3. SAVE DOCUMENTS (KYC) - WITH DUPLICATE CHECK
// ============================================
exports.saveTechnicianDocuments = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User not authenticated');
  }

  const uid = context.auth.uid;
  const {
    aadhaarNumber,
    aadhaarFrontUrl,
    aadhaarBackUrl,
    profilePhotoUrl,
    documentType,
  } = data;

  // Validate Aadhaar
  if (aadhaarNumber) {
    const cleaned = aadhaarNumber.replace(/\s-/g, '');
    if (!/^\d{12}$/.test(cleaned)) {
      throw new functions.https.HttpsError('invalid-argument', 'Invalid Aadhaar format');
    }

    // CRITICAL: Check for duplicate Aadhaar hash
    const aadhaarHash = hashAadhaar(aadhaarNumber);
    const existingDoc = await db.collection('technicians')
      .where('aadhaarHash', '==', aadhaarHash)
      .limit(1)
      .get();

    if (!existingDoc.empty && existingDoc.docs[0].id !== uid) {
      throw new functions.https.HttpsError(
        'duplicate_technician',
        'Technician already registered with this Aadhaar'
      );
    }
  }

  // Validate image URLs
  if (!aadhaarFrontUrl || !aadhaarBackUrl || !profilePhotoUrl) {
    throw new functions.https.HttpsError('invalid-argument', 'All images required');
  }

  try {
    // Mask Aadhaar: XXXX-XXXX-1234
    let maskedAadhaar = null;
    let aadhaarHash = null;
    if (aadhaarNumber) {
      const cleaned = aadhaarNumber.replace(/\s-/g, '');
      maskedAadhaar = `${cleaned.substring(0, 4)}-${cleaned.substring(4, 8)}-${cleaned.substring(8)}`;
      aadhaarHash = hashAadhaar(aadhaarNumber);
    }

    // Update documents
    await db.collection('technicians').doc(uid).update({
      aadhaarNumber: maskedAadhaar,
      aadhaarHash: aadhaarHash, // Store hash for duplicate checking
      aadhaarFrontUrl: aadhaarFrontUrl,
      aadhaarBackUrl: aadhaarBackUrl,
      profilePhotoUrl: profilePhotoUrl,
      documentType: documentType || 'Aadhaar Card',
      kycCompleted: true,
      status: 'kyc_pending',
      updatedAt: admin.firestore.Timestamp.now(),
    });

    return { success: true, message: 'Documents saved' };
  } catch (error) {
    console.error('Error saving documents:', error);
    if (error.code === 'duplicate_technician') {
      throw error;
    }
    throw new functions.https.HttpsError('internal', 'Failed to save documents');
  }
});

// ============================================
// 1. CREATE TECHNICIAN PROFILE - WITH PHONE CHECK
// ============================================
exports.createTechnicianProfile = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User not authenticated');
  }

  const uid = context.auth.uid;
  const phone = data.phone;

  if (!phone) {
    throw new functions.https.HttpsError('invalid-argument', 'Phone number required');
  }

  try {
    // Check if profile already exists
    const existingDoc = await db.collection('technicians').doc(uid).get();
    if (existingDoc.exists) {
      return { success: true, message: 'Profile already exists' };
    }

    // Check for duplicate phone (optional but recommended)
    const phoneCheck = await db.collection('technicians')
      .where('phone', '==', phone)
      .limit(1)
      .get();

    if (!phoneCheck.empty) {
      throw new functions.https.HttpsError(
        'duplicate_technician',
        'Phone number already registered'
      );
    }

    // Create new technician profile
    await db.collection('technicians').doc(uid).set({
      uid: uid,
      phone: phone,
      status: 'onboarding',
      profileCompleted: false,
      kycCompleted: false,
      bankCompleted: false,
      servicesCompleted: false,
      isApproved: false,
      adminApproved: false,
      createdAt: admin.firestore.Timestamp.now(),
      updatedAt: admin.firestore.Timestamp.now(),
      role: 'technician',
    });

    return { success: true, message: 'Profile created' };
  } catch (error) {
    console.error('Error creating profile:', error);
    if (error.code === 'duplicate_technician') {
      throw error;
    }
    throw new functions.https.HttpsError('internal', 'Failed to create profile');
  }
});

// ============================================
// CLIENT-SIDE ERROR HANDLING
// ============================================
// In TechnicianProvider.saveDocuments():
// 
// try {
//   await _onboardingService.saveDocuments(...);
// } catch (e) {
//   if (e.toString().contains('duplicate_technician')) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(
//         content: Text('Technician already registered with this Aadhaar'),
//         backgroundColor: Colors.red,
//       ),
//     );
//     return; // Prevent step progression
//   }
//   rethrow;
// }

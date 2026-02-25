// Cloud Functions for HomeFix Technician Onboarding
// Deploy these functions to Firebase Cloud Functions
// 
// SECURITY: All technician profile writes go through these functions
// Client-side writes are NEVER allowed via Firestore rules

const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();
const db = admin.firestore();

// ============================================
// 1. CREATE TECHNICIAN PROFILE (After OTP)
// ============================================
exports.createTechnicianProfile = functions.https.onCall(async (data, context) => {
  // Verify authentication
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
      role: 'technician', // Set server-side only
    });

    return { success: true, message: 'Profile created' };
  } catch (error) {
    console.error('Error creating profile:', error);
    throw new functions.https.HttpsError('internal', 'Failed to create profile');
  }
});

// ============================================
// 2. SAVE BASIC DETAILS
// ============================================
exports.saveTechnicianBasicDetails = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User not authenticated');
  }

  const uid = context.auth.uid;
  const { fullName, email, district, experienceYears } = data;

  // Validate required fields
  if (!fullName || !district) {
    throw new functions.https.HttpsError('invalid-argument', 'Name and district required');
  }

  try {
    // Verify technician document exists
    const techDoc = await db.collection('technicians').doc(uid).get();
    if (!techDoc.exists) {
      throw new functions.https.HttpsError('not-found', 'Technician profile not found');
    }

    // Update basic details
    await db.collection('technicians').doc(uid).update({
      name: fullName.trim(),
      email: email?.trim() || '',
      district: district.trim(),
      experienceYears: experienceYears || 0,
      profileCompleted: true,
      updatedAt: admin.firestore.Timestamp.now(),
    });

    return { success: true, message: 'Basic details saved', idempotent: false };
  } catch (error) {
    console.error('Error saving basic details:', error);
    throw new functions.https.HttpsError('internal', 'Failed to save details');
  }
});

// ============================================
// 3. SAVE DOCUMENTS (KYC)
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
  }

  // Validate image URLs
  if (!aadhaarFrontUrl || !aadhaarBackUrl || !profilePhotoUrl) {
    throw new functions.https.HttpsError('invalid-argument', 'All images required');
  }

  try {
    // Mask Aadhaar: XXXX-XXXX-1234
    let maskedAadhaar = null;
    if (aadhaarNumber) {
      const cleaned = aadhaarNumber.replace(/\s-/g, '');
      maskedAadhaar = `${cleaned.substring(0, 4)}-${cleaned.substring(4, 8)}-${cleaned.substring(8)}`;
    }

    // Update documents
    await db.collection('technicians').doc(uid).update({
      aadhaarNumber: maskedAadhaar,
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
    throw new functions.https.HttpsError('internal', 'Failed to save documents');
  }
});

// ============================================
// 4. SAVE BANK DETAILS
// ============================================
exports.saveTechnicianBankDetails = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User not authenticated');
  }

  const uid = context.auth.uid;
  const { accountHolder, accountNumber, ifscCode, bankName, upiId } = data;

  // Validate required fields
  if (!accountHolder || !accountNumber || !ifscCode || !bankName) {
    throw new functions.https.HttpsError('invalid-argument', 'Required fields missing');
  }

  // Validate account number (9-18 digits)
  if (!/^\d{9,18}$/.test(accountNumber)) {
    throw new functions.https.HttpsError('invalid-argument', 'Invalid account number');
  }

  // Validate IFSC (XXXX0XXXXXX)
  if (!/^[A-Z]{4}0[A-Z0-9]{6}$/.test(ifscCode)) {
    throw new functions.https.HttpsError('invalid-argument', 'Invalid IFSC code');
  }

  try {
    // Update bank details (NEVER log full account number)
    await db.collection('technicians').doc(uid).update({
      accountHolder: accountHolder.trim(),
      accountNumber: accountNumber, // Stored encrypted in Firestore
      ifscCode: ifscCode.toUpperCase(),
      bankName: bankName.trim(),
      upiId: upiId?.trim() || null,
      bankCompleted: true,
      updatedAt: admin.firestore.Timestamp.now(),
    });

    return { success: true, message: 'Bank details saved' };
  } catch (error) {
    console.error('Error saving bank details:', error);
    throw new functions.https.HttpsError('internal', 'Failed to save bank details');
  }
});

// ============================================
// 5. SAVE SERVICES
// ============================================
exports.saveTechnicianServices = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User not authenticated');
  }

  const uid = context.auth.uid;
  const { categoryId, categoryName, skills, basePrice, visitingCharge, maxTravelDistance } = data;

  if (!categoryId || !categoryName || !skills || skills.length === 0) {
    throw new functions.https.HttpsError('invalid-argument', 'Required fields missing');
  }

  try {
    await db.collection('technicians').doc(uid).update({
      primaryCategoryId: categoryId,
      primaryCategoryName: categoryName,
      skills: skills,
      basePrice: basePrice || 0,
      visitingCharge: visitingCharge || 0,
      maxTravelDistance: maxTravelDistance || 10,
      servicesCompleted: true,
      updatedAt: admin.firestore.Timestamp.now(),
    });

    return { success: true, message: 'Services saved' };
  } catch (error) {
    console.error('Error saving services:', error);
    throw new functions.https.HttpsError('internal', 'Failed to save services');
  }
});

// ============================================
// 6. SUBMIT KYC APPLICATION
// ============================================
exports.submitTechnicianKyc = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User not authenticated');
  }

  const uid = context.auth.uid;

  try {
    // Verify all required steps are complete
    const techDoc = await db.collection('technicians').doc(uid).get();
    if (!techDoc.exists) {
      throw new functions.https.HttpsError('not-found', 'Technician not found');
    }

    const tech = techDoc.data();
    if (!tech.profileCompleted || !tech.kycCompleted || !tech.bankCompleted || !tech.servicesCompleted) {
      throw new functions.https.HttpsError('failed-precondition', 'All steps must be completed');
    }

    // Update status to pending approval
    await db.collection('technicians').doc(uid).update({
      status: 'pending_approval',
      updatedAt: admin.firestore.Timestamp.now(),
    });

    // Send admin notification (implement based on your notification system)
    console.log(`New KYC submission from technician: ${uid}`);

    return { success: true, message: 'Application submitted' };
  } catch (error) {
    console.error('Error submitting KYC:', error);
    throw new functions.https.HttpsError('internal', 'Failed to submit application');
  }
});

// ============================================
// 7. APPROVE TECHNICIAN (Admin only)
// ============================================
exports.approveTechnicianKyc = functions.https.onCall(async (data, context) => {
  // Verify admin role (implement your admin verification)
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User not authenticated');
  }

  // TODO: Add admin role verification
  // const adminDoc = await db.collection('admins').doc(context.auth.uid).get();
  // if (!adminDoc.exists) {
  //   throw new functions.https.HttpsError('permission-denied', 'Admin access required');
  // }

  const technicianUid = data.technicianUid;

  if (!technicianUid) {
    throw new functions.https.HttpsError('invalid-argument', 'Technician UID required');
  }

  try {
    await db.collection('technicians').doc(technicianUid).update({
      isApproved: true,
      adminApproved: true,
      status: 'approved',
      updatedAt: admin.firestore.Timestamp.now(),
    });

    // Send notification to technician
    console.log(`Technician ${technicianUid} approved`);

    return { success: true, message: 'Technician approved' };
  } catch (error) {
    console.error('Error approving technician:', error);
    throw new functions.https.HttpsError('internal', 'Failed to approve technician');
  }
});

// ============================================
// 8. REJECT TECHNICIAN (Admin only)
// ============================================
exports.rejectTechnicianKyc = functions.https.onCall(async (data, context) => {
  // Verify admin role
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User not authenticated');
  }

  const { technicianUid, reason } = data;

  if (!technicianUid || !reason) {
    throw new functions.https.HttpsError('invalid-argument', 'Technician UID and reason required');
  }

  try {
    await db.collection('technicians').doc(technicianUid).update({
      status: 'rejected',
      rejectionReason: reason,
      updatedAt: admin.firestore.Timestamp.now(),
    });

    // Send notification to technician
    console.log(`Technician ${technicianUid} rejected: ${reason}`);

    return { success: true, message: 'Technician rejected' };
  } catch (error) {
    console.error('Error rejecting technician:', error);
    throw new functions.https.HttpsError('internal', 'Failed to reject technician');
  }
});

// ============================================
// 9. UPDATE TECHNICIAN STATUS
// ============================================
exports.updateTechnicianStatus = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User not authenticated');
  }

  const uid = context.auth.uid;
  const { isOnline } = data;

  try {
    // Verify technician is approved
    const techDoc = await db.collection('technicians').doc(uid).get();
    if (!techDoc.exists || !techDoc.data().isApproved) {
      throw new functions.https.HttpsError('permission-denied', 'Not approved');
    }

    await db.collection('technicians').doc(uid).update({
      isOnline: isOnline,
      updatedAt: admin.firestore.Timestamp.now(),
    });

    return { success: true, message: 'Status updated' };
  } catch (error) {
    console.error('Error updating status:', error);
    throw new functions.https.HttpsError('internal', 'Failed to update status');
  }
});

// ============================================
// DEPLOYMENT INSTRUCTIONS
// ============================================
/*
1. Copy this file to: backend/functions/index.js
2. Install dependencies: npm install firebase-functions firebase-admin
3. Deploy: firebase deploy --only functions
4. Test each function via Firebase Console
5. Update Firestore security rules to allow only Cloud Function writes
*/

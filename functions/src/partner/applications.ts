import { onCall, HttpsError } from 'firebase-functions/v2/https';
import * as admin from 'firebase-admin';

const db = admin.firestore();

/**
 * Submit Partner Application (V2)
 * 
 * CRITICAL: This is the ONLY way to submit partner applications
 * - Validates all required fields
 * - Checks for duplicate applications
 * - Writes to technician_applications collection
 * - Sends notification to admin
 */
export const submitPartnerApplication = onCall(async (request) => {
  try {
    // V2: Auth is in request.auth, not context.auth
    const auth = request.auth;
    if (!auth) {
      throw new HttpsError(
        'unauthenticated',
        'User must be authenticated to submit application'
      );
    }

    const userId = auth.uid;
    const data = request.data;

    // Validate required fields
    const requiredFields = [
      'fullName',
      'phone',
      'email',
      'categoryIds',
      'subcategoryIds',
      'experienceYears',
      'address',
      'bankDetails',
    ];

    for (const field of requiredFields) {
      if (!data[field]) {
        throw new HttpsError(
          'invalid-argument',
          `Missing required field: ${field}`
        );
      }
    }

    // Validate bank details structure
    if (!data.bankDetails.accountNumber || !data.bankDetails.ifscCode || !data.bankDetails.holderName) {
      throw new HttpsError(
        'invalid-argument',
        'Bank details must include accountNumber, ifscCode, and holderName'
      );
    }

    // Validate arrays
    if (!Array.isArray(data.categoryIds) || data.categoryIds.length === 0) {
      throw new HttpsError(
        'invalid-argument',
        'categoryIds must be a non-empty array'
      );
    }

    if (!Array.isArray(data.subcategoryIds) || data.subcategoryIds.length === 0) {
      throw new HttpsError(
        'invalid-argument',
        'subcategoryIds must be a non-empty array'
      );
    }

    // Validate experience years
    if (typeof data.experienceYears !== 'number' || data.experienceYears <= 0) {
      throw new HttpsError(
        'invalid-argument',
        'experienceYears must be a positive number'
      );
    }

    // Check for duplicate application
    const existingApp = await db
      .collection('technician_applications')
      .doc(userId)
      .get();

    if (existingApp.exists) {
      const status = existingApp.data()?.status;
      if (status === 'pending' || status === 'approved') {
        throw new HttpsError(
          'already-exists',
          'You have already submitted an application'
        );
      }
    }

    // Create application document
    const applicationData = {
      userId,
      fullName: data.fullName,
      phone: data.phone,
      email: data.email,
      categoryIds: data.categoryIds,
      subcategoryIds: data.subcategoryIds,
      experienceYears: data.experienceYears,
      experienceDescription: data.experienceDescription || '',
      profilePhotoUrl: data.profilePhotoUrl || null,
      idProofUrl: data.idProofUrl || null,
      address: data.address,
      bankDetails: {
        accountNumber: data.bankDetails.accountNumber,
        ifscCode: data.bankDetails.ifscCode,
        holderName: data.bankDetails.holderName,
      },
      status: 'pending',
      appliedAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    // Write to Firestore
    await db
      .collection('technician_applications')
      .doc(userId)
      .set(applicationData);

    // Send notification to admin
    try {
      await db.collection('admin_notifications').add({
        type: 'new_partner_application',
        userId,
        userName: data.fullName,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        isRead: false,
      });
    } catch (notifError) {
      console.error('[Partner Application] Failed to send admin notification:', notifError);
      // Don't fail the application if notification fails
    }

    console.log(`[Partner Application] Application submitted successfully for user: ${userId}`);

    return {
      success: true,
      message: 'Application submitted successfully',
      applicationId: userId,
    };
  } catch (error: any) {
    console.error('[Partner Application] Error:', error);
    
    // Re-throw HttpsError as-is
    if (error instanceof HttpsError) {
      throw error;
    }
    
    // Wrap other errors
    throw new HttpsError(
      'internal',
      error.message || 'Failed to submit application'
    );
  }
});

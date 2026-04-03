import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { checkRateLimit } from '../shared/utils';

const db = admin.firestore();

/**
 * Submit Partner Application (V1)
 * 
 * CRITICAL: This is the ONLY way to submit partner applications
 * - Validates all required fields
 * - Checks for duplicate applications
 * - Writes to technician_applications collection
 * - Sends notification to admin
 */
export const submitPartnerApplication = functions.region('asia-south1').https.onCall(async (data, context) => {
  try {
    // V1: Auth is in context.auth
    const auth = context.auth;
    if (!auth) {
      throw new functions.https.HttpsError(
        'unauthenticated',
        'User must be authenticated to submit application'
      );
    }

    const userId = auth.uid;
    // data is already the first argument in V1 onCall

    // 0. RATE LIMITING (Harden)
    await checkRateLimit(userId, 'submit_partner_application', 2, 1440);

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
        throw new functions.https.HttpsError(
          'invalid-argument',
          `Missing required field: ${field}`
        );
      }
    }

    // Validate bank details structure
    if (!data.bankDetails.accountNumber || !data.bankDetails.ifscCode || !data.bankDetails.holderName) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'Bank details must include accountNumber, ifscCode, and holderName'
      );
    }

    // Validate arrays
    if (!Array.isArray(data.categoryIds) || data.categoryIds.length === 0) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'categoryIds must be a non-empty array'
      );
    }

    if (!Array.isArray(data.subcategoryIds) || data.subcategoryIds.length === 0) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'subcategoryIds must be a non-empty array'
      );
    }

    // Validate experience years
    if (typeof data.experienceYears !== 'number' || data.experienceYears <= 0) {
      throw new functions.https.HttpsError(
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
        throw new functions.https.HttpsError(
          'already-exists',
          'You have already submitted an application'
        );
      }
    }

    // Build skills mapping if selectedServices provided
    const selectedServices = data.selectedServices;
    const skills: { [key: string]: any } = {};
    const serviceIds: string[] = [];

    if (Array.isArray(selectedServices) && selectedServices.length > 0) {
      console.log(`[Partner Application] Processing ${selectedServices.length} mapped services for user: ${userId}`);

      selectedServices.forEach((s: any) => {
        if (s.serviceId && typeof s.serviceId === 'string') {
          // Standardize serviceId format and prevent duplicates
          const sId = s.serviceId.trim();
          if (!skills[sId]) {
            skills[sId] = {
              serviceId: sId,
              serviceName: s.serviceName || 'Service',
              subServiceIds: Array.isArray(s.subServiceIds) ? s.subServiceIds : [],
              addedAt: admin.firestore.FieldValue.serverTimestamp(),
            };
            serviceIds.push(sId);
          }
        }
      });
    } else {
      console.warn(`[Partner Application] No selectedServices provided for user: ${userId}. Backwards compatibility active.`);
    }

    // Create application document
    const applicationData = {
      userId,
      fullName: data.fullName,
      phone: data.phone,
      email: data.email,
      categoryIds: data.categoryIds,
      subcategoryIds: data.subcategoryIds,
      serviceIds, // Flat array for fast matching
      skills,     // Structured mapping
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
      district: data.district || (data.address?.district || ''),
      districtNormalized: data.district ? data.district.toString().trim().toLowerCase() : (data.address?.district ? data.address.district.toString().trim().toLowerCase() : ''),
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

    console.log(`[Partner Application] Application submitted successfully for user: ${userId} with ${serviceIds.length} services.`);

    return {
      success: true,
      message: 'Application submitted successfully',
      applicationId: userId,
      mappedServices: serviceIds.length
    };
  } catch (error: any) {
    console.error('[Partner Application] Error:', error);

    // Re-throw HttpsError as-is
    if (error instanceof functions.https.HttpsError) {
      throw error;
    }

    // Wrap other errors
    throw new functions.https.HttpsError(
      'internal',
      error.message || 'Failed to submit application'
    );
  }
});

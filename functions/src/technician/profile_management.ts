import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

const db = admin.firestore();

export const updateTechnicianPersonalDetails = functions.region('asia-south1').https.onCall(async (data, context) => {
    console.log("Auth UID:", context.auth?.uid);
    
    if (!context.auth) {
        throw new functions.https.HttpsError(
            "unauthenticated",
            "User must be logged in"
        );
    }
    
    const uid = context.auth.uid;
    console.log(`[updateTechnicianPersonalDetails] Request from uid: ${uid}`);
    console.log(`[updateTechnicianPersonalDetails] Request data:`, data);

    // Protected fields that cannot be modified by users
    const protectedFields = new Set([
        'uid', 'walletBalance', 'rating', 'totalJobs', 'isApproved', 
        'createdAt', 'adminApproved', 'isKycComplete', 'onboardingCompleted',
        'role', 'status', 'bankStatus', 'aadhaarFrontStatus', 'aadhaarBackStatus',
        'profilePhotoStatus'
    ]);

    const updates: Record<string, any> = {};

    // Dynamically build updates from request data
    for (const [key, value] of Object.entries(data)) {
        // Skip protected fields
        if (protectedFields.has(key)) {
            console.log(`[updateTechnicianPersonalDetails] Skipping protected field: ${key}`);
            continue;
        }
        
        // Skip null and undefined values
        if (value !== null && value !== undefined) {
            updates[key] = value;
            console.log(`[updateTechnicianPersonalDetails] Adding field: ${key} = ${value}`);
            
            // Special handling for fullName - also update name field for compatibility
            if (key === 'fullName') {
                updates['name'] = value;
                console.log(`[updateTechnicianPersonalDetails] Also updating name field: ${value}`);
            }
        }
    }

    // If no valid fields to update, return early
    if (Object.keys(updates).length === 0) {
        console.log(`[updateTechnicianPersonalDetails] No fields to update`);
        return { success: true, message: 'Nothing to update', updatedFields: [] };
    }

    // Always add timestamp to trigger stream updates
    updates.updatedAt = admin.firestore.FieldValue.serverTimestamp();
    console.log(`[updateTechnicianPersonalDetails] Final updates object:`, updates);

    try {
        // Update technician document using .update() to preserve existing fields
        await db.collection('technicians').doc(uid).update(updates);
        console.log(`[updateTechnicianPersonalDetails] Firestore update successful`);
    } catch (error) {
        console.error(`[updateTechnicianPersonalDetails] Firestore update failed:`, error);
        throw new functions.https.HttpsError('internal', 'Failed to update profile');
    }

    const updatedFields = Object.keys(updates).filter(key => key !== 'updatedAt');
    console.log(`[updateTechnicianPersonalDetails] Updated fields: ${updatedFields.join(', ')}`);

    return {
        success: true,
        message: 'Profile updated successfully',
        updatedFields
    };
});

export const updateTechnicianBankDetails = functions.region('asia-south1').https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'User must be logged in');
    }
    
    const uid = context.auth.uid;
    const { accountHolderName, bankName, accountNumber, ifscCode } = data;
    
    if (!accountHolderName || accountHolderName.trim().length < 3) {
        throw new functions.https.HttpsError('invalid-argument', 'Account holder name is required (min 3 characters)');
    }
    
    if (!bankName || bankName.trim().length < 2) {
        throw new functions.https.HttpsError('invalid-argument', 'Bank name is required');
    }
    
    if (!accountNumber || !/^[0-9]{9,18}$/.test(accountNumber.trim())) {
        throw new functions.https.HttpsError('invalid-argument', 'Valid account number is required (9-18 digits)');
    }
    
    if (!ifscCode || !/^[A-Z]{4}0[A-Z0-9]{6}$/.test(ifscCode.toUpperCase())) {
        throw new functions.https.HttpsError('invalid-argument', 'Valid IFSC code is required (format: ABCD0123456)');
    }
    
    const techDoc = await db.collection('technicians').doc(uid).get();
    if (!techDoc.exists) {
        throw new functions.https.HttpsError('not-found', 'Technician profile not found');
    }
    
    const techData = techDoc.data();
    const currentBankStatus = techData?.bankStatus || 'not_submitted';
    
    if (currentBankStatus === 'approved') {
        throw new functions.https.HttpsError('failed-precondition', 'Cannot modify approved bank details. Contact support if changes are needed.');
    }
    
    const updateData: Record<string, any> = {
        accountHolderName: accountHolderName.trim(),
        bankName: bankName.trim(),
        accountNumber: accountNumber.trim(),
        ifscCode: ifscCode.toUpperCase().trim(),
        bankStatus: 'pending',
        bankSubmittedAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
    };
    
    if (currentBankStatus === 'rejected') {
        updateData.bankRejectionReason = admin.firestore.FieldValue.delete();
    }
    
    await db.collection('technicians').doc(uid).update(updateData);
    
    console.log(`[updateTechnicianBankDetails] Updated for uid: ${uid}, status: pending`);
    
    const maskedAccount = accountNumber.trim().length > 4 ? `****${accountNumber.trim().slice(-4)}` : accountNumber.trim();
    
    return {
        success: true,
        message: 'Bank details submitted for verification',
        bankStatus: 'pending',
        maskedAccountNumber: maskedAccount
    };
});

export const reuploadVerificationDocument = functions.region('asia-south1').https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'User must be logged in');
    }
    
    const uid = context.auth.uid;
    const { documentType, documentUrl } = data;
    
    if (!documentType || !['aadhaarFront', 'aadhaarBack', 'profilePhoto'].includes(documentType)) {
        throw new functions.https.HttpsError('invalid-argument', 'Invalid document type. Must be: aadhaarFront, aadhaarBack, or profilePhoto');
    }
    
    if (!documentUrl || !documentUrl.startsWith('https://')) {
        throw new functions.https.HttpsError('invalid-argument', 'Valid document URL is required');
    }
    
    const techDoc = await db.collection('technicians').doc(uid).get();
    if (!techDoc.exists) {
        throw new functions.https.HttpsError('not-found', 'Technician profile not found');
    }
    
    const techData = techDoc.data();
    const statusField = `${documentType}Status`;
    const currentStatus = techData?.[statusField] || 'missing';
    
    if (currentStatus === 'approved') {
        throw new functions.https.HttpsError('failed-precondition', 'Cannot re-upload approved document. Contact support if changes are needed.');
    }
    
    const updateData: Record<string, any> = {
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
    };
    
    const fieldMap: Record<string, string> = {
        'aadhaarFront': 'aadhaarFrontUrl',
        'aadhaarBack': 'aadhaarBackUrl',
        'profilePhoto': 'profilePhotoUrl'
    };
    
    const urlField = fieldMap[documentType];
    updateData[urlField] = documentUrl;
    updateData[statusField] = 'pending';
    
    const rejectionField = `${documentType}RejectionReason`;
    if (currentStatus === 'rejected') {
        updateData[rejectionField] = admin.firestore.FieldValue.delete();
    }
    
    await db.collection('technicians').doc(uid).update(updateData);
    
    console.log(`[reuploadVerificationDocument] Re-uploaded ${documentType} for uid: ${uid}`);
    
    return {
        success: true,
        message: 'Document uploaded successfully',
        documentType,
        status: 'pending'
    };
});

export const adminUpdateBankStatus = functions.region('asia-south1').https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'User must be logged in');
    }
    
    const adminDoc = await db.collection('admins').doc(context.auth.uid).get();
    if (!adminDoc.exists) {
        throw new functions.https.HttpsError('permission-denied', 'Only admins can update bank status');
    }
    
    const { technicianId, status, rejectionReason } = data;
    
    if (!technicianId) {
        throw new functions.https.HttpsError('invalid-argument', 'Technician ID is required');
    }
    
    if (!['approved', 'rejected'].includes(status)) {
        throw new functions.https.HttpsError('invalid-argument', 'Status must be "approved" or "rejected"');
    }
    
    if (status === 'rejected' && !rejectionReason) {
        throw new functions.https.HttpsError('invalid-argument', 'Rejection reason is required when rejecting');
    }
    
    const techDoc = await db.collection('technicians').doc(technicianId).get();
    if (!techDoc.exists) {
        throw new functions.https.HttpsError('not-found', 'Technician not found');
    }
    
    const updateData: Record<string, any> = {
        bankStatus: status,
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
    };
    
    if (status === 'rejected') {
        updateData.bankRejectionReason = rejectionReason;
    } else {
        updateData.bankRejectionReason = admin.firestore.FieldValue.delete();
    }
    
    await db.collection('technicians').doc(technicianId).update(updateData);
    
    console.log(`[adminUpdateBankStatus] Updated ${technicianId} to ${status}`);
    
    return {
        success: true,
        message: `Bank details ${status}`,
        bankStatus: status
    };
});

export const adminUpdateDocumentStatus = functions.region('asia-south1').https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'User must be logged in');
    }
    
    const adminDoc = await db.collection('admins').doc(context.auth.uid).get();
    if (!adminDoc.exists) {
        throw new functions.https.HttpsError('permission-denied', 'Only admins');
    }
    
    const { technicianId, documentType, status, rejectionReason } = data;
    
    if (!technicianId || !documentType || !status) {
        throw new functions.https.HttpsError('invalid-argument', 'Missing required fields');
    }
    
    const updateData: Record<string, any> = {
        [`${documentType}Status`]: status,
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
    };
    
    if (status === 'rejected' && rejectionReason) {
        updateData[`${documentType}RejectionReason`] = rejectionReason;
    }
    
    await db.collection('technicians').doc(technicianId).update(updateData);
    
    return { success: true };
});

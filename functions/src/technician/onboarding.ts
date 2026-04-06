import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { assertAuthenticated, encrypt, sanitizeString, sanitizeEmail, sanitizeAadhaar } from '../shared/security';

const db = admin.firestore();

/**
 * SECURE TECHNICIAN ONBOARDING CLOUD FUNCTION
 * 
 * All technician profile writes MUST go through this function.
 * This ensures:
 * - Firebase Auth UID is validated server-side
 * - role = 'technician' is set server-side only
 * - Protected fields (isApproved, adminApproved, etc.) can only be set by admin
 * - Proper validation before writes
 */

// Protected fields that ONLY admin can set
const ADMIN_ONLY_FIELDS = [
    'isApproved',
    'adminApproved',
    'rating',
    'walletBalance',
    'adminNotes',
    'totalJobs',
    'earnings',
    'avgRating',
    'jobsDone',
    'rejectionReason',
    'suspendedAt',
    'blockedAt'
];

/**
 * Create or update technician profile draft
 * Called after successful Phone OTP verification
 */
export const createTechnicianProfile = functions.region('asia-south1').https.onCall(async (data, context) => {
    assertAuthenticated(context);
    const uid = context.auth!.uid;
    const { phone, email } = data;

    // Validate phone
    if (!phone || phone.length < 10) {
        throw new functions.https.HttpsError(
            'invalid-argument',
            'Valid phone number is required'
        );
    }

    // Check if technician profile already exists
    const existingDoc = await db.collection('technicians').doc(uid).get();

    if (existingDoc.exists) {
        // Return existing onboarding state instead of throwing error
        const existingData = existingDoc.data();
        const currentStep = existingData?.onboardingStep || 'basicDetails';
        const status = existingData?.status || 'pending';
        
        console.log(`[createTechnicianProfile] Technician ${uid} already exists, returning current state: ${currentStep}`);
        
        return {
            success: true,
            message: 'Profile already exists',
            step: currentStep,
            status: status,
            existing: true
        };
    }

    // Create new technician profile
    const now = admin.firestore.FieldValue.serverTimestamp();

    await db.collection('technicians').doc(uid).set({
        uid: uid,
        phone: phone,
        email: email || '',
        // Role is set server-side only - client cannot set this
        role: 'technician', // Server-side only

        // Onboarding state
        onboardingStep: 'basicDetails',
        isKycComplete: false,
        isApproved: false,
        adminApproved: false, // Explicit admin approval flag
        status: 'pending',
        kycStatus: 'pending',

        // Initialize empty fields
        name: '',
        fullName: '',
        district: '',
        skills: [],
        isOnline: false,
        isVerified: false,
        isActive: false,

        // Default values (protected)
        rating: 0,
        avgRating: 0.0,
        totalRatings: 0,
        totalJobs: 0,
        jobsDone: 0,
        walletBalance: 0,
        earnings: 0,

        createdAt: now,
        updatedAt: now
    }, { merge: true });

    // Also set the user role in users collection
    await db.collection('users').doc(uid).set({
        uid: uid,
        phone: phone,
        email: email || '',
        role: 'technician',
        createdAt: now,
        updatedAt: now
    }, { merge: true });

    return {
        success: true,
        message: 'Profile created',
        step: 'basicDetails'
    };
});

/**
 * Save basic details during onboarding
 * 
 * IDEMPOTENT: Allows updates when technician is in:
 * - draft (no onboardingStep)
 * - basic_pending (before basic details completed)
 * - basic_completed (basic details saved, can re-save)
 * - basicDetails (current step)
 * - phone (before basic details)
 * - documents (if user goes back)
 * 
 * Stage progression: draft/phone → basicDetails → documents
 */
export const saveTechnicianBasicDetails = functions.region('asia-south1').https.onCall(async (data, context) => {
    assertAuthenticated(context);
    const uid = context.auth!.uid;
    const { fullName, email, district, experienceYears } = data;

    // SECURITY FIX: Sanitize inputs
    const sanitizedFullName = sanitizeString(fullName || '', 100);
    const sanitizedEmail = sanitizeEmail(email || '');
    const sanitizedDistrict = sanitizeString(district || '', 50);

    // Validation
    if (!sanitizedFullName || sanitizedFullName.length < 2) {
        throw new functions.https.HttpsError(
            'invalid-argument',
            'Full name is required (min 2 characters)'
        );
    }

    // Get current technician to verify onboarding state
    const techDoc = await db.collection('technicians').doc(uid).get();
    if (!techDoc.exists) {
        throw new functions.https.HttpsError(
            'not-found',
            'Technician profile not found. Please start onboarding again.'
        );
    }

    const techData = techDoc.data();
    const currentStep = techData?.onboardingStep;

    // FIX: Check if profile is locked (submitted for review)
    if (techData?.isLocked === true) {
        throw new functions.https.HttpsError(
            'failed-precondition',
            'Profile is locked. Contact support to make changes.'
        );
    }

    // ALLOWED STEPS FOR BASIC DETAILS UPDATE:
    // - undefined/null: draft state (profile created but no step assigned)
    // - 'phone': after OTP, before basic details
    // - 'basicDetails': current step
    // - 'documents': user went back from documents
    // - 'basic_completed': legacy state from older implementation
    // - 'basic_pending': legacy state from older implementation
    const allowedSteps = [
        undefined,
        null,
        '',
        'phone',
        'basicDetails',
        'documents',
        'basic_completed',
        'basic_pending',
        'draft' // explicit draft state
    ];

    const isStepAllowed = currentStep === undefined ||
        currentStep === null ||
        currentStep === '' ||
        allowedSteps.includes(currentStep);

    // Also allow if we're already past documents (shouldn't happen but being defensive)
    const isBeforeServices = !currentStep ||
        currentStep === 'phone' ||
        currentStep === 'basicDetails' ||
        currentStep === 'documents' ||
        currentStep === 'basic_completed' ||
        currentStep === 'basic_pending' ||
        currentStep === 'draft';

    if (!isStepAllowed && !isBeforeServices) {
        console.log(`[saveTechnicianBasicDetails] Rejected update for uid ${uid}, currentStep: ${currentStep}`);
        throw new functions.https.HttpsError(
            'failed-precondition',
            'Cannot modify basic details at this stage. Please complete the current step first.'
        );
    }

    // Check if data is already the same (idempotent update)
    const existingFullName = techData?.fullName || techData?.name || '';
    const existingEmail = techData?.email || '';
    const existingDistrict = techData?.district || '';
    const existingExperience = techData?.experienceYears || 0;

    const isDataUnchanged = existingFullName === fullName &&
        existingEmail === (email || '') &&
        existingDistrict === (district || '') &&
        existingExperience === (experienceYears || 0);

    if (isDataUnchanged && currentStep === 'documents') {
        // Data unchanged and already past this step - return success
        console.log(`[saveTechnicianBasicDetails] Idempotent update for uid ${uid}, data unchanged`);
        return {
            success: true,
            nextStep: 'documents',
            idempotent: true
        };
    }

    // Determine target step based on current position
    // If already at documents or beyond, stay there; otherwise move to documents
    let targetStep = 'documents';
    if (currentStep === 'documents' || currentStep === 'services' || currentStep === 'review') {
        // User went back - keep them at current step
        targetStep = currentStep;
    }

    // Update technician profile
    await db.collection('technicians').doc(uid).update({
        fullName: sanitizedFullName,
        name: sanitizedFullName, // Alias for compatibility
        email: sanitizedEmail,
        district: sanitizedDistrict,
        experienceYears: experienceYears || 0,
        onboardingStep: targetStep,
        'stepsCompleted.basic': true,
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
    });

    console.log(`[saveTechnicianBasicDetails] Updated basic details for uid ${uid}, targetStep: ${targetStep}`);

    return {
        success: true,
        nextStep: targetStep
    };
});

/**
 * Save documents/KYC during onboarding
 */
export const saveTechnicianDocuments = functions.region('asia-south1').https.onCall(async (data, context) => {
    assertAuthenticated(context);
    const uid = context.auth!.uid;
    const {
        aadhaarNumber,
        aadhaarFrontUrl,
        aadhaarBackUrl,
        profilePhotoUrl,
        documentType
    } = data;

    // SECURITY FIX: Sanitize Aadhaar
    const sanitizedAadhaar = sanitizeAadhaar(aadhaarNumber || '');

    // Validate required fields
    if (!sanitizedAadhaar || sanitizedAadhaar.length !== 12) {
        throw new functions.https.HttpsError(
            'invalid-argument',
            'Valid 12-digit Aadhaar number is required'
        );
    }

    if (!aadhaarFrontUrl || !profilePhotoUrl) {
        throw new functions.https.HttpsError(
            'invalid-argument',
            'Document images and profile photo are required'
        );
    }

    // Get current technician to verify onboarding state
    const techDoc = await db.collection('technicians').doc(uid).get();
    if (!techDoc.exists) {
        throw new functions.https.HttpsError(
            'not-found',
            'Technician profile not found'
        );
    }

    const techData = techDoc.data();
    const currentStep = techData?.onboardingStep;

    // FIX: Check if profile is locked (submitted for review)
    if (techData?.isLocked === true) {
        throw new functions.https.HttpsError(
            'failed-precondition',
            'Profile is locked. Contact support to make changes.'
        );
    }

    // Allow if in documents step or earlier
    if (currentStep && currentStep !== 'documents' && currentStep !== 'basicDetails') {
        throw new functions.https.HttpsError(
            'failed-precondition',
            'Cannot modify documents at this stage'
        );
    }

    // CRITICAL SECURITY FIX: Encrypt Aadhaar before storing
    const encryptedAadhaar = encrypt(sanitizedAadhaar);
    
    // Mask Aadhaar for display (store last 4 digits)
    const maskedAadhaar = `XXXX-XXXX-${sanitizedAadhaar.substring(8)}`;

    // Update technician profile with documents
    await db.collection('technicians').doc(uid).update({
        aadhaarNumber: encryptedAadhaar, // ENCRYPTED
        aadhaarMasked: maskedAadhaar,
        aadhaarFrontUrl: aadhaarFrontUrl,
        aadhaarBackUrl: aadhaarBackUrl || '',
        profilePhotoUrl: profilePhotoUrl,
        documentType: documentType || 'Aadhaar Card',
        onboardingStep: 'services',
        'stepsCompleted.kyc': true,
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
    });

    console.log(`[SECURITY] Aadhaar encrypted and stored for technician ${uid}`);

    return {
        success: true,
        nextStep: 'services'
    };
});

/**
 * Save service/category selection during onboarding
 */
export const saveTechnicianServices = functions.region('asia-south1').https.onCall(async (data, context) => {
    assertAuthenticated(context);
    const uid = context.auth!.uid;
    const { categoryId, categoryName, skills } = data;

    // Validation
    if (!categoryId || !categoryName) {
        throw new functions.https.HttpsError(
            'invalid-argument',
            'Category selection is required'
        );
    }

    if (!skills || skills.length === 0) {
        throw new functions.https.HttpsError(
            'invalid-argument',
            'At least one skill is required'
        );
    }

    // Verify category exists
    const categoryDoc = await db.collection('categories').doc(categoryId).get();
    if (!categoryDoc.exists) {
        throw new functions.https.HttpsError(
            'not-found',
            'Invalid category selected'
        );
    }

    // Get current technician to verify onboarding state
    const techDoc = await db.collection('technicians').doc(uid).get();
    if (!techDoc.exists) {
        throw new functions.https.HttpsError(
            'not-found',
            'Technician profile not found'
        );
    }

    const techData = techDoc.data();
    const currentStep = techData?.onboardingStep;

    // Allow if in services step or earlier
    if (currentStep && currentStep !== 'services' && currentStep !== 'documents') {
        throw new functions.https.HttpsError(
            'failed-precondition',
            'Cannot modify services at this stage'
        );
    }

    // Update technician profile with services
    await db.collection('technicians').doc(uid).update({
        primaryCategoryId: categoryId,
        primaryCategoryName: categoryName,
        skills: skills,
        onboardingStep: 'review',
        'stepsCompleted.services': true,
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
    });

    return {
        success: true,
        nextStep: 'review'
    };
});

/**
 * Submit KYC application for admin approval
 * CRITICAL: This transitions the technician from onboarding to pending review
 */
export const submitTechnicianKyc = functions.region('asia-south1').https.onCall(async (data, context) => {
    assertAuthenticated(context);
    const uid = context.auth!.uid;

    console.log('[KYC SUBMIT] Starting submission for uid:', uid);

    // Get current technician to verify all data is complete
    const techDoc = await db.collection('technicians').doc(uid).get();
    if (!techDoc.exists) {
        throw new functions.https.HttpsError(
            'not-found',
            'Technician profile not found'
        );
    }

    const techData = techDoc.data();
    const currentStep = techData?.onboardingStep;

    // Must be in review step to submit
    if (currentStep !== 'review') {
        throw new functions.https.HttpsError(
            'failed-precondition',
            'Please complete all onboarding steps before submitting'
        );
    }

    // Validate required fields
    const requiredFields = ['fullName', 'phone', 'aadhaarNumber', 'profilePhotoUrl', 'primaryCategoryId'];
    for (const field of requiredFields) {
        if (!techData?.[field]) {
            throw new functions.https.HttpsError(
                'failed-precondition',
                `Missing required field: ${field}. Please complete all steps.`
            );
        }
    }

    console.log('[KYC SUBMIT] Marking technician as KYC complete:', uid);

    // Validate Step 4 (Work Portfolio) fields before submission
    if (!techData?.experienceDescription || techData.experienceDescription.length < 20) {
        throw new functions.https.HttpsError(
            'failed-precondition',
            'Experience description must be at least 20 characters'
        );
    }

    if (!techData?.workPreference) {
        throw new functions.https.HttpsError(
            'failed-precondition',
            'Work preference is required'
        );
    }

    // Submit the application - this marks KYC as complete and locks profile
    await db.collection('technicians').doc(uid).update({
        isKycComplete: true,
        onboardingCompleted: true, // keep for backward compatibility
        onboardingStep: 'submitted',
        status: 'pending',
        kycStatus: 'pending',
        isLocked: true, // FIX: Lock profile after submission to prevent edits during review
        'stepsCompleted.review': true,
        submittedAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
    });

    console.log('[KYC SUBMIT] Successfully marked KYC complete');

    return {
        success: true,
        message: 'Application submitted successfully. Pending admin approval.',
        status: 'pending'
    };
});

/**
 * Update technician profile after initial creation
 * Used for profile updates (not onboarding)
 */
export const updateTechnicianProfile = functions.region('asia-south1').https.onCall(async (data, context) => {
    assertAuthenticated(context);
    const uid = context.auth!.uid;
    const { updates } = data;

    // Verify authenticated user owns this profile
    const techDoc = await db.collection('technicians').doc(uid).get();
    if (!techDoc.exists) {
        throw new functions.https.HttpsError(
            'not-found',
            'Technician profile not found'
        );
    }

    // Filter out protected fields - client cannot set these
    const allowedUpdates: Record<string, any> = {};
    const disallowedFields: string[] = [];

    for (const [key, value] of Object.entries(updates)) {
        if (ADMIN_ONLY_FIELDS.includes(key)) {
            disallowedFields.push(key);
        } else {
            allowedUpdates[key] = value;
        }
    }

    if (disallowedFields.length > 0) {
        console.warn(`Security: Client attempted to set protected fields: ${disallowedFields.join(', ')}`);
    }

    if (Object.keys(allowedUpdates).length === 0) {
        throw new functions.https.HttpsError(
            'invalid-argument',
            'No valid fields to update'
        );
    }

    allowedUpdates.updatedAt = admin.firestore.FieldValue.serverTimestamp();

    await db.collection('technicians').doc(uid).update(allowedUpdates);

    return {
        success: true,
        message: 'Profile updated',
        disallowedFields: disallowedFields.length > 0 ? disallowedFields : undefined
    };
});

/**
 * Update technician online status
 */
export const updateTechnicianStatus = functions.region('asia-south1').https.onCall(async (data, context) => {
    assertAuthenticated(context);
    const uid = context.auth!.uid;
    const { isOnline } = data;

    if (typeof isOnline !== 'boolean') {
        throw new functions.https.HttpsError(
            'invalid-argument',
            'isOnline must be a boolean'
        );
    }

    // Verify technician is approved before allowing online status
    const techDoc = await db.collection('technicians').doc(uid).get();
    if (!techDoc.exists) {
        throw new functions.https.HttpsError(
            'not-found',
            'Technician profile not found'
        );
    }

    const techData = techDoc.data();

    // Only approved technicians can go online
    if (isOnline && (!techData?.isApproved || !techData?.isKycComplete)) {
        throw new functions.https.HttpsError(
            'failed-precondition',
            'You must complete onboarding and receive approval before going online'
        );
    }

    // Check for suspended/blocked status
    if (techData?.status === 'suspended' || techData?.status === 'blocked') {
        throw new functions.https.HttpsError(
            'permission-denied',
            'Your account is suspended or blocked'
        );
    }

    await db.collection('technicians').doc(uid).update({
        isOnline: isOnline,
        lastOnlineAt: isOnline ? null : admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
    });

    return {
        success: true,
        isOnline: isOnline
    };
});

/**
 * Save technician step data (generic step saver)
 * Used for flexible onboarding step updates
 */
export const saveTechnicianStepData = functions.region('asia-south1').https.onCall(async (data, context) => {
    assertAuthenticated(context);
    const uid = context.auth!.uid;
    const { step, stepName, stepKey, data: updateData } = data;

    console.log(`[CF saveTechnicianStepData] authUid=${uid}`);
    console.log(`[CF saveTechnicianStepData] payload=`, JSON.stringify(data));

    // Verify technician exists
    const techDoc = await db.collection('technicians').doc(uid).get();
    if (!techDoc.exists) {
        console.error(`[CF saveTechnicianStepData] ERROR: technician not found`);
        throw new functions.https.HttpsError(
            'not-found',
            'Technician profile not found'
        );
    }

    // FIX: Check if profile is locked (submitted for review)
    const techData = techDoc.data();
    if (techData?.isLocked === true) {
        throw new functions.https.HttpsError(
            'failed-precondition',
            'Profile is locked. Contact support to make changes.'
        );
    }

    // Filter out admin-only fields
    const filteredData: Record<string, any> = {};
    for (const [key, value] of Object.entries(updateData || {})) {
        if (!ADMIN_ONLY_FIELDS.includes(key)) {
            filteredData[key] = value;
        }
    }

    // Add server timestamp
    filteredData.updatedAt = admin.firestore.FieldValue.serverTimestamp();

    try {
        // Update with merge to preserve existing profile fields
        await db.collection('technicians').doc(uid).update(filteredData);
        console.log(`[CF saveTechnicianStepData] WRITE SUCCESS`);
    } catch (error) {
        console.error(`[CF saveTechnicianStepData] ERROR:`, error);
        throw error;
    }

    return {
        success: true,
        step: stepName
    };
});

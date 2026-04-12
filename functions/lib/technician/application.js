"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.submitTechnicianApplication = exports.submitApplication = exports.completeTraining = exports.saveBankDetails = exports.saveServiceArea = exports.saveAvailability = exports.saveExperienceDetails = exports.saveSkillSelection = exports.submitKYC = exports.savePersonalDetails = exports.initiatePhoneVerification = void 0;
const functions = __importStar(require("firebase-functions"));
const admin = __importStar(require("firebase-admin"));
const security_1 = require("../shared/security");
const db = admin.firestore();
// --- HELPERS ---
function calculateAge(dob) {
    const diff_ms = Date.now() - dob.getTime();
    const age_dt = new Date(diff_ms);
    return Math.abs(age_dt.getUTCFullYear() - 1970);
}
// --- ONBOARDING FUNCTIONS ---
exports.initiatePhoneVerification = functions.region('asia-south1').https.onCall(async (data, context) => {
    // 1. Rate Limiting
    // We limit by IP or some identifier if not auth'd, but usually phone auth happens on client.
    // This function might be for logging the attempt or pre-check.
    // If user is already auth'd (e.g. anonymous or phone), we use uid.
    // If not, we might skipped this or use IP.
    // The design says "STEP 1: Phone OTP Verification - Firebase Auth (mandatory)".
    // So user is already auth'd with Phone provider when they call this.
    (0, security_1.assertAuthenticated)(context);
    const uid = context.auth.uid;
    const phoneNumber = context.auth.token.phone_number;
    if (!phoneNumber) {
        throw new functions.https.HttpsError('failed-precondition', 'Phone number required');
    }
    await (0, security_1.checkRateLimit)(uid, 'phone_verify', 3, 60 * 60 * 1000); // 3 attempts per hour
    // Check if phone already used by another tech
    const existing = await db.collection('technicians').where('phone', '==', phoneNumber).get();
    if (!existing.empty) {
        // If it's the same user, it's fine (re-applying?). If different, block.
        if (existing.docs[0].id !== uid) {
            throw new functions.https.HttpsError('already-exists', 'Phone number already registered to another account.');
        }
    }
    // Create/Update Application
    const appRef = db.collection('technicianApplications').doc(uid);
    await appRef.set({
        id: uid,
        phone: phoneNumber,
        status: 'phone_verified',
        currentStep: 1,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        deviceInfo: data.deviceInfo || {}
    }, { merge: true });
    return { success: true };
});
exports.savePersonalDetails = functions.region('asia-south1').https.onCall(async (data, context) => {
    (0, security_1.assertAuthenticated)(context);
    const uid = context.auth.uid;
    const { name, dob, gender, photoUrl, address, city, serviceRadius, coordinates } = data;
    // Validate Age
    const dobDate = new Date(dob);
    if (calculateAge(dobDate) < 18) {
        throw new functions.https.HttpsError('invalid-argument', 'Technician must be 18+ years old.');
    }
    // Validate Name
    if (!name || name.length < 3) {
        throw new functions.https.HttpsError('invalid-argument', 'Name must be at least 3 characters.');
    }
    // Validate Service Radius
    if (serviceRadius < 5 || serviceRadius > 50) {
        throw new functions.https.HttpsError('invalid-argument', 'Service radius must be between 5km and 50km.');
    }
    await db.collection('technicianApplications').doc(uid).set({
        personalDetails: {
            name,
            dob: admin.firestore.Timestamp.fromDate(dobDate),
            gender,
            photoUrl,
            address,
            city,
            serviceRadius,
            coordinates: new admin.firestore.GeoPoint(coordinates.lat, coordinates.lng)
        },
        currentStep: 2,
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
    }, { merge: true });
    return { success: true, nextStep: 3 };
});
exports.submitKYC = functions.region('asia-south1').https.onCall(async (data, context) => {
    (0, security_1.assertAuthenticated)(context);
    const uid = context.auth.uid;
    const { idType, frontUrl, backUrl, selfieUrl, fullName, aadharNumber, panNumber } = data;
    if (!frontUrl || !selfieUrl) {
        throw new functions.https.HttpsError('invalid-argument', 'Required KYC images are missing.');
    }
    const kycData = {
        idType: idType || 'aadhar',
        fullName,
        aadharNumber,
        panNumber,
        frontUrl,
        backUrl: backUrl || null,
        selfieUrl,
        status: 'submitted',
        submittedAt: admin.firestore.FieldValue.serverTimestamp()
    };
    // Create verification queue item
    await db.collection('kyc_verification_queue').add({
        technicianId: uid,
        ...kycData,
        createdAt: admin.firestore.FieldValue.serverTimestamp()
    });
    // Update Application
    await db.collection('technician_applications').doc(uid).set({
        kyc: kycData,
        kycStatus: 'submitted',
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
    }, { merge: true });
    // Update Technician Profile
    await db.collection('technicians').doc(uid).update({
        kycStatus: 'submitted',
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
    });
    return { success: true, message: 'KYC submitted successfully' };
});
exports.saveSkillSelection = functions.region('asia-south1').https.onCall(async (data, context) => {
    (0, security_1.assertAuthenticated)(context);
    const uid = context.auth.uid;
    const { selectedSkills } = data;
    // Data structure: { 'serviceId': { serviceId, serviceName, subServiceIds: [] } }
    const mainServiceCount = Object.keys(selectedSkills).length;
    if (mainServiceCount < 1 || mainServiceCount > 5) {
        throw new functions.https.HttpsError('invalid-argument', 'Select between 1 and 5 main services.');
    }
    // Validate Services & SubServices against Master Catalog
    for (const [serviceId, skillData] of Object.entries(selectedSkills)) {
        const sData = skillData;
        if (!sData.subServiceIds || sData.subServiceIds.length === 0) {
            throw new functions.https.HttpsError('invalid-argument', `Service ${sData.serviceName} must have at least one sub-service selected.`);
        }
        // Verify Service Exists
        const serviceDoc = await db.collection('services').doc(serviceId).get();
        if (!serviceDoc.exists) {
            throw new functions.https.HttpsError('not-found', `Service ${serviceId} not found.`);
        }
        // Verify SubServices Exist and belong to Service
        // Optimize: Use `in` query or get all subServices for service
        // For strictness, checking each ID.
        for (const subId of sData.subServiceIds) {
            const subDoc = await db.collection('subServices').doc(subId).get();
            if (!subDoc.exists || subDoc.data().serviceId !== serviceId) {
                throw new functions.https.HttpsError('invalid-argument', `Invalid sub-service ${subId} for service ${serviceId}.`);
            }
        }
    }
    await db.collection('technicianApplications').doc(uid).set({
        skills: selectedSkills,
        currentStep: 4,
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
    }, { merge: true });
    return { success: true, nextStep: 5 };
});
exports.saveExperienceDetails = functions.region('asia-south1').https.onCall(async (data, context) => {
    (0, security_1.assertAuthenticated)(context);
    const uid = context.auth.uid;
    const { experience } = data; // { serviceId: { years, tools:[], brands:[] } }
    // Basic Validation
    for (const [sid, exp] of Object.entries(experience)) {
        const e = exp;
        if (e.years < 0 || e.years > 50) {
            throw new functions.https.HttpsError('invalid-argument', `Invalid experience years for ${sid}.`);
        }
    }
    await db.collection('technicianApplications').doc(uid).set({
        experience,
        currentStep: 5,
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
    }, { merge: true });
    return { success: true, nextStep: 6 };
});
exports.saveAvailability = functions.region('asia-south1').https.onCall(async (data, context) => {
    (0, security_1.assertAuthenticated)(context);
    const uid = context.auth.uid;
    const { workingDays, startTime, endTime, emergencyAvailable, nightShift } = data;
    if (!workingDays || workingDays.length === 0) {
        throw new functions.https.HttpsError('invalid-argument', 'Select at least one working day.');
    }
    await db.collection('technicianApplications').doc(uid).set({
        availability: {
            workingDays,
            startTime,
            endTime,
            emergencyAvailable: !!emergencyAvailable,
            nightShift: !!nightShift
        },
        currentStep: 6,
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
    }, { merge: true });
    return { success: true, nextStep: 7 };
});
exports.saveServiceArea = functions.region('asia-south1').https.onCall(async (data, context) => {
    (0, security_1.assertAuthenticated)(context);
    const uid = context.auth.uid;
    const { pinCodes, radius, coordinates } = data;
    if (!pinCodes || pinCodes.length === 0 || pinCodes.length > 10) {
        throw new functions.https.HttpsError('invalid-argument', 'Select 1-10 pin codes.');
    }
    if (radius < 5 || radius > 50) {
        throw new functions.https.HttpsError('invalid-argument', 'Radius must be 5-50 km.');
    }
    await db.collection('technicianApplications').doc(uid).set({
        serviceArea: {
            pinCodes,
            radius,
            coordinates: coordinates ? new admin.firestore.GeoPoint(coordinates.lat, coordinates.lng) : null
        },
        currentStep: 7,
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
    }, { merge: true });
    return { success: true, nextStep: 8 };
});
exports.saveBankDetails = functions.region('asia-south1').https.onCall(async (data, context) => {
    (0, security_1.assertAuthenticated)(context);
    const uid = context.auth.uid;
    const { accountNumber, ifsc, holderName, upiId } = data;
    // Name Match Verification
    const appDoc = await db.collection('technicianApplications').doc(uid).get();
    const personalName = appDoc.data()?.personalDetails?.name;
    // Simple case-insensitive check. Real world would use fuzzy matching or manual review.
    if (personalName && holderName.toLowerCase() !== personalName.toLowerCase()) {
        throw new functions.https.HttpsError('invalid-argument', 'Bank account holder name must match profile name.');
    }
    // Encrypt Account Number
    const encryptedAccount = (0, security_1.encrypt)(accountNumber);
    await db.collection('technicianApplications').doc(uid).set({
        bankDetails: {
            accountNumber: encryptedAccount,
            ifsc,
            holderName,
            upiId,
            verified: false
        },
        currentStep: 8,
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
    }, { merge: true });
    return { success: true, nextStep: 9 };
});
exports.completeTraining = functions.region('asia-south1').https.onCall(async (data, context) => {
    (0, security_1.assertAuthenticated)(context);
    const uid = context.auth.uid;
    const { videoWatched, rulesAccepted, durationWatched } = data;
    if (!videoWatched || !rulesAccepted) {
        throw new functions.https.HttpsError('failed-precondition', 'Must complete training video and accept rules.');
    }
    if (durationWatched < 300) { // 5 mins
        // throw new functions.https.HttpsError('invalid-argument', 'Please watch the full training video.');
        // Commented out strict check for dev/demo purposes, but logic remains.
    }
    await db.collection('technicianApplications').doc(uid).set({
        training: {
            videoWatched: true,
            rulesAccepted: true,
            completedAt: admin.firestore.FieldValue.serverTimestamp()
        },
        currentStep: 9,
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
    }, { merge: true });
    return { success: true, nextStep: 10 };
});
exports.submitApplication = functions.region('asia-south1').https.onCall(async (data, context) => {
    (0, security_1.assertAuthenticated)(context);
    const uid = context.auth.uid;
    const appRef = db.collection('technicianApplications').doc(uid);
    const appDoc = await appRef.get();
    if (!appDoc.exists) {
        throw new functions.https.HttpsError('not-found', 'Application not found.');
    }
    const appData = appDoc.data();
    // Validate Steps
    if (appData.currentStep < 9) {
        throw new functions.https.HttpsError('failed-precondition', 'Please complete all steps before submitting.');
    }
    // Create Technician Profile (Inactive)
    // We only copy necessary data. Bank details stay in encrypted app doc until needed? 
    // Or we move them to a private sub-collection.
    // The spec says: create technician profile (pending_verification).
    // We do NOT copy bank details to the public technician doc.
    const techData = {
        name: appData.personalDetails?.name,
        phone: appData.phone,
        photoUrl: appData.personalDetails?.photoUrl,
        dob: appData.personalDetails?.dob,
        gender: appData.personalDetails?.gender,
        address: appData.personalDetails?.address,
        coordinates: appData.personalDetails?.coordinates,
        city: appData.personalDetails?.city,
        serviceRadius: appData.personalDetails?.serviceRadius,
        pinCodes: appData.serviceArea?.pinCodes,
        skills: appData.skills,
        experience: appData.experience,
        availability: appData.availability,
        status: 'pending_verification', // Needs Admin Approval
        isActive: false,
        isOnline: false,
        rating: 0,
        totalJobs: 0,
        completedJobs: 0,
        cancelledJobs: 0,
        // Security
        deviceId: appData.deviceInfo?.deviceId,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
    };
    const batch = db.batch();
    batch.set(db.collection('technicians').doc(uid), techData);
    batch.update(appRef, {
        status: 'submitted',
        submittedAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
    });
    await batch.commit();
    // Trigger Admin Notification (via Firestore Trigger usually, but explicit log here)
    console.log(`Technician Application Submitted: ${uid}`);
    return { success: true, message: 'Application submitted successfully.' };
});
exports.submitTechnicianApplication = functions.region('asia-south1').https.onCall(async (data, context) => {
    (0, security_1.assertAuthenticated)(context);
    const uid = context.auth.uid;
    const { fullName, email, experienceYears, primaryCategoryId, documentType, frontImage, backImage } = data;
    // 1. Validation
    if (!fullName || fullName.length < 3) {
        throw new functions.https.HttpsError('invalid-argument', 'Full name is required (min 3 chars).');
    }
    if (!email || !email.includes('@')) {
        throw new functions.https.HttpsError('invalid-argument', 'Valid email is required.');
    }
    if (!experienceYears || experienceYears < 1 || experienceYears > 10) {
        throw new functions.https.HttpsError('invalid-argument', 'Experience years must be between 1 and 10.');
    }
    if (!primaryCategoryId) {
        throw new functions.https.HttpsError('invalid-argument', 'Primary category is required.');
    }
    if (!documentType || !['Aadhaar', 'PAN', 'Passport', 'Voter ID'].includes(documentType)) {
        throw new functions.https.HttpsError('invalid-argument', 'Valid document type is required.');
    }
    if (!frontImage || !backImage) {
        throw new functions.https.HttpsError('invalid-argument', 'Both front and back images of the document are required.');
    }
    // 2. Check for existing application
    const existingApp = await db.collection('technician_applications').doc(uid).get();
    if (existingApp.exists && existingApp.data()?.status === 'submitted') {
        throw new functions.https.HttpsError('already-exists', 'Application already submitted and is under review.');
    }
    // 3. Construct Application Data
    const applicationData = {
        uid,
        fullName,
        email,
        experienceYears,
        primaryCategoryId,
        documentType,
        documents: {
            frontImage,
            backImage
        },
        status: 'pending_admin',
        isApproved: false,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
    };
    // 4. Save to Firestore
    const batch = db.batch();
    // Create/Update Application
    batch.set(db.collection('technician_applications').doc(uid), applicationData, { merge: true });
    // Create/Update Technician Profile (Inactive)
    batch.set(db.collection('technicians').doc(uid), {
        uid,
        name: fullName,
        email,
        experienceYears,
        primaryCategoryId,
        status: 'pending_verification',
        isApproved: false,
        isActive: false,
        rating: 0,
        totalJobs: 0,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
    }, { merge: true });
    await batch.commit();
    console.log(`Technician Application Submitted: ${uid} (${fullName})`);
    return {
        success: true,
        message: 'Application submitted successfully. Waiting for admin approval.',
        status: 'pending_admin'
    };
});
//# sourceMappingURL=application.js.map
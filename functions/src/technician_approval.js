const functions = require('firebase-functions');
const admin = require('firebase-admin');

// Validate technician approval before service creation
exports.validateTechnicianApproval = functions.https.onCall(async (data, context) => {
  // Check authentication
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }

  const uid = context.auth.uid;

  try {
    // Get technician document
    const technicianDoc = await admin.firestore()
      .collection('technicians')
      .doc(uid)
      .get();

    if (!technicianDoc.exists) {
      throw new functions.https.HttpsError('not-found', 'Technician profile not found');
    }

    const technician = technicianDoc.data();

    // Calculate profile completion
    const profileCompletion = calculateProfileCompletion(technician);

    // Check if profile completion is 100%
    if (profileCompletion < 100) {
      throw new functions.https.HttpsError(
        'failed-precondition', 
        'Please complete your profile to 100% before listing services.'
      );
    }

    // Check if profile is approved
    if (!technician.profileApproved) {
      if (technician.profileRejected) {
        throw new functions.https.HttpsError(
          'failed-precondition',
          'Your profile was rejected. Please update your information and resubmit.'
        );
      } else {
        throw new functions.https.HttpsError(
          'failed-precondition',
          'Your profile is currently under admin review. You will be able to list services once it is approved.'
        );
      }
    }

    return {
      success: true,
      canCreateServices: true,
      profileCompletion: profileCompletion
    };

  } catch (error) {
    console.error('Error validating technician approval:', error);
    if (error instanceof functions.https.HttpsError) {
      throw error;
    }
    throw new functions.https.HttpsError('internal', 'Failed to validate technician approval');
  }
});

// Enhanced service creation with approval validation
exports.createTechnicianService = functions.https.onCall(async (data, context) => {
  // Check authentication
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }

  const uid = context.auth.uid;
  const { name, price, imageUrl, category, description, originalPrice, offerPrice } = data;

  try {
    // First validate technician approval
    const validationResult = await exports.validateTechnicianApproval(null, context);
    
    if (!validationResult.canCreateServices) {
      throw new functions.https.HttpsError('failed-precondition', 'Technician not approved for service creation');
    }

    // Validate required fields
    if (!name || !price || !category) {
      throw new functions.https.HttpsError('invalid-argument', 'Missing required fields');
    }

    // Create service document
    const serviceData = {
      technicianId: uid,
      name: name.trim(),
      price: parseFloat(price),
      category: category,
      imageUrl: imageUrl || null,
      description: description?.trim() || null,
      originalPrice: originalPrice ? parseFloat(originalPrice) : null,
      offerPrice: offerPrice ? parseFloat(offerPrice) : null,
      status: 'active',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    };

    // Add service to technician_services collection
    const serviceRef = await admin.firestore()
      .collection('technician_services')
      .add(serviceData);

    return {
      success: true,
      serviceId: serviceRef.id,
      message: 'Service created successfully'
    };

  } catch (error) {
    console.error('Error creating service:', error);
    if (error instanceof functions.https.HttpsError) {
      throw error;
    }
    throw new functions.https.HttpsError('internal', 'Failed to create service');
  }
});

// Calculate profile completion percentage
function calculateProfileCompletion(technician) {
  if (technician.stepsCompleted && Object.keys(technician.stepsCompleted).length > 0) {
    const totalSteps = 5;
    let completedSteps = 0;
    for (const [key, value] of Object.entries(technician.stepsCompleted)) {
      if (value === true) completedSteps++;
    }
    return Math.round((completedSteps / totalSteps) * 100);
  }
  
  let completed = 0;
  const total = 8;
  
  if (technician.fullName && technician.fullName.trim().length > 0) completed++;
  if (technician.phone && technician.phone.trim().length > 0) completed++;
  if (technician.profilePhotoUrl && technician.profilePhotoUrl.trim().length > 0) completed++;
  if (technician.skills && technician.skills.length > 0) completed++;
  if (technician.experienceYears && technician.experienceYears > 0) completed++;
  if (technician.bankStatus === 'approved') completed++;
  if ((technician.aadhaarFrontUrl && technician.aadhaarFrontUrl.trim().length > 0) || 
      (technician.panNumber && technician.panNumber.trim().length > 0)) completed++;
  if ((technician.customServices && technician.customServices.length > 0) || 
      (technician.skills && technician.skills.length > 0)) completed++;
  
  return Math.round((completed / total) * 100);
}

// Trigger admin review when profile reaches 100%
exports.onTechnicianProfileUpdate = functions.firestore
  .document('technicians/{technicianId}')
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();
    const technicianId = context.params.technicianId;

    try {
      // Calculate profile completion
      const profileCompletion = calculateProfileCompletion(after);

      // Check if profile just reached 100% and hasn't been requested for review yet
      if (profileCompletion === 100 && 
          !after.profileApprovalRequested && 
          !after.profileApproved && 
          !after.profileRejected) {
        
        // Update document to request admin review
        await admin.firestore()
          .collection('technicians')
          .doc(technicianId)
          .update({
            profileApprovalRequested: true,
            profileApproved: false,
            profileRejected: false,
            reviewRequestedAt: admin.firestore.FieldValue.serverTimestamp(),
            updatedAt: admin.firestore.FieldValue.serverTimestamp()
          });

        console.log(`Admin review requested for technician: ${technicianId}`);
      }

    } catch (error) {
      console.error('Error processing technician profile update:', error);
    }
  });
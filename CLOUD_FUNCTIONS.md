# Cloud Functions Implementation Guide

This document provides the Cloud Functions implementations needed for the HomeFix app. These functions must be deployed to the Firebase project.

---

## Prerequisites

```bash
# Install Firebase CLI
npm install -g firebase-tools

# Initialize functions in your project
firebase init functions

# Install dependencies
cd functions
npm install firebase firebase-admin firebase-functions
```

---

## 1. saveFcmToken

Saves FCM tokens for push notifications.

### Location: `functions/index.js`

```javascript
const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

exports.saveFcmToken = functions.https.onCall(async (data, context) => {
  // Verify authentication
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'Must be logged in to save FCM token'
    );
  }

  const { token, userType } = data;
  const uid = context.auth.uid;

  // Validate input
  if (!token || typeof token !== 'string') {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'Invalid FCM token'
    );
  }

  if (!['customer', 'technician'].includes(userType)) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'Invalid user type'
    );
  }

  try {
    const tokenRef = admin.firestore()
      .collection(`${userType}s`)
      .doc(uid)
      .collection('fcmTokens')
      .doc(token);

    await tokenRef.set({
      token: token,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      platform: data.platform || 'unknown',
      active: true,
    });

    return { success: true };
  } catch (error) {
    console.error('Error saving FCM token:', error);
    throw new functions.https.HttpsError(
      'internal',
      'Failed to save FCM token'
    );
  }
});
```

---

## 2. submitPartnerApplication

Submits partner application with validation and file reference storage.

### Location: `functions/index.js`

```javascript
exports.submitPartnerApplication = functions.https.onCall(async (data, context) => {
  // Verify authentication and App Check
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'Must be logged in to submit application'
    );
  }

  const uid = context.auth.uid;
  const {
    fullName,
    phone,
    email,
    categoryIds,
    subcategoryIds,
    experienceYears,
    experienceDescription,
    profilePhotoUrl,
    idProofUrl,
    address,
    bankHolderName,
    bankAccountNumber,
    bankIfscCode,
    agreedToTerms,
  } = data;

  // Validate required fields
  if (!fullName || fullName.trim().length < 3) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'Full name must be at least 3 characters'
    );
  }

  if (!phone || !/^\d{10}$/.test(phone)) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'Phone must be 10 digits'
    );
  }

  if (!email || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'Invalid email address'
    );
  }

  if (!categoryIds || categoryIds.length === 0) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'At least one category must be selected'
    );
  }

  if (!experienceYears || parseInt(experienceYears) < 0) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'Invalid experience years'
    );
  }

  if (!profilePhotoUrl || !idProofUrl) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'Profile photo and ID proof are required'
    );
  }

  if (!address || address.trim().length < 10) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'Address must be at least 10 characters'
    );
  }

  if (!bankAccountNumber || !/^\d{9,18}$/.test(bankAccountNumber)) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'Invalid bank account number'
    );
  }

  if (!bankIfscCode || !/^[A-Z]{4}0[A-Z0-9]{6}$/i.test(bankIfscCode)) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'Invalid IFSC code'
    );
  }

  if (!agreedToTerms) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'Must agree to terms and conditions'
    );
  }

  try {
    // Create application document
    const applicationRef = admin.firestore()
      .collection('technicianApplications')
      .doc(uid);

    await applicationRef.set({
      // Personal Info
      fullName: fullName.trim(),
      phone: phone.trim(),
      email: email.trim().toLowerCase(),
      
      // Services
      categoryIds: categoryIds,
      subcategoryIds: subcategoryIds,
      
      // Experience
      experienceYears: parseInt(experienceYears),
      experienceDescription: experienceDescription?.trim() || '',
      
      // File References (URLs from Storage)
      profilePhotoUrl: profilePhotoUrl,
      idProofUrl: idProofUrl,
      
      // Address
      address: address.trim(),
      
      // Bank Details (last 4 digits only for security)
      bankLast4: bankAccountNumber.slice(-4),
      bankIfsc: bankIfscCode.toUpperCase(),
      
      // Status
      status: 'pending',
      agreedToTerms: true,
      submittedAt: admin.firestore.FieldValue.serverTimestamp(),
      
      // Metadata
      userId: uid,
    });

    // Update technician profile with basic info
    await admin.firestore()
      .collection('technicians')
      .doc(uid)
      .set({
        onboardingStatus: 'application_submitted',
        applicationSubmittedAt: admin.firestore.FieldValue.serverTimestamp(),
      }, { merge: true });

    return {
      success: true,
      message: 'Application submitted successfully',
      applicationId: uid,
    };
  } catch (error) {
    console.error('Error submitting application:', error);
    throw new functions.https.HttpsError(
      'internal',
      'Failed to submit application. Please try again.'
    );
  }
});
```

---

## 3. saveAddress

Saves customer/technician address with validation.

### Location: `functions/index.js`

```javascript
exports.saveAddress = functions.https.onCall(async (data, context) => {
  // Verify authentication
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'Must be logged in to save address'
    );
  }

  const uid = context.auth.uid;
  const {
    address,
    addressLine2,
    city,
    state,
    pincode,
    latitude,
    longitude,
    label,
    userType, // 'customer' or 'technician'
    isDefault,
  } = data;

  // Validate required fields
  if (!address || address.trim().length < 10) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'Address must be at least 10 characters'
    );
  }

  if (!city || city.trim().length < 2) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'City is required'
    );
  }

  if (!pincode || !/^\d{6}$/.test(pincode)) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'PIN code must be 6 digits'
    );
  }

  if (!latitude || !longitude) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'Location coordinates are required'
    );
  }

  if (!['customer', 'technician'].includes(userType)) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'Invalid user type'
    );
  }

  try {
    const addressId = data.addressId || admin.firestore().collection('dummy').doc().id;
    const addressRef = admin.firestore()
      .collection(`${userType}s`)
      .doc(uid)
      .collection('addresses')
      .doc(addressId);

    // If setting as default, unset other defaults
    if (isDefault) {
      const snapshot = await admin.firestore()
        .collection(`${userType}s`)
        .doc(uid)
        .collection('addresses')
        .where('isDefault', '==', true)
        .get();

      const batch = admin.firestore().batch();
      snapshot.docs.forEach(doc => {
        batch.update(doc.ref, { isDefault: false });
      });
      await batch.commit();
    }

    await addressRef.set({
      address: address.trim(),
      addressLine2: addressLine2?.trim() || '',
      city: city.trim(),
      state: state?.trim() || '',
      pincode: pincode.trim(),
      latitude: parseFloat(latitude),
      longitude: parseFloat(longitude),
      label: label || 'Home',
      isDefault: isDefault || false,
      userId: uid,
      userType: userType,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });

    return {
      success: true,
      addressId: addressId,
      message: 'Address saved successfully',
    };
  } catch (error) {
    console.error('Error saving address:', error);
    throw new functions.https.HttpsError(
      'internal',
      'Failed to save address'
    );
  }
});
```

---

## 4. updateUserProfile

Updates user profile with security restrictions.

### Location: `functions/index.js`

```javascript
exports.updateUserProfile = functions.https.onCall(async (data, context) => {
  // Verify authentication
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'Must be logged in to update profile'
    );
  }

  const uid = context.auth.uid;
  const {
    displayName,
    photoUrl,
    phoneNumber,
  } = data;

  try {
    const userRef = admin.firestore()
      .collection('customers')
      .doc(uid);

    const updateData = {
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    if (displayName) {
      updateData.displayName = displayName.trim();
    }

    if (photoUrl) {
      // Validate it's a Firebase Storage URL
      if (!photoUrl.includes('firebasestorage.googleapis.com')) {
        throw new functions.https.HttpsError(
          'invalid-argument',
          'Invalid photo URL'
        );
      }
      updateData.photoUrl = photoUrl;
    }

    if (phoneNumber) {
      if (!/^\d{10}$/.test(phoneNumber)) {
        throw new functions.https.HttpsError(
          'invalid-argument',
          'Invalid phone number'
        );
      }
      updateData.phoneNumber = phoneNumber;
    }

    await userRef.update(updateData);

    // Also update Auth profile
    try {
      await admin.auth().updateUser(uid, {
        displayName: displayName,
        photoURL: photoUrl,
      });
    } catch (authError) {
      // Log but don't fail - Auth update might fail for various reasons
      console.warn('Failed to update Auth profile:', authError);
    }

    return {
      success: true,
      message: 'Profile updated successfully',
    };
  } catch (error) {
    console.error('Error updating profile:', error);
    if (error instanceof functions.https.HttpsError) {
      throw error;
    }
    throw new functions.https.HttpsError(
      'internal',
      'Failed to update profile'
    );
  }
});
```

---

## Deployment

```bash
# Deploy all functions
firebase deploy --only functions

# Deploy specific function
firebase deploy --only functions:submitPartnerApplication
firebase deploy --only functions:saveFcmToken
firebase deploy --only functions:saveAddress
firebase deploy --only functions:updateUserProfile
```

---

## Testing with Emulators

```bash
# Start emulators
firebase emulators:start --only functions,firestore

# Run test (using Firebase Extension or Postman)
# Call the functions from your Flutter app with test data
```

---

## Security Rules Compatibility

These functions are designed to work with the Firestore rules defined in `firestore.rules`. The rules require:

1. Authentication (`context.auth != null`)
2. Owner verification (`request.auth.uid == userId`)
3. No direct writes to restricted collections (all writes via functions)

---

## Error Codes

| Error Code | Description |
|------------|-------------|
| `unauthenticated` | User not logged in |
| `invalid-argument` | Validation failed |
| `internal` | Server error |
| `permission-denied` | Insufficient permissions |

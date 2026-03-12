import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

const db = admin.firestore();

/**
 * Set Primary Address with Transaction Safety
 * Ensures only one primary address exists at any time
 */
export const setPrimaryAddress = functions.https.onCall(async (request, context) => {
  const auth = context.auth;

  if (!auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }

  const { addressId } = request.data;
  if (!addressId) {
    throw new functions.https.HttpsError('invalid-argument', 'addressId is required');
  }

  const userId = auth.uid;

  try {
    await db.runTransaction(async (transaction) => {
      const addressesRef = db.collection('users').doc(userId).collection('addresses');
      const addressesSnapshot = await transaction.get(addressesRef);

      addressesSnapshot.docs.forEach((doc) => {
        transaction.update(doc.ref, { isPrimary: false, isDefault: false });
      });

      const selectedAddressRef = addressesRef.doc(addressId);
      const selectedAddressDoc = await transaction.get(selectedAddressRef);

      if (!selectedAddressDoc.exists) {
        throw new functions.https.HttpsError('not-found', 'Address not found');
      }

      transaction.update(selectedAddressRef, { isPrimary: true, isDefault: true });

      const addressData = selectedAddressDoc.data();
      const userRef = db.collection('users').doc(userId);
      transaction.update(userRef, {
        primaryAddressId: addressId,
        serviceDistrict: addressData?.district || '',
        serviceState: addressData?.state || '',
      });
    });

    return { success: true, message: 'Primary address updated successfully' };
  } catch (error: any) {
    console.error('setPrimaryAddress error:', error);
    throw new functions.https.HttpsError('internal', error.message);
  }
});

export const manageAddress = functions.https.onCall(async (request, context) => {
  const auth = context.auth;

  if (!auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }

  const { action, addressId, addressData, setAsPrimary } = request.data;
  const userId = auth.uid;

  try {
    const addressesRef = db.collection('users').doc(userId).collection('addresses');

    if (action === 'add') {
      if (!addressData?.addressLine || !addressData?.district || !addressData?.state) {
        throw new functions.https.HttpsError('invalid-argument', 'Missing required address fields');
      }

      const newAddressRef = addressesRef.doc();
      const newAddress = {
        ...addressData,
        id: newAddressRef.id,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        isPrimary: setAsPrimary === true,
        isDefault: setAsPrimary === true,
      };

      await newAddressRef.set(newAddress);

      if (setAsPrimary) {
        const batch = db.batch();
        const otherAddresses = await addressesRef.where('id', '!=', newAddressRef.id).get();
        otherAddresses.docs.forEach((doc) => {
          batch.update(doc.ref, { isPrimary: false, isDefault: false });
        });
        await batch.commit();

        await db.collection('users').doc(userId).update({
          primaryAddressId: newAddressRef.id,
          serviceDistrict: addressData.district,
          serviceState: addressData.state,
        });
      }

      return { success: true, addressId: newAddressRef.id };
    } else if (action === 'edit') {
      if (!addressId) {
        throw new functions.https.HttpsError('invalid-argument', 'addressId is required for edit');
      }

      const addressRef = addressesRef.doc(addressId);
      const addressDoc = await addressRef.get();

      if (!addressDoc.exists) {
        throw new functions.https.HttpsError('not-found', 'Address not found');
      }

      await addressRef.update({
        ...addressData,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      if (addressDoc.data()?.isPrimary) {
        await db.collection('users').doc(userId).update({
          serviceDistrict: addressData.district || addressDoc.data()?.district,
          serviceState: addressData.state || addressDoc.data()?.state,
        });
      }

      return { success: true, addressId };
    } else if (action === 'delete') {
      if (!addressId) {
        throw new functions.https.HttpsError('invalid-argument', 'addressId is required for delete');
      }

      const addressRef = addressesRef.doc(addressId);
      const addressDoc = await addressRef.get();

      if (!addressDoc.exists) {
        throw new functions.https.HttpsError('not-found', 'Address not found');
      }

      const wasPrimary = addressDoc.data()?.isPrimary;
      await addressRef.delete();

      if (wasPrimary) {
        const remainingAddresses = await addressesRef.limit(1).get();
        if (!remainingAddresses.empty) {
          const nextAddress = remainingAddresses.docs[0];
          await nextAddress.ref.update({ isPrimary: true, isDefault: true });
          await db.collection('users').doc(userId).update({
            primaryAddressId: nextAddress.id,
            serviceDistrict: nextAddress.data().district,
            serviceState: nextAddress.data().state,
          });
        } else {
          await db.collection('users').doc(userId).update({
            primaryAddressId: admin.firestore.FieldValue.delete(),
            serviceDistrict: admin.firestore.FieldValue.delete(),
            serviceState: admin.firestore.FieldValue.delete(),
          });
        }
      }

      return { success: true };
    } else {
      throw new functions.https.HttpsError('invalid-argument', 'Invalid action');
    }
  } catch (error: any) {
    console.error('manageAddress error:', error);
    throw new functions.https.HttpsError('internal', error.message);
  }
});

export const validateAddressForBooking = functions.https.onCall(async (request) => {
  const { auth, data } = request;

  if (!auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }

  const { addressId } = data;
  if (!addressId) {
    throw new functions.https.HttpsError('invalid-argument', 'addressId is required');
  }

  const userId = auth.uid;

  try {
    const addressRef = db.collection('users').doc(userId).collection('addresses').doc(addressId);
    const addressDoc = await addressRef.get();

    if (!addressDoc.exists) {
      throw new functions.https.HttpsError('not-found', 'Address not found');
    }

    const addressData = addressDoc.data();

    return {
      valid: true,
      address: {
        addressId: addressDoc.id,
        addressLine: addressData?.addressLine || '',
        area: addressData?.area || '',
        city: addressData?.city || '',
        district: addressData?.district || '',
        state: addressData?.state || '',
        pincode: addressData?.pincode || '',
        latitude: addressData?.latitude || 0,
        longitude: addressData?.longitude || 0,
      },
    };
  } catch (error: any) {
    console.error('validateAddressForBooking error:', error);
    throw new functions.https.HttpsError('internal', error.message);
  }
});

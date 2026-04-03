import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

const db = admin.firestore();

/**
 * Add item to cart
 * Creates or updates customers/{uid}/cart/{itemId}
 */
export const addToCartCallable = functions
  .region('asia-south1')
  .https.onCall(async (data: any, context: functions.https.CallableContext) => {
    console.log('[addToCartCallable] REQUEST DATA:', data);
    console.log('[addToCartCallable] AUTH UID:', context.auth?.uid);

    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }

    const uid = context.auth.uid;
    console.log('[addToCartCallable] Authenticated UID:', uid);
    
    const serviceId: string = data.serviceId ?? '';
    const categoryId: string = data.categoryId ?? '';
    const categoryName: string = data.categoryName ?? '';
    const technicianId: string = data.technicianId ?? '';
    const serviceName: string = data.serviceName ?? '';
    const subServiceId: string = data.subServiceId ?? '';
    const subServiceName: string = data.subServiceName ?? '';
    const serviceImage: string = data.serviceImage ?? '';
    const price: number = typeof data.price === 'number' ? data.price : 0;
    const quantity: number = typeof data.quantity === 'number' ? data.quantity : 1;
    const finalPriceSnapshot: number = typeof data.finalPriceSnapshot === 'number' ? data.finalPriceSnapshot : price;

    console.log('[addToCartCallable] Extracted:', { serviceId, categoryId, technicianId, price, quantity, finalPriceSnapshot });

    if (!serviceId) {
      console.error('[addToCartCallable] VALIDATION FAILED: serviceId missing', { requestData: data });
      throw new functions.https.HttpsError('invalid-argument', 'Missing required fields', { requestData: data });
    }
    if (!categoryId) {
      console.error('[addToCartCallable] VALIDATION FAILED: categoryId missing', { requestData: data });
      throw new functions.https.HttpsError('invalid-argument', 'Missing required fields', { requestData: data });
    }
    if (!technicianId) {
      console.error('[addToCartCallable] VALIDATION FAILED: technicianId missing', { requestData: data });
      throw new functions.https.HttpsError('invalid-argument', 'Missing required fields', { requestData: data });
    }
    if (price <= 0) {
      console.error('[addToCartCallable] VALIDATION FAILED: price invalid', { price, requestData: data });
      throw new functions.https.HttpsError('invalid-argument', 'price must be > 0', { requestData: data });
    }
    if (finalPriceSnapshot <= 0) {
      console.error('[addToCartCallable] VALIDATION FAILED: finalPriceSnapshot invalid', { finalPriceSnapshot, requestData: data });
      throw new functions.https.HttpsError('invalid-argument', 'finalPriceSnapshot must be > 0', { requestData: data });
    }

    try {
      console.log('[addToCartCallable] Starting cart operation for user:', uid);
      
      const cartRef = db.collection('customers').doc(uid).collection('cart');
      
      // Generate item ID (serviceId + subServiceId if exists)
      const itemId = subServiceId && subServiceId.trim() !== '' ? `${serviceId}_${subServiceId}` : serviceId;
      console.log('[addToCartCallable] Generated itemId:', itemId);
      
      // Check if item already exists
      console.log('[addToCartCallable] Checking if item exists...');
      const existingItem = await cartRef.doc(itemId).get();
      console.log('[addToCartCallable] Item exists:', existingItem.exists);
      
      if (existingItem.exists) {
        // Update quantity if item already in cart
        console.log('[addToCartCallable] Updating existing item quantity');
        const existingData = existingItem.data()!;
        const newQuantity = (existingData.quantity || 1) + quantity;
        const newTotalPrice = price * newQuantity;
        
        console.log('[addToCartCallable] New quantity:', newQuantity, 'New total price:', newTotalPrice);
        
        await cartRef.doc(itemId).update({
          quantity: newQuantity,
          totalPrice: newTotalPrice,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        console.log('[addToCartCallable] Item quantity updated successfully');
      } else {
        // Add new item to cart
        console.log('[addToCartCallable] Adding new item to cart');
        const cartData = {
          id: itemId,
          serviceId,
          categoryId,
          categoryName: categoryName || '',
          technicianId,
          serviceName: serviceName || '',
          subServiceId: subServiceId || null,
          subServiceName: subServiceName || null,
          serviceImage: serviceImage || '',
          price,
          quantity,
          totalPrice: price * quantity,
          finalPriceSnapshot: finalPriceSnapshot || price,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        };
        
        console.log('[addToCartCallable] Cart data to write:', cartData);
        await cartRef.doc(itemId).set(cartData);
        console.log('[addToCartCallable] New item added to cart successfully');
      }

      // Update lastCartUpdate on customer document for abandoned cart tracking
      console.log('[addToCartCallable] Updating customer lastCartUpdate...');
      try {
        await db.collection('customers').doc(uid).update({
          lastCartUpdate: admin.firestore.FieldValue.serverTimestamp(),
        });
        console.log('[addToCartCallable] Customer lastCartUpdate updated successfully');
      } catch (updateError: any) {
        console.warn('[addToCartCallable] Failed to update customer lastCartUpdate (non-critical):', updateError.message);
        // Don't throw - this is non-critical
      }

      const response = {
        success: true,
        itemId,
        message: existingItem.exists ? 'Quantity updated' : 'Item added to cart',
      };
      console.log('[addToCartCallable] SUCCESS:', response);
      return response;
    } catch (error: any) {
      console.error('[addToCartCallable] FULL ERROR:', error);
      throw new functions.https.HttpsError('internal', error.message);
    }
  });

/**
 * Update cart item quantity
 */
export const updateCartQuantityCallable = functions
  .region('asia-south1')
  .https.onCall(async (data: any, context: functions.https.CallableContext) => {
    console.log('[updateCartQuantityCallable] REQUEST DATA:', data);

    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }

    const uid = context.auth.uid;
    const itemId: string = data.itemId ?? '';
    const quantity: number = typeof data.quantity === 'number' ? data.quantity : 0;

    if (!itemId) {
      console.error('[updateCartQuantityCallable] VALIDATION FAILED: itemId missing', { requestData: data });
      throw new functions.https.HttpsError('invalid-argument', 'Missing required fields', { requestData: data });
    }
    if (quantity <= 0) {
      console.error('[updateCartQuantityCallable] VALIDATION FAILED: quantity invalid', { quantity, requestData: data });
      throw new functions.https.HttpsError('invalid-argument', 'quantity must be > 0', { requestData: data });
    }

    try {
      console.log('[updateCartQuantityCallable] Fetching item:', itemId);
      const itemRef = db.collection('customers').doc(uid).collection('cart').doc(itemId);
      const itemDoc = await itemRef.get();

      if (!itemDoc.exists) {
        console.error('[updateCartQuantityCallable] Item not found:', itemId);
        throw new functions.https.HttpsError('not-found', 'Item not found in cart');
      }

      const itemData = itemDoc.data()!;
      console.log('[updateCartQuantityCallable] Item data:', itemData);
      
      if (typeof itemData.price !== 'number' || itemData.price <= 0) {
        console.error('[updateCartQuantityCallable] Invalid price in item:', itemData.price);
        throw new functions.https.HttpsError('internal', 'Invalid price in cart item');
      }
      
      const newTotalPrice = itemData.price * quantity;
      console.log('[updateCartQuantityCallable] Updating quantity to:', quantity, 'New total:', newTotalPrice);

      await itemRef.update({
        quantity,
        totalPrice: newTotalPrice,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      console.log('[updateCartQuantityCallable] SUCCESS');
      return { success: true, message: 'Quantity updated' };
    } catch (error: any) {
      console.error('[updateCartQuantityCallable] FULL ERROR:', error);
      throw new functions.https.HttpsError('internal', error.message);
    }
  });

/**
 * Remove item from cart
 */
export const removeFromCartCallable = functions
  .region('asia-south1')
  .https.onCall(async (data: any, context: functions.https.CallableContext) => {
    console.log('[removeFromCartCallable] REQUEST DATA:', data);

    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }

    const uid = context.auth.uid;
    const itemId: string = data.itemId ?? '';

    if (!itemId) {
      console.error('[removeFromCartCallable] VALIDATION FAILED: itemId missing', { requestData: data });
      throw new functions.https.HttpsError('invalid-argument', 'Missing required fields', { requestData: data });
    }

    try {
      console.log('[removeFromCartCallable] Deleting item:', itemId);
      await db.collection('customers').doc(uid).collection('cart').doc(itemId).delete();
      console.log('[removeFromCartCallable] SUCCESS');
      return { success: true, message: 'Item removed from cart' };
    } catch (error: any) {
      console.error('[removeFromCartCallable] FULL ERROR:', error);
      throw new functions.https.HttpsError('internal', error.message);
    }
  });

/**
 * Clear entire cart
 */
export const clearCartCallable = functions
  .region('asia-south1')
  .https.onCall(async (data: any, context: functions.https.CallableContext) => {
    console.log('[clearCartCallable] REQUEST DATA:', data);

    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }

    const uid = context.auth.uid;

    try {
      console.log('[clearCartCallable] Fetching all cart items for user:', uid);
      const cartRef = db.collection('customers').doc(uid).collection('cart');
      const cartItems = await cartRef.get();
      console.log('[clearCartCallable] Found items:', cartItems.size);

      if (cartItems.empty) {
        console.log('[clearCartCallable] Cart is already empty');
        return { success: true, message: 'Cart cleared', itemsDeleted: 0 };
      }

      console.log('[clearCartCallable] Creating batch delete for', cartItems.size, 'items');
      const batch = db.batch();
      cartItems.docs.forEach((doc) => {
        batch.delete(doc.ref);
      });

      console.log('[clearCartCallable] Committing batch delete...');
      await batch.commit();
      console.log('[clearCartCallable] SUCCESS - Deleted', cartItems.size, 'items');

      return { success: true, message: 'Cart cleared', itemsDeleted: cartItems.size };
    } catch (error: any) {
      console.error('[clearCartCallable] FULL ERROR:', error);
      throw new functions.https.HttpsError('internal', error.message);
    }
  });

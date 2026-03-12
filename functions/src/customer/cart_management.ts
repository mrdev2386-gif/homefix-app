import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

const db = admin.firestore();

/**
 * Add item to cart
 * Creates or updates customers/{uid}/cart/{itemId}
 */
export const addToCartCallable = functions.https.onCall(
  async (request, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }

    const uid = context.auth.uid;
    const {
      serviceId,
      categoryId,
      categoryName,
      technicianId,
      serviceName,
      subServiceId,
      subServiceName,
      serviceImage,
      price,
      quantity = 1,
      finalPriceSnapshot,
    } = request.data;

    // Validation
    if (!serviceId || !categoryId || !technicianId || !price) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'Missing required fields: serviceId, categoryId, technicianId, price'
      );
    }

    if (price <= 0) {
      throw new functions.https.HttpsError('invalid-argument', 'Price must be greater than 0');
    }

    if (quantity <= 0) {
      throw new functions.https.HttpsError('invalid-argument', 'Quantity must be greater than 0');
    }

    try {
      const cartRef = db.collection('customers').doc(uid).collection('cart');
      
      // Generate item ID (serviceId + subServiceId if exists)
      const itemId = subServiceId ? `${serviceId}_${subServiceId}` : serviceId;
      
      // Check if item already exists
      const existingItem = await cartRef.doc(itemId).get();
      
      if (existingItem.exists) {
        // Update quantity if item already in cart
        const existingData = existingItem.data()!;
        const newQuantity = (existingData.quantity || 1) + quantity;
        const newTotalPrice = price * newQuantity;
        
        await cartRef.doc(itemId).update({
          quantity: newQuantity,
          totalPrice: newTotalPrice,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      } else {
        // Add new item to cart
        await cartRef.doc(itemId).set({
          id: itemId,
          serviceId,
          categoryId,
          categoryName,
          technicianId,
          serviceName,
          subServiceId,
          subServiceName,
          serviceImage,
          price,
          quantity,
          totalPrice: price * quantity,
          finalPriceSnapshot: finalPriceSnapshot || price,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      }

      // Update lastCartUpdate on customer document for abandoned cart tracking
      await db.collection('customers').doc(uid).update({
        lastCartUpdate: admin.firestore.FieldValue.serverTimestamp(),
      });

      return {
        success: true,
        itemId,
        message: existingItem.exists ? 'Quantity updated' : 'Item added to cart',
      };
    } catch (error: any) {
      console.error(`[CART] Add failed for user ${uid}:`, error);
      throw new functions.https.HttpsError('internal', 'Failed to add item to cart');
    }
  }
);

/**
 * Update cart item quantity
 */
export const updateCartQuantityCallable = functions.https.onCall(
  async (request, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }

    const uid = context.auth.uid;
    const { itemId, quantity } = request.data;

    if (!itemId) {
      throw new functions.https.HttpsError('invalid-argument', 'itemId is required');
    }

    if (quantity <= 0) {
      throw new functions.https.HttpsError('invalid-argument', 'Quantity must be greater than 0');
    }

    try {
      const itemRef = db.collection('customers').doc(uid).collection('cart').doc(itemId);
      const itemDoc = await itemRef.get();

      if (!itemDoc.exists) {
        throw new functions.https.HttpsError('not-found', 'Item not found in cart');
      }

      const itemData = itemDoc.data()!;
      const newTotalPrice = itemData.price * quantity;

      await itemRef.update({
        quantity,
        totalPrice: newTotalPrice,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      return { success: true, message: 'Quantity updated' };
    } catch (error: any) {
      console.error(`[CART] Update quantity failed for user ${uid}:`, error);
      throw new functions.https.HttpsError('internal', 'Failed to update quantity');
    }
  }
);

/**
 * Remove item from cart
 */
export const removeFromCartCallable = functions.https.onCall(
  async (request, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }

    const uid = context.auth.uid;
    const { itemId } = request.data;

    if (!itemId) {
      throw new functions.https.HttpsError('invalid-argument', 'itemId is required');
    }

    try {
      await db.collection('customers').doc(uid).collection('cart').doc(itemId).delete();
      return { success: true, message: 'Item removed from cart' };
    } catch (error: any) {
      console.error(`[CART] Remove failed for user ${uid}:`, error);
      throw new functions.https.HttpsError('internal', 'Failed to remove item from cart');
    }
  }
);

/**
 * Clear entire cart
 */
export const clearCartCallable = functions.https.onCall(
  async (request, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }

    const uid = context.auth.uid;

    try {
      const cartRef = db.collection('customers').doc(uid).collection('cart');
      const cartItems = await cartRef.get();

      const batch = db.batch();
      cartItems.docs.forEach((doc) => {
        batch.delete(doc.ref);
      });

      if (!cartItems.empty) {
        await batch.commit();
      }

      return { success: true, message: 'Cart cleared', itemsDeleted: cartItems.size };
    } catch (error: any) {
      console.error(`[CART] Clear failed for user ${uid}:`, error);
      throw new functions.https.HttpsError('internal', 'Failed to clear cart');
    }
  }
);

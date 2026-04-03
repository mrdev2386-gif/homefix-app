import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

const db = admin.firestore();

/**
 * Toggle favorite status for a service
 * Creates or deletes customers/{uid}/favorites/{serviceId}
 */
export const toggleFavoriteCallable = functions
  .region('asia-south1')
  .https.onCall(async (data: any, context: functions.https.CallableContext) => {
    console.log('[toggleFavoriteCallable] REQUEST DATA:', data);
    console.log('[toggleFavoriteCallable] AUTH UID:', context.auth?.uid);

    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }

    const uid = context.auth.uid;
    const serviceId: string = data.serviceId ?? '';
    const categoryId: string = data.categoryId ?? '';
    const isFavorite: unknown = data.isFavorite;

    console.log('[toggleFavoriteCallable] Extracted:', { serviceId, categoryId, isFavorite, isFavoriteType: typeof isFavorite });

    if (!serviceId) {
      console.error('[toggleFavoriteCallable] VALIDATION FAILED: serviceId missing', { requestData: data });
      throw new functions.https.HttpsError('invalid-argument', 'Missing required fields', { requestData: data });
    }
    if (!categoryId) {
      console.error('[toggleFavoriteCallable] VALIDATION FAILED: categoryId missing', { requestData: data });
      throw new functions.https.HttpsError('invalid-argument', 'Missing required fields', { requestData: data });
    }
    if (typeof isFavorite !== 'boolean') {
      console.error('[toggleFavoriteCallable] VALIDATION FAILED: isFavorite must be boolean', { isFavorite, type: typeof isFavorite, requestData: data });
      throw new functions.https.HttpsError('invalid-argument', 'Missing required fields', { requestData: data });
    }

    try {
      console.log('[toggleFavoriteCallable] Starting toggle operation for user:', uid);
      
      const favoritesRef = db.collection('customers').doc(uid).collection('favorites');
      const favoriteDoc = favoritesRef.doc(serviceId);

      console.log('[toggleFavoriteCallable] Favorite doc path:', favoriteDoc.path);

      if (isFavorite) {
        // Add to favorites
        console.log('[toggleFavoriteCallable] Adding to favorites...');
        const favoriteData = {
          serviceId,
          categoryId,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        };
        console.log('[toggleFavoriteCallable] Favorite data to write:', favoriteData);
        
        await favoriteDoc.set(favoriteData);
        console.log('[toggleFavoriteCallable] Successfully added to favorites');
      } else {
        // Remove from favorites
        console.log('[toggleFavoriteCallable] Removing from favorites...');
        await favoriteDoc.delete();
        console.log('[toggleFavoriteCallable] Successfully removed from favorites');
      }

      const response = {
        success: true,
        message: isFavorite ? 'Added to favorites' : 'Removed from favorites',
        isFavorite,
      };
      console.log('[toggleFavoriteCallable] SUCCESS:', response);
      return response;
    } catch (error: any) {
      console.error('[toggleFavoriteCallable] FULL ERROR:', error);
      throw new functions.https.HttpsError('internal', error.message);
    }
  });

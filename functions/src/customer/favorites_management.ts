import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

const db = admin.firestore();

/**
 * Toggle favorite status for a service
 * Creates or deletes customers/{uid}/favorites/{serviceId}
 */
export const toggleFavoriteCallable = functions.https.onCall(
  async (request, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }

    const uid = context.auth.uid;
    const { serviceId, categoryId, isFavorite } = request.data;

    // Validation
    if (!serviceId) {
      throw new functions.https.HttpsError('invalid-argument', 'serviceId is required');
    }

    if (!categoryId) {
      throw new functions.https.HttpsError('invalid-argument', 'categoryId is required');
    }

    if (typeof isFavorite !== 'boolean') {
      throw new functions.https.HttpsError('invalid-argument', 'isFavorite must be a boolean');
    }

    try {
      const favoritesRef = db.collection('customers').doc(uid).collection('favorites');
      const favoriteDoc = favoritesRef.doc(serviceId);

      if (isFavorite) {
        // Add to favorites
        await favoriteDoc.set({
          serviceId,
          categoryId,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      } else {
        // Remove from favorites
        await favoriteDoc.delete();
      }

      return {
        success: true,
        message: isFavorite ? 'Added to favorites' : 'Removed from favorites',
        isFavorite,
      };
    } catch (error: any) {
      console.error(`[FAVORITES] Toggle failed for user ${uid}:`, error);
      throw new functions.https.HttpsError('internal', 'Failed to toggle favorite');
    }
  }
);

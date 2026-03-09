import { onCall } from 'firebase-functions/v2/https';
import { CallableRequest } from 'firebase-functions/v2/https';
import * as admin from 'firebase-admin';
import * as https from 'firebase-functions/v2/https';

const db = admin.firestore();

/**
 * Toggle favorite status for a service
 * Creates or deletes customers/{uid}/favorites/{serviceId}
 */
export const toggleFavoriteCallable = onCall(
  { region: 'us-central1', memory: '256MiB', timeoutSeconds: 30 },
  async (request: CallableRequest<any>) => {
    if (!request.auth) {
      throw new https.HttpsError('unauthenticated', 'User must be authenticated');
    }

    const uid = request.auth.uid;
    const { serviceId, categoryId, isFavorite } = request.data;

    // Validation
    if (!serviceId) {
      throw new https.HttpsError('invalid-argument', 'serviceId is required');
    }

    if (!categoryId) {
      throw new https.HttpsError('invalid-argument', 'categoryId is required');
    }

    if (typeof isFavorite !== 'boolean') {
      throw new https.HttpsError('invalid-argument', 'isFavorite must be a boolean');
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
      throw new https.HttpsError('internal', 'Failed to toggle favorite');
    }
  }
);

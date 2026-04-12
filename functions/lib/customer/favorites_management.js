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
exports.toggleFavoriteCallable = void 0;
const functions = __importStar(require("firebase-functions"));
const admin = __importStar(require("firebase-admin"));
const db = admin.firestore();
/**
 * Toggle favorite status for a service
 * Creates or deletes customers/{uid}/favorites/{serviceId}
 */
exports.toggleFavoriteCallable = functions
    .region('asia-south1')
    .https.onCall(async (data, context) => {
    console.log('[toggleFavoriteCallable] REQUEST DATA:', data);
    console.log('[toggleFavoriteCallable] AUTH UID:', context.auth?.uid);
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }
    const uid = context.auth.uid;
    const serviceId = data.serviceId ?? '';
    const categoryId = data.categoryId ?? '';
    const isFavorite = data.isFavorite;
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
        }
        else {
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
    }
    catch (error) {
        console.error('[toggleFavoriteCallable] FULL ERROR:', error);
        throw new functions.https.HttpsError('internal', error.message);
    }
});
//# sourceMappingURL=favorites_management.js.map
import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { assertAdmin, logAdminAction } from './utils';

// Helper to generate random ID
const generateId = () => Math.random().toString(36).substring(2, 15) + Math.random().toString(36).substring(2, 15);

export const uploadServiceImage = functions.https.onCall(async (data, context) => {
    try {
        await assertAdmin(context);

        const { imageBase64, folder = 'services', mimeType = 'image/jpeg' } = data;

        if (!imageBase64) {
            throw new functions.https.HttpsError('invalid-argument', 'Missing imageBase64 data');
        }

        // Validate base64 (simple check)
        const buffer = Buffer.from(imageBase64, 'base64');
        if (buffer.length > 5 * 1024 * 1024) { // 5MB limit
            throw new functions.https.HttpsError('invalid-argument', 'Image too large (max 5MB)');
        }

        const bucket = admin.storage().bucket();
        const fileName = `${folder}/${Date.now()}_${generateId()}.${mimeType.split('/')[1] || 'jpg'}`;
        const file = bucket.file(fileName);

        await file.save(buffer, {
            metadata: {
                contentType: mimeType,
            },
            public: true, // Make public for app access
        });

        // Get public URL
        // Method 1: explicitly make public
        await file.makePublic();
        const publicUrl = `https://storage.googleapis.com/${bucket.name}/${fileName}`;

        await logAdminAction(context.auth!.uid, 'upload_image', fileName, { folder });

        return { url: publicUrl };

    } catch (error: any) {
        console.error('[Images] Upload failed:', error);
        if (error instanceof functions.https.HttpsError) throw error;
        throw new functions.https.HttpsError('internal', error.message || 'Image upload failed');
    }
});

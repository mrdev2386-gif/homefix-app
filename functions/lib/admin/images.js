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
exports.uploadServiceImage = void 0;
const functions = __importStar(require("firebase-functions"));
const admin = __importStar(require("firebase-admin"));
const utils_1 = require("./utils");
// Helper to generate random ID
const generateId = () => Math.random().toString(36).substring(2, 15) + Math.random().toString(36).substring(2, 15);
exports.uploadServiceImage = functions.region('asia-south1').https.onCall(async (data, context) => {
    try {
        await (0, utils_1.assertAdmin)(context);
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
        await (0, utils_1.logAdminAction)(context.auth.uid, 'upload_image', fileName, { folder });
        return { url: publicUrl };
    }
    catch (error) {
        console.error('[Images] Upload failed:', error);
        if (error instanceof functions.https.HttpsError)
            throw error;
        throw new functions.https.HttpsError('internal', error.message || 'Image upload failed');
    }
});
//# sourceMappingURL=images.js.map

import * as admin from 'firebase-admin';
import * as functions from 'firebase-functions';
import * as crypto from 'crypto';

const db = admin.firestore();

// Environment variable for encryption key
const ENCRYPTION_KEY_SECRET = process.env.SECURITY_SECRET || 'default_secret_key_change_me_in_prod';

// --- RATE LIMITING ---

export async function checkRateLimit(uid: string, action: string, limit: number, windowMs: number) {
    const now = Date.now();
    const rateLimitRef = db.collection('rate_limits').doc(`${uid}_${action}`);
    const doc = await rateLimitRef.get();

    if (doc.exists) {
        const data = doc.data()!;
        if (now - data.lastReset < windowMs) {
            if (data.count >= limit) {
                throw new functions.https.HttpsError('resource-exhausted', 'Rate limit exceeded. Try again later.');
            }
            await rateLimitRef.update({ count: admin.firestore.FieldValue.increment(1) });
        } else {
            await rateLimitRef.set({ count: 1, lastReset: now });
        }
    } else {
        await rateLimitRef.set({ count: 1, lastReset: now });
    }
}

// --- ENCRYPTION ---

// Use a fixed key from config or environment for demo purposes. 
// In production, use Google Cloud KMS.
// We'll use a 32-byte key derived from a config secret or default.
const ENCRYPTION_KEY = crypto.scryptSync(ENCRYPTION_KEY_SECRET, 'salt', 32);
const IV_LENGTH = 16;

export function encrypt(text: string): string {
    const iv = crypto.randomBytes(IV_LENGTH);
    const cipher = crypto.createCipheriv('aes-256-cbc', ENCRYPTION_KEY, iv);
    let encrypted = cipher.update(text);
    encrypted = Buffer.concat([encrypted, cipher.final()]);
    return iv.toString('hex') + ':' + encrypted.toString('hex');
}

export function decrypt(text: string): string {
    const textParts = text.split(':');
    const iv = Buffer.from(textParts.shift()!, 'hex');
    const encryptedText = Buffer.from(textParts.join(':'), 'hex');
    const decipher = crypto.createDecipheriv('aes-256-cbc', ENCRYPTION_KEY, iv);
    let decrypted = decipher.update(encryptedText);
    decrypted = Buffer.concat([decrypted, decipher.final()]);
    return decrypted.toString();
}

// --- INPUT SANITIZATION ---

/**
 * Sanitize string input to prevent XSS
 */
export function sanitizeString(input: string, maxLength: number = 500): string {
    if (!input) return '';
    
    return input
        .trim()
        .replace(/[<>]/g, '') // Remove HTML tags
        .replace(/[^\w\s\-.,!?@#$%&*()]/g, '') // Remove special chars except common punctuation
        .substring(0, maxLength);
}

/**
 * Sanitize Aadhaar number (digits only)
 */
export function sanitizeAadhaar(aadhaar: string): string {
    if (!aadhaar) return '';
    return aadhaar.replace(/[^0-9]/g, '').substring(0, 12);
}

/**
 * Sanitize email
 */
export function sanitizeEmail(email: string): string {
    if (!email) return '';
    return email.trim().toLowerCase().substring(0, 100);
}

/**
 * Sanitize phone number (digits only)
 */
export function sanitizePhone(phone: string): string {
    if (!phone) return '';
    return phone.replace(/[^0-9+]/g, '').substring(0, 15);
}

// --- AUTH HELPERS ---

export function assertAuthenticated(context: functions.https.CallableContext) {
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }
}

export async function assertAdmin(context: functions.https.CallableContext) {
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }
    
    // Use custom claims for admin verification
    if (!context.auth.token?.admin) {
        throw new functions.https.HttpsError('permission-denied', 'Admin access required');
    }
}

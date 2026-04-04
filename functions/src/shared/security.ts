
import * as functions from 'firebase-functions';
import { logger } from './utils';
import * as crypto from 'crypto';

/**
 * Production Security & Hardening Layer
 */

/**
 * Assert user is authenticated
 */
export function assertAuthenticated(context: functions.https.CallableContext): string {
    if (!context.auth || !context.auth.uid) {
        throw new functions.https.HttpsError(
            'unauthenticated',
            'User must be authenticated'
        );
    }
    return context.auth.uid;
}

/**
 * Assert user is admin
 */
export async function assertAdmin(context: functions.https.CallableContext): Promise<string> {
    const uid = assertAuthenticated(context);
    const admin = await import('firebase-admin');
    const db = admin.firestore();
    
    const adminDoc = await db.collection('admins').doc(uid).get();
    if (!adminDoc.exists) {
        throw new functions.https.HttpsError(
            'permission-denied',
            'Only admins can perform this action'
        );
    }
    
    return uid;
}

/**
 * Check rate limit (stub - implement as needed)
 */
export async function checkRateLimit(
    uid: string,
    action: string,
    maxAttempts?: number,
    windowMs?: number
): Promise<boolean> {
    // TODO: Implement rate limiting logic with Redis or Firestore
    // For now, always allow
    return true;
}

/**
 * Encrypt sensitive data
 */
export function encrypt(text: string, algorithm?: string): string {
    // Simple encryption - replace with proper encryption in production
    return Buffer.from(text).toString('base64');
}

/**
 * Sanitize string input
 */
export function sanitizeString(text: string, maxLength?: number): string {
    if (typeof text !== 'string') return '';
    const cleaned = text.trim().replace(/<[^>]*>/g, '');
    if (maxLength && cleaned.length > maxLength) {
        return cleaned.substring(0, maxLength);
    }
    return cleaned;
}

/**
 * Sanitize email
 */
export function sanitizeEmail(email: string, maxLength?: number): string {
    if (typeof email !== 'string') return '';
    const cleaned = email.trim().toLowerCase();
    if (maxLength && cleaned.length > maxLength) {
        return cleaned.substring(0, maxLength);
    }
    return cleaned;
}

/**
 * Sanitize Aadhaar number
 */
export function sanitizeAadhaar(aadhaar: string, maxLength?: number): string {
    if (typeof aadhaar !== 'string') return '';
    const cleaned = aadhaar.replace(/\D/g, '').slice(0, 12);
    return cleaned;
}

/**
 * Enforce App Check on all incoming requests
 * DISABLED: App Check SDK is disabled in Flutter apps
 */
// export function enforceAppCheck(context: functions.https.CallableContext) {
//     if (!context.app) {
//         logger.warn('APP_CHECK_MISSING', { 
//             uid: context.auth?.uid,
//             ip: context.rawRequest?.ip 
//         });
//         throw new functions.https.HttpsError(
//             'failed-precondition',
//             'App Check token required'
//         );
//     }
// }

/**
 * Sanitize user input strings
 */
export function sanitize(text: any): any {
    if (typeof text !== 'string') {
        if (text && typeof text === 'object') {
            const sanitizedObj: any = {};
            for (const key in text) {
                sanitizedObj[key] = sanitize(text[key]);
            }
            return sanitizedObj;
        }
        return text;
    }

    // Remove scripts, HTML tags, and dangerous characters
    return text
        .replace(/<script\b[^>]*>([\s\S]*?)<\/script>/gim, "")
        .replace(/<[^>]*>?/gm, "")
        .trim();
}

/**
 * Standardized High-Performance Function Wrapper
 * - ENFORCES AUTHENTICATION (CRITICAL FIX)
 * - Standardizes Error Handling
 * - Provides Structured Logging
 * - Validates Auth Context Before Handler Execution
 */
export function secureCallable(
    handler: (data: any, context: functions.https.CallableContext) => Promise<any>
) {
    return async (data: any, context: functions.https.CallableContext) => {
        const functionName = context.rawRequest?.url?.split('/').pop() || 'unknown';
        
        try {
            // ========================================
            // CRITICAL FIX: ENFORCE AUTHENTICATION FIRST
            // ========================================
            console.log(`[${functionName}] 🔍 Incoming request`);
            console.log(`[${functionName}] Auth context:`, {
                hasAuth: !!context.auth,
                uid: context.auth?.uid,
                token: context.auth?.token ? 'present' : 'missing'
            });

            // STEP 1: Verify auth context exists
            if (!context.auth) {
                console.error(`[${functionName}] ❌ UNAUTHENTICATED: context.auth is NULL`);
                console.error(`[${functionName}] Request Headers:`, context.rawRequest?.headers);
                console.error(`[${functionName}] Auth Header:`, context.rawRequest?.headers['authorization']);
                throw new functions.https.HttpsError(
                    'unauthenticated',
                    'Authentication required. Please ensure you are logged in and try again.'
                );
            }

            // STEP 2: Verify UID exists
            if (!context.auth.uid) {
                console.error(`[${functionName}] ❌ UNAUTHENTICATED: context.auth.uid is NULL`);
                throw new functions.https.HttpsError(
                    'unauthenticated',
                    'Invalid authentication token. Please log in again.'
                );
            }

            console.log(`[${functionName}] ✅ AUTHENTICATED: UID=${context.auth.uid}`);

            // 2. Structured Start Log
            logger.info(`${functionName}_start`, { 
                uid: context.auth.uid,
                params: sanitizeParams(data)
            });

            // 3. Execute Handler
            const result = await handler(data, context);

            // 4. Structured Success Log
            logger.info(`${functionName}_success`, { uid: context.auth.uid });
            console.log(`[${functionName}] ✅ SUCCESS`);

            return result;
        } catch (error: any) {
            // 5. Standardized Error Response
            if (error instanceof functions.https.HttpsError) {
                console.error(`[${functionName}] ❌ HttpsError:`, {
                    code: error.code,
                    message: error.message,
                    uid: context.auth?.uid
                });
                logger.warn(`${functionName}_error`, { 
                    code: error.code, 
                    message: error.message,
                    uid: context.auth?.uid 
                });
                throw error;
            }

            // 6. Fallback Unhandled Error
            console.error(`[${functionName}] ❌ Unhandled error:`, error);
            console.error(`[${functionName}] STACK:`, error?.stack);
            logger.error(`${functionName}_failure`, { uid: context.auth?.uid }, error);
            throw new functions.https.HttpsError(
                'internal',
                error?.message || 'An unexpected error occurred'
            );
        }
    };
}

/**
 * Internal helper to sanitize params for logging (hide PII)
 */
function sanitizeParams(data: any): any {
    if (!data || typeof data !== 'object') return data;
    const sanitized = { ...data };
    const piiFields = ['phone', 'email', 'address', 'token', 'password', 'paymentId'];
    
    piiFields.forEach(field => {
        if (field in sanitized) {
            sanitized[field] = '***REDACTED***';
        }
    });
    
    return sanitized;
}

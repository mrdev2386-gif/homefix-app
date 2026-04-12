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
exports.assertAuthenticated = assertAuthenticated;
exports.assertAdmin = assertAdmin;
exports.checkRateLimit = checkRateLimit;
exports.encrypt = encrypt;
exports.sanitizeString = sanitizeString;
exports.sanitizeEmail = sanitizeEmail;
exports.sanitizeAadhaar = sanitizeAadhaar;
exports.sanitize = sanitize;
exports.secureCallable = secureCallable;
const functions = __importStar(require("firebase-functions"));
const utils_1 = require("./utils");
/**
 * Production Security & Hardening Layer
 */
/**
 * Assert user is authenticated
 */
function assertAuthenticated(context) {
    if (!context.auth || !context.auth.uid) {
        throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }
    return context.auth.uid;
}
/**
 * Assert user is admin
 */
async function assertAdmin(context) {
    const uid = assertAuthenticated(context);
    const admin = await Promise.resolve().then(() => __importStar(require('firebase-admin')));
    const db = admin.firestore();
    const adminDoc = await db.collection('admins').doc(uid).get();
    if (!adminDoc.exists) {
        throw new functions.https.HttpsError('permission-denied', 'Only admins can perform this action');
    }
    return uid;
}
/**
 * Check rate limit (stub - implement as needed)
 */
async function checkRateLimit(uid, action, maxAttempts, windowMs) {
    // TODO: Implement rate limiting logic with Redis or Firestore
    // For now, always allow
    return true;
}
/**
 * Encrypt sensitive data
 */
function encrypt(text, algorithm) {
    // Simple encryption - replace with proper encryption in production
    return Buffer.from(text).toString('base64');
}
/**
 * Sanitize string input
 */
function sanitizeString(text, maxLength) {
    if (typeof text !== 'string')
        return '';
    const cleaned = text.trim().replace(/<[^>]*>/g, '');
    if (maxLength && cleaned.length > maxLength) {
        return cleaned.substring(0, maxLength);
    }
    return cleaned;
}
/**
 * Sanitize email
 */
function sanitizeEmail(email, maxLength) {
    if (typeof email !== 'string')
        return '';
    const cleaned = email.trim().toLowerCase();
    if (maxLength && cleaned.length > maxLength) {
        return cleaned.substring(0, maxLength);
    }
    return cleaned;
}
/**
 * Sanitize Aadhaar number
 */
function sanitizeAadhaar(aadhaar, maxLength) {
    if (typeof aadhaar !== 'string')
        return '';
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
function sanitize(text) {
    if (typeof text !== 'string') {
        if (text && typeof text === 'object') {
            const sanitizedObj = {};
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
function secureCallable(handler) {
    return async (data, context) => {
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
                throw new functions.https.HttpsError('unauthenticated', 'Authentication required. Please ensure you are logged in and try again.');
            }
            // STEP 2: Verify UID exists
            if (!context.auth.uid) {
                console.error(`[${functionName}] ❌ UNAUTHENTICATED: context.auth.uid is NULL`);
                throw new functions.https.HttpsError('unauthenticated', 'Invalid authentication token. Please log in again.');
            }
            console.log(`[${functionName}] ✅ AUTHENTICATED: UID=${context.auth.uid}`);
            // 2. Structured Start Log
            utils_1.logger.info(`${functionName}_start`, {
                uid: context.auth.uid,
                params: sanitizeParams(data)
            });
            // 3. Execute Handler
            const result = await handler(data, context);
            // 4. Structured Success Log
            utils_1.logger.info(`${functionName}_success`, { uid: context.auth.uid });
            console.log(`[${functionName}] ✅ SUCCESS`);
            return result;
        }
        catch (error) {
            // 5. Standardized Error Response
            if (error instanceof functions.https.HttpsError) {
                console.error(`[${functionName}] ❌ HttpsError:`, {
                    code: error.code,
                    message: error.message,
                    uid: context.auth?.uid
                });
                utils_1.logger.warn(`${functionName}_error`, {
                    code: error.code,
                    message: error.message,
                    uid: context.auth?.uid
                });
                throw error;
            }
            // 6. Fallback Unhandled Error
            console.error(`[${functionName}] ❌ Unhandled error:`, error);
            console.error(`[${functionName}] STACK:`, error?.stack);
            utils_1.logger.error(`${functionName}_failure`, { uid: context.auth?.uid }, error);
            throw new functions.https.HttpsError('internal', error?.message || 'An unexpected error occurred');
        }
    };
}
/**
 * Internal helper to sanitize params for logging (hide PII)
 */
function sanitizeParams(data) {
    if (!data || typeof data !== 'object')
        return data;
    const sanitized = { ...data };
    const piiFields = ['phone', 'email', 'address', 'token', 'password', 'paymentId'];
    piiFields.forEach(field => {
        if (field in sanitized) {
            sanitized[field] = '***REDACTED***';
        }
    });
    return sanitized;
}
//# sourceMappingURL=security.js.map
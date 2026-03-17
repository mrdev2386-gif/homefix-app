
import * as functions from 'firebase-functions';
import { logger } from './utils';

/**
 * Production Security & Hardening Layer
 */

/**
 * Enforce App Check on all incoming requests
 */
export function enforceAppCheck(context: functions.https.CallableContext) {
    if (!context.app) {
        logger.warn('APP_CHECK_MISSING', { 
            uid: context.auth?.uid,
            ip: context.rawRequest?.ip 
        });
        throw new functions.https.HttpsError(
            'failed-precondition',
            'App Check token required'
        );
    }
}

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
 * - Enforces App Check
 * - Standardizes Error Handling
 * - Provides Structured Logging
 */
export function secureCallable(
    handler: (data: any, context: functions.https.CallableContext) => Promise<any>
) {
    return async (data: any, context: functions.https.CallableContext) => {
        const functionName = context.rawRequest?.url?.split('/').pop() || 'unknown';
        
        try {
            // 1. App Check Enforcement
            enforceAppCheck(context);

            // 2. Structured Start Log
            logger.info(`${functionName}_start`, { 
                uid: context.auth?.uid,
                params: sanitizeParams(data)
            });

            // 3. Execute Handler
            const result = await handler(data, context);

            // 4. Structured Success Log
            logger.info(`${functionName}_success`, { uid: context.auth?.uid });

            return result;
        } catch (error: any) {
            // 5. Standardized Error Response
            if (error instanceof functions.https.HttpsError) {
                logger.warn(`${functionName}_error`, { 
                    code: error.code, 
                    message: error.message,
                    uid: context.auth?.uid 
                });
                throw error;
            }

            // 6. Fallback Unhandled Error
            logger.error(`${functionName}_failure`, { uid: context.auth?.uid }, error);
            throw new functions.https.HttpsError(
                'internal',
                'An unexpected error occurred. Please try again later.'
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

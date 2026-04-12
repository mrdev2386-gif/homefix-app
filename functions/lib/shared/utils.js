"use strict";
/**
 * Shared Utility Functions
 *
 * Common utilities used across Cloud Functions
 */
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
exports.logger = void 0;
exports.sanitizeInput = sanitizeInput;
exports.assertAdmin = assertAdmin;
exports.logAdminAction = logAdminAction;
exports.assertAuthenticated = assertAuthenticated;
exports.assertOwnership = assertOwnership;
exports.sanitizePhoneNumber = sanitizePhoneNumber;
exports.generateBookingNumber = generateBookingNumber;
exports.calculateDistance = calculateDistance;
exports.isValidEmail = isValidEmail;
exports.isValidIndianPhone = isValidIndianPhone;
exports.generateOTP = generateOTP;
exports.formatCurrency = formatCurrency;
exports.validateRequiredFields = validateRequiredFields;
exports.checkRateLimit = checkRateLimit;
const functions = __importStar(require("firebase-functions"));
const admin = __importStar(require("firebase-admin"));
const config_1 = require("./config");
/**
 * App Check Validation - DISABLED
 * App Check SDK is disabled in Flutter apps
 */
// export function validateAppCheck(context: functions.https.CallableContext) {
//     if (!context.app) {
//         throw new functions.https.HttpsError(
//             'failed-precondition',
//             'App Check token required'
//         );
//     }
// }
/**
 * Structured Logger
 */
exports.logger = {
    info: (event, data = {}) => {
        console.log(`[INFO-${event}]`, JSON.stringify({ ...data, timestamp: new Date().toISOString() }));
    },
    warn: (event, data = {}) => {
        console.warn(`[WARN-${event}]`, JSON.stringify({ ...data, timestamp: new Date().toISOString() }));
    },
    error: (event, data = {}, error) => {
        console.error(`[ERROR-${event}]`, JSON.stringify({
            ...data,
            error: error?.message || error,
            stack: error?.stack,
            timestamp: new Date().toISOString()
        }));
    }
};
/**
 * Input Sanitization
 */
function sanitizeInput(text) {
    if (!text)
        return '';
    // Remove scripts, HTML tags, and dangerous characters
    return text
        .replace(/<script\b[^>]*>([\s\S]*?)<\/script>/gim, "")
        .replace(/<[^>]*>?/gm, "")
        .replace(/[&<>"']/g, (m) => ({
        '&': '&amp;',
        '<': '&lt;',
        '>': '&gt;',
        '"': '&quot;',
        "'": '&#39;'
    })[m] || m)
        .trim();
}
/**
 * Assert that the user is an admin
 * Throws HttpsError if not admin
 */
async function assertAdmin(context) {
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }
    // Check if user has admin custom claim
    if (!context.auth.token.admin) {
        throw new functions.https.HttpsError('permission-denied', 'Admin access required');
    }
}
/**
 * Log admin action for audit trail
 */
async function logAdminAction(adminUid, action, targetId, metadata) {
    try {
        await config_1.db.collection('audit_logs').add({
            adminUid,
            action,
            targetId,
            metadata: metadata || {},
            createdAt: admin.firestore.FieldValue.serverTimestamp()
        });
    }
    catch (error) {
        console.error('Failed to log admin action:', error);
        // Don't throw - logging failure shouldn't break the operation
    }
}
/**
 * Verify user is authenticated
 */
function assertAuthenticated(context) {
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }
}
/**
 * Verify user owns the resource
 */
function assertOwnership(userId, resourceOwnerId) {
    if (userId !== resourceOwnerId) {
        throw new functions.https.HttpsError('permission-denied', 'You do not own this resource');
    }
}
/**
 * Sanitize phone number to E.164 format
 */
function sanitizePhoneNumber(phone) {
    // Remove all non-digit characters
    const digits = phone.replace(/\D/g, '');
    // If it's 10 digits, assume Indian number
    if (digits.length === 10) {
        return `+91${digits}`;
    }
    // If it already has country code
    if (digits.length > 10) {
        return `+${digits}`;
    }
    return phone;
}
/**
 * Generate unique booking number
 */
async function generateBookingNumber() {
    const year = new Date().getFullYear();
    // Get counter for this year
    const counterRef = config_1.db.collection('counters').doc('bookings');
    const counterDoc = await counterRef.get();
    let count = 1;
    if (counterDoc.exists) {
        const data = counterDoc.data();
        if (data && data.year === year) {
            count = (data.count || 0) + 1;
        }
    }
    // Update counter
    await counterRef.set({
        year,
        count
    });
    // Format: BK-2026-0001
    return `BK-${year}-${count.toString().padStart(4, '0')}`;
}
/**
 * Calculate distance between two coordinates (in km)
 */
function calculateDistance(lat1, lon1, lat2, lon2) {
    const R = 6371; // Radius of the earth in km
    const dLat = deg2rad(lat2 - lat1);
    const dLon = deg2rad(lon2 - lon1);
    const a = Math.sin(dLat / 2) * Math.sin(dLat / 2) +
        Math.cos(deg2rad(lat1)) * Math.cos(deg2rad(lat2)) *
            Math.sin(dLon / 2) * Math.sin(dLon / 2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    const d = R * c; // Distance in km
    return d;
}
function deg2rad(deg) {
    return deg * (Math.PI / 180);
}
/**
 * Validate email format
 */
function isValidEmail(email) {
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    return emailRegex.test(email);
}
/**
 * Validate Indian phone number
 */
function isValidIndianPhone(phone) {
    const phoneRegex = /^(\+91)?[6-9]\d{9}$/;
    return phoneRegex.test(phone.replace(/\s/g, ''));
}
/**
 * Generate random OTP
 */
function generateOTP(length = 6) {
    const digits = '0123456789';
    let otp = '';
    for (let i = 0; i < length; i++) {
        otp += digits[Math.floor(Math.random() * 10)];
    }
    return otp;
}
/**
 * Format currency (INR)
 */
function formatCurrency(amount) {
    return `₹${amount.toLocaleString('en-IN', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`;
}
/**
 * Validate required fields
 */
function validateRequiredFields(data, requiredFields) {
    const missingFields = requiredFields.filter(field => !data[field]);
    if (missingFields.length > 0) {
        throw new functions.https.HttpsError('invalid-argument', `Missing required fields: ${missingFields.join(', ')}`);
    }
}
/**
 * Rate limiting check
 *
 * @param userId - User ID to check
 * @param action - Action being rate limited
 * @param maxAttempts - Maximum attempts allowed
 * @param windowMinutes - Time window in minutes (NOT seconds)
 */
async function checkRateLimit(userId, action, maxAttempts, windowMinutes) {
    const rateLimitRef = config_1.db.collection('rate_limits').doc(`${userId}_${action}`);
    const rateLimitDoc = await rateLimitRef.get();
    const now = Date.now();
    const windowMs = windowMinutes * 60 * 1000;
    if (rateLimitDoc.exists) {
        const data = rateLimitDoc.data();
        const resetTime = data.resetAt?.toMillis() || 0;
        if (now < resetTime) {
            // Within window
            if (data.attempts >= maxAttempts) {
                throw new functions.https.HttpsError('resource-exhausted', `Rate limit exceeded. Try again in ${Math.ceil((resetTime - now) / 60000)} minutes.`);
            }
            // Increment attempts
            await rateLimitRef.update({
                attempts: admin.firestore.FieldValue.increment(1)
            });
        }
        else {
            // Window expired, reset
            await rateLimitRef.set({
                attempts: 1,
                resetAt: admin.firestore.Timestamp.fromMillis(now + windowMs)
            });
        }
    }
    else {
        // First attempt
        await rateLimitRef.set({
            attempts: 1,
            resetAt: admin.firestore.Timestamp.fromMillis(now + windowMs)
        });
    }
}
//# sourceMappingURL=utils.js.map
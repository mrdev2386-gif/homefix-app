/**
 * Shared Utility Functions
 * 
 * Common utilities used across Cloud Functions
 */

import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { db } from './config';

/**
 * App Check Validation
 */
export function validateAppCheck(context: functions.https.CallableContext) {
    if (!context.app) {
        throw new functions.https.HttpsError(
            'failed-precondition',
            'App Check token required'
        );
    }
}

/**
 * Structured Logger
 */
export const logger = {
    info: (event: string, data: any = {}) => {
        console.log(`[INFO-${event}]`, JSON.stringify({ ...data, timestamp: new Date().toISOString() }));
    },
    warn: (event: string, data: any = {}) => {
        console.warn(`[WARN-${event}]`, JSON.stringify({ ...data, timestamp: new Date().toISOString() }));
    },
    error: (event: string, data: any = {}, error?: any) => {
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
export function sanitizeInput(text: string): string {
    if (!text) return '';
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
export async function assertAdmin(context: functions.https.CallableContext) {
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
export async function logAdminAction(
    adminUid: string,
    action: string,
    targetId: string,
    metadata?: any
) {
    try {
        await db.collection('audit_logs').add({
            adminUid,
            action,
            targetId,
            metadata: metadata || {},
            createdAt: admin.firestore.FieldValue.serverTimestamp()
        });
    } catch (error) {
        console.error('Failed to log admin action:', error);
        // Don't throw - logging failure shouldn't break the operation
    }
}

/**
 * Verify user is authenticated
 */
export function assertAuthenticated(context: functions.https.CallableContext) {
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }
}

/**
 * Verify user owns the resource
 */
export function assertOwnership(userId: string, resourceOwnerId: string) {
    if (userId !== resourceOwnerId) {
        throw new functions.https.HttpsError('permission-denied', 'You do not own this resource');
    }
}

/**
 * Sanitize phone number to E.164 format
 */
export function sanitizePhoneNumber(phone: string): string {
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
export async function generateBookingNumber(): Promise<string> {
    const year = new Date().getFullYear();

    // Get counter for this year
    const counterRef = db.collection('counters').doc('bookings');
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
export function calculateDistance(
    lat1: number,
    lon1: number,
    lat2: number,
    lon2: number
): number {
    const R = 6371; // Radius of the earth in km
    const dLat = deg2rad(lat2 - lat1);
    const dLon = deg2rad(lon2 - lon1);
    const a =
        Math.sin(dLat / 2) * Math.sin(dLat / 2) +
        Math.cos(deg2rad(lat1)) * Math.cos(deg2rad(lat2)) *
        Math.sin(dLon / 2) * Math.sin(dLon / 2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    const d = R * c; // Distance in km
    return d;
}

function deg2rad(deg: number): number {
    return deg * (Math.PI / 180);
}

/**
 * Validate email format
 */
export function isValidEmail(email: string): boolean {
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    return emailRegex.test(email);
}

/**
 * Validate Indian phone number
 */
export function isValidIndianPhone(phone: string): boolean {
    const phoneRegex = /^(\+91)?[6-9]\d{9}$/;
    return phoneRegex.test(phone.replace(/\s/g, ''));
}

/**
 * Generate random OTP
 */
export function generateOTP(length: number = 6): string {
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
export function formatCurrency(amount: number): string {
    return `₹${amount.toLocaleString('en-IN', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`;
}

/**
 * Validate required fields
 */
export function validateRequiredFields(data: any, requiredFields: string[]) {
    const missingFields = requiredFields.filter(field => !data[field]);

    if (missingFields.length > 0) {
        throw new functions.https.HttpsError(
            'invalid-argument',
            `Missing required fields: ${missingFields.join(', ')}`
        );
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
export async function checkRateLimit(
    userId: string,
    action: string,
    maxAttempts: number,
    windowMinutes: number
): Promise<void> {
    const rateLimitRef = db.collection('rate_limits').doc(`${userId}_${action}`);
    const rateLimitDoc = await rateLimitRef.get();

    const now = Date.now();
    const windowMs = windowMinutes * 60 * 1000;

    if (rateLimitDoc.exists) {
        const data = rateLimitDoc.data()!;
        const resetTime = data.resetAt?.toMillis() || 0;

        if (now < resetTime) {
            // Within window
            if (data.attempts >= maxAttempts) {
                throw new functions.https.HttpsError(
                    'resource-exhausted',
                    `Rate limit exceeded. Try again in ${Math.ceil((resetTime - now) / 60000)} minutes.`
                );
            }

            // Increment attempts
            await rateLimitRef.update({
                attempts: admin.firestore.FieldValue.increment(1)
            });
        } else {
            // Window expired, reset
            await rateLimitRef.set({
                attempts: 1,
                resetAt: admin.firestore.Timestamp.fromMillis(now + windowMs)
            });
        }
    } else {
        // First attempt
        await rateLimitRef.set({
            attempts: 1,
            resetAt: admin.firestore.Timestamp.fromMillis(now + windowMs)
        });
    }
}

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
exports.updatePrivacySettings = exports.managePaymentMethod = exports.manageAddress = exports.deleteAccount = exports.updateTechnicianProfile = exports.updateUserProfile = exports.submitSupportRequest = exports.submitServiceRating = exports.cancelBooking = exports.onBookingCompletedAwardReferral = exports.validateReferralCode = void 0;
const functions = __importStar(require("firebase-functions"));
const admin = __importStar(require("firebase-admin"));
const config_1 = require("./shared/config");
const utils_1 = require("./shared/utils");
const security_1 = require("./shared/security");
// ==========================================
// REFERRAL SYSTEM
// ==========================================
exports.validateReferralCode = functions
    .region('asia-south1')
    .https.onCall((0, security_1.secureCallable)(async (data, context) => {
    console.log('✅ [validateReferralCode] Auth UID:', context.auth?.uid);
    if (!context.auth) {
        console.error('❌ [validateReferralCode] context.auth is NULL');
        throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }
    const { code } = data;
    if (!code)
        throw new functions.https.HttpsError('invalid-argument', 'Referral code is required');
    // Check if the code belongs to another user
    const userQuery = await config_1.db.collection('customers').where('referralCode', '==', code).limit(1).get();
    if (userQuery.empty) {
        throw new functions.https.HttpsError('not-found', 'Invalid referral code');
    }
    const referrer = userQuery.docs[0];
    if (referrer.id === context.auth.uid) {
        throw new functions.https.HttpsError('invalid-argument', 'You cannot use your own referral code');
    }
    return {
        valid: true,
        referrerId: referrer.id,
        referrerName: referrer.data().name || 'A user'
    };
}));
// Trigger referral award on first successful booking completion
exports.onBookingCompletedAwardReferral = functions
    .region('asia-south1')
    .firestore.document('bookings/{bookingId}')
    .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();
    if (before.status !== 'completed' && after.status === 'completed') {
        const customerId = after.customerId;
        const customerRef = config_1.db.collection('customers').doc(customerId);
        const customerDoc = await customerRef.get();
        const customerData = customerDoc.data();
        if (customerData?.referredBy && !customerData?.referralRewardClaimed) {
            const referrerId = customerData.referredBy;
            const bonusAmount = 50; // Example: ₹50 bonus
            try {
                await config_1.db.runTransaction(async (t) => {
                    const referrerRef = config_1.db.collection('customers').doc(referrerId);
                    const referrerDoc = await t.get(referrerRef);
                    if (referrerDoc.exists) {
                        // Credit Referrer
                        t.update(referrerRef, {
                            walletBalance: admin.firestore.FieldValue.increment(bonusAmount),
                            updatedAt: admin.firestore.FieldValue.serverTimestamp()
                        });
                        t.set(referrerRef.collection('wallet_transactions').doc(), {
                            type: 'credit',
                            amount: bonusAmount,
                            description: `Referral bonus for inviting ${customerData.name || 'a friend'}`,
                            createdAt: admin.firestore.FieldValue.serverTimestamp(),
                            status: 'completed'
                        });
                        // Credit Customer
                        t.update(customerRef, {
                            walletBalance: admin.firestore.FieldValue.increment(bonusAmount),
                            referralRewardClaimed: true,
                            updatedAt: admin.firestore.FieldValue.serverTimestamp()
                        });
                        t.set(customerRef.collection('wallet_transactions').doc(), {
                            type: 'credit',
                            amount: bonusAmount,
                            description: `Welcome bonus for using referral code`,
                            createdAt: admin.firestore.FieldValue.serverTimestamp(),
                            status: 'completed'
                        });
                    }
                });
                console.log(`Referral reward processed for ${customerId} referred by ${referrerId}`);
            }
            catch (e) {
                console.error('Failed to process referral reward:', e);
            }
        }
    }
});
// ==========================================
// BOOKING CANCELLATION
// ==========================================
exports.cancelBooking = functions
    .region('asia-south1')
    .https.onCall((0, security_1.secureCallable)(async (data, context) => {
    console.log('✅ [cancelBooking] Auth UID:', context.auth?.uid);
    if (!context.auth) {
        console.error('❌ [cancelBooking] context.auth is NULL');
        throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }
    const { bookingId, reason } = data;
    const bookingRef = config_1.db.collection('bookings').doc(bookingId);
    const bookingDoc = await bookingRef.get();
    if (!bookingDoc.exists)
        throw new functions.https.HttpsError('not-found', 'Booking not found');
    const booking = bookingDoc.data();
    if (booking.customerId !== context.auth.uid) {
        throw new functions.https.HttpsError('permission-denied', 'You can only cancel your own bookings');
    }
    const nonCancellableStatus = ['completed', 'cancelled', 'refunded'];
    if (nonCancellableStatus.includes(booking.status)) {
        throw new functions.https.HttpsError('failed-precondition', `Booking cannot be cancelled in status: ${booking.status}`);
    }
    // Cancellation Rules:
    // 1. If status is 'started', cannot cancel.
    if (booking.status === 'started') {
        throw new functions.https.HttpsError('failed-precondition', 'Cannot cancel a job that has already started');
    }
    await config_1.db.runTransaction(async (t) => {
        t.update(bookingRef, {
            status: 'cancelled',
            cancellationReason: (0, security_1.sanitize)(reason) || 'Cancelled by customer',
            cancelledBy: 'customer',
            updatedAt: admin.firestore.FieldValue.serverTimestamp()
        });
        // Release the slot if assigned
        if (booking.assignedTechnicianId && booking.slotId) {
            const slotRef = config_1.db.collection('availability').doc(booking.assignedTechnicianId).collection('slots').doc(booking.slotId);
            t.update(slotRef, {
                isAvailable: true,
                lockedBy: null,
                lockedAt: null
            });
        }
        // Refund to wallet if paid?
        if (booking.paymentStatus === 'paid') {
            const customerRef = config_1.db.collection('customers').doc(context.auth.uid);
            t.update(customerRef, {
                walletBalance: admin.firestore.FieldValue.increment(booking.finalAmount),
                updatedAt: admin.firestore.FieldValue.serverTimestamp()
            });
            t.set(customerRef.collection('wallet_transactions').doc(), {
                type: 'credit',
                amount: booking.finalAmount,
                description: `Refund for cancelled booking ${bookingId}`,
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
                status: 'completed'
            });
            t.update(bookingRef, { paymentStatus: 'refunded' });
        }
    });
    return { success: true };
}));
const notifications_1 = require("./shared/notifications");
// ... (skipping referral and cancellation for now, targeting submitServiceRating)
exports.submitServiceRating = functions
    .region('asia-south1')
    .https.onCall((0, security_1.secureCallable)(async (data, context) => {
    console.log('✅ [submitServiceRating] Auth UID:', context.auth?.uid);
    if (!context.auth) {
        console.error('❌ [submitServiceRating] context.auth is NULL');
        throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }
    const { bookingId, rating, comment, tags } = data; // tags is string[]
    const customerId = context.auth.uid;
    // 0. RATE LIMITING (Harden)
    await (0, utils_1.checkRateLimit)(customerId, 'submit_rating', 5, 60);
    if (!bookingId || typeof rating !== 'number' || rating < 1 || rating > 5) {
        throw new functions.https.HttpsError('invalid-argument', 'Invalid rating data');
    }
    const bookingRef = config_1.db.collection('bookings').doc(bookingId);
    const bookingDoc = await bookingRef.get();
    if (!bookingDoc.exists)
        throw new functions.https.HttpsError('not-found', 'Booking not found');
    const booking = bookingDoc.data();
    if (booking.customerId !== context.auth.uid) {
        throw new functions.https.HttpsError('permission-denied', 'You can only rate your own bookings');
    }
    if (booking.status !== 'completed') {
        throw new functions.https.HttpsError('failed-precondition', 'You can only rate completed bookings');
    }
    if (booking.paymentStatus !== 'paid') {
        throw new functions.https.HttpsError('failed-precondition', 'Payment must be completed before rating');
    }
    if (booking.isRated) {
        throw new functions.https.HttpsError('already-exists', 'You have already rated this booking');
    }
    const techId = booking.assignedTechnicianId;
    if (!techId) {
        throw new functions.https.HttpsError('failed-precondition', 'No technician assigned to this booking');
    }
    const reviewId = config_1.db.collection('reviews').doc().id;
    await config_1.db.runTransaction(async (t) => {
        // 2. Write Review
        const reviewRef = config_1.db.collection('reviews').doc(reviewId);
        t.set(reviewRef, {
            id: reviewId,
            bookingId,
            customerId: context.auth.uid,
            customerName: booking.customerName || 'Customer',
            technicianId: techId,
            serviceIds: booking.services?.map((s) => s.id) || [booking.serviceId],
            serviceTitle: booking.serviceTitle,
            rating,
            tags: tags || [],
            reviewText: (0, security_1.sanitize)(comment) || '',
            createdAt: admin.firestore.FieldValue.serverTimestamp()
        });
        // 3. Mark Booking as Rated
        t.update(bookingRef, {
            isRated: true,
            ratingId: reviewId,
            updatedAt: admin.firestore.FieldValue.serverTimestamp()
        });
        // 4. Update Technician Aggregates
        const techRef = config_1.db.collection('technicians').doc(techId);
        const techDoc = await t.get(techRef);
        if (techDoc.exists) {
            const techData = techDoc.data();
            const totalRatings = (techData.totalRatings || 0) + 1;
            const currentAvg = techData.avgRating || 0;
            const newAvg = ((currentAvg * (totalRatings - 1)) + rating) / totalRatings;
            const breakdown = techData.ratingBreakdown || { "1": 0, "2": 0, "3": 0, "4": 0, "5": 0 };
            const starKey = rating.toString();
            breakdown[starKey] = (breakdown[starKey] || 0) + 1;
            t.update(techRef, {
                avgRating: newAvg,
                totalRatings: totalRatings,
                ratingBreakdown: breakdown,
                updatedAt: admin.firestore.FieldValue.serverTimestamp()
            });
        }
        // 5. Trigger Dispute if rating <= 2
        if (rating <= 2) {
            const disputeId = config_1.db.collection('disputes').doc().id;
            t.set(config_1.db.collection('disputes').doc(disputeId), {
                id: disputeId,
                bookingId,
                reviewId,
                customerId: context.auth.uid,
                technicianId: techId,
                reason: `Low Rating Alert: ${rating} Stars`,
                comment: comment || 'No comment provided',
                status: 'open',
                adminNotes: null,
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
                updatedAt: admin.firestore.FieldValue.serverTimestamp()
            });
        }
    });
    // 6. Notifications
    try {
        await (0, notifications_1.sendPushNotification)(context.auth.uid, 'customers', {
            title: 'Thank you!',
            body: 'Your rating helps us maintain high quality standards.',
            data: { type: 'rating_submitted', bookingId }
        });
        await (0, notifications_1.sendPushNotification)(techId, 'technicians', {
            title: 'New Rating!',
            body: `You received a ${rating}-star rating for ${booking.serviceTitle}.`,
            data: { type: 'new_rating', rating: rating.toString() }
        });
        if (rating <= 2) {
            const adminSnap = await config_1.db.collection('admins').get();
            const adminNotifications = adminSnap.docs.map(adminDoc => (0, notifications_1.sendPushNotification)(adminDoc.id, 'admins', {
                title: 'Low Rating Alert ⚠️',
                body: `Booking ${bookingId} received a ${rating}-star rating. Dispute created.`,
                data: { type: 'low_rating_alert', bookingId, reviewId }
            }));
            await Promise.all(adminNotifications);
        }
    }
    catch (e) {
        console.error('Notification error:', e);
    }
    return { success: true, reviewId };
}));
// ==========================================
// SUPPORT / ASSISTANCE
// ==========================================
exports.submitSupportRequest = functions
    .region('asia-south1')
    .https.onCall((0, security_1.secureCallable)(async (data, context) => {
    console.log('✅ [submitSupportRequest] Auth UID:', context.auth?.uid);
    if (!context.auth) {
        console.error('❌ [submitSupportRequest] context.auth is NULL');
        throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }
    const { category, message } = data;
    if (!category || !message) {
        throw new functions.https.HttpsError('invalid-argument', 'Category and message are required');
    }
    const requestId = config_1.db.collection('support_requests').doc().id;
    await config_1.db.collection('support_requests').doc(requestId).set({
        id: requestId,
        userId: context.auth.uid,
        userEmail: context.auth.token.email || '',
        userName: context.auth.token.name || 'User',
        category,
        message,
        status: 'open',
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
    });
    return { success: true, requestId };
}));
// ==========================================
// ACCOUNT & PROFILE MANAGEMENT
// ==========================================
exports.updateUserProfile = functions
    .region('asia-south1')
    .https.onCall((0, security_1.secureCallable)(async (data, context) => {
    console.log('[updateUserProfile] Called', { uid: context.auth?.uid, data });
    console.log('✅ [updateUserProfile] Auth UID:', context.auth?.uid);
    if (!context.auth) {
        console.error('❌ [updateUserProfile] context.auth is NULL');
        throw new functions.https.HttpsError('unauthenticated', 'Auth required');
    }
    const uid = context.auth.uid;
    await (0, utils_1.checkRateLimit)(uid, 'update_profile', 10, 60);
    // PROTECTED FIELDS - EXPLICITLY REJECT
    const protectedFields = ['walletBalance', 'isSuspended', 'referralCode', 'referredBy', 'isApproved', 'avgRating', 'totalRatings'];
    for (const field of protectedFields) {
        if (field in data) {
            console.warn(`[updateUserProfile] Rejected protected field: ${field} for uid: ${uid}`);
            throw new functions.https.HttpsError('permission-denied', `Cannot modify protected field: ${field}`);
        }
    }
    // ALLOWED FIELDS ONLY
    const allowedKeys = [
        'name',
        'displayName',
        'email',
        'phone',
        'photoUrl',
        'isOnboarded',
        'profileCompleted',
        'district',
        'state',
        'defaultAddress',
        'latitude',
        'longitude'
    ];
    const updateData = {};
    for (const key of allowedKeys) {
        if (key in data && data[key] !== undefined && data[key] !== null) {
            const val = (0, security_1.sanitize)(data[key]);
            if (key === 'district') {
                const district = val.toString().trim();
                updateData.district = district;
                updateData.districtNormalized = district.toLowerCase();
            }
            else if (key === 'state') {
                const state = val.toString().trim();
                updateData.state = state;
                updateData.stateNormalized = state.toLowerCase();
            }
            else {
                updateData[key] = val;
            }
        }
    }
    if (Object.keys(updateData).length === 0) {
        throw new functions.https.HttpsError('invalid-argument', 'No valid fields provided for update');
    }
    const userRef = config_1.db.collection('customers').doc(uid);
    updateData.updatedAt = admin.firestore.FieldValue.serverTimestamp();
    try {
        // CRITICAL FIX: Create address with state/district if provided during signup
        if (updateData.state && updateData.district) {
            const addressesRef = userRef.collection('addresses');
            // Check if user already has a primary address
            const existingAddresses = await addressesRef.get();
            if (existingAddresses.empty) {
                // Create first address with state/district
                const addressId = addressesRef.doc().id;
                await addressesRef.doc(addressId).set({
                    id: addressId,
                    label: 'Home',
                    state: updateData.state,
                    district: updateData.district,
                    fullAddress: `${updateData.district}, ${updateData.state}`,
                    city: updateData.district,
                    isDefault: true,
                    createdAt: admin.firestore.FieldValue.serverTimestamp(),
                });
                // Set primaryAddressId on customer document
                updateData.primaryAddressId = addressId;
                console.log(`[updateUserProfile] ✅ Created address ${addressId} with location for uid: ${uid}`);
            }
            else {
                // Update existing addresses with state/district if missing
                const batch = config_1.db.batch();
                let primaryAddressId = updateData.primaryAddressId;
                for (const doc of existingAddresses.docs) {
                    const addressData = doc.data();
                    if (!addressData.state || !addressData.district) {
                        batch.update(doc.ref, {
                            state: updateData.state,
                            district: updateData.district,
                        });
                        console.log(`[updateUserProfile] ✅ Updated address ${doc.id} with location`);
                    }
                    // Set first address as primary if not set
                    if (!primaryAddressId && addressData.isDefault) {
                        primaryAddressId = doc.id;
                    }
                }
                // If still no primary, set first address as primary
                if (!primaryAddressId && existingAddresses.docs.length > 0) {
                    primaryAddressId = existingAddresses.docs[0].id;
                    batch.update(existingAddresses.docs[0].ref, { isDefault: true });
                }
                if (primaryAddressId) {
                    updateData.primaryAddressId = primaryAddressId;
                }
                await batch.commit();
            }
        }
        await userRef.set(updateData, { merge: true });
        console.log(`[updateUserProfile] ✅ Success for uid: ${uid}`);
    }
    catch (error) {
        console.error(`[updateUserProfile] ❌ Firestore error for uid: ${uid}:`, error);
        throw new functions.https.HttpsError('internal', 'Failed to update profile');
    }
    return { success: true };
}));
exports.updateTechnicianProfile = functions
    .region('asia-south1')
    .https.onCall((0, security_1.secureCallable)(async (data, context) => {
    console.log('✅ [updateTechnicianProfile] Auth UID:', context.auth?.uid);
    if (!context.auth) {
        console.error('❌ [updateTechnicianProfile] context.auth is NULL');
        throw new functions.https.HttpsError('unauthenticated', 'Auth required');
    }
    const uid = context.auth.uid;
    // 0. RATE LIMITING (Harden)
    await (0, utils_1.checkRateLimit)(uid, 'update_tech_profile', 10, 60);
    const allowedKeys = ['name', 'email', 'phone', 'photoUrl', 'skills', 'bio', 'experience', 'isOnline', 'geo'];
    const updateData = {};
    Object.keys(data).forEach(key => {
        if (allowedKeys.includes(key)) {
            if (key === 'district' && data[key]) {
                const district = data[key].toString().trim();
                updateData['district'] = district;
                updateData['districtNormalized'] = district.toLowerCase();
            }
            else {
                updateData[key] = data[key];
            }
        }
    });
    if (Object.keys(updateData).length === 0) {
        throw new functions.https.HttpsError('invalid-argument', 'No valid fields provided for update');
    }
    updateData.updatedAt = admin.firestore.FieldValue.serverTimestamp();
    await config_1.db.collection('technicians').doc(uid).set(updateData, { merge: true });
    return { success: true };
}));
exports.deleteAccount = functions
    .region('asia-south1')
    .https.onCall((0, security_1.secureCallable)(async (data, context) => {
    console.log('✅ [deleteAccount] Auth UID:', context.auth?.uid);
    if (!context.auth) {
        console.error('❌ [deleteAccount] context.auth is NULL');
        throw new functions.https.HttpsError('unauthenticated', 'Auth required');
    }
    const uid = context.auth.uid;
    // 1. Delete Firestore Data
    await config_1.db.collection('customers').doc(uid).delete();
    // 2. Disable/Delete Auth User
    await admin.auth().deleteUser(uid);
    return { success: true };
}));
exports.manageAddress = functions
    .region('asia-south1')
    .https.onCall((0, security_1.secureCallable)(async (data, context) => {
    console.log('✅ [manageAddress] Auth UID:', context.auth?.uid);
    if (!context.auth) {
        console.error('❌ [manageAddress] context.auth is NULL');
        throw new functions.https.HttpsError('unauthenticated', 'Auth required');
    }
    const uid = context.auth.uid;
    const { action, addressId, addressData } = data; // action: 'add', 'edit', 'delete', 'setDefault'
    const addrRef = config_1.db.collection('customers').doc(uid).collection('addresses');
    if (action === 'add') {
        const newId = addrRef.doc().id;
        await addrRef.doc(newId).set({
            ...addressData,
            id: newId,
            createdAt: admin.firestore.FieldValue.serverTimestamp()
        });
    }
    else if (action === 'edit' && addressId) {
        await addrRef.doc(addressId).update(addressData);
    }
    else if (action === 'delete' && addressId) {
        await addrRef.doc(addressId).delete();
    }
    else if (action === 'setDefault' && addressId) {
        const batch = config_1.db.batch();
        const all = await addrRef.get();
        all.docs.forEach(doc => {
            batch.update(doc.ref, { isDefault: doc.id === addressId });
        });
        batch.update(config_1.db.collection('customers').doc(uid), { defaultAddress: addressId });
        await batch.commit();
    }
    return { success: true };
}));
exports.managePaymentMethod = functions
    .region('asia-south1')
    .https.onCall((0, security_1.secureCallable)(async (data, context) => {
    console.log('✅ [managePaymentMethod] Auth UID:', context.auth?.uid);
    if (!context.auth) {
        console.error('❌ [managePaymentMethod] context.auth is NULL');
        throw new functions.https.HttpsError('unauthenticated', 'Auth required');
    }
    const uid = context.auth.uid;
    const { action, methodId, methodData } = data;
    const pmRef = config_1.db.collection('customers').doc(uid).collection('payment_methods');
    if (action === 'add') {
        const newId = pmRef.doc().id;
        await pmRef.doc(newId).set({ ...methodData, id: newId, createdAt: admin.firestore.FieldValue.serverTimestamp() });
    }
    else if (action === 'delete' && methodId) {
        await pmRef.doc(methodId).delete();
    }
    else if (action === 'setDefault' && methodId) {
        const batch = config_1.db.batch();
        const all = await pmRef.get();
        all.docs.forEach(doc => batch.update(doc.ref, { isDefault: doc.id === methodId }));
        await batch.commit();
    }
    return { success: true };
}));
exports.updatePrivacySettings = functions
    .region('asia-south1')
    .https.onCall((0, security_1.secureCallable)(async (data, context) => {
    console.log('✅ [updatePrivacySettings] Auth UID:', context.auth?.uid);
    if (!context.auth) {
        console.error('❌ [updatePrivacySettings] context.auth is NULL');
        throw new functions.https.HttpsError('unauthenticated', 'Auth required');
    }
    const uid = context.auth.uid;
    await config_1.db.collection('customers').doc(uid).set({ privacy: data }, { merge: true });
    return { success: true };
}));
//# sourceMappingURL=customer_features.js.map
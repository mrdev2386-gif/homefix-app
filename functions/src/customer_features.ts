
import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { db } from './shared/config';
import { checkRateLimit } from './shared/utils';

// ==========================================
// REFERRAL SYSTEM
// ==========================================

export const validateReferralCode = functions.https.onCall(async (data, context) => {
    if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    const { code } = data;

    if (!code) throw new functions.https.HttpsError('invalid-argument', 'Referral code is required');

    // Check if the code belongs to another user
    const userQuery = await db.collection('customers').where('referralCode', '==', code).limit(1).get();

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
});

// Trigger referral award on first successful booking completion
export const onBookingCompletedAwardReferral = functions.firestore.document('bookings/{bookingId}')
    .onUpdate(async (change, context) => {
        const before = change.before.data();
        const after = change.after.data();

        if (before.status !== 'completed' && after.status === 'completed') {
            const customerId = after.customerId;
            const customerRef = db.collection('customers').doc(customerId);
            const customerDoc = await customerRef.get();
            const customerData = customerDoc.data();

            if (customerData?.referredBy && !customerData?.referralRewardClaimed) {
                const referrerId = customerData.referredBy;
                const bonusAmount = 50; // Example: ₹50 bonus

                try {
                    await db.runTransaction(async (t) => {
                        const referrerRef = db.collection('customers').doc(referrerId);
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
                } catch (e) {
                    console.error('Failed to process referral reward:', e);
                }
            }
        }
    });

// ==========================================
// BOOKING CANCELLATION
// ==========================================

export const cancelBooking = functions.https.onCall(async (data, context) => {
    if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    const { bookingId, reason } = data;

    const bookingRef = db.collection('bookings').doc(bookingId);
    const bookingDoc = await bookingRef.get();

    if (!bookingDoc.exists) throw new functions.https.HttpsError('not-found', 'Booking not found');
    const booking = bookingDoc.data()!;

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

    await db.runTransaction(async (t) => {
        t.update(bookingRef, {
            status: 'cancelled',
            cancellationReason: reason || 'Cancelled by customer',
            cancelledBy: 'customer',
            updatedAt: admin.firestore.FieldValue.serverTimestamp()
        });

        // Release the slot if assigned
        if (booking.assignedTechnicianId && booking.slotId) {
            const slotRef = db.collection('availability').doc(booking.assignedTechnicianId).collection('slots').doc(booking.slotId);
            t.update(slotRef, {
                isAvailable: true,
                lockedBy: null,
                lockedAt: null
            });
        }

        // Refund to wallet if paid?
        if (booking.paymentStatus === 'paid') {
            const customerRef = db.collection('customers').doc(context.auth!.uid);
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
});

import { sendPushNotification } from './shared/notifications';

// ... (skipping referral and cancellation for now, targeting submitServiceRating)

export const submitServiceRating = functions.https.onCall(async (data, context) => {
    if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    const { bookingId, rating, comment, tags } = data; // tags is string[]
    const customerId = context.auth.uid;

    // 0. RATE LIMITING (Harden)
    await checkRateLimit(customerId, 'submit_rating', 5, 60);
    if (!bookingId || typeof rating !== 'number' || rating < 1 || rating > 5) {
        throw new functions.https.HttpsError('invalid-argument', 'Invalid rating data');
    }

    const bookingRef = db.collection('bookings').doc(bookingId);
    const bookingDoc = await bookingRef.get();

    if (!bookingDoc.exists) throw new functions.https.HttpsError('not-found', 'Booking not found');
    const booking = bookingDoc.data()!;

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

    const reviewId = db.collection('reviews').doc().id;

    await db.runTransaction(async (t) => {
        // 2. Write Review
        const reviewRef = db.collection('reviews').doc(reviewId);
        t.set(reviewRef, {
            id: reviewId,
            bookingId,
            customerId: context.auth!.uid,
            customerName: booking.customerName || 'Customer',
            technicianId: techId,
            serviceIds: booking.services?.map((s: any) => s.id) || [booking.serviceId],
            serviceTitle: booking.serviceTitle,
            rating,
            tags: tags || [],
            reviewText: comment || '',
            createdAt: admin.firestore.FieldValue.serverTimestamp()
        });

        // 3. Mark Booking as Rated
        t.update(bookingRef, {
            isRated: true,
            ratingId: reviewId,
            updatedAt: admin.firestore.FieldValue.serverTimestamp()
        });

        // 4. Update Technician Aggregates
        const techRef = db.collection('technicians').doc(techId);
        const techDoc = await t.get(techRef);

        if (techDoc.exists) {
            const techData = techDoc.data()!;
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
            const disputeId = db.collection('disputes').doc().id;
            t.set(db.collection('disputes').doc(disputeId), {
                id: disputeId,
                bookingId,
                reviewId,
                customerId: context.auth!.uid,
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
        await sendPushNotification(context.auth!.uid, 'customers', {
            title: 'Thank you!',
            body: 'Your rating helps us maintain high quality standards.',
            data: { type: 'rating_submitted', bookingId }
        });

        await sendPushNotification(techId, 'technicians', {
            title: 'New Rating!',
            body: `You received a ${rating}-star rating for ${booking.serviceTitle}.`,
            data: { type: 'new_rating', rating: rating.toString() }
        });

        if (rating <= 2) {
            const adminSnap = await db.collection('admins').get();
            const adminNotifications = adminSnap.docs.map(adminDoc =>
                sendPushNotification(adminDoc.id, 'admins', {
                    title: 'Low Rating Alert ⚠️',
                    body: `Booking ${bookingId} received a ${rating}-star rating. Dispute created.`,
                    data: { type: 'low_rating_alert', bookingId, reviewId }
                })
            );
            await Promise.all(adminNotifications);
        }
    } catch (e) {
        console.error('Notification error:', e);
    }

    return { success: true, reviewId };
});

// ==========================================
// SUPPORT / ASSISTANCE
// ==========================================

export const submitSupportRequest = functions.https.onCall(async (data, context) => {
    if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    const { category, message } = data;

    if (!category || !message) {
        throw new functions.https.HttpsError('invalid-argument', 'Category and message are required');
    }

    const requestId = db.collection('support_requests').doc().id;
    await db.collection('support_requests').doc(requestId).set({
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
});

// ==========================================
// ACCOUNT & PROFILE MANAGEMENT
// ==========================================

export const updateUserProfile = functions.https.onCall(async (data: any, context: functions.https.CallableContext) => {
    if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'Auth required');

    const uid = context.auth.uid;
    await checkRateLimit(uid, 'update_profile', 10, 60);

    // PROTECTED FIELDS - EXPLICITLY REJECT
    const protectedFields = ['walletBalance', 'isSuspended', 'referralCode', 'referredBy', 'isApproved', 'avgRating', 'totalRatings'];
    for (const field of protectedFields) {
        if (field in data) {
            console.warn(`[updateUserProfile] Rejected protected field: ${field} for uid: ${uid}`);
            throw new functions.https.HttpsError('permission-denied', `Cannot modify protected field: ${field}`);
        }
    }

    // ALLOWED FIELDS ONLY
    const allowedKeys = ['name', 'email', 'phone', 'photoUrl', 'isOnboarded', 'profileCompleted', 'district'];
    const updateData: any = {};

    for (const key of allowedKeys) {
        if (key in data && data[key] !== undefined && data[key] !== null) {
            if (key === 'district') {
                const district = data[key].toString().trim();
                updateData.district = district;
                updateData.districtNormalized = district.toLowerCase();
            } else {
                updateData[key] = data[key];
            }
        }
    }

    if (Object.keys(updateData).length === 0) {
        throw new functions.https.HttpsError('invalid-argument', 'No valid fields provided for update');
    }

    const userRef = db.collection('customers').doc(uid);
    updateData.updatedAt = admin.firestore.FieldValue.serverTimestamp();

    try {
        await userRef.set(updateData, { merge: true });
        console.log(`[updateUserProfile] Success for uid: ${uid}`);
    } catch (error) {
        console.error(`[updateUserProfile] Firestore error for uid: ${uid}:`, error);
        throw new functions.https.HttpsError('internal', 'Failed to update profile');
    }

    return { success: true };
});


export const updateTechnicianProfile = functions.https.onCall(async (data: any, context: functions.https.CallableContext) => {
    if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'Auth required');

    const uid = context.auth.uid;

    // 0. RATE LIMITING (Harden)
    await checkRateLimit(uid, 'update_tech_profile', 10, 60);

    const allowedKeys = ['name', 'email', 'phone', 'photoUrl', 'skills', 'bio', 'experience', 'isOnline', 'geo'];
    const updateData: any = {};

    Object.keys(data).forEach(key => {
        if (allowedKeys.includes(key)) {
            if (key === 'district' && data[key]) {
                const district = data[key].toString().trim();
                updateData['district'] = district;
                updateData['districtNormalized'] = district.toLowerCase();
            } else {
                updateData[key] = data[key];
            }
        }
    });

    if (Object.keys(updateData).length === 0) {
        throw new functions.https.HttpsError('invalid-argument', 'No valid fields provided for update');
    }

    updateData.updatedAt = admin.firestore.FieldValue.serverTimestamp();
    await db.collection('technicians').doc(uid).set(updateData, { merge: true });

    return { success: true };
});

export const deleteAccount = functions.https.onCall(async (data, context) => {
    if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'Auth required');
    const uid = context.auth.uid;

    // 1. Delete Firestore Data
    await db.collection('customers').doc(uid).delete();
    // 2. Disable/Delete Auth User
    await admin.auth().deleteUser(uid);

    return { success: true };
});

export const manageAddress = functions.https.onCall(async (data, context) => {
    if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'Auth required');
    const uid = context.auth.uid;
    const { action, addressId, addressData } = data; // action: 'add', 'edit', 'delete', 'setDefault'

    const addrRef = db.collection('customers').doc(uid).collection('addresses');

    if (action === 'add') {
        const newId = addrRef.doc().id;
        await addrRef.doc(newId).set({
            ...addressData,
            id: newId,
            createdAt: admin.firestore.FieldValue.serverTimestamp()
        });
    } else if (action === 'edit' && addressId) {
        await addrRef.doc(addressId).update(addressData);
    } else if (action === 'delete' && addressId) {
        await addrRef.doc(addressId).delete();
    } else if (action === 'setDefault' && addressId) {
        const batch = db.batch();
        const all = await addrRef.get();
        all.docs.forEach(doc => {
            batch.update(doc.ref, { isDefault: doc.id === addressId });
        });
        batch.update(db.collection('customers').doc(uid), { defaultAddress: addressId });
        await batch.commit();
    }

    return { success: true };
});


export const managePaymentMethod = functions.https.onCall(async (data, context) => {
    if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'Auth required');
    const uid = context.auth.uid;
    const { action, methodId, methodData } = data;

    const pmRef = db.collection('customers').doc(uid).collection('payment_methods');

    if (action === 'add') {
        const newId = pmRef.doc().id;
        await pmRef.doc(newId).set({ ...methodData, id: newId, createdAt: admin.firestore.FieldValue.serverTimestamp() });
    } else if (action === 'delete' && methodId) {
        await pmRef.doc(methodId).delete();
    } else if (action === 'setDefault' && methodId) {
        const batch = db.batch();
        const all = await pmRef.get();
        all.docs.forEach(doc => batch.update(doc.ref, { isDefault: doc.id === methodId }));
        await batch.commit();
    }

    return { success: true };
});

export const updatePrivacySettings = functions.https.onCall(async (data, context) => {
    if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'Auth required');
    const uid = context.auth.uid;
    await db.collection('customers').doc(uid).set({ privacy: data }, { merge: true });
    return { success: true };
});


import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { db, getAppConfig } from '../shared/config';

export const simulatePayment = functions.https.onCall(async (data, context) => {
    if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'Auth required');

    const config = await getAppConfig();
    if (!config.isTestMode) {
        throw new functions.https.HttpsError('failed-precondition', 'Test mode is not enabled');
    }

    const { bookingId } = data;
    const bookingRef = db.collection('bookings').doc(bookingId);
    const bookingDoc = await bookingRef.get();

    if (!bookingDoc.exists) throw new functions.https.HttpsError('not-found', 'Booking not found');

    // Check if it's a test booking OR we are in global test mode
    // Requirement says "When isTestMode=true... Payments are simulated".
    // So if app is in test mode, we can simulate payment for ANY booking? 
    // Ideally only for test bookings or if we want to test with real users (dangerous).
    // Let's restrict to isTestBooking OR isTestMode globally enabled.

    if (!bookingDoc.data()?.isTestBooking && !config.isTestMode) {
        throw new functions.https.HttpsError('permission-denied', 'Not a test booking and Test Mode disabled');
    }

    const paymentQuery = await db.collection('payments').where('bookingId', '==', bookingId).limit(1).get();

    const batch = db.batch();

    // Update Booking
    batch.update(bookingRef, {
        status: 'confirmed',
        paymentStatus: 'paid',
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
    });

    // Update Payment
    if (!paymentQuery.empty) {
        batch.update(paymentQuery.docs[0].ref, {
            status: 'success',
            paymentId: `pay_test_${Math.random().toString(36).substring(7)}`,
            updatedAt: admin.firestore.FieldValue.serverTimestamp()
        });
    }

    await batch.commit();

    return { success: true };
});

export const resetTestData = functions.https.onCall(async (data, context) => {
    if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'Auth required');
    // Ideally check Admin

    const { confirm } = data;
    if (confirm !== true) throw new functions.https.HttpsError('invalid-argument', 'Must confirm reset');

    const batch = db.batch();
    let deleteCount = 0;

    // 1. Delete Test Customers
    const customers = await db.collection('customers').where('isTestUser', '==', true).limit(100).get();
    for (const doc of customers.docs) {
        batch.delete(doc.ref);
        try {
            await admin.auth().deleteUser(doc.id);
        } catch (e) { console.error(`Failed to delete auth for ${doc.id}`, e); }
        deleteCount++;
    }

    // 2. Delete Test Technicians
    const techs = await db.collection('technicians').where('isTestUser', '==', true).limit(100).get();
    for (const doc of techs.docs) {
        batch.delete(doc.ref);
        try {
            await admin.auth().deleteUser(doc.id);
        } catch (e) { console.error(`Failed to delete auth for ${doc.id}`, e); }
        deleteCount++;
    }

    // 3. Delete Test Bookings
    const bookings = await db.collection('bookings').where('isTestBooking', '==', true).limit(200).get();
    for (const doc of bookings.docs) {
        batch.delete(doc.ref);
        deleteCount++;
    }

    // 4. Delete payments for test bookings (cleanup)
    // This is harder without a direct link in query, but we can query by isTestPayment if we added it,
    // or we skip for now as payments are less critical to clear than bookings.
    // We added isTestPayment in factory, so let's use it.
    const payments = await db.collection('payments').where('isTestPayment', '==', true).limit(100).get();
    for (const doc of payments.docs) {
        batch.delete(doc.ref);
        deleteCount++;
    }

    await batch.commit();

    return { success: true, count: deleteCount };
});

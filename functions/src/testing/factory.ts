
import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { db } from '../shared/config';

// Helper to create a random string
const randomString = (length: number) => Math.random().toString(36).substring(2, 2 + length);

export const createTestCustomer = functions.https.onCall(async (data, context) => {
    if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'Auth required');

    const { name, email, phone } = data;
    const password = 'testuser123';

    try {
        const userRecord = await admin.auth().createUser({
            email,
            password,
            displayName: name,
            emailVerified: true
        });

        await db.collection('customers').doc(userRecord.uid).set({
            uid: userRecord.uid,
            name,
            email,
            phone: phone || '+910000000000',
            isTestUser: true,
            isOnboarded: true, // Allow bypassing onboarding for tests
            walletBalance: 1000,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            updatedAt: admin.firestore.FieldValue.serverTimestamp()
        });

        return { uid: userRecord.uid, email, password };
    } catch (error: any) {
        throw new functions.https.HttpsError('internal', error.message);
    }
});

export const createTestTechnician = functions.https.onCall(async (data, context) => {
    if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'Auth required');

    const { name, email, phone, skills } = data;
    const password = 'testtech123';

    try {
        const userRecord = await admin.auth().createUser({
            email,
            password,
            displayName: name,
            emailVerified: true
        });

        await db.collection('technicians').doc(userRecord.uid).set({
            uid: userRecord.uid,
            name,
            email,
            phone: phone || '+919999999999',
            skills: skills || ['plumbing', 'electrician'], // Standardized skills
            isTestUser: true,
            isVerified: true,
            kycStatus: 'approved',
            rating: 4.8,
            jobsDone: 0,
            walletBalance: 500,
            isOnline: true,
            geo: { lat: 12.9716, lng: 77.5946 }, // Bangalore default
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            updatedAt: admin.firestore.FieldValue.serverTimestamp()
        });

        // Initialize availability for today
        const today = new Date().toISOString().split('T')[0];
        const slotsRef = db.collection('technicians').doc(userRecord.uid).collection('availability').doc(today);
        await slotsRef.set({ date: today, isWorkingDay: true });

        const slotsSub = slotsRef.collection('slots');
        const times = ['09:00', '11:00', '13:00', '15:00'];
        for (const time of times) {
            await slotsSub.doc(time).set({
                time,
                isAvailable: true,
                technicianId: userRecord.uid
            });
        }

        return { uid: userRecord.uid, email, password };
    } catch (error: any) {
        throw new functions.https.HttpsError('internal', error.message);
    }
});

export const generateTestBooking = functions.https.onCall(async (data, context) => {
    if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'Auth required');

    const { customerId, technicianId, serviceId, serviceTitle } = data;

    const custDoc = await db.collection('customers').doc(customerId).get();
    const techDoc = await db.collection('technicians').doc(technicianId).get();

    if (!custDoc.data()?.isTestUser || !techDoc.data()?.isTestUser) {
        throw new functions.https.HttpsError('failed-precondition', 'Both users must be test users');
    }

    const bookingId = db.collection('bookings').doc().id;
    const price = 500;

    const bookingData = {
        bookingId,
        customerId,
        customerName: custDoc.data()?.name || 'Test Customer',
        assignedTechnicianId: technicianId || null,
        serviceId: serviceId || 'test_service',
        serviceTitle: serviceTitle || 'Test Service',
        status: 'confirmed', // Set to confirmed so tech can see it
        paymentStatus: 'paid',
        price,
        finalAmount: price,
        isTestBooking: true,
        addressSnapshot: { fullAddress: '123 Test Street, Bangalore' },
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        scheduledAt: admin.firestore.FieldValue.serverTimestamp(),
        scheduledTime: '10:00',
        razorpayOrderId: `order_test_${randomString(10)}`
    };

    await db.collection('bookings').doc(bookingId).set(bookingData);

    await db.collection('payments').add({
        bookingId,
        customerId,
        amount: price,
        status: 'success',
        orderId: bookingData.razorpayOrderId,
        isTestPayment: true,
        createdAt: admin.firestore.FieldValue.serverTimestamp()
    });

    return { bookingId };
});

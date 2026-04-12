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
exports.generateTestBooking = exports.createTestTechnician = exports.createTestCustomer = void 0;
const functions = __importStar(require("firebase-functions"));
const admin = __importStar(require("firebase-admin"));
const config_1 = require("../shared/config");
// Helper to create a random string
const randomString = (length) => Math.random().toString(36).substring(2, 2 + length);
exports.createTestCustomer = functions.region('asia-south1').https.onCall(async (data, context) => {
    if (!context.auth)
        throw new functions.https.HttpsError('unauthenticated', 'Auth required');
    const { name, email, phone } = data;
    const password = 'testuser123';
    try {
        const userRecord = await admin.auth().createUser({
            email,
            password,
            displayName: name,
            emailVerified: true
        });
        await config_1.db.collection('customers').doc(userRecord.uid).set({
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
    }
    catch (error) {
        throw new functions.https.HttpsError('internal', error.message);
    }
});
exports.createTestTechnician = functions.region('asia-south1').https.onCall(async (data, context) => {
    if (!context.auth)
        throw new functions.https.HttpsError('unauthenticated', 'Auth required');
    const { name, email, phone, skills } = data;
    const password = 'testtech123';
    try {
        const userRecord = await admin.auth().createUser({
            email,
            password,
            displayName: name,
            emailVerified: true
        });
        await config_1.db.collection('technicians').doc(userRecord.uid).set({
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
        const slotsRef = config_1.db.collection('technicians').doc(userRecord.uid).collection('availability').doc(today);
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
    }
    catch (error) {
        throw new functions.https.HttpsError('internal', error.message);
    }
});
exports.generateTestBooking = functions.region('asia-south1').https.onCall(async (data, context) => {
    if (!context.auth)
        throw new functions.https.HttpsError('unauthenticated', 'Auth required');
    const { customerId, technicianId, serviceId, serviceTitle } = data;
    const custDoc = await config_1.db.collection('customers').doc(customerId).get();
    const techDoc = await config_1.db.collection('technicians').doc(technicianId).get();
    if (!custDoc.data()?.isTestUser || !techDoc.data()?.isTestUser) {
        throw new functions.https.HttpsError('failed-precondition', 'Both users must be test users');
    }
    const bookingId = config_1.db.collection('bookings').doc().id;
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
    await config_1.db.collection('bookings').doc(bookingId).set(bookingData);
    await config_1.db.collection('payments').add({
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
//# sourceMappingURL=factory.js.map
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
exports.resetTestData = exports.simulatePayment = void 0;
const functions = __importStar(require("firebase-functions"));
const admin = __importStar(require("firebase-admin"));
const config_1 = require("../shared/config");
exports.simulatePayment = functions.region('asia-south1').https.onCall(async (data, context) => {
    if (!context.auth)
        throw new functions.https.HttpsError('unauthenticated', 'Auth required');
    const config = await (0, config_1.getAppConfig)();
    if (!config.isTestMode) {
        throw new functions.https.HttpsError('failed-precondition', 'Test mode is not enabled');
    }
    const { bookingId } = data;
    const bookingRef = config_1.db.collection('bookings').doc(bookingId);
    const bookingDoc = await bookingRef.get();
    if (!bookingDoc.exists)
        throw new functions.https.HttpsError('not-found', 'Booking not found');
    // Check if it's a test booking OR we are in global test mode
    // Requirement says "When isTestMode=true... Payments are simulated".
    // So if app is in test mode, we can simulate payment for ANY booking? 
    // Ideally only for test bookings or if we want to test with real users (dangerous).
    // Let's restrict to isTestBooking OR isTestMode globally enabled.
    if (!bookingDoc.data()?.isTestBooking && !config.isTestMode) {
        throw new functions.https.HttpsError('permission-denied', 'Not a test booking and Test Mode disabled');
    }
    const paymentQuery = await config_1.db.collection('payments').where('bookingId', '==', bookingId).limit(1).get();
    const batch = config_1.db.batch();
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
exports.resetTestData = functions.region('asia-south1').https.onCall(async (data, context) => {
    if (!context.auth)
        throw new functions.https.HttpsError('unauthenticated', 'Auth required');
    // Ideally check Admin
    const { confirm } = data;
    if (confirm !== true)
        throw new functions.https.HttpsError('invalid-argument', 'Must confirm reset');
    const batch = config_1.db.batch();
    let deleteCount = 0;
    // 1. Delete Test Customers
    const customers = await config_1.db.collection('customers').where('isTestUser', '==', true).limit(100).get();
    for (const doc of customers.docs) {
        batch.delete(doc.ref);
        try {
            await admin.auth().deleteUser(doc.id);
        }
        catch (e) {
            console.error(`Failed to delete auth for ${doc.id}`, e);
        }
        deleteCount++;
    }
    // 2. Delete Test Technicians
    const techs = await config_1.db.collection('technicians').where('isTestUser', '==', true).limit(100).get();
    for (const doc of techs.docs) {
        batch.delete(doc.ref);
        try {
            await admin.auth().deleteUser(doc.id);
        }
        catch (e) {
            console.error(`Failed to delete auth for ${doc.id}`, e);
        }
        deleteCount++;
    }
    // 3. Delete Test Bookings
    const bookings = await config_1.db.collection('bookings').where('isTestBooking', '==', true).limit(200).get();
    for (const doc of bookings.docs) {
        batch.delete(doc.ref);
        deleteCount++;
    }
    // 4. Delete payments for test bookings (cleanup)
    // This is harder without a direct link in query, but we can query by isTestPayment if we added it,
    // or we skip for now as payments are less critical to clear than bookings.
    // We added isTestPayment in factory, so let's use it.
    const payments = await config_1.db.collection('payments').where('isTestPayment', '==', true).limit(100).get();
    for (const doc of payments.docs) {
        batch.delete(doc.ref);
        deleteCount++;
    }
    await batch.commit();
    return { success: true, count: deleteCount };
});
//# sourceMappingURL=actions.js.map
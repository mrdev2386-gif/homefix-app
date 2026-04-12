"use strict";
/**
 * HYBRID LIVE FLOW TEST
 *
 * Tests complete booking flow: Customer → Admin → Technician → Payment
 * Combines automated backend verification with manual UI actions
 *
 * Usage:
 * npx ts-node src/payments/hybridFlowTest.ts
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
const admin = __importStar(require("firebase-admin"));
const readline = __importStar(require("readline"));
// Initialize Firebase Admin
if (!admin.apps.length) {
    const serviceAccount = require('../../serviceAccountKey.json');
    admin.initializeApp({
        credential: admin.credential.cert(serviceAccount),
        databaseURL: 'https://homefix-aa42d.firebaseio.com'
    });
}
const db = admin.firestore();
// Terminal colors
const colors = {
    reset: '\x1b[0m',
    bright: '\x1b[1m',
    green: '\x1b[32m',
    red: '\x1b[31m',
    yellow: '\x1b[33m',
    blue: '\x1b[34m',
    cyan: '\x1b[36m',
};
const results = [];
// Helper to prompt user
const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout
});
function prompt(question) {
    return new Promise((resolve) => {
        rl.question(question, (answer) => {
            resolve(answer);
        });
    });
}
function log(message, color = 'reset') {
    console.log(`${colors[color]}${message}${colors.reset}`);
}
function logStep(stepNumber, title) {
    console.log('\n' + '='.repeat(80));
    log(`STEP ${stepNumber}: ${title}`, 'bright');
    console.log('='.repeat(80));
}
function logResult(status, message) {
    const color = status === 'PASS' ? 'green' : 'red';
    log(`${status === 'PASS' ? '✔' : '✖'} ${message}`, color);
}
async function waitForUser(action) {
    log(`\n👉 MANUAL ACTION REQUIRED:`, 'yellow');
    log(action, 'cyan');
    await prompt('\nPress ENTER when done...');
}
// ============================================================================
// TEST FUNCTIONS
// ============================================================================
async function step0_setup() {
    logStep(0, 'TEST SETUP');
    log('Using primary customer UID...', 'blue');
    // Use primary customer UID (single source of truth)
    const customerId = 'S8EAzPS1nfho2dspOxy0JJHQnJ12';
    // Verify customer exists
    const customerDoc = await db.collection('customers').doc(customerId).get();
    if (!customerDoc.exists) {
        throw new Error(`Primary customer ${customerId} not found in database`);
    }
    const customerData = customerDoc.data();
    // Get a technician
    const techniciansSnapshot = await db.collection('technicians')
        .where('status', '==', 'approved')
        .limit(1)
        .get();
    if (techniciansSnapshot.empty) {
        throw new Error('No approved technicians found');
    }
    const technicianId = techniciansSnapshot.docs[0].id;
    const technicianData = techniciansSnapshot.docs[0].data();
    // Get an active service
    const servicesSnapshot = await db.collection('services')
        .where('isActive', '==', true)
        .limit(1)
        .get();
    if (servicesSnapshot.empty) {
        throw new Error('No active services found');
    }
    const serviceId = servicesSnapshot.docs[0].id;
    const serviceData = servicesSnapshot.docs[0].data();
    log(`\nTest Configuration:`, 'green');
    log(`  Customer ID: ${customerId}`, 'cyan');
    log(`  Customer Name: ${customerData.name || 'N/A'}`, 'cyan');
    log(`  Technician ID: ${technicianId}`, 'cyan');
    log(`  Technician Name: ${technicianData.name || 'N/A'}`, 'cyan');
    log(`  Service ID: ${serviceId}`, 'cyan');
    log(`  Service Name: ${serviceData.name || 'N/A'}`, 'cyan');
    results.push({ step: 'Setup', status: 'PASS' });
    return { customerId, technicianId, serviceId };
}
async function step1_customerBooking(customerId) {
    logStep(1, 'CUSTOMER BOOKING (MANUAL)');
    await waitForUser(`1. Open customer app\n` +
        `2. Login as customer: ${customerId}\n` +
        `3. Book a service\n` +
        `4. Complete the booking form`);
}
async function step2_verifyBookingCreated(customerId) {
    logStep(2, 'VERIFY BOOKING CREATED (AUTO)');
    log('Fetching latest booking for customer...', 'blue');
    const bookingsSnapshot = await db.collection('bookings')
        .where('customerId', '==', customerId)
        .orderBy('createdAt', 'desc')
        .limit(1)
        .get();
    if (bookingsSnapshot.empty) {
        logResult('FAIL', 'No booking found for customer');
        results.push({ step: 'Booking Created', status: 'FAIL', message: 'No booking found' });
        throw new Error('Test failed: No booking created');
    }
    const bookingId = bookingsSnapshot.docs[0].id;
    const booking = bookingsSnapshot.docs[0].data();
    log(`\nBooking ID: ${bookingId}`, 'cyan');
    log(`Booking Status: ${booking.bookingStatus || booking.status}`, 'cyan');
    const actualStatus = booking.bookingStatus || booking.status;
    // Support both current and legacy status
    if (actualStatus === 'pending' || actualStatus === 'pending_admin_review') {
        logResult('PASS', `Booking created with valid initial status: "${actualStatus}"`);
        results.push({ step: 'Booking Created', status: 'PASS' });
    }
    else {
        logResult('FAIL', `Expected status "pending" or "pending_admin_review", got "${actualStatus}"`);
        results.push({ step: 'Booking Created', status: 'FAIL', message: `Wrong status: ${actualStatus}` });
    }
    return bookingId;
}
async function step3_adminApproval(bookingId) {
    logStep(3, 'ADMIN APPROVAL (MANUAL)');
    await waitForUser(`1. Open admin panel\n` +
        `2. Navigate to bookings\n` +
        `3. Find booking: ${bookingId}\n` +
        `4. Approve the booking and assign technician`);
}
async function step4_verifyAdminUpdate(bookingId) {
    logStep(4, 'VERIFY ADMIN UPDATE (AUTO)');
    log('Fetching booking after admin approval...', 'blue');
    const bookingDoc = await db.collection('bookings').doc(bookingId).get();
    if (!bookingDoc.exists) {
        logResult('FAIL', 'Booking not found');
        results.push({ step: 'Admin Approval', status: 'FAIL', message: 'Booking not found' });
        return;
    }
    const booking = bookingDoc.data();
    const status = booking.bookingStatus || booking.status;
    const technicianId = booking.technicianId;
    log(`\nBooking Status: ${status}`, 'cyan');
    log(`Technician ID: ${technicianId || 'Not assigned'}`, 'cyan');
    let passed = true;
    if (status !== 'approved_by_admin') {
        logResult('FAIL', `Expected status "approved_by_admin", got "${status}"`);
        passed = false;
    }
    else {
        logResult('PASS', 'Booking status is "approved_by_admin"');
    }
    if (!technicianId) {
        logResult('FAIL', 'Technician not assigned');
        passed = false;
    }
    else {
        logResult('PASS', 'Technician assigned');
    }
    results.push({
        step: 'Admin Approval',
        status: passed ? 'PASS' : 'FAIL',
        message: passed ? undefined : 'Status or technician assignment incorrect'
    });
}
async function step5_technicianAccept(bookingId) {
    logStep(5, 'TECHNICIAN ACCEPT (MANUAL)');
    await waitForUser(`1. Open technician app\n` +
        `2. Login as assigned technician\n` +
        `3. Find booking: ${bookingId}\n` +
        `4. Accept the booking`);
}
async function step6_verifyTechnicianAccept(bookingId) {
    logStep(6, 'VERIFY TECHNICIAN ACCEPT (AUTO)');
    log('Fetching booking after technician acceptance...', 'blue');
    const bookingDoc = await db.collection('bookings').doc(bookingId).get();
    const booking = bookingDoc.data();
    const status = booking.bookingStatus || booking.status;
    log(`\nBooking Status: ${status}`, 'cyan');
    if (status === 'technician_accepted' || status === 'confirmed') {
        logResult('PASS', `Booking status is "${status}"`);
        results.push({ step: 'Technician Accept', status: 'PASS' });
    }
    else {
        logResult('FAIL', `Expected status "technician_accepted" or "confirmed", got "${status}"`);
        results.push({ step: 'Technician Accept', status: 'FAIL', message: `Wrong status: ${status}` });
    }
}
async function step7_serviceComplete(bookingId) {
    logStep(7, 'SERVICE COMPLETE (MANUAL)');
    await waitForUser(`1. In technician app\n` +
        `2. Find booking: ${bookingId}\n` +
        `3. Mark service as complete`);
}
async function step8_verifyPaymentState(bookingId) {
    logStep(8, 'VERIFY PAYMENT STATE (AUTO)');
    log('Fetching booking after service completion...', 'blue');
    const bookingDoc = await db.collection('bookings').doc(bookingId).get();
    const booking = bookingDoc.data();
    const status = booking.bookingStatus || booking.status;
    log(`\nBooking Status: ${status}`, 'cyan');
    if (status === 'awaiting_payment') {
        logResult('PASS', 'Booking status is "awaiting_payment"');
        results.push({ step: 'Payment State', status: 'PASS' });
    }
    else {
        logResult('FAIL', `Expected status "awaiting_payment", got "${status}"`);
        results.push({ step: 'Payment State', status: 'FAIL', message: `Wrong status: ${status}` });
    }
}
async function step9_payment(bookingId) {
    logStep(9, 'PAYMENT (MANUAL - REAL TEST)');
    await waitForUser(`1. In customer app\n` +
        `2. Find booking: ${bookingId}\n` +
        `3. Click "Pay Now"\n` +
        `4. Complete ₹1 payment via Razorpay\n` +
        `5. Wait for payment confirmation`);
}
async function step10_verifyPaymentResult(bookingId) {
    logStep(10, 'VERIFY PAYMENT RESULT (AUTO)');
    log('Fetching booking after payment...', 'blue');
    const bookingDoc = await db.collection('bookings').doc(bookingId).get();
    const booking = bookingDoc.data();
    const bookingStatus = booking.bookingStatus || booking.status;
    const paymentStatus = booking.payment?.status || booking.paymentStatus;
    log(`\nBooking Status: ${bookingStatus}`, 'cyan');
    log(`Payment Status: ${paymentStatus}`, 'cyan');
    log(`Payment ID: ${booking.payment?.razorpayPaymentId || 'N/A'}`, 'cyan');
    log(`Amount Paid: ₹${booking.payment?.amountPaid || 0}`, 'cyan');
    let passed = true;
    if (bookingStatus !== 'paid') {
        logResult('FAIL', `Expected booking status "paid", got "${bookingStatus}"`);
        passed = false;
    }
    else {
        logResult('PASS', 'Booking status is "paid"');
    }
    if (paymentStatus !== 'paid') {
        logResult('FAIL', `Expected payment status "paid", got "${paymentStatus}"`);
        passed = false;
    }
    else {
        logResult('PASS', 'Payment status is "paid"');
    }
    results.push({
        step: 'Payment Result',
        status: passed ? 'PASS' : 'FAIL',
        message: passed ? undefined : 'Payment verification failed'
    });
}
async function step11_verifyWallet(bookingId) {
    logStep(11, 'VERIFY WALLET (AUTO)');
    log('Fetching booking and wallet data...', 'blue');
    const bookingDoc = await db.collection('bookings').doc(bookingId).get();
    const booking = bookingDoc.data();
    const technicianId = booking.technicianId;
    if (!technicianId) {
        logResult('FAIL', 'No technician ID in booking');
        results.push({ step: 'Wallet Credit', status: 'FAIL', message: 'No technician ID' });
        return;
    }
    const walletDoc = await db.collection('technician_wallets').doc(technicianId).get();
    if (!walletDoc.exists) {
        logResult('FAIL', 'Wallet not found for technician');
        results.push({ step: 'Wallet Credit', status: 'FAIL', message: 'Wallet not found' });
        return;
    }
    const wallet = walletDoc.data();
    log(`\nWallet Balance: ₹${wallet.availableBalance || 0}`, 'cyan');
    log(`Lifetime Earnings: ₹${wallet.lifetimeEarnings || 0}`, 'cyan');
    // Check for transaction
    const transactionsSnapshot = await db.collection('technician_wallets')
        .doc(technicianId)
        .collection('transactions')
        .where('referenceId', '==', bookingId)
        .where('type', '==', 'credit')
        .where('source', '==', 'booking_payment')
        .limit(1)
        .get();
    let passed = true;
    if (wallet.availableBalance > 0) {
        logResult('PASS', 'Wallet has positive balance');
    }
    else {
        logResult('FAIL', 'Wallet balance is zero or negative');
        passed = false;
    }
    if (!transactionsSnapshot.empty) {
        const txn = transactionsSnapshot.docs[0].data();
        log(`Transaction Amount: ₹${txn.amount}`, 'cyan');
        logResult('PASS', 'Transaction entry exists');
    }
    else {
        logResult('FAIL', 'No transaction entry found');
        passed = false;
    }
    results.push({
        step: 'Wallet Credit',
        status: passed ? 'PASS' : 'FAIL',
        message: passed ? undefined : 'Wallet not credited properly'
    });
}
async function step12_realTimeCheck() {
    logStep(12, 'REAL-TIME CHECK (AUTO + OBSERVE)');
    log('This step requires manual observation:', 'yellow');
    log('  - Check if booking updates appear without manual refresh', 'cyan');
    log('  - Verify Firestore listeners are working', 'cyan');
    log('  - Confirm real-time sync across apps', 'cyan');
    const answer = await prompt('\nDid real-time updates work? (yes/no): ');
    if (answer.toLowerCase() === 'yes' || answer.toLowerCase() === 'y') {
        logResult('PASS', 'Real-time updates working');
        results.push({ step: 'Real-time Updates', status: 'PASS' });
    }
    else {
        logResult('FAIL', 'Real-time updates not working');
        results.push({ step: 'Real-time Updates', status: 'FAIL', message: 'Manual refresh required' });
    }
}
async function step13_logCheck(bookingId) {
    logStep(13, 'LOG CHECK (AUTO)');
    log('Fetching payment logs...', 'blue');
    const logsSnapshot = await db.collection('payment_logs')
        .where('bookingId', '==', bookingId)
        .get();
    log(`\nFound ${logsSnapshot.size} log entries`, 'cyan');
    const actions = logsSnapshot.docs.map(doc => doc.data().action);
    log(`Actions: ${actions.join(', ')}`, 'cyan');
    const hasVerified = actions.includes('payment_verified_client') || actions.includes('verification_complete');
    if (hasVerified) {
        logResult('PASS', 'Payment verification logged');
        results.push({ step: 'Log Check', status: 'PASS' });
    }
    else {
        logResult('FAIL', 'Payment verification not logged');
        results.push({ step: 'Log Check', status: 'FAIL', message: 'Missing verification log' });
    }
}
function step14_finalResult() {
    logStep(14, 'FINAL RESULT');
    console.log('\n' + '='.repeat(80));
    log('TEST RESULTS SUMMARY', 'bright');
    console.log('='.repeat(80) + '\n');
    const summary = {
        'Booking Flow': results.filter(r => ['Setup', 'Booking Created', 'Admin Approval', 'Technician Accept'].includes(r.step)),
        'Payment Flow': results.filter(r => ['Payment State', 'Payment Result'].includes(r.step)),
        'Wallet Flow': results.filter(r => r.step === 'Wallet Credit'),
        'Real-time Updates': results.filter(r => r.step === 'Real-time Updates'),
        'Logging': results.filter(r => r.step === 'Log Check'),
    };
    for (const [category, categoryResults] of Object.entries(summary)) {
        const allPassed = categoryResults.every(r => r.status === 'PASS');
        const status = allPassed ? 'PASS' : 'FAIL';
        const color = allPassed ? 'green' : 'red';
        log(`✔ ${category}: ${status}`, color);
        // Show failed tests
        categoryResults.filter(r => r.status === 'FAIL').forEach(r => {
            log(`  └─ ${r.step}: ${r.message || 'Failed'}`, 'red');
        });
    }
    console.log('\n' + '='.repeat(80));
    const totalTests = results.length;
    const passedTests = results.filter(r => r.status === 'PASS').length;
    const failedTests = results.filter(r => r.status === 'FAIL').length;
    log(`\nTotal Tests: ${totalTests}`, 'bright');
    log(`Passed: ${passedTests}`, 'green');
    log(`Failed: ${failedTests}`, failedTests > 0 ? 'red' : 'green');
    const successRate = ((passedTests / totalTests) * 100).toFixed(1);
    log(`Success Rate: ${successRate}%`, failedTests > 0 ? 'yellow' : 'green');
    console.log('='.repeat(80) + '\n');
}
// ============================================================================
// MAIN TEST RUNNER
// ============================================================================
async function runHybridFlowTest() {
    try {
        log('\n╔════════════════════════════════════════════════════════════════════════════╗', 'bright');
        log('║                     HYBRID LIVE FLOW TEST                                  ║', 'bright');
        log('║              Customer → Admin → Technician → Payment                       ║', 'bright');
        log('╚════════════════════════════════════════════════════════════════════════════╝\n', 'bright');
        // Step 0: Setup
        const { customerId, technicianId, serviceId } = await step0_setup();
        // Step 1: Customer Booking (Manual)
        await step1_customerBooking(customerId);
        // Step 2: Verify Booking Created (Auto)
        const bookingId = await step2_verifyBookingCreated(customerId);
        // Step 3: Admin Approval (Manual)
        await step3_adminApproval(bookingId);
        // Step 4: Verify Admin Update (Auto)
        await step4_verifyAdminUpdate(bookingId);
        // Step 5: Technician Accept (Manual)
        await step5_technicianAccept(bookingId);
        // Step 6: Verify Technician Accept (Auto)
        await step6_verifyTechnicianAccept(bookingId);
        // Step 7: Service Complete (Manual)
        await step7_serviceComplete(bookingId);
        // Step 8: Verify Payment State (Auto)
        await step8_verifyPaymentState(bookingId);
        // Step 9: Payment (Manual)
        await step9_payment(bookingId);
        // Step 10: Verify Payment Result (Auto)
        await step10_verifyPaymentResult(bookingId);
        // Step 11: Verify Wallet (Auto)
        await step11_verifyWallet(bookingId);
        // Step 12: Real-time Check (Auto + Observe)
        await step12_realTimeCheck();
        // Step 13: Log Check (Auto)
        await step13_logCheck(bookingId);
        // Step 14: Final Result
        step14_finalResult();
    }
    catch (error) {
        log(`\n✖ TEST FAILED: ${error.message}`, 'red');
        console.error(error);
    }
    finally {
        rl.close();
        process.exit(0);
    }
}
// Run the test
runHybridFlowTest();
//# sourceMappingURL=hybridFlowTest.js.map
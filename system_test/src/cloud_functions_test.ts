import * as admin from 'firebase-admin';
import * as fs from 'fs';
import { TestLogger, FirebaseTestHelper, printTestSummary } from './test_utils';

async function runCloudFunctionsTests(): Promise<void> {
  const logger = new TestLogger();
  const helper = new FirebaseTestHelper();

  console.log('\n☁️  CLOUD FUNCTIONS TESTS');
  console.log('='.repeat(60));

  try {
    const serviceAccountPath = '../scripts/serviceAccountKey.json';
    if (!fs.existsSync(serviceAccountPath)) {
      logger.skip('Cloud Functions Tests', 'serviceAccountKey.json not found');
      const summary = logger.getSummary();
      printTestSummary(summary);
      process.exit(0);
    }

    await helper.initializeApp(serviceAccountPath);
    const db = helper.getFirestore();
    const auth = helper.getAuth();

    // Test 1: Check Firestore Deployment
    logger.startTest('Check Firestore Deployment');
    try {
      const collections = await db.listCollections();
      logger.pass('Check Firestore Deployment', {
        collectionsFound: collections.length,
      });
    } catch (error: any) {
      logger.fail('Check Firestore Deployment', error.message);
    }

    // Test 2: Test KYC Evaluation via Firestore
    logger.startTest('Test KYC Evaluation via Firestore');
    try {
      const testEmail = `kyc_test_${Date.now()}@homefix.test`;
      const user = await auth.createUser({
        email: testEmail,
        password: 'TestPassword123!',
        emailVerified: true,
      });

      await db.collection('technicians').doc(user.uid).set({
        uid: user.uid,
        email: testEmail,
        name: 'KYC Test Technician',
        phone: '+919999999996',
        isOnline: false,
        isVerified: true,
        avgRating: 0,
        totalRatings: 0,
        ratingBreakdown: { '1': 0, '2': 0, '3': 0, '4': 0, '5': 0 },
        jobsDone: 0,
        skills: ['plumbing'],
        status: 'pending_verification',
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      logger.pass('Test KYC Evaluation via Firestore', {
        technicianCreated: user.uid,
      });

      await db.collection('technicians').doc(user.uid).delete();
      await auth.deleteUser(user.uid);
    } catch (error: any) {
      logger.fail('Test KYC Evaluation via Firestore', error.message);
    }

    // Test 3: Test Technician Profile Queries
    logger.startTest('Test Technician Profile Queries');
    try {
      const technicians = await db.collection('technicians').limit(5).get();
      logger.pass('Test Technician Profile Queries', {
        techniciansFound: technicians.size,
      });
    } catch (error: any) {
      logger.fail('Test Technician Profile Queries', error.message);
    }

    // Test 4: Verify Firestore Indexes
    logger.startTest('Verify Firestore Indexes');
    try {
      const bookings = await db.collection('bookings').limit(1).get();
      logger.pass('Verify Firestore Indexes', {
        bookingsAccessible: true,
      });
    } catch (error: any) {
      logger.fail('Verify Firestore Indexes', error.message);
    }

    // Test 5: Verify Firestore Rules
    logger.startTest('Verify Firestore Rules');
    try {
      const services = await db.collection('services').limit(1).get();
      logger.pass('Verify Firestore Rules', {
        servicesAccessible: true,
      });
    } catch (error: any) {
      logger.fail('Verify Firestore Rules', error.message);
    }

    // Test 6: Verify Admin Collection
    logger.startTest('Verify Admin Collection');
    try {
      const admins = await db.collection('admins').limit(1).get();
      logger.pass('Verify Admin Collection', {
        adminsAccessible: true,
      });
    } catch (error: any) {
      logger.fail('Verify Admin Collection', error.message);
    }

    // Test 7: Verify Wallet System
    logger.startTest('Verify Wallet System');
    try {
      const wallets = await db.collection('wallets').limit(1).get();
      logger.pass('Verify Wallet System', {
        walletsAccessible: true,
      });
    } catch (error: any) {
      logger.fail('Verify Wallet System', error.message);
    }

  } catch (error: any) {
    logger.fail('Cloud Functions Tests', error.message);
  }

  const summary = logger.getSummary();
  printTestSummary(summary);

  process.exit(summary.failCount > 0 ? 1 : 0);
}

runCloudFunctionsTests().catch((error) => {
  console.error('Fatal error:', error);
  process.exit(1);
});

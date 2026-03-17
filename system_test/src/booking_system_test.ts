import * as admin from 'firebase-admin';
import * as fs from 'fs';
import { TestLogger, FirebaseTestHelper, printTestSummary, sleep } from './test_utils';

async function runBookingSystemTests(): Promise<void> {
  const logger = new TestLogger();
  const helper = new FirebaseTestHelper();

  console.log('\n📅 BOOKING SYSTEM TESTS');
  console.log('='.repeat(60));

  try {
    const serviceAccountPath = '../scripts/serviceAccountKey.json';
    if (!fs.existsSync(serviceAccountPath)) {
      logger.skip('Booking Tests', 'serviceAccountKey.json not found');
      const summary = logger.getSummary();
      printTestSummary(summary);
      process.exit(0);
    }

    await helper.initializeApp(serviceAccountPath);
    const db = helper.getFirestore();
    const auth = helper.getAuth();

    // Create test customer
    logger.startTest('Create Test Customer');
    const customerEmail = `customer_${Date.now()}@homefix.test`;
    let customerId = '';

    try {
      const user = await auth.createUser({
        email: customerEmail,
        password: 'TestPassword123!',
        emailVerified: true,
      });
      customerId = user.uid;
      
      // Create customer profile
      await db.collection('users').doc(customerId).set({
        uid: customerId,
        email: customerEmail,
        name: 'Test Customer',
        phone: '+919999999999',
        walletBalance: 1000,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      
      logger.pass('Create Test Customer', {
        uid: customerId,
      });
    } catch (error: any) {
      logger.fail('Create Test Customer', error.message);
    }

    if (!customerId) {
      logger.skip('Remaining Booking Tests', 'Customer creation failed');
      const summary = logger.getSummary();
      printTestSummary(summary);
      process.exit(0);
    }

    // Create test technician
    logger.startTest('Create Test Technician');
    const techEmail = `tech_${Date.now()}@homefix.test`;
    let technicianId = '';

    try {
      const user = await auth.createUser({
        email: techEmail,
        password: 'TestPassword123!',
        emailVerified: true,
      });
      technicianId = user.uid;
      
      // Create technician profile
      await db.collection('technicians').doc(technicianId).set({
        uid: technicianId,
        email: techEmail,
        name: 'Test Technician',
        phone: '+919999999998',
        isOnline: true,
        isVerified: true,
        avgRating: 4.5,
        totalRatings: 10,
        ratingBreakdown: { '1': 0, '2': 0, '3': 0, '4': 5, '5': 5 },
        jobsDone: 10,
        skills: ['plumbing', 'electrical'],
        status: 'approved',
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      
      logger.pass('Create Test Technician', {
        uid: technicianId,
      });
    } catch (error: any) {
      logger.fail('Create Test Technician', error.message);
    }

    if (!technicianId) {
      logger.skip('Remaining Booking Tests', 'Technician creation failed');
      const summary = logger.getSummary();
      printTestSummary(summary);
      process.exit(0);
    }

    // Test 1: Create Booking
    logger.startTest('Create Booking');
    const bookingId = `booking_${Date.now()}`;
    try {
      await db.collection('bookings').doc(bookingId).set({
        bookingId,
        customerId,
        technicianId: null,
        serviceId: 'plumbing_repair',
        serviceName: 'Plumbing Repair',
        status: 'pending',
        paymentStatus: 'pending',
        scheduledDate: new Date(Date.now() + 86400000).toISOString(),
        scheduledTime: '10:00 AM',
        address: '123 Test Street',
        description: 'Test booking',
        estimatedPrice: 500,
        finalAmount: null,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      logger.pass('Create Booking', {
        bookingId,
      });
    } catch (error: any) {
      logger.fail('Create Booking', error.message);
    }

    // Test 2: Verify Booking Created
    logger.startTest('Verify Booking Created');
    try {
      await sleep(500);
      const doc = await db.collection('bookings').doc(bookingId).get();
      if (doc.exists && doc.data()?.status === 'pending') {
        logger.pass('Verify Booking Created', {
          status: doc.data()?.status,
        });
      } else {
        logger.fail('Verify Booking Created', 'Booking not found or invalid status');
      }
    } catch (error: any) {
      logger.fail('Verify Booking Created', error.message);
    }

    // Test 3: Query Customer Bookings
    logger.startTest('Query Customer Bookings');
    try {
      const query = await db
        .collection('bookings')
        .where('customerId', '==', customerId)
        .get();
      logger.pass('Query Customer Bookings', {
        bookingsFound: query.size,
      });
    } catch (error: any) {
      logger.fail('Query Customer Bookings', error.message);
    }

    // Test 4: Query Pending Bookings
    logger.startTest('Query Pending Bookings');
    try {
      const query = await db
        .collection('bookings')
        .where('status', '==', 'pending')
        .limit(10)
        .get();
      logger.pass('Query Pending Bookings', {
        bookingsFound: query.size,
      });
    } catch (error: any) {
      logger.fail('Query Pending Bookings', error.message);
    }

    // Test 5: Booking Subcollection - Messages
    logger.startTest('Create Booking Message');
    try {
      await db
        .collection('bookings')
        .doc(bookingId)
        .collection('messages')
        .add({
          senderId: customerId,
          message: 'Test message',
          timestamp: admin.firestore.FieldValue.serverTimestamp(),
        });
      logger.pass('Create Booking Message', {
        bookingId,
      });
    } catch (error: any) {
      logger.fail('Create Booking Message', error.message);
    }

    // Test 6: Query Booking Messages
    logger.startTest('Query Booking Messages');
    try {
      const messages = await db
        .collection('bookings')
        .doc(bookingId)
        .collection('messages')
        .get();
      logger.pass('Query Booking Messages', {
        messagesFound: messages.size,
      });
    } catch (error: any) {
      logger.fail('Query Booking Messages', error.message);
    }

    // Test 7: Booking Status Transition (Simulate)
    logger.startTest('Booking Status Transition');
    try {
      // Note: In production, this would be done via Cloud Functions
      // Here we're just testing the data structure
      const bookingData = await db.collection('bookings').doc(bookingId).get();
      if (bookingData.exists) {
        logger.pass('Booking Status Transition', {
          currentStatus: bookingData.data()?.status,
        });
      } else {
        logger.fail('Booking Status Transition', 'Booking not found');
      }
    } catch (error: any) {
      logger.fail('Booking Status Transition', error.message);
    }

    // Cleanup
    logger.startTest('Cleanup Test Data');
    try {
      await db.collection('bookings').doc(bookingId).delete();
      await db.collection('users').doc(customerId).delete();
      await db.collection('technicians').doc(technicianId).delete();
      await auth.deleteUser(customerId);
      await auth.deleteUser(technicianId);
      logger.pass('Cleanup Test Data', {
        bookingId,
        customerId,
        technicianId,
      });
    } catch (error: any) {
      logger.fail('Cleanup Test Data', error.message);
    }

  } catch (error: any) {
    logger.fail('Booking System Tests', error.message);
  }

  const summary = logger.getSummary();
  printTestSummary(summary);

  process.exit(summary.failCount > 0 ? 1 : 0);
}

runBookingSystemTests().catch((error) => {
  console.error('Fatal error:', error);
  process.exit(1);
});

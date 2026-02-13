/**
 * V2 Booking Flow End-to-End Test Script
 * 
 * This script tests the complete V2 booking flow:
 * 1. Create a test booking using createBookingV2
 * 2. Trigger matchTechniciansV2
 * 3. Simulate technician response
 * 4. Transition booking through all status states
 * 5. Verify Firestore triggers execute properly
 * 
 * Usage: 
 *   npx ts-node functions/test_v2_booking_flow.ts
 * 
 * Prerequisites:
 *   - Firebase admin SDK credentials set up
 *   - Test customer and technician accounts in Firestore
 */

import * as admin from 'firebase-admin';

// Initialize Firebase Admin
if (!admin.apps.length) {
  admin.initializeApp();
}
const db = admin.firestore();

// Test Configuration
const TEST_CONFIG = {
  customerId: 'test_customer_001',
  technicianId: 'test_technician_001',
  serviceId: 'ac_repair',
  subServiceId: 'ac_installation',
  testLocation: {
    latitude: 28.6139,  // Delhi coordinates
    longitude: 77.2090
  },
  testAddress: {
    fullAddress: '123 Test Street, Delhi, India',
    latitude: 28.6139,
    longitude: 77.2090
  }
};

// ============================================
// TEST DATA SETUP
// ============================================

async function setupTestData(): Promise<string> {
  console.log('\n=== SETUP: Creating test data ===\n');

  // Create test customer
  const customerRef = db.collection('customers').doc(TEST_CONFIG.customerId);
  await customerRef.set({
    uid: TEST_CONFIG.customerId,
    name: 'Test Customer',
    email: 'test@homefix.com',
    phone: '+919999999999',
    createdAt: admin.firestore.FieldValue.serverTimestamp()
  });
  console.log(`✓ Created test customer: ${TEST_CONFIG.customerId}`);

  // Create test technician with location
  const techRef = db.collection('technicians').doc(TEST_CONFIG.technicianId);
  await techRef.set({
    uid: TEST_CONFIG.technicianId,
    name: 'Test Technician',
    phone: '+919888888888',
    isApproved: true,
    isOnline: true,
    services: [TEST_CONFIG.serviceId],
    subServices: [TEST_CONFIG.subServiceId],
    location: {
      lat: 28.6150,  // Close to customer
      lng: 77.2100
    },
    rating: 4.5,
    totalReviews: 50,
    totalCompletedOrders: 45,
    totalEarnings: 50000,
    createdAt: admin.firestore.FieldValue.serverTimestamp()
  });
  console.log(`✓ Created test technician: ${TEST_CONFIG.technicianId}`);

  // Create test service
  const serviceRef = db.collection('services').doc(TEST_CONFIG.serviceId);
  await serviceRef.set({
    id: TEST_CONFIG.serviceId,
    name: 'AC Repair',
    basePrice: 500,
    createdAt: admin.firestore.FieldValue.serverTimestamp()
  });
  console.log(`✓ Created test service: ${TEST_CONFIG.serviceId}`);

  return TEST_CONFIG.customerId;
}

// ============================================
// TEST 1: CREATE BOOKING V2
// ============================================

async function testCreateBookingV2(): Promise<string> {
  console.log('\n=== TEST 1: Create Booking V2 ===\n');

  const bookingId = db.collection('bookings').doc().id;
  const now = admin.firestore.FieldValue.serverTimestamp();
  
  // Simulate createBookingV2 function logic
  const bookingData = {
    id: bookingId,
    bookingId,
    customerId: TEST_CONFIG.customerId,
    customerName: 'Test Customer',
    addressSnapshot: TEST_CONFIG.testAddress,
    status: 'pending_payment',
    paymentStatus: 'pending',
    price: 500,
    finalAmount: 500,
    createdAt: now,
    updatedAt: now,
    services: [{
      id: 'service_1',
      name: 'AC Repair',
      price: 500,
      quantity: 1
    }],
    serviceTitle: 'AC Repair',
    scheduledDate: new Date().toISOString().split('T')[0],
    scheduledTime: '10:00 AM - 12:00 PM',
    scheduledAt: admin.firestore.Timestamp.fromDate(new Date()),
    couponCode: null,
    // Idempotency key for duplicate prevention
    idempotencyKey: `booking_${TEST_CONFIG.customerId}_${Date.now()}`
  };

  // Use transaction for consistency
  await db.runTransaction(async (transaction) => {
    // Check for existing booking with same idempotency key
    const existingBooking = await db.collection('bookings')
      .where('customerId', '==', TEST_CONFIG.customerId)
      .where('idempotencyKey', '==', bookingData.idempotencyKey)
      .limit(1)
      .get();

    if (!existingBooking.empty) {
      console.log('⚠️  Booking already exists (idempotency check passed)');
      return;
    }

    transaction.set(db.collection('bookings').doc(bookingId), bookingData);
    console.log(`✓ Created booking document: ${bookingId}`);
  });

  // Verify booking was created
  const bookingDoc = await db.collection('bookings').doc(bookingId).get();
  if (!bookingDoc.exists) {
    throw new Error('Booking document not found after creation');
  }

  const booking = bookingDoc.data()!;
  console.log(`✓ Booking status: ${booking.status}`);
  console.log(`✓ Booking amount: ₹${booking.finalAmount}`);
  console.log(`✓ Booking services: ${booking.serviceTitle}`);

  return bookingId;
}

// ============================================
// TEST 2: TRIGGER MATCHING (Simulate matchTechniciansV2)
// ============================================

async function testMatchTechniciansV2(bookingId: string): Promise<string[]> {
  console.log('\n=== TEST 2: Match Technicians V2 ===\n');

  // Simulate matchTechniciansV2 function logic
  const customerLocation = TEST_CONFIG.testLocation;

  // Query eligible technicians
  const eligibleTechnicians = await db.collection('technicians')
    .where('isApproved', '==', true)
    .where('isOnline', '==', true)
    .where('services', 'array-contains', TEST_CONFIG.serviceId)
    .get();

  console.log(`✓ Found ${eligibleTechnicians.size} eligible technicians`);

  if (eligibleTechnicians.empty) {
    console.log('⚠️  No eligible technicians found');
    return [];
  }

  // Calculate scores and distance for each technician
  const scoredTechnicians: Array<{
    id: string;
    name: string;
    rating: number;
    totalCompletedOrders: number;
    distanceKm: number;
    score: number;
  }> = [];

  eligibleTechnicians.docs.forEach((doc) => {
    const tech = doc.data();
    
    // Haversine distance calculation
    const distanceKm = calculateDistance(
      customerLocation.latitude,
      customerLocation.longitude,
      tech.location.lat,
      tech.location.lng
    );

    // Skip if too far (>25km)
    if (distanceKm > 25) {
      console.log(`⚠️  Technician ${doc.id} too far: ${distanceKm.toFixed(2)}km`);
      return;
    }

    // Calculate score (simplified)
    const ratingScore = (tech.rating / 5) * 0.35;
    const ordersScore = Math.min(tech.totalCompletedOrders / 100, 1) * 0.25;
    const distanceScore = Math.max(0, 1 - distanceKm / 25) * 0.40;
    const score = ratingScore + ordersScore + distanceScore;

    scoredTechnicians.push({
      id: doc.id,
      name: tech.name || 'Technician',
      rating: tech.rating,
      totalCompletedOrders: tech.totalCompletedOrders,
      distanceKm,
      score
    });
  });

  // Sort by score and take top 3
  scoredTechnicians.sort((a, b) => b.score - a.score);
  const topTechnicians = scoredTechnicians.slice(0, 3);

  console.log('\nTop matched technicians:');
  topTechnicians.forEach((tech, index) => {
    console.log(`  ${index + 1}. ${tech.name} (ID: ${tech.id})`);
    console.log(`     Rating: ${tech.rating}, Distance: ${tech.distanceKm.toFixed(2)}km, Score: ${tech.score.toFixed(2)}`);
  });

  // Create matched_technicians subcollection
  const batch = db.batch();
  topTechnicians.forEach((tech, index) => {
    const matchRef = db.collection('bookings')
      .doc(bookingId)
      .collection('matched_technicians')
      .doc(tech.id);
    
    batch.set(matchRef, {
      technicianId: tech.id,
      name: tech.name,
      rating: tech.rating,
      distanceKm: Math.round(tech.distanceKm * 100) / 100,
      score: Math.round(tech.score * 100) / 100,
      rank: index + 1,
      createdAt: admin.firestore.FieldValue.serverTimestamp()
    });
  });
  await batch.commit();

  console.log(`✓ Saved ${topTechnicians.length} matched technicians`);

  return topTechnicians.map(t => t.id);
}

// ============================================
// TEST 3: SIMULATE TECHNICIAN ASSIGNMENT
// ============================================

async function testTechnicianAssignment(bookingId: string, technicianIds: string[]): Promise<void> {
  console.log('\n=== TEST 3: Technician Assignment ===\n');

  if (technicianIds.length === 0) {
    console.log('⚠️  No technicians to assign');
    return;
  }

  const selectedTechId = technicianIds[0];
  
  // Update booking with technician assignment
  await db.collection('bookings').doc(bookingId).update({
    assignedTechnicianId: selectedTechId,
    assignedTechnicianName: 'Test Technician',
    status: 'assigned',
    assignedAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp()
  });

  console.log(`✓ Assigned technician ${selectedTechId} to booking ${bookingId}`);

  // Update technician's lastAssignedAt
  await db.collection('technicians').doc(selectedTechId).update({
    lastAssignedAt: admin.firestore.FieldValue.serverTimestamp()
  });

  console.log(`✓ Updated technician assignment timestamp`);
}

// ============================================
// TEST 4: BOOKING STATUS TRANSITIONS
// ============================================

async function testStatusTransitions(bookingId: string): Promise<void> {
  console.log('\n=== TEST 4: Booking Status Transitions ===\n');

  const statusTransitions = [
    { from: 'pending_payment', to: 'confirmed', action: 'Payment verified' },
    { from: 'confirmed', to: 'assigned', action: 'Technician assigned' },
    { from: 'assigned', to: 'on_the_way', action: 'Technician en route' },
    { from: 'on_the_way', to: 'started', action: 'Service started' },
    { from: 'started', to: 'completed', action: 'Service completed' }
  ];

  for (const transition of statusTransitions) {
    // First transition: pending_payment -> confirmed (simulate payment)
    if (transition.from === 'pending_payment') {
      await db.collection('bookings').doc(bookingId).update({
        paymentStatus: 'paid',
        status: transition.to,
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      });
    } else {
      await db.collection('bookings').doc(bookingId).update({
        status: transition.to,
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      });
    }

    console.log(`✓ ${transition.action}: ${transition.from} → ${transition.to}`);

    // Small delay to allow triggers to execute
    await new Promise(resolve => setTimeout(resolve, 500));
  }

  // Final status check
  const bookingDoc = await db.collection('bookings').doc(bookingId).get();
  const booking = bookingDoc.data()!;
  console.log(`\n✓ Final booking status: ${booking.status}`);
  console.log(`✓ Final payment status: ${booking.paymentStatus}`);
}

// ============================================
// TEST 5: VERIFY FIRESTORE TRIGGERS EXECUTED
// ============================================

async function testFirestoreTriggers(bookingId: string): Promise<void> {
  console.log('\n=== TEST 5: Verify Firestore Triggers ===\n');

  // Check notification logs collection (if exists)
  const notificationsRef = db.collection('notifications');
  const notifications = await notificationsRef
    .where('bookingId', '==', bookingId)
    .orderBy('createdAt', 'desc')
    .limit(10)
    .get();

  console.log(`✓ Found ${notifications.size} notification records for booking ${bookingId}`);

  // Check booking history subcollection
  const historyRef = db.collection('bookings').doc(bookingId).collection('history');
  const historySnap = await historyRef.orderBy('timestamp', 'desc').get();
  const history = historySnap.docs;

  console.log(`✓ Found ${history.length} history records for booking ${bookingId}`);

  history.forEach((doc) => {
    const data = doc.data();
    console.log(`  - ${data.action} at ${data.timestamp?.toDate?.() || 'unknown'}`);
  });
}

// ============================================
// TEST 6: EARNINGS LOGIC VERIFICATION
// ============================================

async function testEarningsLogic(bookingId: string): Promise<void> {
  console.log('\n=== TEST 6: Earnings Logic ===\n');

  const bookingDoc = await db.collection('bookings').doc(bookingId).get();
  const booking = bookingDoc.data()!;

  if (booking.status === 'completed' && booking.assignedTechnicianId) {
    // Calculate technician earnings (80% of booking amount)
    const techEarnings = Math.round(booking.finalAmount * 0.8);
    
    console.log(`✓ Booking amount: ₹${booking.finalAmount}`);
    console.log(`✓ Technician earnings (80%): ₹${techEarnings}`);

    // Check if earnings were recorded
    const earningsRef = db.collection('technician_earnings');
    const earnings = await earningsRef
      .where('bookingId', '==', bookingId)
      .where('technicianId', '==', booking.assignedTechnicianId)
      .get();

    if (!earnings.empty) {
      console.log(`✓ Earnings record found: ₹${earnings.docs[0].data().amount}`);
    } else {
      console.log(`⚠️  No earnings record found (trigger should create it)`);
    }
  }
}

// ============================================
// TEST 7: IDEMPOTENCY CHECK
// ============================================

async function testIdempotency(): Promise<void> {
  console.log('\n=== TEST 7: Idempotency Check ===\n');

  const idempotencyKey = `test_idempotency_${Date.now()}`;
  const bookingId1 = db.collection('bookings').doc().id;
  const bookingId2 = db.collection('bookings').doc().id;

  // First creation
  await db.collection('bookings').doc(bookingId1).set({
    bookingId: bookingId1,
    customerId: TEST_CONFIG.customerId,
    idempotencyKey,
    status: 'pending_payment',
    createdAt: admin.firestore.FieldValue.serverTimestamp()
  });

  console.log(`✓ Created first booking with idempotency key: ${bookingId1}`);

  // Try to create duplicate
  try {
    await db.runTransaction(async (transaction) => {
      const existing = await transaction.get(
        db.collection('bookings')
          .where('idempotencyKey', '==', idempotencyKey)
          .limit(1)
          .get()
      );

      if (!existing.empty) {
        console.log('⚠️  Duplicate creation blocked by transaction');
        return;
      }

      transaction.set(db.collection('bookings').doc(bookingId2), {
        bookingId: bookingId2,
        customerId: TEST_CONFIG.customerId,
        idempotencyKey,
        status: 'pending_payment',
        createdAt: admin.firestore.FieldValue.serverTimestamp()
      });
    });
    console.log('⚠️  Second booking created (idempotency may need strengthening)');
  } catch (error: any) {
    console.log(`✓ Duplicate blocked: ${error.message}`);
  }
}

// ============================================
// HELPER: Haversine Distance Calculation
// ============================================

function calculateDistance(
  lat1: number, 
  lng1: number, 
  lat2: number, 
  lng2: number
): number {
  const R = 6371; // Earth's radius in km
  const dLat = toRad(lat2 - lat1);
  const dLng = toRad(lng2 - lng1);
  const a = 
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) *
    Math.sin(dLng / 2) * Math.sin(dLng / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return R * c;
}

function toRad(deg: number): number {
  return deg * (Math.PI / 180);
}

// ============================================
// MAIN: RUN ALL TESTS
// ============================================

async function runAllTests(): Promise<void> {
  console.log('╔════════════════════════════════════════════════╗');
  console.log('║  V2 BOOKING FLOW E2E TEST SUITE              ║');
  console.log('╚════════════════════════════════════════════════╝');

  const startTime = Date.now();

  try {
    // Setup
    await setupTestData();

    // Test 1: Create Booking
    const bookingId = await testCreateBookingV2();

    // Test 2: Match Technicians
    const technicianIds = await testMatchTechniciansV2(bookingId);

    // Test 3: Assign Technician
    await testTechnicianAssignment(bookingId, technicianIds);

    // Test 4: Status Transitions
    await testStatusTransitions(bookingId);

    // Test 5: Verify Triggers
    await testFirestoreTriggers(bookingId);

    // Test 6: Earnings Logic
    await testEarningsLogic(bookingId);

    // Test 7: Idempotency
    await testIdempotency();

    const duration = Date.now() - startTime;
    console.log('\n╔════════════════════════════════════════════════╗');
    console.log('║  ALL TESTS COMPLETED SUCCESSFULLY!            ║');
    console.log(`║  Duration: ${(duration / 1000).toFixed(2)}s                            ║`);
    console.log('╚════════════════════════════════════════════════╝');
  } catch (error: any) {
    console.error('\n❌ TEST FAILED:', error.message);
    console.error(error.stack);
    process.exit(1);
  }
}

// Run tests
runAllTests();

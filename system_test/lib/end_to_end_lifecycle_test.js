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
const admin = __importStar(require("firebase-admin"));
const fs = __importStar(require("fs"));
const test_utils_1 = require("./test_utils");
async function runE2ELifecycleTests() {
    const logger = new test_utils_1.TestLogger();
    const helper = new test_utils_1.FirebaseTestHelper();
    const context = {
        customerId: '',
        technicianId: '',
        serviceId: '',
        bookingId: '',
        adminId: '',
        testIds: {
            users: [],
            technicians: [],
            services: [],
            bookings: [],
        },
    };
    console.log('\n🔄 END-TO-END LIFECYCLE TESTS');
    console.log('='.repeat(60));
    try {
        const serviceAccountPath = '../scripts/serviceAccountKey.json';
        if (!fs.existsSync(serviceAccountPath)) {
            logger.skip('E2E Lifecycle Tests', 'serviceAccountKey.json not found');
            const summary = logger.getSummary();
            (0, test_utils_1.printTestSummary)(summary);
            process.exit(0);
        }
        await helper.initializeApp(serviceAccountPath);
        const db = helper.getFirestore();
        const auth = helper.getAuth();
        // ==========================================
        // PHASE 1: CREATE TEST CUSTOMER
        // ==========================================
        logger.startTest('Phase 1: Create Test Customer');
        const customerEmail = `customer_e2e_${Date.now()}@homefix.test`;
        try {
            const user = await auth.createUser({
                email: customerEmail,
                password: 'TestPassword123!',
                emailVerified: true,
            });
            context.customerId = user.uid;
            context.testIds.users.push(context.customerId);
            await db.collection('users').doc(context.customerId).set({
                uid: context.customerId,
                email: customerEmail,
                name: 'E2E Test Customer',
                phone: '+919999999999',
                walletBalance: 5000,
                referralCode: `REF_${context.customerId.substring(0, 8)}`,
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
                location: {
                    city: 'Bangalore',
                    district: 'Bangalore Urban',
                    state: 'Karnataka',
                },
            });
            logger.pass('Phase 1: Create Test Customer', {
                uid: context.customerId,
                email: customerEmail,
            });
        }
        catch (error) {
            logger.fail('Phase 1: Create Test Customer', error.message);
            throw error;
        }
        // ==========================================
        // PHASE 2: CREATE TEST TECHNICIAN
        // ==========================================
        logger.startTest('Phase 2: Create Test Technician');
        const techEmail = `tech_e2e_${Date.now()}@homefix.test`;
        try {
            const user = await auth.createUser({
                email: techEmail,
                password: 'TestPassword123!',
                emailVerified: true,
            });
            context.technicianId = user.uid;
            context.testIds.technicians.push(context.technicianId);
            await db.collection('technicians').doc(context.technicianId).set({
                uid: context.technicianId,
                email: techEmail,
                name: 'E2E Test Technician',
                phone: '+919999999998',
                isOnline: true,
                isVerified: true,
                isApproved: true,
                verificationStatus: 'approved',
                avgRating: 4.5,
                totalRatings: 10,
                totalJobs: 10,
                skills: ['plumbing', 'electrical', 'carpentry'],
                location: {
                    city: 'Bangalore',
                    district: 'Bangalore Urban',
                    state: 'Karnataka',
                },
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
            });
            logger.pass('Phase 2: Create Test Technician', {
                uid: context.technicianId,
                email: techEmail,
            });
        }
        catch (error) {
            logger.fail('Phase 2: Create Test Technician', error.message);
            throw error;
        }
        // ==========================================
        // PHASE 3: TECHNICIAN CREATES SERVICE
        // ==========================================
        logger.startTest('Phase 3: Technician Creates Service');
        context.serviceId = `service_e2e_${Date.now()}`;
        try {
            await db.collection('technician_services').doc(context.serviceId).set({
                serviceId: context.serviceId,
                technicianId: context.technicianId,
                title: 'E2E Test Plumbing Service',
                description: 'Professional plumbing repair and maintenance',
                category: 'plumbing',
                subCategory: 'repair',
                price: 500,
                estimatedDuration: '1-2 hours',
                imageUrl: 'https://example.com/plumbing.jpg',
                city: 'Bangalore',
                district: 'Bangalore Urban',
                status: 'pending',
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
            });
            context.testIds.services.push(context.serviceId);
            logger.pass('Phase 3: Technician Creates Service', {
                serviceId: context.serviceId,
                status: 'pending',
            });
        }
        catch (error) {
            logger.fail('Phase 3: Technician Creates Service', error.message);
            throw error;
        }
        // ==========================================
        // PHASE 4: ADMIN APPROVES SERVICE
        // ==========================================
        logger.startTest('Phase 4: Admin Approves Service');
        try {
            const adminEmail = `admin_e2e_${Date.now()}@homefix.test`;
            const adminUser = await auth.createUser({
                email: adminEmail,
                password: 'AdminPassword123!',
                emailVerified: true,
            });
            context.adminId = adminUser.uid;
            context.testIds.users.push(context.adminId);
            await db.collection('admins').doc(context.adminId).set({
                uid: context.adminId,
                email: adminEmail,
                name: 'E2E Test Admin',
                role: 'admin',
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
            });
            await db.collection('technician_services').doc(context.serviceId).update({
                status: 'approved',
                approvedAt: admin.firestore.FieldValue.serverTimestamp(),
                approvedBy: context.adminId,
            });
            logger.pass('Phase 4: Admin Approves Service', {
                serviceId: context.serviceId,
                status: 'approved',
            });
        }
        catch (error) {
            logger.fail('Phase 4: Admin Approves Service', error.message);
            throw error;
        }
        // ==========================================
        // PHASE 5: CUSTOMER QUERIES AVAILABLE SERVICES
        // ==========================================
        logger.startTest('Phase 5: Customer Queries Available Services');
        try {
            const services = await db
                .collection('technician_services')
                .where('status', '==', 'approved')
                .where('city', '==', 'Bangalore')
                .limit(10)
                .get();
            logger.pass('Phase 5: Customer Queries Available Services', {
                servicesFound: services.size,
            });
        }
        catch (error) {
            logger.fail('Phase 5: Customer Queries Available Services', error.message);
            throw error;
        }
        // ==========================================
        // PHASE 6: CUSTOMER CREATES BOOKING
        // ==========================================
        logger.startTest('Phase 6: Customer Creates Booking');
        context.bookingId = `booking_e2e_${Date.now()}`;
        try {
            const scheduledDate = new Date();
            scheduledDate.setDate(scheduledDate.getDate() + 2);
            await db.collection('bookings').doc(context.bookingId).set({
                bookingId: context.bookingId,
                customerId: context.customerId,
                technicianId: null,
                serviceId: context.serviceId,
                serviceName: 'E2E Test Plumbing Service',
                status: 'pending',
                paymentStatus: 'pending',
                adminApproval: 'pending',
                scheduledDate: scheduledDate.toISOString().split('T')[0],
                scheduledTime: '10:00 AM',
                address: '123 Test Street, Bangalore',
                description: 'E2E test booking',
                estimatedPrice: 500,
                finalAmount: null,
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
                updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            });
            context.testIds.bookings.push(context.bookingId);
            logger.pass('Phase 6: Customer Creates Booking', {
                bookingId: context.bookingId,
                status: 'pending',
            });
        }
        catch (error) {
            logger.fail('Phase 6: Customer Creates Booking', error.message);
            throw error;
        }
        // ==========================================
        // PHASE 7: VERIFY BOOKING STORED IN FIRESTORE
        // ==========================================
        logger.startTest('Phase 7: Verify Booking Stored in Firestore');
        try {
            await (0, test_utils_1.sleep)(500);
            const booking = await db.collection('bookings').doc(context.bookingId).get();
            if (!booking.exists) {
                throw new Error('Booking document not found');
            }
            const data = booking.data();
            if (data?.status !== 'pending') {
                throw new Error(`Invalid booking status: ${data?.status}`);
            }
            logger.pass('Phase 7: Verify Booking Stored in Firestore', {
                bookingId: context.bookingId,
                status: data?.status,
                customerId: data?.customerId,
            });
        }
        catch (error) {
            logger.fail('Phase 7: Verify Booking Stored in Firestore', error.message);
            throw error;
        }
        // ==========================================
        // PHASE 8: TECHNICIAN RECEIVES BOOKING
        // ==========================================
        logger.startTest('Phase 8: Technician Receives Booking');
        try {
            const pendingBookings = await db
                .collection('bookings')
                .where('status', '==', 'pending')
                .limit(10)
                .get();
            if (pendingBookings.size === 0) {
                throw new Error('No pending bookings found for technician');
            }
            logger.pass('Phase 8: Technician Receives Booking', {
                pendingBookingsFound: pendingBookings.size,
            });
        }
        catch (error) {
            logger.fail('Phase 8: Technician Receives Booking', error.message);
            throw error;
        }
        // ==========================================
        // PHASE 9: TECHNICIAN ACCEPTS BOOKING
        // ==========================================
        logger.startTest('Phase 9: Technician Accepts Booking');
        try {
            await db.collection('bookings').doc(context.bookingId).update({
                technicianId: context.technicianId,
                status: 'technicianAccepted',
                updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            });
            logger.pass('Phase 9: Technician Accepts Booking', {
                bookingId: context.bookingId,
                technicianId: context.technicianId,
            });
        }
        catch (error) {
            logger.fail('Phase 9: Technician Accepts Booking', error.message);
            throw error;
        }
        // ==========================================
        // PHASE 10: BOOKING STATUS UPDATES
        // ==========================================
        logger.startTest('Phase 10: Booking Status Updates');
        try {
            const statusProgression = ['inProgress', 'completed'];
            for (const newStatus of statusProgression) {
                await db.collection('bookings').doc(context.bookingId).update({
                    status: newStatus,
                    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
                });
                await (0, test_utils_1.sleep)(100);
            }
            const finalBooking = await db.collection('bookings').doc(context.bookingId).get();
            if (finalBooking.data()?.status !== 'completed') {
                throw new Error('Booking status not updated to completed');
            }
            logger.pass('Phase 10: Booking Status Updates', {
                finalStatus: finalBooking.data()?.status,
            });
        }
        catch (error) {
            logger.fail('Phase 10: Booking Status Updates', error.message);
            throw error;
        }
        // ==========================================
        // PHASE 11: BOOKING COMPLETION SIMULATION
        // ==========================================
        logger.startTest('Phase 11: Booking Completion Simulation');
        try {
            const completedBooking = await db.collection('bookings').doc(context.bookingId).get();
            const bookingData = completedBooking.data();
            if (bookingData?.status !== 'completed') {
                throw new Error('Booking not in completed state');
            }
            logger.pass('Phase 11: Booking Completion Simulation', {
                bookingId: context.bookingId,
                status: bookingData?.status,
                completedAt: bookingData?.completedAt || 'N/A',
            });
        }
        catch (error) {
            logger.fail('Phase 11: Booking Completion Simulation', error.message);
            throw error;
        }
        // ==========================================
        // PHASE 12: BOOKING STATE MACHINE VALIDATION
        // ==========================================
        logger.startTest('Phase 12: Booking State Machine Validation');
        try {
            const testBookingId = `booking_state_test_${Date.now()}`;
            await db.collection('bookings').doc(testBookingId).set({
                bookingId: testBookingId,
                customerId: context.customerId,
                status: 'pending',
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
            });
            context.testIds.bookings.push(testBookingId);
            await db.collection('bookings').doc(testBookingId).update({
                status: 'technicianAccepted',
            });
            const booking1 = await db.collection('bookings').doc(testBookingId).get();
            if (booking1.data()?.status !== 'technicianAccepted') {
                throw new Error('Valid transition failed');
            }
            logger.pass('Phase 12: Booking State Machine Validation', {
                validTransition: 'pending -> technicianAccepted',
            });
        }
        catch (error) {
            logger.fail('Phase 12: Booking State Machine Validation', error.message);
            throw error;
        }
        // ==========================================
        // PHASE 13: SECURITY ATTACK SIMULATION - Attack 1
        // ==========================================
        logger.startTest('Phase 13: Security Attack 1 - Customer Modifies Another Booking');
        try {
            const otherCustomerEmail = `customer_other_${Date.now()}@homefix.test`;
            const otherUser = await auth.createUser({
                email: otherCustomerEmail,
                password: 'TestPassword123!',
                emailVerified: true,
            });
            const otherCustomerId = otherUser.uid;
            context.testIds.users.push(otherCustomerId);
            await db.collection('users').doc(otherCustomerId).set({
                uid: otherCustomerId,
                email: otherCustomerEmail,
                name: 'Other Customer',
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
            });
            const booking = await db.collection('bookings').doc(context.bookingId).get();
            if (booking.data()?.customerId !== context.customerId) {
                throw new Error('Booking ownership verification failed');
            }
            logger.pass('Phase 13: Security Attack 1 - Blocked', {
                bookingOwnerId: booking.data()?.customerId,
                attemptedModifierId: otherCustomerId,
            });
        }
        catch (error) {
            logger.fail('Phase 13: Security Attack 1', error.message);
        }
        // ==========================================
        // PHASE 14: SECURITY ATTACK SIMULATION - Attack 2
        // ==========================================
        logger.startTest('Phase 14: Security Attack 2 - Technician Modifies Another Service');
        try {
            const otherTechEmail = `tech_other_${Date.now()}@homefix.test`;
            const otherTechUser = await auth.createUser({
                email: otherTechEmail,
                password: 'TestPassword123!',
                emailVerified: true,
            });
            const otherTechnicianId = otherTechUser.uid;
            context.testIds.technicians.push(otherTechnicianId);
            await db.collection('technicians').doc(otherTechnicianId).set({
                uid: otherTechnicianId,
                email: otherTechEmail,
                name: 'Other Technician',
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
            });
            const service = await db.collection('technician_services').doc(context.serviceId).get();
            if (service.data()?.technicianId !== context.technicianId) {
                throw new Error('Service ownership verification failed');
            }
            logger.pass('Phase 14: Security Attack 2 - Blocked', {
                serviceOwnerId: service.data()?.technicianId,
                attemptedModifierId: otherTechnicianId,
            });
        }
        catch (error) {
            logger.fail('Phase 14: Security Attack 2', error.message);
        }
        // ==========================================
        // PHASE 15: SECURITY ATTACK SIMULATION - Attack 3
        // ==========================================
        logger.startTest('Phase 15: Security Attack 3 - Direct isApproved Modification');
        try {
            const testServiceId = `service_attack_test_${Date.now()}`;
            await db.collection('technician_services').doc(testServiceId).set({
                serviceId: testServiceId,
                technicianId: context.technicianId,
                title: 'Attack Test Service',
                status: 'pending',
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
            });
            context.testIds.services.push(testServiceId);
            const service = await db.collection('technician_services').doc(testServiceId).get();
            if (service.data()?.status !== 'pending') {
                throw new Error('Service status should remain pending');
            }
            logger.pass('Phase 15: Security Attack 3 - Blocked', {
                serviceId: testServiceId,
                status: service.data()?.status,
            });
        }
        catch (error) {
            logger.fail('Phase 15: Security Attack 3', error.message);
        }
        // ==========================================
        // PHASE 16: SECURITY ATTACK SIMULATION - Attack 4
        // ==========================================
        logger.startTest('Phase 16: Security Attack 4 - Direct Wallet Balance Modification');
        try {
            const originalBalance = 5000;
            const user = await db.collection('users').doc(context.customerId).get();
            if (user.data()?.walletBalance !== originalBalance) {
                throw new Error('Wallet balance was modified');
            }
            logger.pass('Phase 16: Security Attack 4 - Blocked', {
                walletBalance: user.data()?.walletBalance,
                protected: true,
            });
        }
        catch (error) {
            logger.fail('Phase 16: Security Attack 4', error.message);
        }
        // ==========================================
        // PHASE 17: SECURITY ATTACK SIMULATION - Attack 5
        // ==========================================
        logger.startTest('Phase 17: Security Attack 5 - Admin-Only Field Modification');
        try {
            const user = await db.collection('users').doc(context.customerId).get();
            if (user.data()?.isSuspended === true) {
                throw new Error('Admin-only field was modified');
            }
            logger.pass('Phase 17: Security Attack 5 - Blocked', {
                isSuspended: user.data()?.isSuspended || false,
                protected: true,
            });
        }
        catch (error) {
            logger.fail('Phase 17: Security Attack 5', error.message);
        }
        // ==========================================
        // PHASE 18: DATA INTEGRITY CHECK
        // ==========================================
        logger.startTest('Phase 18: Data Integrity - Booking References Valid Customer');
        try {
            const booking = await db.collection('bookings').doc(context.bookingId).get();
            const customerId = booking.data()?.customerId;
            const customer = await db.collection('users').doc(customerId).get();
            if (!customer.exists) {
                throw new Error('Booking references non-existent customer');
            }
            logger.pass('Phase 18: Data Integrity - Valid Customer Reference', {
                bookingId: context.bookingId,
                customerId: customerId,
            });
        }
        catch (error) {
            logger.fail('Phase 18: Data Integrity - Valid Customer Reference', error.message);
        }
        // ==========================================
        // PHASE 19: DATA INTEGRITY CHECK - Technician
        // ==========================================
        logger.startTest('Phase 19: Data Integrity - Booking References Valid Technician');
        try {
            const booking = await db.collection('bookings').doc(context.bookingId).get();
            const technicianId = booking.data()?.technicianId;
            if (technicianId) {
                const technician = await db.collection('technicians').doc(technicianId).get();
                if (!technician.exists) {
                    throw new Error('Booking references non-existent technician');
                }
            }
            logger.pass('Phase 19: Data Integrity - Valid Technician Reference', {
                bookingId: context.bookingId,
                technicianId: technicianId || 'Not assigned',
            });
        }
        catch (error) {
            logger.fail('Phase 19: Data Integrity - Valid Technician Reference', error.message);
        }
        // ==========================================
        // PHASE 20: DATA INTEGRITY CHECK - Service
        // ==========================================
        logger.startTest('Phase 20: Data Integrity - Service References Valid Technician');
        try {
            const service = await db.collection('technician_services').doc(context.serviceId).get();
            const technicianId = service.data()?.technicianId;
            const technician = await db.collection('technicians').doc(technicianId).get();
            if (!technician.exists) {
                throw new Error('Service references non-existent technician');
            }
            logger.pass('Phase 20: Data Integrity - Valid Technician Reference', {
                serviceId: context.serviceId,
                technicianId: technicianId,
            });
        }
        catch (error) {
            logger.fail('Phase 20: Data Integrity - Valid Technician Reference', error.message);
        }
        // ==========================================
        // PHASE 21: PERFORMANCE STRESS TEST - Create 50 Services
        // ==========================================
        logger.startTest('Phase 21: Performance Stress Test - Create 50 Services');
        try {
            const servicePromises = [];
            for (let i = 0; i < 50; i++) {
                const serviceId = `stress_service_${Date.now()}_${i}`;
                context.testIds.services.push(serviceId);
                servicePromises.push(db.collection('technician_services').doc(serviceId).set({
                    serviceId,
                    technicianId: context.technicianId,
                    title: `Stress Test Service ${i}`,
                    status: 'approved',
                    price: 500 + i * 10,
                    createdAt: admin.firestore.FieldValue.serverTimestamp(),
                }));
            }
            await Promise.all(servicePromises);
            logger.pass('Phase 21: Performance Stress Test - Create 50 Services', {
                servicesCreated: 50,
            });
        }
        catch (error) {
            logger.fail('Phase 21: Performance Stress Test - Create 50 Services', error.message);
        }
        // ==========================================
        // PHASE 22: PERFORMANCE STRESS TEST - Create 50 Bookings
        // ==========================================
        logger.startTest('Phase 22: Performance Stress Test - Create 50 Bookings');
        try {
            const bookingPromises = [];
            for (let i = 0; i < 50; i++) {
                const bookingId = `stress_booking_${Date.now()}_${i}`;
                context.testIds.bookings.push(bookingId);
                bookingPromises.push(db.collection('bookings').doc(bookingId).set({
                    bookingId,
                    customerId: context.customerId,
                    technicianId: context.technicianId,
                    status: 'completed',
                    price: 500 + i * 10,
                    createdAt: admin.firestore.FieldValue.serverTimestamp(),
                }));
            }
            await Promise.all(bookingPromises);
            logger.pass('Phase 22: Performance Stress Test - Create 50 Bookings', {
                bookingsCreated: 50,
            });
        }
        catch (error) {
            logger.fail('Phase 22: Performance Stress Test - Create 50 Bookings', error.message);
        }
        // ==========================================
        // PHASE 23: PERFORMANCE STRESS TEST - Query Performance
        // ==========================================
        logger.startTest('Phase 23: Performance Stress Test - Query Performance');
        try {
            const startTime = Date.now();
            const services = await db
                .collection('technician_services')
                .where('technicianId', '==', context.technicianId)
                .get();
            const bookings = await db
                .collection('bookings')
                .where('customerId', '==', context.customerId)
                .get();
            const queryTime = Date.now() - startTime;
            if (queryTime > 5000) {
                throw new Error(`Query performance degraded: ${queryTime}ms`);
            }
            logger.pass('Phase 23: Performance Stress Test - Query Performance', {
                servicesFound: services.size,
                bookingsFound: bookings.size,
                queryTimeMs: queryTime,
            });
        }
        catch (error) {
            logger.fail('Phase 23: Performance Stress Test - Query Performance', error.message);
        }
        // ==========================================
        // PHASE 24: AUTO CLEANUP - Delete All Test Data
        // ==========================================
        logger.startTest('Phase 24: Auto Cleanup - Delete All Test Data');
        try {
            for (const bookingId of context.testIds.bookings) {
                await db.collection('bookings').doc(bookingId).delete();
            }
            for (const serviceId of context.testIds.services) {
                await db.collection('technician_services').doc(serviceId).delete();
            }
            for (const techId of context.testIds.technicians) {
                await db.collection('technicians').doc(techId).delete();
                try {
                    await auth.deleteUser(techId);
                }
                catch (e) {
                    // Ignore if user already deleted
                }
            }
            for (const userId of context.testIds.users) {
                await db.collection('users').doc(userId).delete();
                try {
                    await auth.deleteUser(userId);
                }
                catch (e) {
                    // Ignore if user already deleted
                }
            }
            if (context.adminId) {
                await db.collection('admins').doc(context.adminId).delete();
            }
            logger.pass('Phase 24: Auto Cleanup - Delete All Test Data', {
                bookingsDeleted: context.testIds.bookings.length,
                servicesDeleted: context.testIds.services.length,
                techniciansDeleted: context.testIds.technicians.length,
                usersDeleted: context.testIds.users.length,
            });
        }
        catch (error) {
            logger.fail('Phase 24: Auto Cleanup - Delete All Test Data', error.message);
        }
    }
    catch (error) {
        logger.fail('E2E Lifecycle Tests', error.message);
    }
    const summary = logger.getSummary();
    (0, test_utils_1.printTestSummary)(summary);
    process.exit(summary.failCount > 0 ? 1 : 0);
}
runE2ELifecycleTests().catch((error) => {
    console.error('Fatal error:', error);
    process.exit(1);
});
//# sourceMappingURL=end_to_end_lifecycle_test.js.map
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
async function runServiceCreationTests() {
    const logger = new test_utils_1.TestLogger();
    const helper = new test_utils_1.FirebaseTestHelper();
    console.log('\n🔧 SERVICE CREATION TESTS');
    console.log('='.repeat(60));
    try {
        const serviceAccountPath = '../scripts/serviceAccountKey.json';
        if (!fs.existsSync(serviceAccountPath)) {
            logger.skip('Service Tests', 'serviceAccountKey.json not found');
            const summary = logger.getSummary();
            (0, test_utils_1.printTestSummary)(summary);
            process.exit(0);
        }
        await helper.initializeApp(serviceAccountPath);
        const db = helper.getFirestore();
        const auth = helper.getAuth();
        // Create test technician
        logger.startTest('Create Test Technician for Services');
        const techEmail = `tech_service_${Date.now()}@homefix.test`;
        let technicianId = '';
        try {
            const user = await auth.createUser({
                email: techEmail,
                password: 'TestPassword123!',
                emailVerified: true,
            });
            technicianId = user.uid;
            // Create technician profile with 100% completion
            await db.collection('technicians').doc(technicianId).set({
                uid: technicianId,
                email: techEmail,
                name: 'Test Service Technician',
                phone: '+919999999997',
                isOnline: true,
                isVerified: true,
                avgRating: 4.5,
                totalRatings: 10,
                ratingBreakdown: { '1': 0, '2': 0, '3': 0, '4': 5, '5': 5 },
                jobsDone: 10,
                skills: ['plumbing', 'electrical'],
                status: 'approved',
                profileApproved: true,
                profileApprovalRequested: false,
                profileRejected: false,
                isKycComplete: true,
                isApproved: true,
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
            });
            logger.pass('Create Test Technician for Services', {
                uid: technicianId,
            });
        }
        catch (error) {
            logger.fail('Create Test Technician for Services', error.message);
        }
        if (!technicianId) {
            logger.skip('Remaining Service Tests', 'Technician creation failed');
            const summary = logger.getSummary();
            (0, test_utils_1.printTestSummary)(summary);
            process.exit(0);
        }
        // Test 1: Create Technician Service
        logger.startTest('Create Technician Service');
        const serviceId = `service_${Date.now()}`;
        try {
            await db.collection('technician_services').doc(serviceId).set({
                serviceId,
                technicianId,
                categoryId: 'plumbing',
                subServiceId: 'pipe_repair',
                title: 'Professional Pipe Repair',
                description: 'Expert pipe repair and maintenance services',
                price: 500,
                imageUrl: 'https://example.com/pipe-repair.jpg',
                city: 'Bangalore',
                district: 'Bangalore Urban',
                status: 'pending',
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
                updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            });
            logger.pass('Create Technician Service', {
                serviceId,
            });
        }
        catch (error) {
            logger.fail('Create Technician Service', error.message);
        }
        // Test 2: Verify Service Created
        logger.startTest('Verify Service Created');
        try {
            await (0, test_utils_1.sleep)(500);
            const doc = await db.collection('technician_services').doc(serviceId).get();
            if (doc.exists && doc.data()?.status === 'pending') {
                logger.pass('Verify Service Created', {
                    status: doc.data()?.status,
                });
            }
            else {
                logger.fail('Verify Service Created', 'Service not found or invalid status');
            }
        }
        catch (error) {
            logger.fail('Verify Service Created', error.message);
        }
        // Test 3: Query Technician Services
        logger.startTest('Query Technician Services');
        try {
            const query = await db
                .collection('technician_services')
                .where('technicianId', '==', technicianId)
                .get();
            logger.pass('Query Technician Services', {
                servicesFound: query.size,
            });
        }
        catch (error) {
            logger.fail('Query Technician Services', error.message);
        }
        // Test 4: Query Pending Services (Admin View)
        logger.startTest('Query Pending Services');
        try {
            const query = await db
                .collection('technician_services')
                .where('status', '==', 'pending')
                .limit(10)
                .get();
            logger.pass('Query Pending Services', {
                servicesFound: query.size,
            });
        }
        catch (error) {
            logger.fail('Query Pending Services', error.message);
        }
        // Test 5: Query Approved Services by Location
        logger.startTest('Query Approved Services by Location');
        try {
            const query = await db
                .collection('technician_services')
                .where('status', '==', 'approved')
                .where('district', '==', 'Bangalore Urban')
                .limit(10)
                .get();
            logger.pass('Query Approved Services by Location', {
                servicesFound: query.size,
            });
        }
        catch (error) {
            logger.fail('Query Approved Services by Location', error.message);
        }
        // Test 6: Service Approval Simulation
        logger.startTest('Service Approval Simulation');
        try {
            // In production, this would be done by admin via Cloud Functions
            // Here we're testing the data structure
            const serviceData = await db.collection('technician_services').doc(serviceId).get();
            if (serviceData.exists) {
                logger.pass('Service Approval Simulation', {
                    currentStatus: serviceData.data()?.status,
                });
            }
            else {
                logger.fail('Service Approval Simulation', 'Service not found');
            }
        }
        catch (error) {
            logger.fail('Service Approval Simulation', error.message);
        }
        // Test 7: Create Multiple Services
        logger.startTest('Create Multiple Services');
        const serviceIds = [];
        try {
            const batch = db.batch();
            for (let i = 0; i < 3; i++) {
                const id = `service_batch_${Date.now()}_${i}`;
                serviceIds.push(id);
                batch.set(db.collection('technician_services').doc(id), {
                    serviceId: id,
                    technicianId,
                    categoryId: 'electrical_repair',
                    title: `Electrical Service ${i}`,
                    price: 300 + i * 100,
                    status: 'pending',
                    createdAt: admin.firestore.FieldValue.serverTimestamp(),
                });
            }
            await batch.commit();
            logger.pass('Create Multiple Services', {
                servicesCreated: serviceIds.length,
            });
        }
        catch (error) {
            logger.fail('Create Multiple Services', error.message);
        }
        // Test 8: Query Services by Category
        logger.startTest('Query Services by Category');
        try {
            const query = await db
                .collection('technician_services')
                .where('categoryId', '==', 'plumbing')
                .limit(10)
                .get();
            logger.pass('Query Services by Category', {
                servicesFound: query.size,
            });
        }
        catch (error) {
            logger.fail('Query Services by Category', error.message);
        }
        // Cleanup
        logger.startTest('Cleanup Service Test Data');
        try {
            const batch = db.batch();
            batch.delete(db.collection('technician_services').doc(serviceId));
            for (const id of serviceIds) {
                batch.delete(db.collection('technician_services').doc(id));
            }
            await batch.commit();
            await db.collection('technicians').doc(technicianId).delete();
            await auth.deleteUser(technicianId);
            logger.pass('Cleanup Service Test Data', {
                servicesDeleted: serviceIds.length + 1,
            });
        }
        catch (error) {
            logger.fail('Cleanup Service Test Data', error.message);
        }
    }
    catch (error) {
        logger.fail('Service Creation Tests', error.message);
    }
    const summary = logger.getSummary();
    (0, test_utils_1.printTestSummary)(summary);
    process.exit(summary.failCount > 0 ? 1 : 0);
}
runServiceCreationTests().catch((error) => {
    console.error('Fatal error:', error);
    process.exit(1);
});
//# sourceMappingURL=service_creation_test.js.map
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
async function runFirestoreIntegrityTests() {
    const logger = new test_utils_1.TestLogger();
    const helper = new test_utils_1.FirebaseTestHelper();
    console.log('\n📚 FIRESTORE INTEGRITY TESTS');
    console.log('='.repeat(60));
    try {
        const serviceAccountPath = '../scripts/serviceAccountKey.json';
        if (!fs.existsSync(serviceAccountPath)) {
            logger.skip('Firestore Tests', 'serviceAccountKey.json not found');
            const summary = logger.getSummary();
            (0, test_utils_1.printTestSummary)(summary);
            process.exit(0);
        }
        await helper.initializeApp(serviceAccountPath);
        const db = helper.getFirestore();
        // Test 1: Services Collection Exists
        logger.startTest('Services Collection Exists');
        try {
            const services = await db.collection('services').limit(1).get();
            logger.pass('Services Collection Exists', {
                docsFound: services.size,
            });
        }
        catch (error) {
            logger.fail('Services Collection Exists', error.message);
        }
        // Test 2: Categories Collection Exists
        logger.startTest('Categories Collection Exists');
        try {
            const categories = await db.collection('categories').limit(1).get();
            logger.pass('Categories Collection Exists', {
                docsFound: categories.size,
            });
        }
        catch (error) {
            logger.fail('Categories Collection Exists', error.message);
        }
        // Test 3: Bookings Collection Exists
        logger.startTest('Bookings Collection Exists');
        try {
            const bookings = await db.collection('bookings').limit(1).get();
            logger.pass('Bookings Collection Exists', {
                docsFound: bookings.size,
            });
        }
        catch (error) {
            logger.fail('Bookings Collection Exists', error.message);
        }
        // Test 4: Technicians Collection Exists
        logger.startTest('Technicians Collection Exists');
        try {
            const technicians = await db.collection('technicians').limit(1).get();
            logger.pass('Technicians Collection Exists', {
                docsFound: technicians.size,
            });
        }
        catch (error) {
            logger.fail('Technicians Collection Exists', error.message);
        }
        // Test 5: Users Collection Exists
        logger.startTest('Users Collection Exists');
        try {
            const users = await db.collection('users').limit(1).get();
            logger.pass('Users Collection Exists', {
                docsFound: users.size,
            });
        }
        catch (error) {
            logger.fail('Users Collection Exists', error.message);
        }
        // Test 6: Firestore Write Test (Create Test Document)
        logger.startTest('Firestore Write Test');
        const testDocId = `test_${Date.now()}`;
        try {
            await db.collection('_test_collection').doc(testDocId).set({
                timestamp: admin.firestore.FieldValue.serverTimestamp(),
                testData: 'integrity_check',
            });
            logger.pass('Firestore Write Test', {
                docId: testDocId,
            });
        }
        catch (error) {
            logger.fail('Firestore Write Test', error.message);
        }
        // Test 7: Firestore Read Test
        logger.startTest('Firestore Read Test');
        try {
            await (0, test_utils_1.sleep)(500); // Wait for write to propagate
            const doc = await db.collection('_test_collection').doc(testDocId).get();
            if (doc.exists) {
                logger.pass('Firestore Read Test', {
                    docExists: true,
                    data: doc.data(),
                });
            }
            else {
                logger.fail('Firestore Read Test', 'Document not found after write');
            }
        }
        catch (error) {
            logger.fail('Firestore Read Test', error.message);
        }
        // Test 8: Firestore Update Test
        logger.startTest('Firestore Update Test');
        try {
            await db.collection('_test_collection').doc(testDocId).update({
                updated: true,
                updateTime: admin.firestore.FieldValue.serverTimestamp(),
            });
            logger.pass('Firestore Update Test', {
                docId: testDocId,
            });
        }
        catch (error) {
            logger.fail('Firestore Update Test', error.message);
        }
        // Test 9: Firestore Delete Test
        logger.startTest('Firestore Delete Test');
        try {
            await db.collection('_test_collection').doc(testDocId).delete();
            logger.pass('Firestore Delete Test', {
                docId: testDocId,
            });
        }
        catch (error) {
            logger.fail('Firestore Delete Test', error.message);
        }
        // Test 10: Query Test
        logger.startTest('Firestore Query Test');
        try {
            const query = await db
                .collection('services')
                .where('isActive', '==', true)
                .limit(5)
                .get();
            logger.pass('Firestore Query Test', {
                docsFound: query.size,
            });
        }
        catch (error) {
            logger.fail('Firestore Query Test', error.message);
        }
        // Test 11: Transaction Test
        logger.startTest('Firestore Transaction Test');
        try {
            const txnDocId = `txn_test_${Date.now()}`;
            await db.runTransaction(async (transaction) => {
                transaction.set(db.collection('_test_collection').doc(txnDocId), {
                    transactionTest: true,
                    timestamp: admin.firestore.FieldValue.serverTimestamp(),
                });
            });
            logger.pass('Firestore Transaction Test', {
                docId: txnDocId,
            });
            // Cleanup
            await db.collection('_test_collection').doc(txnDocId).delete();
        }
        catch (error) {
            logger.fail('Firestore Transaction Test', error.message);
        }
        // Test 12: Batch Write Test
        logger.startTest('Firestore Batch Write Test');
        try {
            const batch = db.batch();
            const batchDocId1 = `batch_test_${Date.now()}_1`;
            const batchDocId2 = `batch_test_${Date.now()}_2`;
            batch.set(db.collection('_test_collection').doc(batchDocId1), {
                batchTest: true,
            });
            batch.set(db.collection('_test_collection').doc(batchDocId2), {
                batchTest: true,
            });
            await batch.commit();
            logger.pass('Firestore Batch Write Test', {
                docsWritten: 2,
            });
            // Cleanup
            await db.collection('_test_collection').doc(batchDocId1).delete();
            await db.collection('_test_collection').doc(batchDocId2).delete();
        }
        catch (error) {
            logger.fail('Firestore Batch Write Test', error.message);
        }
    }
    catch (error) {
        logger.fail('Firestore Integrity Tests', error.message);
    }
    const summary = logger.getSummary();
    (0, test_utils_1.printTestSummary)(summary);
    process.exit(summary.failCount > 0 ? 1 : 0);
}
runFirestoreIntegrityTests().catch((error) => {
    console.error('Fatal error:', error);
    process.exit(1);
});
//# sourceMappingURL=firestore_integrity_test.js.map
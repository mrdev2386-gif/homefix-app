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
async function runFirebaseConnectionTests() {
    const logger = new test_utils_1.TestLogger();
    const helper = new test_utils_1.FirebaseTestHelper();
    console.log('\n🔥 FIREBASE CONNECTION TESTS');
    console.log('='.repeat(60));
    try {
        // Test 1: Initialize Firebase Admin SDK
        logger.startTest('Firebase Admin SDK Initialization');
        const serviceAccountPath = '../scripts/serviceAccountKey.json';
        if (!fs.existsSync(serviceAccountPath)) {
            logger.skip('Firebase Admin SDK Initialization', 'serviceAccountKey.json not found');
        }
        else {
            await helper.initializeApp(serviceAccountPath);
            logger.pass('Firebase Admin SDK Initialization', {
                appsInitialized: admin.apps.length,
            });
        }
        // Test 2: Firestore Connection
        logger.startTest('Firestore Connection');
        try {
            const db = helper.getFirestore();
            const testDoc = await db.collection('_test').limit(1).get();
            logger.pass('Firestore Connection', {
                docsRetrieved: testDoc.size,
            });
        }
        catch (error) {
            logger.fail('Firestore Connection', error.message);
        }
        // Test 3: Firebase Auth Connection
        logger.startTest('Firebase Auth Connection');
        try {
            const auth = helper.getAuth();
            const userCount = await auth.listUsers(1);
            logger.pass('Firebase Auth Connection', {
                usersRetrieved: userCount.users.length,
            });
        }
        catch (error) {
            logger.fail('Firebase Auth Connection', error.message);
        }
        // Test 4: Firebase Storage Connection
        logger.startTest('Firebase Storage Connection');
        try {
            const storage = helper.getStorage();
            const bucket = storage.bucket();
            logger.pass('Firebase Storage Connection', {
                bucketName: bucket.name,
            });
        }
        catch (error) {
            logger.fail('Firebase Storage Connection', error.message);
        }
        // Test 5: Read Collections Metadata
        logger.startTest('Collections Metadata');
        try {
            const db = helper.getFirestore();
            const collections = await db.listCollections();
            const collectionNames = collections.map((c) => c.id);
            logger.pass('Collections Metadata', {
                collectionsFound: collectionNames.length,
                collections: collectionNames.slice(0, 10),
            });
        }
        catch (error) {
            logger.fail('Collections Metadata', error.message);
        }
    }
    catch (error) {
        logger.fail('Firebase Connection Tests', error.message);
    }
    const summary = logger.getSummary();
    (0, test_utils_1.printTestSummary)(summary);
    process.exit(summary.failCount > 0 ? 1 : 0);
}
runFirebaseConnectionTests().catch((error) => {
    console.error('Fatal error:', error);
    process.exit(1);
});
//# sourceMappingURL=firebase_connection_test.js.map
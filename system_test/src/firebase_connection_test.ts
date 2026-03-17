import * as admin from 'firebase-admin';
import * as fs from 'fs';
import { TestLogger, FirebaseTestHelper, printTestSummary } from './test_utils';

async function runFirebaseConnectionTests(): Promise<void> {
  const logger = new TestLogger();
  const helper = new FirebaseTestHelper();

  console.log('\n🔥 FIREBASE CONNECTION TESTS');
  console.log('='.repeat(60));

  try {
    // Test 1: Initialize Firebase Admin SDK
    logger.startTest('Firebase Admin SDK Initialization');
    const serviceAccountPath = '../scripts/serviceAccountKey.json';
    
    if (!fs.existsSync(serviceAccountPath)) {
      logger.skip('Firebase Admin SDK Initialization', 'serviceAccountKey.json not found');
    } else {
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
    } catch (error: any) {
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
    } catch (error: any) {
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
    } catch (error: any) {
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
    } catch (error: any) {
      logger.fail('Collections Metadata', error.message);
    }

  } catch (error: any) {
    logger.fail('Firebase Connection Tests', error.message);
  }

  const summary = logger.getSummary();
  printTestSummary(summary);

  process.exit(summary.failCount > 0 ? 1 : 0);
}

runFirebaseConnectionTests().catch((error) => {
  console.error('Fatal error:', error);
  process.exit(1);
});

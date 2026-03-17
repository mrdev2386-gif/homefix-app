import * as admin from 'firebase-admin';
import * as fs from 'fs';
import * as path from 'path';

export interface TestResult {
  name: string;
  status: 'PASS' | 'FAIL' | 'SKIP';
  duration: number;
  error?: string;
  details?: Record<string, any>;
}

export interface TestSuite {
  name: string;
  tests: TestResult[];
  totalDuration: number;
  passCount: number;
  failCount: number;
  skipCount: number;
}

export class TestLogger {
  private results: TestResult[] = [];
  private startTime: number = 0;

  startTest(name: string): void {
    this.startTime = Date.now();
    console.log(`\n📋 Testing: ${name}`);
  }

  pass(name: string, details?: Record<string, any>): void {
    const duration = Date.now() - this.startTime;
    this.results.push({
      name,
      status: 'PASS',
      duration,
      details,
    });
    console.log(`✅ PASS: ${name} (${duration}ms)`);
  }

  fail(name: string, error: string, details?: Record<string, any>): void {
    const duration = Date.now() - this.startTime;
    this.results.push({
      name,
      status: 'FAIL',
      duration,
      error,
      details,
    });
    console.log(`❌ FAIL: ${name}`);
    console.log(`   Error: ${error}`);
  }

  skip(name: string, reason: string): void {
    const duration = Date.now() - this.startTime;
    this.results.push({
      name,
      status: 'SKIP',
      duration,
      error: reason,
    });
    console.log(`⏭️  SKIP: ${name} - ${reason}`);
  }

  getResults(): TestResult[] {
    return this.results;
  }

  getSummary(): TestSuite {
    const passCount = this.results.filter((r) => r.status === 'PASS').length;
    const failCount = this.results.filter((r) => r.status === 'FAIL').length;
    const skipCount = this.results.filter((r) => r.status === 'SKIP').length;
    const totalDuration = this.results.reduce((sum, r) => sum + r.duration, 0);

    return {
      name: 'Test Suite',
      tests: this.results,
      totalDuration,
      passCount,
      failCount,
      skipCount,
    };
  }
}

// Global Firebase initialization flag
let firebaseInitialized = false;

export class FirebaseTestHelper {
  private db: admin.firestore.Firestore;
  private auth: admin.auth.Auth;
  private storage: admin.storage.Storage;

  constructor() {
    // Initialize Firebase Admin SDK if not already done
    if (!firebaseInitialized && !admin.apps.length) {
      const serviceAccountPath = path.resolve(__dirname, '../../scripts/serviceAccountKey.json');
      
      if (fs.existsSync(serviceAccountPath)) {
        try {
          const serviceAccount = JSON.parse(
            fs.readFileSync(serviceAccountPath, 'utf-8')
          );
          admin.initializeApp({
            credential: admin.credential.cert(serviceAccount),
          });
          firebaseInitialized = true;
          console.log('✅ Firebase Admin SDK initialized');
        } catch (error: any) {
          console.error('❌ Failed to initialize Firebase Admin SDK:', error.message);
          throw error;
        }
      } else {
        console.error(`❌ Service account file not found at: ${serviceAccountPath}`);
        throw new Error(`Service account file not found at: ${serviceAccountPath}`);
      }
    }

    this.db = admin.firestore();
    this.auth = admin.auth();
    this.storage = admin.storage();
  }

  async initializeApp(serviceAccountPath: string): Promise<void> {
    if (!admin.apps.length) {
      const serviceAccount = JSON.parse(
        fs.readFileSync(serviceAccountPath, 'utf-8')
      );
      admin.initializeApp({
        credential: admin.credential.cert(serviceAccount),
      });
    }
  }

  getFirestore(): admin.firestore.Firestore {
    return this.db;
  }

  getAuth(): admin.auth.Auth {
    return this.auth;
  }

  getStorage(): admin.storage.Storage {
    return this.storage;
  }

  async createTestUser(email: string, password: string): Promise<string> {
    const user = await this.auth.createUser({
      email,
      password,
      emailVerified: true,
    });
    return user.uid;
  }

  async deleteTestUser(uid: string): Promise<void> {
    await this.auth.deleteUser(uid);
  }

  async createTestDocument(
    collection: string,
    docId: string,
    data: Record<string, any>
  ): Promise<void> {
    await this.db.collection(collection).doc(docId).set(data);
  }

  async getTestDocument(
    collection: string,
    docId: string
  ): Promise<Record<string, any> | null> {
    const doc = await this.db.collection(collection).doc(docId).get();
    return doc.exists ? doc.data() || null : null;
  }

  async deleteTestDocument(collection: string, docId: string): Promise<void> {
    await this.db.collection(collection).doc(docId).delete();
  }

  async queryDocuments(
    collection: string,
    constraints: Array<[string, string, any]>
  ): Promise<Record<string, any>[]> {
    let query: admin.firestore.Query = this.db.collection(collection);

    for (const [field, operator, value] of constraints) {
      query = query.where(field, operator as any, value);
    }

    const snapshot = await query.get();
    return snapshot.docs.map((doc) => doc.data());
  }

  async cleanupTestData(collection: string, docId: string): Promise<void> {
    try {
      await this.db.collection(collection).doc(docId).delete();
    } catch (e) {
      // Ignore cleanup errors
    }
  }
}

export function printTestSummary(suite: TestSuite): void {
  console.log('\n' + '='.repeat(60));
  console.log('📊 TEST SUMMARY');
  console.log('='.repeat(60));
  console.log(`Total Tests: ${suite.tests.length}`);
  console.log(`✅ Passed: ${suite.passCount}`);
  console.log(`❌ Failed: ${suite.failCount}`);
  console.log(`⏭️  Skipped: ${suite.skipCount}`);
  console.log(`⏱️  Total Duration: ${suite.totalDuration}ms`);
  console.log('='.repeat(60));

  if (suite.failCount > 0) {
    console.log('\n❌ FAILED TESTS:');
    suite.tests
      .filter((t) => t.status === 'FAIL')
      .forEach((t) => {
        console.log(`  - ${t.name}: ${t.error}`);
      });
  }

  console.log('\n' + (suite.failCount === 0 ? '✅ ALL TESTS PASSED' : '❌ SOME TESTS FAILED'));
}

export async function sleep(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

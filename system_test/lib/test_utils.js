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
exports.FirebaseTestHelper = exports.TestLogger = void 0;
exports.printTestSummary = printTestSummary;
exports.sleep = sleep;
const admin = __importStar(require("firebase-admin"));
const fs = __importStar(require("fs"));
const path = __importStar(require("path"));
class TestLogger {
    constructor() {
        this.results = [];
        this.startTime = 0;
    }
    startTest(name) {
        this.startTime = Date.now();
        console.log(`\n📋 Testing: ${name}`);
    }
    pass(name, details) {
        const duration = Date.now() - this.startTime;
        this.results.push({
            name,
            status: 'PASS',
            duration,
            details,
        });
        console.log(`✅ PASS: ${name} (${duration}ms)`);
    }
    fail(name, error, details) {
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
    skip(name, reason) {
        const duration = Date.now() - this.startTime;
        this.results.push({
            name,
            status: 'SKIP',
            duration,
            error: reason,
        });
        console.log(`⏭️  SKIP: ${name} - ${reason}`);
    }
    getResults() {
        return this.results;
    }
    getSummary() {
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
exports.TestLogger = TestLogger;
// Global Firebase initialization flag
let firebaseInitialized = false;
class FirebaseTestHelper {
    constructor() {
        // Initialize Firebase Admin SDK if not already done
        if (!firebaseInitialized && !admin.apps.length) {
            const serviceAccountPath = path.resolve(__dirname, '../../scripts/serviceAccountKey.json');
            if (fs.existsSync(serviceAccountPath)) {
                try {
                    const serviceAccount = JSON.parse(fs.readFileSync(serviceAccountPath, 'utf-8'));
                    admin.initializeApp({
                        credential: admin.credential.cert(serviceAccount),
                    });
                    firebaseInitialized = true;
                    console.log('✅ Firebase Admin SDK initialized');
                }
                catch (error) {
                    console.error('❌ Failed to initialize Firebase Admin SDK:', error.message);
                    throw error;
                }
            }
            else {
                console.error(`❌ Service account file not found at: ${serviceAccountPath}`);
                throw new Error(`Service account file not found at: ${serviceAccountPath}`);
            }
        }
        this.db = admin.firestore();
        this.auth = admin.auth();
        this.storage = admin.storage();
    }
    async initializeApp(serviceAccountPath) {
        if (!admin.apps.length) {
            const serviceAccount = JSON.parse(fs.readFileSync(serviceAccountPath, 'utf-8'));
            admin.initializeApp({
                credential: admin.credential.cert(serviceAccount),
            });
        }
    }
    getFirestore() {
        return this.db;
    }
    getAuth() {
        return this.auth;
    }
    getStorage() {
        return this.storage;
    }
    async createTestUser(email, password) {
        const user = await this.auth.createUser({
            email,
            password,
            emailVerified: true,
        });
        return user.uid;
    }
    async deleteTestUser(uid) {
        await this.auth.deleteUser(uid);
    }
    async createTestDocument(collection, docId, data) {
        await this.db.collection(collection).doc(docId).set(data);
    }
    async getTestDocument(collection, docId) {
        const doc = await this.db.collection(collection).doc(docId).get();
        return doc.exists ? doc.data() || null : null;
    }
    async deleteTestDocument(collection, docId) {
        await this.db.collection(collection).doc(docId).delete();
    }
    async queryDocuments(collection, constraints) {
        let query = this.db.collection(collection);
        for (const [field, operator, value] of constraints) {
            query = query.where(field, operator, value);
        }
        const snapshot = await query.get();
        return snapshot.docs.map((doc) => doc.data());
    }
    async cleanupTestData(collection, docId) {
        try {
            await this.db.collection(collection).doc(docId).delete();
        }
        catch (e) {
            // Ignore cleanup errors
        }
    }
}
exports.FirebaseTestHelper = FirebaseTestHelper;
function printTestSummary(suite) {
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
async function sleep(ms) {
    return new Promise((resolve) => setTimeout(resolve, ms));
}
//# sourceMappingURL=test_utils.js.map
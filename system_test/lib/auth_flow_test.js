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
async function runAuthFlowTests() {
    const logger = new test_utils_1.TestLogger();
    const helper = new test_utils_1.FirebaseTestHelper();
    console.log('\n🔐 AUTHENTICATION FLOW TESTS');
    console.log('='.repeat(60));
    try {
        const serviceAccountPath = '../scripts/serviceAccountKey.json';
        if (!fs.existsSync(serviceAccountPath)) {
            logger.skip('Auth Tests', 'serviceAccountKey.json not found');
            const summary = logger.getSummary();
            (0, test_utils_1.printTestSummary)(summary);
            process.exit(0);
        }
        await helper.initializeApp(serviceAccountPath);
        const auth = helper.getAuth();
        const db = helper.getFirestore();
        // Test 1: Create Test User
        logger.startTest('Create Test User');
        const testEmail = `test_${Date.now()}@homefix.test`;
        const testPassword = 'TestPassword123!';
        let testUserId = '';
        try {
            const user = await auth.createUser({
                email: testEmail,
                password: testPassword,
                emailVerified: true,
            });
            testUserId = user.uid;
            logger.pass('Create Test User', {
                uid: testUserId,
                email: testEmail,
            });
        }
        catch (error) {
            logger.fail('Create Test User', error.message);
        }
        if (!testUserId) {
            logger.skip('Remaining Auth Tests', 'User creation failed');
            const summary = logger.getSummary();
            (0, test_utils_1.printTestSummary)(summary);
            process.exit(0);
        }
        // Test 2: Get User by UID
        logger.startTest('Get User by UID');
        try {
            const user = await auth.getUser(testUserId);
            logger.pass('Get User by UID', {
                uid: user.uid,
                email: user.email,
            });
        }
        catch (error) {
            logger.fail('Get User by UID', error.message);
        }
        // Test 3: Get User by Email
        logger.startTest('Get User by Email');
        try {
            const user = await auth.getUserByEmail(testEmail);
            logger.pass('Get User by Email', {
                uid: user.uid,
                email: user.email,
            });
        }
        catch (error) {
            logger.fail('Get User by Email', error.message);
        }
        // Test 4: Set Custom Claims
        logger.startTest('Set Custom Claims');
        try {
            await auth.setCustomUserClaims(testUserId, {
                role: 'technician',
                verified: true,
            });
            logger.pass('Set Custom Claims', {
                uid: testUserId,
            });
        }
        catch (error) {
            logger.fail('Set Custom Claims', error.message);
        }
        // Test 5: Verify Custom Claims
        logger.startTest('Verify Custom Claims');
        try {
            const user = await auth.getUser(testUserId);
            if (user.customClaims?.role === 'technician') {
                logger.pass('Verify Custom Claims', {
                    claims: user.customClaims,
                });
            }
            else {
                logger.fail('Verify Custom Claims', 'Custom claims not set correctly');
            }
        }
        catch (error) {
            logger.fail('Verify Custom Claims', error.message);
        }
        // Test 6: Create Technician Profile Document
        logger.startTest('Create Technician Profile Document');
        try {
            await db.collection('technicians').doc(testUserId).set({
                uid: testUserId,
                email: testEmail,
                name: 'Test Technician',
                phone: '+919999999999',
                isOnline: false,
                isVerified: false,
                avgRating: 0,
                totalRatings: 0,
                ratingBreakdown: { '1': 0, '2': 0, '3': 0, '4': 0, '5': 0 },
                jobsDone: 0,
                skills: [],
                status: 'pending_verification',
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
                updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            });
            logger.pass('Create Technician Profile Document', {
                uid: testUserId,
            });
        }
        catch (error) {
            logger.fail('Create Technician Profile Document', error.message);
        }
        // Test 7: Verify Technician Profile
        logger.startTest('Verify Technician Profile');
        try {
            const doc = await db.collection('technicians').doc(testUserId).get();
            if (doc.exists) {
                logger.pass('Verify Technician Profile', {
                    data: doc.data(),
                });
            }
            else {
                logger.fail('Verify Technician Profile', 'Profile document not found');
            }
        }
        catch (error) {
            logger.fail('Verify Technician Profile', error.message);
        }
        // Test 8: Generate Custom Token
        logger.startTest('Generate Custom Token');
        try {
            const token = await auth.createCustomToken(testUserId);
            logger.pass('Generate Custom Token', {
                tokenLength: token.length,
            });
        }
        catch (error) {
            logger.fail('Generate Custom Token', error.message);
        }
        // Test 9: Disable User
        logger.startTest('Disable User');
        try {
            await auth.updateUser(testUserId, {
                disabled: true,
            });
            logger.pass('Disable User', {
                uid: testUserId,
            });
        }
        catch (error) {
            logger.fail('Disable User', error.message);
        }
        // Test 10: Verify User Disabled
        logger.startTest('Verify User Disabled');
        try {
            const user = await auth.getUser(testUserId);
            if (user.disabled) {
                logger.pass('Verify User Disabled', {
                    disabled: user.disabled,
                });
            }
            else {
                logger.fail('Verify User Disabled', 'User not disabled');
            }
        }
        catch (error) {
            logger.fail('Verify User Disabled', error.message);
        }
        // Test 11: Delete Test User
        logger.startTest('Delete Test User');
        try {
            await auth.deleteUser(testUserId);
            logger.pass('Delete Test User', {
                uid: testUserId,
            });
        }
        catch (error) {
            logger.fail('Delete Test User', error.message);
        }
        // Test 12: Verify User Deleted
        logger.startTest('Verify User Deleted');
        try {
            await auth.getUser(testUserId);
            logger.fail('Verify User Deleted', 'User still exists after deletion');
        }
        catch (error) {
            if (error.code === 'auth/user-not-found') {
                logger.pass('Verify User Deleted', {
                    uid: testUserId,
                });
            }
            else {
                logger.fail('Verify User Deleted', error.message);
            }
        }
        // Cleanup technician profile
        try {
            await db.collection('technicians').doc(testUserId).delete();
        }
        catch (e) {
            // Ignore cleanup errors
        }
    }
    catch (error) {
        logger.fail('Auth Flow Tests', error.message);
    }
    const summary = logger.getSummary();
    (0, test_utils_1.printTestSummary)(summary);
    process.exit(summary.failCount > 0 ? 1 : 0);
}
runAuthFlowTests().catch((error) => {
    console.error('Fatal error:', error);
    process.exit(1);
});
//# sourceMappingURL=auth_flow_test.js.map
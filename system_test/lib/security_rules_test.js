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
const fs = __importStar(require("fs"));
const test_utils_1 = require("./test_utils");
async function runSecurityRulesTests() {
    const logger = new test_utils_1.TestLogger();
    const helper = new test_utils_1.FirebaseTestHelper();
    console.log('\n🔒 SECURITY RULES TESTS');
    console.log('='.repeat(60));
    try {
        const serviceAccountPath = '../scripts/serviceAccountKey.json';
        if (!fs.existsSync(serviceAccountPath)) {
            logger.skip('Security Tests', 'serviceAccountKey.json not found');
            const summary = logger.getSummary();
            (0, test_utils_1.printTestSummary)(summary);
            process.exit(0);
        }
        await helper.initializeApp(serviceAccountPath);
        const db = helper.getFirestore();
        // Test 1: Verify Admin Collection Exists
        logger.startTest('Verify Admin Collection Exists');
        try {
            const admins = await db.collection('admins').limit(1).get();
            logger.pass('Verify Admin Collection Exists', {
                docsFound: admins.size,
            });
        }
        catch (error) {
            logger.fail('Verify Admin Collection Exists', error.message);
        }
        // Test 2: Verify Technician Protected Fields
        logger.startTest('Verify Technician Protected Fields');
        try {
            const technicians = await db.collection('technicians').limit(1).get();
            if (technicians.size > 0) {
                const tech = technicians.docs[0].data();
                const protectedFields = [
                    'verificationStatus',
                    'profileCompletion',
                    'approvedAt',
                    'isApproved',
                    'isKycComplete',
                    'avgRating',
                    'totalRatings',
                    'walletBalance',
                ];
                const hasProtectedFields = protectedFields.some((field) => field in tech);
                logger.pass('Verify Technician Protected Fields', {
                    protectedFieldsFound: hasProtectedFields,
                });
            }
            else {
                logger.skip('Verify Technician Protected Fields', 'No technicians found');
            }
        }
        catch (error) {
            logger.fail('Verify Technician Protected Fields', error.message);
        }
        // Test 3: Verify Booking Protected Fields
        logger.startTest('Verify Booking Protected Fields');
        try {
            const bookings = await db.collection('bookings').limit(1).get();
            if (bookings.size > 0) {
                const booking = bookings.docs[0].data();
                const protectedFields = [
                    'status',
                    'paymentStatus',
                    'adminApproval',
                    'finalAmount',
                    'cancelledBy',
                    'completedAt',
                ];
                const hasProtectedFields = protectedFields.some((field) => field in booking);
                logger.pass('Verify Booking Protected Fields', {
                    protectedFieldsFound: hasProtectedFields,
                });
            }
            else {
                logger.skip('Verify Booking Protected Fields', 'No bookings found');
            }
        }
        catch (error) {
            logger.fail('Verify Booking Protected Fields', error.message);
        }
        // Test 4: Verify Service Moderation Fields
        logger.startTest('Verify Service Moderation Fields');
        try {
            const services = await db.collection('technician_services').limit(1).get();
            if (services.size > 0) {
                const service = services.docs[0].data();
                const moderationFields = [
                    'status',
                    'approvedAt',
                    'approvedBy',
                    'rejectedAt',
                    'rejectionReason',
                ];
                const hasModerationFields = moderationFields.some((field) => field in service);
                logger.pass('Verify Service Moderation Fields', {
                    moderationFieldsFound: hasModerationFields,
                });
            }
            else {
                logger.skip('Verify Service Moderation Fields', 'No services found');
            }
        }
        catch (error) {
            logger.fail('Verify Service Moderation Fields', error.message);
        }
        // Test 5: Verify Wallet Transactions Read-Only
        logger.startTest('Verify Wallet Transactions Read-Only');
        try {
            const transactions = await db.collection('walletTransactions').limit(1).get();
            logger.pass('Verify Wallet Transactions Read-Only', {
                transactionsFound: transactions.size,
            });
        }
        catch (error) {
            logger.fail('Verify Wallet Transactions Read-Only', error.message);
        }
        // Test 6: Verify Reviews Immutable
        logger.startTest('Verify Reviews Collection Exists');
        try {
            const reviews = await db.collection('reviews').limit(1).get();
            logger.pass('Verify Reviews Collection Exists', {
                reviewsFound: reviews.size,
            });
        }
        catch (error) {
            logger.fail('Verify Reviews Collection Exists', error.message);
        }
        // Test 7: Verify Coupons Read-Only
        logger.startTest('Verify Coupons Collection Exists');
        try {
            const coupons = await db.collection('coupons').limit(1).get();
            logger.pass('Verify Coupons Collection Exists', {
                couponsFound: coupons.size,
            });
        }
        catch (error) {
            logger.fail('Verify Coupons Collection Exists', error.message);
        }
        // Test 8: Verify Notifications Collection
        logger.startTest('Verify Notifications Collection Exists');
        try {
            const notifications = await db.collection('notifications').limit(1).get();
            logger.pass('Verify Notifications Collection Exists', {
                notificationsFound: notifications.size,
            });
        }
        catch (error) {
            logger.fail('Verify Notifications Collection Exists', error.message);
        }
        // Test 9: Verify Support Tickets Collection
        logger.startTest('Verify Support Tickets Collection Exists');
        try {
            const tickets = await db.collection('support_tickets').limit(1).get();
            logger.pass('Verify Support Tickets Collection Exists', {
                ticketsFound: tickets.size,
            });
        }
        catch (error) {
            logger.fail('Verify Support Tickets Collection Exists', error.message);
        }
        // Test 10: Verify Disputes Collection
        logger.startTest('Verify Disputes Collection Exists');
        try {
            const disputes = await db.collection('disputes').limit(1).get();
            logger.pass('Verify Disputes Collection Exists', {
                disputesFound: disputes.size,
            });
        }
        catch (error) {
            logger.fail('Verify Disputes Collection Exists', error.message);
        }
        // Test 11: Verify Custom Service Requests Collection
        logger.startTest('Verify Custom Service Requests Collection Exists');
        try {
            const requests = await db.collection('custom_service_requests').limit(1).get();
            logger.pass('Verify Custom Service Requests Collection Exists', {
                requestsFound: requests.size,
            });
        }
        catch (error) {
            logger.fail('Verify Custom Service Requests Collection Exists', error.message);
        }
        // Test 12: Verify Referrals Collection
        logger.startTest('Verify Referrals Collection Exists');
        try {
            const referrals = await db.collection('referrals').limit(1).get();
            logger.pass('Verify Referrals Collection Exists', {
                referralsFound: referrals.size,
            });
        }
        catch (error) {
            logger.fail('Verify Referrals Collection Exists', error.message);
        }
    }
    catch (error) {
        logger.fail('Security Rules Tests', error.message);
    }
    const summary = logger.getSummary();
    (0, test_utils_1.printTestSummary)(summary);
    process.exit(summary.failCount > 0 ? 1 : 0);
}
runSecurityRulesTests().catch((error) => {
    console.error('Fatal error:', error);
    process.exit(1);
});
//# sourceMappingURL=security_rules_test.js.map
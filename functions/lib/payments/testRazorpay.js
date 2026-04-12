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
exports.testBankVerification = exports.testRazorpayConnection = void 0;
const functions = __importStar(require("firebase-functions"));
const { razorpay } = require('../config/razorpay');
/**
 * TEST FUNCTION: Verify Razorpay connection and keys
 *
 * This function tests:
 * 1. Config loading
 * 2. Key format validation
 * 3. SDK initialization
 * 4. API connectivity
 * 5. Authentication
 *
 * Call from Flutter to diagnose Razorpay issues
 */
exports.testRazorpayConnection = functions
    .region('asia-south1')
    .https.onCall(async (data, context) => {
    console.log('='.repeat(80));
    console.log('[TEST_RAZORPAY] Starting Razorpay connection test...');
    console.log('='.repeat(80));
    try {
        // ========================================================================
        // STEP 1: LOAD CONFIG
        // ========================================================================
        console.log('[TEST_RAZORPAY] STEP 1: Loading Firebase config...');
        const config = functions.config();
        console.log('[TEST_RAZORPAY] FULL CONFIG:', JSON.stringify(config, null, 2));
        console.log('[TEST_RAZORPAY] config.razorpay:', config.razorpay);
        console.log('[TEST_RAZORPAY] config.razorpay?.key_id:', config.razorpay?.key_id);
        console.log('[TEST_RAZORPAY] config.razorpay?.key_secret:', config.razorpay?.key_secret ? '***PRESENT***' : 'MISSING');
        console.log('[TEST_RAZORPAY] config.razorpay?.key_secret?.length:', config.razorpay?.key_secret?.length);
        // ========================================================================
        // STEP 2: VALIDATE KEY FORMAT
        // ========================================================================
        console.log('[TEST_RAZORPAY] STEP 2: Validating key format...');
        const keyId = config.razorpay?.key_id;
        const keySecret = config.razorpay?.key_secret;
        if (!keyId) {
            console.error('[TEST_RAZORPAY] ERROR: key_id is missing or undefined');
            return {
                success: false,
                step: 'config_loading',
                message: 'Razorpay key_id not configured',
                details: {
                    keyIdPresent: !!keyId,
                    keySecretPresent: !!keySecret,
                    keySecretLength: keySecret?.length || 0
                }
            };
        }
        if (!keySecret) {
            console.error('[TEST_RAZORPAY] ERROR: key_secret is missing or undefined');
            return {
                success: false,
                step: 'config_loading',
                message: 'Razorpay key_secret not configured',
                details: {
                    keyIdPresent: !!keyId,
                    keySecretPresent: !!keySecret,
                    keySecretLength: keySecret?.length || 0
                }
            };
        }
        console.log('[TEST_RAZORPAY] ✓ key_id present:', keyId);
        console.log('[TEST_RAZORPAY] ✓ key_secret present (length:', keySecret.length, ')');
        // Validate format
        if (!keyId.startsWith('rzp_')) {
            console.error('[TEST_RAZORPAY] ERROR: key_id does not start with "rzp_"');
            return {
                success: false,
                step: 'key_format_validation',
                message: 'Invalid key_id format. Must start with "rzp_test_" or "rzp_live_"',
                details: {
                    keyId: keyId.substring(0, 20) + '...',
                    keyIdFormat: keyId.startsWith('rzp_test_') ? 'TEST' : keyId.startsWith('rzp_live_') ? 'LIVE' : 'INVALID'
                }
            };
        }
        const keyMode = keyId.includes('test') ? 'TEST' : 'LIVE';
        console.log('[TEST_RAZORPAY] ✓ Key mode:', keyMode);
        // ========================================================================
        // STEP 3: USE DIRECT SDK INSTANCE
        // ========================================================================
        console.log('[TEST_RAZORPAY] STEP 3: Using direct Razorpay SDK instance...');
        if (!razorpay) {
            console.error('[TEST_RAZORPAY] ERROR: Razorpay instance is null');
            return {
                success: false,
                step: 'sdk_initialization',
                message: 'Razorpay SDK instance is null',
                error: 'Direct import failed'
            };
        }
        console.log('[TEST_RAZORPAY] ✓ Razorpay SDK instance available (direct import)');
        // ========================================================================
        // STEP 4: TEST API CALL - CREATE ORDER
        // ========================================================================
        console.log('[TEST_RAZORPAY] STEP 4: Testing API call (creating test order)...');
        let order;
        try {
            console.log('[TEST_RAZORPAY] Calling razorpay.orders.create()...');
            order = await razorpay.orders.create({
                amount: 100, // ₹1 in paise
                currency: 'INR',
                receipt: 'test_receipt_' + Date.now(),
                notes: {
                    test: 'true',
                    timestamp: new Date().toISOString()
                }
            });
            console.log('[TEST_RAZORPAY] ✓ Order created successfully');
            console.log('[TEST_RAZORPAY] Order ID:', order.id);
            console.log('[TEST_RAZORPAY] Order amount:', order.amount);
            console.log('[TEST_RAZORPAY] Order status:', order.status);
        }
        catch (apiError) {
            console.error('[TEST_RAZORPAY] ERROR: API call failed');
            console.error('[TEST_RAZORPAY] Error message:', apiError.message);
            console.error('[TEST_RAZORPAY] Error code:', apiError.code);
            console.error('[TEST_RAZORPAY] Error statusCode:', apiError.statusCode);
            console.error('[TEST_RAZORPAY] Full error:', JSON.stringify(apiError, null, 2));
            // Extract error details
            const errorDescription = apiError.error?.description ||
                apiError.message ||
                'Unknown error';
            const errorCode = apiError.error?.code ||
                apiError.code ||
                'UNKNOWN';
            return {
                success: false,
                step: 'api_call',
                message: 'Razorpay API call failed',
                error: {
                    description: errorDescription,
                    code: errorCode,
                    statusCode: apiError.statusCode,
                    fullMessage: apiError.message
                },
                diagnosis: {
                    keyMode: keyMode,
                    keyIdFormat: keyId.substring(0, 20) + '...',
                    possibleCauses: [
                        'Invalid API keys',
                        'Key mode mismatch (test key with live dashboard or vice versa)',
                        'Network connectivity issue',
                        'Razorpay API rate limit exceeded',
                        'Invalid request format'
                    ]
                }
            };
        }
        // ========================================================================
        // STEP 5: TEST API CALL - FETCH ORDER
        // ========================================================================
        console.log('[TEST_RAZORPAY] STEP 5: Testing fetch (retrieving order)...');
        let fetchedOrder;
        try {
            console.log('[TEST_RAZORPAY] Calling razorpay.orders.fetch()...');
            fetchedOrder = await razorpay.orders.fetch(order.id);
            console.log('[TEST_RAZORPAY] ✓ Order fetched successfully');
            console.log('[TEST_RAZORPAY] Fetched order ID:', fetchedOrder.id);
            console.log('[TEST_RAZORPAY] Fetched order status:', fetchedOrder.status);
        }
        catch (fetchError) {
            console.error('[TEST_RAZORPAY] ERROR: Fetch failed');
            console.error('[TEST_RAZORPAY] Error:', fetchError.message);
            return {
                success: false,
                step: 'fetch_order',
                message: 'Failed to fetch order',
                error: fetchError.message,
                note: 'Order was created but fetch failed - possible permission issue'
            };
        }
        // ========================================================================
        // SUCCESS
        // ========================================================================
        console.log('='.repeat(80));
        console.log('[TEST_RAZORPAY] ✅ ALL TESTS PASSED');
        console.log('='.repeat(80));
        return {
            success: true,
            message: 'Razorpay connection verified successfully',
            details: {
                keyMode: keyMode,
                orderId: order.id,
                orderStatus: order.status,
                orderAmount: order.amount,
                fetchedOrderId: fetchedOrder.id,
                fetchedOrderStatus: fetchedOrder.status,
                timestamp: new Date().toISOString()
            },
            diagnosis: {
                configLoaded: true,
                keyFormatValid: true,
                sdkInitialized: true,
                apiConnected: true,
                authenticationWorking: true
            }
        };
    }
    catch (error) {
        console.error('[TEST_RAZORPAY] UNEXPECTED ERROR:', error);
        console.error('[TEST_RAZORPAY] Error stack:', error.stack);
        return {
            success: false,
            step: 'unknown',
            message: 'Unexpected error during test',
            error: error.message,
            stack: error.stack
        };
    }
});
/**
 * TEST FUNCTION: Verify bank verification flow
 *
 * Tests the complete bank verification flow with test data
 */
exports.testBankVerification = functions
    .region('asia-south1')
    .https.onCall(async (data, context) => {
    console.log('='.repeat(80));
    console.log('[TEST_BANK_VERIFY] Starting bank verification test...');
    console.log('='.repeat(80));
    try {
        // Check authentication
        if (!context.auth) {
            return {
                success: false,
                message: 'User must be authenticated'
            };
        }
        const uid = context.auth.uid;
        console.log('[TEST_BANK_VERIFY] Authenticated user:', uid);
        // Load config
        const config = functions.config();
        const keyId = config.razorpay?.key_id;
        const keySecret = config.razorpay?.key_secret;
        console.log('[TEST_BANK_VERIFY] Key ID present:', !!keyId);
        console.log('[TEST_BANK_VERIFY] Key Secret length:', keySecret?.length || 0);
        console.log('[TEST_BANK_VERIFY] Key mode:', keyId?.includes('test') ? 'TEST' : 'LIVE');
        if (!keyId || !keySecret) {
            return {
                success: false,
                message: 'Razorpay credentials not configured',
                details: {
                    keyIdPresent: !!keyId,
                    keySecretPresent: !!keySecret
                }
            };
        }
        // Use direct Razorpay instance
        if (!razorpay) {
            return {
                success: false,
                message: 'Razorpay instance is null'
            };
        }
        console.log('[TEST_BANK_VERIFY] Razorpay SDK instance available (direct import)');
        // Test contact creation
        console.log('[TEST_BANK_VERIFY] Testing contact creation...');
        const contact = await razorpay.contacts.create({
            name: 'Test Technician',
            email: `test_${uid}@homefix.app`,
            contact: '9999999999',
            type: 'vendor',
            reference_id: uid,
            notes: {
                test: 'true'
            }
        });
        console.log('[TEST_BANK_VERIFY] ✓ Contact created:', contact.id);
        // Test fund account creation
        console.log('[TEST_BANK_VERIFY] Testing fund account creation...');
        const fundAccount = await razorpay.fund_accounts.create({
            contact_id: contact.id,
            account_type: 'bank_account',
            bank_account: {
                name: 'Test Technician',
                ifsc: 'SBIN0001234',
                account_number: '123456789012'
            }
        });
        console.log('[TEST_BANK_VERIFY] ✓ Fund account created:', fundAccount.id);
        console.log('[TEST_BANK_VERIFY] Fund account active:', fundAccount.active);
        console.log('='.repeat(80));
        console.log('[TEST_BANK_VERIFY] ✅ BANK VERIFICATION TEST PASSED');
        console.log('='.repeat(80));
        return {
            success: true,
            message: 'Bank verification flow test passed',
            details: {
                contactId: contact.id,
                fundAccountId: fundAccount.id,
                fundAccountActive: fundAccount.active,
                timestamp: new Date().toISOString()
            }
        };
    }
    catch (error) {
        console.error('[TEST_BANK_VERIFY] ERROR:', error.message);
        console.error('[TEST_BANK_VERIFY] Full error:', JSON.stringify(error, null, 2));
        return {
            success: false,
            message: 'Bank verification test failed',
            error: error.message,
            errorCode: error.error?.code,
            errorDescription: error.error?.description
        };
    }
});
//# sourceMappingURL=testRazorpay.js.map
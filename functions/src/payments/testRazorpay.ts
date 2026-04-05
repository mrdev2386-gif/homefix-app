import * as functions from 'firebase-functions';
const Razorpay = require('razorpay');

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
export const testRazorpayConnection = functions
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
      // STEP 3: INITIALIZE SDK
      // ========================================================================
      console.log('[TEST_RAZORPAY] STEP 3: Initializing Razorpay SDK...');
      
      let razorpay: any;
      try {
        razorpay = new Razorpay({
          key_id: keyId,
          key_secret: keySecret
        });
        console.log('[TEST_RAZORPAY] ✓ Razorpay SDK initialized successfully');
      } catch (initError: any) {
        console.error('[TEST_RAZORPAY] ERROR: Failed to initialize SDK:', initError.message);
        return {
          success: false,
          step: 'sdk_initialization',
          message: 'Failed to initialize Razorpay SDK',
          error: initError.message
        };
      }

      // ========================================================================
      // STEP 4: TEST API CALL - CREATE ORDER
      // ========================================================================
      console.log('[TEST_RAZORPAY] STEP 4: Testing API call (creating test order)...');
      
      let order: any;
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
      } catch (apiError: any) {
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
      
      let fetchedOrder: any;
      try {
        console.log('[TEST_RAZORPAY] Calling razorpay.orders.fetch()...');
        fetchedOrder = await razorpay.orders.fetch(order.id);
        
        console.log('[TEST_RAZORPAY] ✓ Order fetched successfully');
        console.log('[TEST_RAZORPAY] Fetched order ID:', fetchedOrder.id);
        console.log('[TEST_RAZORPAY] Fetched order status:', fetchedOrder.status);
      } catch (fetchError: any) {
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

    } catch (error: any) {
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
export const testBankVerification = functions
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

      // Initialize Razorpay
      const razorpay = new Razorpay({
        key_id: keyId,
        key_secret: keySecret
      });

      console.log('[TEST_BANK_VERIFY] Razorpay SDK initialized');

      // Test contact creation
      console.log('[TEST_BANK_VERIFY] Testing contact creation...');
      const contact = await (razorpay as any).contacts.create({
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
      const fundAccount = await (razorpay as any).fundAccount.create({
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

    } catch (error: any) {
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

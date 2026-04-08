/**
 * Razorpay SDK - LAZY INITIALIZATION
 *
 * Credentials are validated only when razorpay is first accessed,
 * NOT at module load time. This prevents the emulator/deployment
 * from crashing when env vars are absent during cold start.
 */

import * as functions from 'firebase-functions';

const Razorpay = require('razorpay');

let _razorpay: any = null;

function getRazorpay() {
    if (_razorpay) return _razorpay;

    const config = functions.config();
    const keyId = config.razorpay?.key_id || process.env.RAZORPAY_KEY_ID;
    const keySecret = config.razorpay?.key_secret || process.env.RAZORPAY_KEY_SECRET;

    if (!keyId || !keySecret) {
        throw new functions.https.HttpsError(
            'failed-precondition',
            'Razorpay credentials not configured. Set razorpay.key_id and razorpay.key_secret via firebase functions:config:set.'
        );
    }

    _razorpay = new Razorpay({ key_id: keyId, key_secret: keySecret });
    console.log('[RAZORPAY] Instance created for key:', keyId.substring(0, 8) + '...');
    return _razorpay;
}

// Proxy so existing callers using `razorpay.orders.create(...)` keep working
const razorpay = new Proxy({} as any, {
    get(_target, prop: string) {
        return getRazorpay()[prop];
    }
});

module.exports = { razorpay };

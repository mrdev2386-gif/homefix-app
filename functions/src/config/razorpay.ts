/**
 * Razorpay SDK - DIRECT INSTANCE (NO ABSTRACTION)
 * 
 * CRITICAL: This is the ONLY Razorpay instance.
 * Import directly: const { razorpay } = require('./config/razorpay')
 */

import * as functions from 'firebase-functions';

// DIRECT require - NO fallback, NO factory
const Razorpay = require('razorpay');

// Get config
const config = functions.config();
const keyId = config.razorpay?.key_id;
const keySecret = config.razorpay?.key_secret;

if (!keyId || !keySecret) {
    throw new Error('Razorpay credentials not configured');
}

console.log('[RAZORPAY] Initializing with key:', keyId);

// DIRECT instantiation - NO singleton pattern
const razorpay = new Razorpay({
    key_id: keyId,
    key_secret: keySecret,
});

console.log('[RAZORPAY] Instance created');
console.log('[RAZORPAY] Instance keys:', Object.keys(razorpay));

// HARD CHECK - Fail fast if methods missing
if (!razorpay.contacts || typeof razorpay.contacts.create !== 'function') {
    console.error('[RAZORPAY ERROR] contacts.create missing');
    console.error('[RAZORPAY ERROR] Instance:', razorpay);
    console.error('[RAZORPAY ERROR] contacts:', razorpay.contacts);
    throw new Error('Razorpay contacts.create not available');
}

if (!razorpay.fund_accounts || typeof razorpay.fund_accounts.create !== 'function') {
    console.error('[RAZORPAY ERROR] fund_accounts.create missing');
    console.error('[RAZORPAY ERROR] Instance:', razorpay);
    throw new Error('Razorpay fund_accounts.create not available');
}

if (!razorpay.orders || typeof razorpay.orders.create !== 'function') {
    console.error('[RAZORPAY ERROR] orders.create missing');
    throw new Error('Razorpay orders.create not available');
}

if (!razorpay.payments || typeof razorpay.payments.fetch !== 'function') {
    console.error('[RAZORPAY ERROR] payments.fetch missing');
    throw new Error('Razorpay payments.fetch not available');
}

if (!razorpay.payouts || typeof razorpay.payouts.create !== 'function') {
    console.error('[RAZORPAY ERROR] payouts.create missing');
    throw new Error('Razorpay payouts.create not available');
}

if (!razorpay.qrCodes || typeof razorpay.qrCodes.create !== 'function') {
    console.error('[RAZORPAY ERROR] qrCodes.create missing');
    throw new Error('Razorpay qrCodes.create not available');
}

console.log('[RAZORPAY] ✅ All methods validated');
console.log('[RAZORPAY] ✅ contacts.create available');
console.log('[RAZORPAY] ✅ fund_accounts.create available');
console.log('[RAZORPAY] ✅ orders.create available');
console.log('[RAZORPAY] ✅ payments.fetch available');
console.log('[RAZORPAY] ✅ payouts.create available');
console.log('[RAZORPAY] ✅ qrCodes.create available');

// DIRECT export - NO function wrapper
module.exports = { razorpay };

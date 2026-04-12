"use strict";
/**
 * Razorpay SDK - LAZY INITIALIZATION
 *
 * Credentials are validated only when razorpay is first accessed,
 * NOT at module load time. This prevents the emulator/deployment
 * from crashing when env vars are absent during cold start.
 */
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
const functions = __importStar(require("firebase-functions"));
const Razorpay = require('razorpay');
let _razorpay = null;
function getRazorpay() {
    if (_razorpay)
        return _razorpay;
    const config = functions.config();
    const keyId = config.razorpay?.key_id || process.env.RAZORPAY_KEY_ID;
    const keySecret = config.razorpay?.key_secret || process.env.RAZORPAY_KEY_SECRET;
    if (!keyId || !keySecret) {
        throw new functions.https.HttpsError('failed-precondition', 'Razorpay credentials not configured. Set razorpay.key_id and razorpay.key_secret via firebase functions:config:set.');
    }
    _razorpay = new Razorpay({ key_id: keyId, key_secret: keySecret });
    console.log('[RAZORPAY] Instance created for key:', keyId.substring(0, 8) + '...');
    return _razorpay;
}
// Proxy so existing callers using `razorpay.orders.create(...)` keep working
const razorpay = new Proxy({}, {
    get(_target, prop) {
        return getRazorpay()[prop];
    }
});
module.exports = { razorpay };
//# sourceMappingURL=razorpay.js.map
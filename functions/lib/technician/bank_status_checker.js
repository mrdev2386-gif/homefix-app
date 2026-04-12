"use strict";
/**
 * Bank Verification Status Checker
 *
 * Helper function for technician app to check if bank verification is required
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
exports.checkBankVerificationStatus = void 0;
const functions = __importStar(require("firebase-functions"));
const config_1 = require("../shared/config");
/**
 * Check if technician needs to verify bank account
 *
 * Returns:
 * - isVerified: boolean
 * - status: 'pending' | 'verifying' | 'verified' | 'failed'
 * - message: string
 * - canRequestPayout: boolean
 */
exports.checkBankVerificationStatus = functions
    .region('asia-south1')
    .https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }
    const technicianId = context.auth.uid;
    const techDoc = await config_1.db.collection('technicians').doc(technicianId).get();
    if (!techDoc.exists) {
        throw new functions.https.HttpsError('not-found', 'Technician profile not found');
    }
    const techData = techDoc.data();
    const bankVerified = techData.bankVerified === true;
    const verificationStatus = techData.bankVerificationStatus || 'pending';
    const hasFundAccount = !!techData.fundAccountId;
    let message = '';
    let canRequestPayout = false;
    let canResubmit = false;
    if (bankVerified && verificationStatus === 'verified' && hasFundAccount) {
        message = 'Bank account verified';
        canRequestPayout = true;
        canResubmit = false;
    }
    else if (verificationStatus === 'verifying') {
        message = 'Bank verification in progress...';
        canRequestPayout = false;
        canResubmit = false;
    }
    else if (verificationStatus === 'failed') {
        message = techData.bankVerificationMessage || 'Bank verification failed. Please check your details and try again.';
        canRequestPayout = false;
        canResubmit = true;
    }
    else if (verificationStatus === 'pending') {
        message = 'Please verify your bank account to receive payouts';
        canRequestPayout = false;
        canResubmit = true;
    }
    else {
        message = 'Please verify your bank account to receive payouts';
        canRequestPayout = false;
        canResubmit = true;
    }
    return {
        isVerified: bankVerified,
        status: verificationStatus,
        hasFundAccount,
        message,
        canRequestPayout,
        canResubmit,
        bankDetails: {
            accountNumber: techData.bankAccountNumber ? `***${techData.bankAccountNumber.slice(-4)}` : null,
            ifsc: techData.bankIfsc || null,
            holderName: techData.bankHolderName || null
        }
    };
});
//# sourceMappingURL=bank_status_checker.js.map
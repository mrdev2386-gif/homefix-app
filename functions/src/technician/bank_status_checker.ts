/**
 * Bank Verification Status Checker
 * 
 * Helper function for technician app to check if bank verification is required
 */

import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { db } from '../shared/config';

/**
 * Check if technician needs to verify bank account
 * 
 * Returns:
 * - isVerified: boolean
 * - status: 'pending' | 'verifying' | 'verified' | 'failed'
 * - message: string
 * - canRequestPayout: boolean
 */
export const checkBankVerificationStatus = functions
  .region('asia-south1')
  .https.onCall(async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }

    const technicianId = context.auth.uid;

    const techDoc = await db.collection('technicians').doc(technicianId).get();

    if (!techDoc.exists) {
      throw new functions.https.HttpsError('not-found', 'Technician profile not found');
    }

    const techData = techDoc.data()!;

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
    } else if (verificationStatus === 'verifying') {
      message = 'Bank verification in progress...';
      canRequestPayout = false;
      canResubmit = false;
    } else if (verificationStatus === 'failed') {
      message = techData.bankVerificationMessage || 'Bank verification failed. Please check your details and try again.';
      canRequestPayout = false;
      canResubmit = true;
    } else if (verificationStatus === 'pending') {
      message = 'Please verify your bank account to receive payouts';
      canRequestPayout = false;
      canResubmit = true;
    } else {
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

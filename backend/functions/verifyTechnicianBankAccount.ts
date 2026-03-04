// Cloud Function: verifyTechnicianBankAccount
// Deploy to: backend/functions/src/index.ts

import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import axios from 'axios';

const RAZORPAY_KEY_ID = functions.config().razorpay.key_id;
const RAZORPAY_KEY_SECRET = functions.config().razorpay.key_secret;

interface BankVerificationRequest {
  accountHolderName: string;
  accountNumber: string;
  ifscCode: string;
  bankName: string;
}

export const verifyTechnicianBankAccount = functions.https.onCall(
  async (data: BankVerificationRequest, context) => {
    // 1. Authentication check
    if (!context.auth) {
      throw new functions.https.HttpsError(
        'unauthenticated',
        'User must be authenticated'
      );
    }

    const uid = context.auth.uid;
    const { accountHolderName, accountNumber, ifscCode, bankName } = data;

    // 2. Validation
    if (!accountHolderName || !accountNumber || !ifscCode || !bankName) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'All bank details are required'
      );
    }

    // Validate IFSC format (11 characters)
    if (!/^[A-Z]{4}0[A-Z0-9]{6}$/.test(ifscCode)) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'Invalid IFSC code format'
      );
    }

    // Validate account number (6-18 digits)
    if (!/^\d{6,18}$/.test(accountNumber)) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'Invalid account number'
      );
    }

    try {
      // 3. Save bank details with "verifying" status
      await admin.firestore().collection('technicians').doc(uid).update({
        bankName,
        accountNumber,
        ifscCode,
        accountHolderName,
        bankStatus: 'verifying',
        bankSubmittedAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      // 4. Call Razorpay Penny Drop API
      const razorpayAuth = Buffer.from(
        `${RAZORPAY_KEY_ID}:${RAZORPAY_KEY_SECRET}`
      ).toString('base64');

      const response = await axios.post(
        'https://api.razorpay.com/v1/fund_accounts/validations',
        {
          fund_account: {
            account_type: 'bank_account',
            bank_account: {
              name: accountHolderName,
              ifsc: ifscCode,
              account_number: accountNumber,
            },
          },
          amount: 100, // ₹1 in paise
          currency: 'INR',
          notes: {
            technician_id: uid,
            purpose: 'bank_verification',
          },
        },
        {
          headers: {
            Authorization: `Basic ${razorpayAuth}`,
            'Content-Type': 'application/json',
          },
          timeout: 30000,
        }
      );

      const verificationResult = response.data;
      const status = verificationResult.status;

      // 5. Update Firestore based on verification result
      if (status === 'completed') {
        await admin.firestore().collection('technicians').doc(uid).update({
          bankStatus: 'approved',
          bankVerifiedAt: admin.firestore.FieldValue.serverTimestamp(),
          bankVerificationMessage: 'Bank account verified successfully',
          razorpayFundAccountId: verificationResult.fund_account?.id || null,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        return {
          success: true,
          status: 'approved',
          message: 'Bank account verified successfully',
        };
      } else if (status === 'failed') {
        const errorMessage =
          verificationResult.error?.description ||
          'Bank verification failed. Please check your details.';

        await admin.firestore().collection('technicians').doc(uid).update({
          bankStatus: 'rejected',
          bankVerificationMessage: errorMessage,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        return {
          success: false,
          status: 'rejected',
          message: errorMessage,
        };
      } else {
        // Status is pending or processing
        return {
          success: true,
          status: 'verifying',
          message: 'Bank verification in progress',
        };
      }
    } catch (error: any) {
      console.error('Bank verification error:', error);

      // Update status to rejected on error
      await admin
        .firestore()
        .collection('technicians')
        .doc(uid)
        .update({
          bankStatus: 'rejected',
          bankVerificationMessage:
            error.response?.data?.error?.description ||
            'Verification failed. Please try again.',
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });

      throw new functions.https.HttpsError(
        'internal',
        error.response?.data?.error?.description ||
          'Bank verification failed. Please try again.'
      );
    }
  }
);

// Webhook handler for async verification updates
export const razorpayWebhook = functions.https.onRequest(async (req, res) => {
  try {
    const event = req.body;

    if (event.event === 'fund_account.validation.completed') {
      const validation = event.payload.fund_account.validation.entity;
      const technicianId = validation.notes?.technician_id;

      if (technicianId) {
        await admin.firestore().collection('technicians').doc(technicianId).update({
          bankStatus: 'approved',
          bankVerifiedAt: admin.firestore.FieldValue.serverTimestamp(),
          bankVerificationMessage: 'Bank account verified successfully',
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      }
    } else if (event.event === 'fund_account.validation.failed') {
      const validation = event.payload.fund_account.validation.entity;
      const technicianId = validation.notes?.technician_id;

      if (technicianId) {
        await admin.firestore().collection('technicians').doc(technicianId).update({
          bankStatus: 'rejected',
          bankVerificationMessage: 'Bank verification failed',
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      }
    }

    res.status(200).send({ received: true });
  } catch (error) {
    console.error('Webhook error:', error);
    res.status(500).send({ error: 'Webhook processing failed' });
  }
});

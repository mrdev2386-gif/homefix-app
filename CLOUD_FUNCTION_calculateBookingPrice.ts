// Cloud Function: calculateBookingPrice
// Secure server-side price calculation
// Deploy to: functions/src/bookings/calculateBookingPrice.ts

import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

const db = admin.firestore();

interface PriceBreakdown {
  basePrice: number;
  urgentFee?: number;
  nightCharge?: number;
  finalPrice: number;
}

interface CalculatePriceRequest {
  serviceId: string;
  technicianId: string;
  isUrgentBooking?: boolean;
  isNightBooking?: boolean;
}

/**
 * Calculate booking price with service features
 * 
 * Security:
 * - Validates service exists and belongs to technician
 * - Validates urgent booking is enabled on service
 * - Validates night service is enabled on service
 * - Validates fees are within allowed ranges
 * - Returns only calculated price (no sensitive data)
 */
export const calculateBookingPrice = functions.https.onCall(
  async (data: CalculatePriceRequest, context) => {
    // Require authentication
    if (!context.auth) {
      throw new functions.https.HttpsError(
        'unauthenticated',
        'User must be authenticated'
      );
    }

    const { serviceId, technicianId, isUrgentBooking, isNightBooking } = data;

    // Validate inputs
    if (!serviceId || !technicianId) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'serviceId and technicianId are required'
      );
    }

    try {
      // Fetch service document
      const serviceRef = db
        .collection('technicians')
        .doc(technicianId)
        .collection('services')
        .doc(serviceId);

      const serviceDoc = await serviceRef.get();

      if (!serviceDoc.exists) {
        throw new functions.https.HttpsError(
          'not-found',
          'Service not found'
        );
      }

      const serviceData = serviceDoc.data();
      if (!serviceData) {
        throw new functions.https.HttpsError(
          'internal',
          'Service data is invalid'
        );
      }

      // Start with base price
      let finalPrice = serviceData.price || 0;
      const breakdown: PriceBreakdown = {
        basePrice: finalPrice,
        finalPrice: finalPrice,
      };

      // Add urgent booking fee if selected
      if (isUrgentBooking) {
        // Verify urgent booking is enabled on service
        if (!serviceData.urgentBooking?.enabled) {
          throw new functions.https.HttpsError(
            'failed-precondition',
            'Urgent booking is not available for this service'
          );
        }

        const urgentFee = serviceData.urgentBooking.urgentFee;

        // Validate fee is in allowed range
        const allowedFees = [50, 100, 150, 200, 250, 300];
        if (!allowedFees.includes(urgentFee)) {
          throw new functions.https.HttpsError(
            'internal',
            'Invalid urgent fee configuration'
          );
        }

        breakdown.urgentFee = urgentFee;
        finalPrice += urgentFee;
      }

      // Add night service charge if applicable
      if (isNightBooking) {
        // Verify night service is enabled on service
        if (!serviceData.nightService?.enabled) {
          throw new functions.https.HttpsError(
            'failed-precondition',
            'Night service is not available for this service'
          );
        }

        const nightCharge = serviceData.nightService.nightCharge || 0;

        // Validate charge is in allowed range
        const allowedCharges = [0, 50, 100, 150, 200];
        if (!allowedCharges.includes(nightCharge)) {
          throw new functions.https.HttpsError(
            'internal',
            'Invalid night charge configuration'
          );
        }

        if (nightCharge > 0) {
          breakdown.nightCharge = nightCharge;
          finalPrice += nightCharge;
        }
      }

      breakdown.finalPrice = finalPrice;

      return {
        success: true,
        finalPrice,
        breakdown,
      };
    } catch (error) {
      console.error('calculateBookingPrice error:', error);

      if (error instanceof functions.https.HttpsError) {
        throw error;
      }

      throw new functions.https.HttpsError(
        'internal',
        'Failed to calculate price'
      );
    }
  }
);

/**
 * Example usage in Flutter:
 * 
 * final result = await FirebaseFunctions.instanceFor(region: 'us-central1')
 *   .httpsCallable('calculateBookingPrice')
 *   .call({
 *     'serviceId': 'service_123',
 *     'technicianId': 'tech_456',
 *     'isUrgentBooking': true,
 *     'isNightBooking': false,
 *   });
 * 
 * final finalPrice = result.data['finalPrice'];
 * final breakdown = result.data['breakdown'];
 */

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
  bookingTime: string;
  isUrgentBooking?: boolean;
}

export const calculateBookingPrice = functions.https.onCall(
  async (data: CalculatePriceRequest, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        'unauthenticated',
        'User must be authenticated'
      );
    }

    const { serviceId, technicianId, bookingTime, isUrgentBooking } = data;

    if (!serviceId || !technicianId || !bookingTime) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'serviceId, technicianId, and bookingTime are required'
      );
    }

    try {
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

      let finalPrice = serviceData.price || 0;
      const breakdown: PriceBreakdown = {
        basePrice: finalPrice,
        finalPrice: finalPrice,
      };

      if (isUrgentBooking) {
        if (!serviceData.urgentBooking?.enabled) {
          throw new functions.https.HttpsError(
            'failed-precondition',
            'Urgent booking is not available for this service'
          );
        }

        const urgentFee = serviceData.urgentBooking.urgentFee;
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

      const bookingDate = new Date(bookingTime);
      const hour = bookingDate.getHours();
      const isNightTime = hour >= 22 || hour < 6;

      if (isNightTime) {
        if (!serviceData.nightService?.enabled) {
          throw new functions.https.HttpsError(
            'failed-precondition',
            'Night service is not available for this service'
          );
        }

        const nightCharge = serviceData.nightService.nightCharge || 0;
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
        isNightTime,
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

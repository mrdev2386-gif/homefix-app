import 'package:cloud_functions/cloud_functions.dart';

class FunctionsService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  // Create a new booking
  Future<Map<String, dynamic>> createBooking(Map<String, dynamic> bookingData) async {
    try {
      HttpsCallable callable = _functions.httpsCallable('createBooking');
      final result = await callable.call(bookingData);
      return Map<String, dynamic>.from(result.data);
    } catch (e) {
      rethrow;
    }
  }

  // Cancel a booking
  Future<void> cancelBooking(String bookingId) async {
    try {
      HttpsCallable callable = _functions.httpsCallable('updateBookingStatus');
      await callable.call({'bookingId': bookingId, 'status': 'cancelled'});
    } catch (e) {
      rethrow;
    }
  }

  // Update user profile securely
  Future<void> updateUserProfile(Map<String, dynamic> userData) async {
    try {
      HttpsCallable callable = _functions.httpsCallable('updateUserProfile');
      await callable.call(userData);
    } catch (e) {
      rethrow;
    }
  }

  // Create custom service request
  Future<Map<String, dynamic>> createServiceRequest(Map<String, dynamic> requestData) async {
    try {
      HttpsCallable callable = _functions.httpsCallable('createServiceRequest');
      final result = await callable.call(requestData);
      return Map<String, dynamic>.from(result.data);
    } catch (e) {
      rethrow;
    }
  }

  // Payment System
  Future<Map<String, dynamic>> initiateRazorpayPayment(String bookingId) async {
    try {
      HttpsCallable callable = _functions.httpsCallable('initiateRazorpayPayment');
      final result = await callable.call({'bookingId': bookingId});
      return Map<String, dynamic>.from(result.data);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> verifyRazorpayPayment(Map<String, dynamic> paymentData) async {
    try {
      HttpsCallable callable = _functions.httpsCallable('verifyRazorpayPayment');
      await callable.call(paymentData);
    } catch (e) {
      rethrow;
    }
  }

  // Referral System
  Future<Map<String, dynamic>> validateReferralCode(String code) async {
    try {
      HttpsCallable callable = _functions.httpsCallable('validateReferralCode');
      final result = await callable.call({'code': code});
      return Map<String, dynamic>.from(result.data);
    } catch (e) {
      rethrow;
    }
  }

  // Booking Cancellation override
  Future<void> cancelBookingExtended(String bookingId, String reason) async {
    try {
      HttpsCallable callable = _functions.httpsCallable('cancelBooking');
      await callable.call({'bookingId': bookingId, 'reason': reason});
    } catch (e) {
      rethrow;
    }
  }

  // Service Rating
  Future<void> submitServiceRating(String bookingId, double rating, String comment) async {
    try {
      HttpsCallable callable = _functions.httpsCallable('submitServiceRating');
      await callable.call({
        'bookingId': bookingId,
        'rating': rating,
        'comment': comment,
      });
    } catch (e) {
      rethrow;
    }
  }

  // Support Request
  Future<void> submitSupportRequest(String category, String message) async {
    try {
      HttpsCallable callable = _functions.httpsCallable('submitSupportRequest');
      await callable.call({
        'category': category,
        'message': message,
      });
    } catch (e) {
      rethrow;
    }
  }

  // Matching Logic for Cleaning Essentials
  Future<Map<String, dynamic>> findEligibleTechniciansCount(String categoryId, Map<String, double> userLocation) async {
    try {
      HttpsCallable callable = _functions.httpsCallable('findEligibleTechniciansCount');
      final result = await callable.call({
        'categoryId': categoryId,
        'userLocation': userLocation,
      });
      return Map<String, dynamic>.from(result.data);
    } catch (e) {
      rethrow;
    }
  }
}

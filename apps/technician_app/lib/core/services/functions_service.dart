import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

class FunctionsService {
  // Use region-safe instance for us-central1 to avoid NOT_FOUND errors
  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(region: 'us-central1');

  /// Technician: Get inbox of pending custom requests
  Future<Map<String, dynamic>> getTechnicianInbox({int limit = 20, String? startAfter}) async {
    try {
      HttpsCallable callable = _functions.httpsCallable('getTechnicianInbox');
      final result = await callable.call({
        'limit': limit,
        if (startAfter != null) 'startAfter': startAfter,
      });
      return Map<String, dynamic>.from(result.data);
    } catch (e) {
      rethrow;
    }
  }

  /// Technician: Accept or Reject a custom request
  Future<Map<String, dynamic>> technicianRespondServiceRequest(String requestId, String action, {String? reason}) async {
    try {
      HttpsCallable callable = _functions.httpsCallable('technicianRespondServiceRequest');
      final result = await callable.call({
        'requestId': requestId,
        'action': action, // 'accept' or 'reject'
        if (reason != null) 'rejectionReason': reason,
      });
      return Map<String, dynamic>.from(result.data);
    } catch (e) {
      rethrow;
    }
  }

  /// Get custom request details
  Future<Map<String, dynamic>> getCustomRequestDetail(String requestId) async {
    try {
      HttpsCallable callable = _functions.httpsCallable('getCustomRequestDetail');
      final result = await callable.call({'requestId': requestId});
      return Map<String, dynamic>.from(result.data);
    } catch (e) {
      rethrow;
    }
  }

  /// Update technician online status via Cloud Function
  Future<void> updateTechnicianOnlineStatus(bool isOnline) async {
    try {
      HttpsCallable callable = _functions.httpsCallable('toggleOnlineStatus');
      await callable.call({'isOnline': isOnline});
      debugPrint('[Functions] online status updated: $isOnline');
    } catch (e) {
      debugPrint('[Functions] online status failed: $e');
      // App must not depend on function success - silently fail
    }
  }

  /// Update booking status via Cloud Function
  Future<void> updateBookingStatus(String bookingId, String status, {String? otp}) async {
    try {
      HttpsCallable callable = _functions.httpsCallable('updateBookingStatusNew');
      await callable.call({
        'bookingId': bookingId,
        'status': status,
        if (otp != null) 'otp': otp,
      });
    } catch (e) {
      rethrow;
    }
  }

  /// Report booking issue via Cloud Function
  Future<void> reportBookingIssue(String bookingId, String reason) async {
    try {
      HttpsCallable callable = _functions.httpsCallable('reportBookingIssue');
      await callable.call({
        'bookingId': bookingId,
        'reason': reason,
      });
    } catch (e) {
      rethrow;
    }
  }

  /// Create Razorpay order for wallet credit
  Future<Map<String, dynamic>> createRazorpayOrder({
    required double amount,
    String? notes,
  }) async {
    try {
      HttpsCallable callable = _functions.httpsCallable('createRazorpayOrder');
      final result = await callable.call({
        'amount': amount,
        if (notes != null) 'notes': notes,
      });
      return Map<String, dynamic>.from(result.data);
    } catch (e) {
      rethrow;
    }
  }

  // ============================================
  // TECHNICIAN SERVICES (Secure Callable Functions)
  // Single Source of Truth: technicians/{technicianId}/services/{serviceId}
  // ============================================

  /// Add a new technician service via Cloud Function
  Future<Map<String, dynamic>> addService({
    required String name,
    required double price,
    required String imageUrl,
    required String category,
    String? description,
    double? originalPrice,
    double? offerPrice,
    double? discountPercent,
  }) async {
    try {
      debugPrint('[DEBUG] FunctionsService.addService called with categoryId: $category');
      HttpsCallable callable = _functions.httpsCallable('addTechnicianService');
      final result = await callable.call({
        'name': name,
        'price': price,
        'imageUrl': imageUrl,
        'category': category,
        if (description != null) 'description': description,
        if (originalPrice != null) 'originalPrice': originalPrice,
        if (offerPrice != null) 'offerPrice': offerPrice,
        if (discountPercent != null) 'discountPercent': discountPercent,
      });
      return Map<String, dynamic>.from(result.data);
    } catch (e) {
      rethrow;
    }
  }

  /// Update an existing technician service via Cloud Function
  Future<Map<String, dynamic>> updateService({
    required String serviceId,
    String? name,
    double? price,
    String? imageUrl,
    String? category,
    String? description,
    double? originalPrice,
    double? offerPrice,
    double? discountPercent,
    bool? isActive,
  }) async {
    try {
      HttpsCallable callable = _functions.httpsCallable('updateTechnicianServiceNew');
      final Map<String, dynamic> data = {'serviceId': serviceId};
      
      if (name != null) data['name'] = name;
      if (price != null) data['price'] = price;
      if (imageUrl != null) data['imageUrl'] = imageUrl;
      if (category != null) data['category'] = category;
      if (description != null) data['description'] = description;
      if (originalPrice != null) data['originalPrice'] = originalPrice;
      if (offerPrice != null) data['offerPrice'] = offerPrice;
      if (discountPercent != null) data['discountPercent'] = discountPercent;
      if (isActive != null) data['isActive'] = isActive;

      final result = await callable.call(data);
      return Map<String, dynamic>.from(result.data);
    } catch (e) {
      rethrow;
    }
  }

  /// Toggle technician service active status via Cloud Function
  Future<Map<String, dynamic>> toggleServiceStatus(String serviceId) async {
    try {
      HttpsCallable callable = _functions.httpsCallable('toggleTechnicianServiceStatusNew');
      final result = await callable.call({'serviceId': serviceId});
      return Map<String, dynamic>.from(result.data);
    } catch (e) {
      rethrow;
    }
  }

  /// Delete (soft delete) a technician service via Cloud Function
  Future<Map<String, dynamic>> deleteService(String serviceId) async {
    try {
      HttpsCallable callable = _functions.httpsCallable('deleteTechnicianServiceNew');
      final result = await callable.call({'serviceId': serviceId});
      return Map<String, dynamic>.from(result.data);
    } catch (e) {
      rethrow;
    }
  }

  /// Update technician personal details via Cloud Function
  /// Only allows updating: fullName, email, city, experience, gender, bio
  Future<Map<String, dynamic>> updateTechnicianPersonalDetails({
    required String fullName,
    String? email,
    String? city,
    int? experience,
    String? gender,
    String? bio,
  }) async {
    try {
      debugPrint('[FunctionsService] Calling updateTechnicianPersonalDetails');
      HttpsCallable callable = _functions.httpsCallable('updateTechnicianPersonalDetails');
      final result = await callable.call({
        'fullName': fullName,
        if (email != null) 'email': email,
        if (city != null) 'city': city,
        if (experience != null) 'experience': experience,
        if (gender != null) 'gender': gender,
        if (bio != null) 'bio': bio,
      });
      debugPrint('[FunctionsService] updateTechnicianPersonalDetails success');
      return Map<String, dynamic>.from(result.data);
    } on FirebaseFunctionsException catch (e) {
      debugPrint('[FunctionsService] updateTechnicianPersonalDetails error: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('[FunctionsService] updateTechnicianPersonalDetails unexpected error: $e');
      rethrow;
    }
  }

  /// Update technician bank details via Cloud Function
  /// Only allows updating bank-related fields
  Future<Map<String, dynamic>> updateTechnicianBankDetails({
    required String accountHolderName,
    required String bankName,
    required String accountNumber,
    required String ifscCode,
  }) async {
    try {
      debugPrint('[FunctionsService] Calling updateTechnicianBankDetails');
      HttpsCallable callable = _functions.httpsCallable('updateTechnicianBankDetails');
      final result = await callable.call({
        'accountHolderName': accountHolderName,
        'bankName': bankName,
        'accountNumber': accountNumber,
        'ifscCode': ifscCode.toUpperCase(),
      });
      debugPrint('[FunctionsService] updateTechnicianBankDetails success');
      return Map<String, dynamic>.from(result.data);
    } on FirebaseFunctionsException catch (e) {
      debugPrint('[FunctionsService] updateTechnicianBankDetails error: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('[FunctionsService] updateTechnicianBankDetails unexpected error: $e');
      rethrow;
    }
  }

  /// Re-upload verification document via Cloud Function
  /// Allows re-upload if status is "missing" or "rejected"
  Future<Map<String, dynamic>> reuploadVerificationDocument({
    required String documentType,
    required String documentUrl,
  }) async {
    try {
      debugPrint('[FunctionsService] Calling reuploadVerificationDocument');
      HttpsCallable callable = _functions.httpsCallable('reuploadVerificationDocument');
      final result = await callable.call({
        'documentType': documentType,
        'documentUrl': documentUrl,
      });
      debugPrint('[FunctionsService] reuploadVerificationDocument success');
      return Map<String, dynamic>.from(result.data);
    } on FirebaseFunctionsException catch (e) {
      debugPrint('[FunctionsService] reuploadVerificationDocument error: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('[FunctionsService] reuploadVerificationDocument unexpected error: $e');
      rethrow;
    }
  }
}

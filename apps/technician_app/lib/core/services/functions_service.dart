import 'package:cloud_functions/cloud_functions.dart';

class FunctionsService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

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
      HttpsCallable callable = _functions.httpsCallable('updateTechnicianOnlineStatus');
      await callable.call({'isOnline': isOnline});
    } catch (e) {
      rethrow;
    }
  }

  /// Update booking status via Cloud Function
  Future<void> updateBookingStatus(String bookingId, String status, {String? otp}) async {
    try {
      HttpsCallable callable = _functions.httpsCallable('updateBookingStatus');
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
    String? subCategory,
    String? description,
  }) async {
    try {
      HttpsCallable callable = _functions.httpsCallable('addTechnicianService');
      final result = await callable.call({
        'name': name,
        'price': price,
        'imageUrl': imageUrl,
        'category': category,
        if (subCategory != null) 'subCategory': subCategory,
        if (description != null) 'description': description,
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
  }) async {
    try {
      HttpsCallable callable = _functions.httpsCallable('updateTechnicianServiceNew');
      final Map<String, dynamic> data = {'serviceId': serviceId};
      
      if (name != null) data['name'] = name;
      if (price != null) data['price'] = price;
      if (imageUrl != null) data['imageUrl'] = imageUrl;
      if (category != null) data['category'] = category;
      if (description != null) data['description'] = description;

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
}

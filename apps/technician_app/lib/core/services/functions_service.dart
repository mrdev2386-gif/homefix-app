import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class FunctionsService {
  final FirebaseFunctions _functions =
      FirebaseFunctions.instanceFor(region: 'us-central1');

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
      debugPrint('[Functions] Online status updated: $isOnline');
    } on FirebaseFunctionsException catch (e) {
      debugPrint('[Functions] Online status error: ${e.code} - ${e.message}');
      // Silently fail - app should continue working
    } catch (e) {
      debugPrint('[Functions] Online status unexpected error: $e');
      // Silently fail - app should continue working
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
  /// SECURITY: Validates technician approval before service creation
  Future<Map<String, dynamic>> addService({
    required String name,
    required double price,
    required String imageUrl,
    required String category,
    String? description,
    double? originalPrice,
    double? offerPrice,
    double? discountPercent,
    Map<String, dynamic>? urgentBooking,
    Map<String, dynamic>? nightService,
  }) async {
    try {
      debugPrint('[SERVICE CREATE] Writing to technician_services collection');
      debugPrint('[SERVICE CREATE] categoryId: $category');
      
      HttpsCallable callable = _functions.httpsCallable('addTechnicianService');
      final Map<String, dynamic> data = {
        'name': name,
        'category': category,
        'categoryId': category,
        'price': price,
        'basePrice': originalPrice ?? price,
        'offerPrice': offerPrice ?? price,
        'imageUrl': imageUrl,
        'description': description ?? 'Professional service provided by experienced technician',
      };
      
      debugPrint('[SERVICE CREATE] Calling Cloud Function with data: $data');
      final result = await callable.call(data);
      debugPrint('[SERVICE CREATE] SUCCESS - Service written to technician_services');
      return Map<String, dynamic>.from(result.data);
    } catch (e) {
      debugPrint('[SERVICE CREATE] ERROR: $e');
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
    Map<String, dynamic>? urgentBooking,
    Map<String, dynamic>? nightService,
  }) async {
    try {
      HttpsCallable callable = _functions.httpsCallable('updateTechnicianService');
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
      if (urgentBooking != null) data['urgentBooking'] = urgentBooking;
      if (nightService != null) data['nightService'] = nightService;

      final result = await callable.call(data);
      return Map<String, dynamic>.from(result.data);
    } catch (e) {
      rethrow;
    }
  }

  /// Toggle technician service active status via Cloud Function
  Future<Map<String, dynamic>> toggleServiceStatus(String serviceId) async {
    try {
      HttpsCallable callable = _functions.httpsCallable('toggleTechnicianServiceStatus');
      final result = await callable.call({'serviceId': serviceId});
      return Map<String, dynamic>.from(result.data);
    } catch (e) {
      rethrow;
    }
  }

  /// Delete (soft delete) a technician service via Cloud Function
  Future<Map<String, dynamic>> deleteService(String serviceId) async {
    try {
      HttpsCallable callable = _functions.httpsCallable('deleteTechnicianService');
      final result = await callable.call({'serviceId': serviceId});
      return Map<String, dynamic>.from(result.data);
    } catch (e) {
      rethrow;
    }
  }

  /// Update technician personal details via Cloud Function
  /// Only allows updating: fullName, email, city, experienceYears, gender, bio, alternatePhone, state, district
  /// Supports partial updates - only non-null fields are updated
  Future<Map<String, dynamic>> updateTechnicianPersonalDetails({
    String? fullName,
    String? email,
    String? city,
    String? state,
    String? district,
    int? experienceYears,
    String? gender,
    String? bio,
    String? alternatePhone,
  }) async {
    try {
      // 1. Ensure Firebase user exists before calling the function
      final user = FirebaseAuth.instance.currentUser;
      
      if (user == null) {
        throw Exception('User not logged in');
      }
      
      print('[FunctionsService] UID: ${user.uid}');
      
      // 2. Force refresh the Firebase ID token before calling the function
      await user.getIdToken(true);
      print('[FunctionsService] Token refreshed successfully');
      
      final Map<String, dynamic> updates = {};
      
      if (fullName != null) updates['fullName'] = fullName;
      if (email != null) updates['email'] = email;
      if (city != null) updates['city'] = city;
      if (state != null) updates['state'] = state;
      if (district != null) updates['district'] = district;
      if (experienceYears != null) updates['experienceYears'] = experienceYears;
      if (gender != null) updates['gender'] = gender;
      if (bio != null) updates['bio'] = bio;
      if (alternatePhone != null) updates['alternatePhone'] = alternatePhone;
      
      print('[FunctionsService] Sending updates: $updates');
      
      if (updates.isEmpty) {
        return {'success': true, 'message': 'No updates provided'};
      }
      
      // 3. Call the Cloud Function only after token refresh
      final callable = _functions.httpsCallable('updateTechnicianPersonalDetails');
      
      final result = await callable.call(updates);
      
      debugPrint('[FunctionsService] updateTechnicianPersonalDetails success: ${result.data}');
      return Map<String, dynamic>.from(result.data);
    } on FirebaseFunctionsException catch (e) {
      debugPrint('[FunctionsService] updateTechnicianPersonalDetails error: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('[FunctionsService] updateTechnicianPersonalDetails unexpected error: $e');
      rethrow;
    }
  }

  /// Update email and require verification
  /// Only enforces verification when email is actually being changed
  Future<void> updateEmail(String newEmail) async {
    final user = FirebaseAuth.instance.currentUser;
    
    if (user == null) {
      throw Exception('User not authenticated');
    }

    try {
      await user.updateEmail(newEmail);
      
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
      }
      
      print('Verification email sent');
    } catch (e) {
      debugPrint('[FunctionsService] updateEmail error: $e');
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

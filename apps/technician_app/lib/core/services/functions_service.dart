import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../firebase/firebase_functions.dart';

class FunctionsService {
  final FirebaseFunctions _functions = FirebaseFunctionsService.instance;

  /// Technician: Get inbox of pending custom requests
  Future<Map<String, dynamic>> getTechnicianInbox({int limit = 20, String? startAfter}) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception("User not logged in");
      }
      debugPrint('[FunctionsService] getTechnicianInbox: Current user UID: ${user.uid}');
      await user.getIdToken(true);
      debugPrint('[FunctionsService] getTechnicianInbox: Token refreshed successfully');
      
      final callable = _functions.httpsCallable('getTechnicianInbox');
      final result = await callable.call({
        'limit': limit,
        if (startAfter != null) 'startAfter': startAfter,
      });
      return Map<String, dynamic>.from(result.data);
    } on FirebaseFunctionsException catch (e) {
      debugPrint('[FunctionsService] getTechnicianInbox: FirebaseFunctionsException: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('[FunctionsService] getTechnicianInbox: Unexpected error: $e');
      rethrow;
    }
  }

  /// Technician: Accept or Reject a custom request
  Future<Map<String, dynamic>> technicianRespondServiceRequest(String requestId, String action, {String? reason}) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception("User not logged in");
      }
      debugPrint('[FunctionsService] technicianRespondServiceRequest: Current user UID: ${user.uid}');
      await user.getIdToken(true);
      debugPrint('[FunctionsService] technicianRespondServiceRequest: Token refreshed successfully');
      
      final callable = _functions.httpsCallable('technicianRespondServiceRequest');
      final result = await callable.call({
        'requestId': requestId,
        'action': action, // 'accept' or 'reject'
        if (reason != null) 'rejectionReason': reason,
      });
      return Map<String, dynamic>.from(result.data);
    } on FirebaseFunctionsException catch (e) {
      debugPrint('[FunctionsService] technicianRespondServiceRequest: FirebaseFunctionsException: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('[FunctionsService] technicianRespondServiceRequest: Unexpected error: $e');
      rethrow;
    }
  }

  /// Get custom request details
  Future<Map<String, dynamic>> getCustomRequestDetail(String requestId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception("User not logged in");
      }
      debugPrint('[FunctionsService] getCustomRequestDetail: Current user UID: ${user.uid}');
      await user.getIdToken(true);
      debugPrint('[FunctionsService] getCustomRequestDetail: Token refreshed successfully');
      
      final callable = _functions.httpsCallable('getCustomRequestDetail');
      final result = await callable.call({'requestId': requestId});
      return Map<String, dynamic>.from(result.data);
    } on FirebaseFunctionsException catch (e) {
      debugPrint('[FunctionsService] getCustomRequestDetail: FirebaseFunctionsException: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('[FunctionsService] getCustomRequestDetail: Unexpected error: $e');
      rethrow;
    }
  }

  /// Update technician online status via Cloud Function
  Future<void> updateTechnicianOnlineStatus(bool isOnline) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        debugPrint('[FunctionsService] updateTechnicianOnlineStatus: User not authenticated');
        throw Exception("User not logged in");
      }
      debugPrint('[FunctionsService] updateTechnicianOnlineStatus: Current user UID: ${user.uid}');
      await user.getIdToken(true);
      debugPrint('[FunctionsService] updateTechnicianOnlineStatus: Token refreshed successfully');
      
      final callable = _functions.httpsCallable('toggleOnlineStatus');
      await callable.call({'isOnline': isOnline});
      debugPrint('[Functions] Online status updated: $isOnline');
    } on FirebaseFunctionsException catch (e) {
      debugPrint('[Functions] Online status error - Code: ${e.code}, Message: ${e.message}');
      // Silently fail - app should continue working
    } catch (e) {
      debugPrint('[Functions] Online status unexpected error: $e');
      // Silently fail - app should continue working
    }
  }

  /// Update booking status via Cloud Function
  Future<void> updateBookingStatus(String bookingId, String status, {String? otp}) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception("User not logged in");
      }
      debugPrint('[FunctionsService] updateBookingStatus: Current user UID: ${user.uid}');
      await user.getIdToken(true);
      debugPrint('[FunctionsService] updateBookingStatus: Token refreshed successfully');
      
      final callable = _functions.httpsCallable('updateBookingStatusNew');
      await callable.call({
        'bookingId': bookingId,
        'status': status,
        if (otp != null) 'otp': otp,
      });
    } on FirebaseFunctionsException catch (e) {
      debugPrint('[FunctionsService] updateBookingStatus: FirebaseFunctionsException - Code: ${e.code}, Message: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('[FunctionsService] updateBookingStatus: Unexpected error: $e');
      rethrow;
    }
  }

  /// Report booking issue via Cloud Function
  Future<void> reportBookingIssue(String bookingId, String reason) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception("User not logged in");
      }
      debugPrint('[FunctionsService] reportBookingIssue: Current user UID: ${user.uid}');
      await user.getIdToken(true);
      debugPrint('[FunctionsService] reportBookingIssue: Token refreshed successfully');
      
      final callable = _functions.httpsCallable('reportBookingIssue');
      await callable.call({
        'bookingId': bookingId,
        'reason': reason,
      });
    } on FirebaseFunctionsException catch (e) {
      debugPrint('[FunctionsService] reportBookingIssue: FirebaseFunctionsException - Code: ${e.code}, Message: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('[FunctionsService] reportBookingIssue: Unexpected error: $e');
      rethrow;
    }
  }

  /// Create Razorpay order for wallet credit
  Future<Map<String, dynamic>> createRazorpayOrder({
    required double amount,
    String? notes,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception("User not logged in");
      }
      debugPrint('[FunctionsService] createRazorpayOrder: Current user UID: ${user.uid}');
      await user.getIdToken(true);
      debugPrint('[FunctionsService] createRazorpayOrder: Token refreshed successfully');
      
      final callable = _functions.httpsCallable('createRazorpayOrder');
      final result = await callable.call({
        'amount': amount,
        if (notes != null) 'notes': notes,
      });
      return Map<String, dynamic>.from(result.data);
    } on FirebaseFunctionsException catch (e) {
      debugPrint('[FunctionsService] createRazorpayOrder: FirebaseFunctionsException - Code: ${e.code}, Message: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('[FunctionsService] createRazorpayOrder: Unexpected error: $e');
      rethrow;
    }
  }

  // ============================================
  // TECHNICIAN SERVICES (Secure Callable Functions)
  // Single Source of Truth: technicians/{technicianId}/services/{serviceId}
  // ============================================

  /// Add a new technician service via Cloud Function
  /// SECURITY: Validates technician approval before service creation
  /// PRICING: price = original price (before discount), offerPrice = discounted price
  Future<Map<String, dynamic>> addService({
    required String name,
    required double price,
    required double offerPrice,
    required String imageUrl,
    required String category,
    String? description,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }
      debugPrint('[FunctionsService] addService: Current user UID: ${user.uid}');
      await user.getIdToken(true);
      debugPrint('[FunctionsService] addService: Token refreshed successfully');
      
      final callable = _functions.httpsCallable('addTechnicianService');
      
      final Map<String, dynamic> data = {
        'name': name,
        'category': category,
        'categoryId': category,
        'price': price,  // Original price (before discount)
        'offerPrice': offerPrice,  // Discounted price
        'imageUrl': imageUrl,
        'description': description ?? 'Professional service provided by experienced technician',
      };
      
      debugPrint('[FunctionsService] addService REQUEST PAYLOAD: $data');
      debugPrint('[FunctionsService] addService - Sending ONLY price + offerPrice (NO basePrice)');
      
      final result = await callable.call(data);
      return Map<String, dynamic>.from(result.data);
    } on FirebaseFunctionsException catch (e) {
      debugPrint('[FunctionsService] addService: FirebaseFunctionsException - Code: ${e.code}, Message: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('[FunctionsService] addService: Unexpected error: $e');
      rethrow;
    }
  }

  /// Update an existing technician service via Cloud Function
  /// PRICING: price = original price (before discount), offerPrice = discounted price
  Future<Map<String, dynamic>> updateService({
    required String serviceId,
    String? name,
    double? price,
    double? offerPrice,
    String? imageUrl,
    String? category,
    String? description,
    bool? isActive,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }
      debugPrint('[FunctionsService] updateService: Current user UID: ${user.uid}');
      await user.getIdToken(true);
      debugPrint('[FunctionsService] updateService: Token refreshed successfully');
      
      final callable = _functions.httpsCallable('updateTechnicianService');
      final Map<String, dynamic> data = {'serviceId': serviceId};
      
      if (name != null) data['name'] = name;
      if (price != null) data['price'] = price;  // Original price
      if (offerPrice != null) data['offerPrice'] = offerPrice;  // Discounted price
      if (imageUrl != null) data['imageUrl'] = imageUrl;
      if (category != null) data['category'] = category;
      if (description != null) data['description'] = description;
      if (isActive != null) data['isActive'] = isActive;

      debugPrint('[FunctionsService] updateService REQUEST PAYLOAD: $data');
      debugPrint('[FunctionsService] updateService - Sending ONLY price + offerPrice (NO basePrice)');

      final result = await callable.call(data);
      return Map<String, dynamic>.from(result.data);
    } on FirebaseFunctionsException catch (e) {
      debugPrint('[FunctionsService] updateService: FirebaseFunctionsException - Code: ${e.code}, Message: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('[FunctionsService] updateService: Unexpected error: $e');
      rethrow;
    }
  }

  /// Toggle technician service active status via Cloud Function
  Future<Map<String, dynamic>> toggleServiceStatus(String serviceId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }
      debugPrint('[FunctionsService] toggleServiceStatus: Current user UID: ${user.uid}');
      await user.getIdToken(true);
      debugPrint('[FunctionsService] toggleServiceStatus: Token refreshed successfully');
      
      final callable = _functions.httpsCallable('toggleTechnicianServiceStatus');
      final result = await callable.call({'serviceId': serviceId});
      return Map<String, dynamic>.from(result.data);
    } on FirebaseFunctionsException catch (e) {
      debugPrint('[FunctionsService] toggleServiceStatus: FirebaseFunctionsException - Code: ${e.code}, Message: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('[FunctionsService] toggleServiceStatus: Unexpected error: $e');
      rethrow;
    }
  }

  /// Delete (soft delete) a technician service via Cloud Function
  Future<Map<String, dynamic>> deleteService(String serviceId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }
      
      print('[AUTH DEBUG] UID: ${user.uid}');
      await user.getIdToken(true);
      print('[AUTH DEBUG] TOKEN REFRESHED');
      
      debugPrint('[FunctionsService] deleteService: Current user UID: ${user.uid}');
      debugPrint('[FunctionsService] deleteService: Token refreshed successfully');
      debugPrint('[FunctionsService] deleteService: Calling deleteTechnicianService with serviceId: $serviceId');
      
      final callable = FirebaseFunctionsService.instance
          .httpsCallable('deleteTechnicianService');
      
      final result = await callable.call({'serviceId': serviceId});
      
      debugPrint('[FunctionsService] deleteService: SUCCESS - ${result.data}');
      return Map<String, dynamic>.from(result.data);
    } on FirebaseFunctionsException catch (e) {
      debugPrint('[FunctionsService] deleteService: FirebaseFunctionsException - Code: ${e.code}, Message: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('[FunctionsService] deleteService: Unexpected error: $e');
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
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }
      debugPrint('[FunctionsService] updateTechnicianPersonalDetails: Current user UID: ${user.uid}');
      await user.getIdToken(true);
      debugPrint('[FunctionsService] updateTechnicianPersonalDetails: Token refreshed successfully');
      
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
      
      if (updates.isEmpty) {
        return {'success': true, 'message': 'No updates provided'};
      }
      
      final callable = _functions.httpsCallable('updateTechnicianPersonalDetails');
      final result = await callable.call(updates);
      return Map<String, dynamic>.from(result.data);
    } on FirebaseFunctionsException catch (e) {
      debugPrint('[FunctionsService] updateTechnicianPersonalDetails: FirebaseFunctionsException - Code: ${e.code}, Message: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('[FunctionsService] updateTechnicianPersonalDetails: Unexpected error: $e');
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

  /// Verify technician bank account using production-safe Cloud Function
  /// Uses verifyTechnicianBankAccountSecure with idempotency and race condition protection
  Future<Map<String, dynamic>> verifyTechnicianBankAccountSecure({
    required String accountHolderName,
    required String accountNumber,
    required String ifscCode,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }
      debugPrint('[FunctionsService] verifyTechnicianBankAccountSecure: Current user UID: ${user.uid}');
      await user.getIdToken(true);
      debugPrint('[FunctionsService] verifyTechnicianBankAccountSecure: Token refreshed successfully');
      
      // FIX 1: Use correct function name
      debugPrint('[FunctionsService] Calling verifyTechnicianBankAccountSecure...');
      final callable = _functions.httpsCallable('verifyTechnicianBankAccountSecure');
      
      // FIX 2: Add debug log before call
      debugPrint('[FunctionsService] Bank verification request: accountHolder=$accountHolderName, ifsc=$ifscCode');
      
      final result = await callable.call({
        'accountHolderName': accountHolderName,
        'accountNumber': accountNumber,
        'ifscCode': ifscCode.toUpperCase(),
      });
      
      // FIX 3: Validate response structure
      final responseData = Map<String, dynamic>.from(result.data);
      debugPrint('[FunctionsService] Bank verification response: $responseData');
      
      // FIX 4: Check for success flag
      if (responseData['success'] != true) {
        final message = responseData['message'] ?? 'Bank verification failed';
        debugPrint('[FunctionsService] Bank verification failed: $message');
        throw Exception(message);
      }
      
      debugPrint('[FunctionsService] Bank verification successful: ${responseData['status']}');
      return responseData;
    } on FirebaseFunctionsException catch (e) {
      debugPrint('[FunctionsService] verifyTechnicianBankAccountSecure: FirebaseFunctionsException - Code: ${e.code}, Message: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('[FunctionsService] verifyTechnicianBankAccountSecure: Unexpected error: $e');
      rethrow;
    }
  }

  /// Check bank verification status using production-safe Cloud Function
  Future<Map<String, dynamic>> checkBankVerificationStatus() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }
      debugPrint('[FunctionsService] checkBankVerificationStatus: Current user UID: ${user.uid}');
      await user.getIdToken(true);
      debugPrint('[FunctionsService] checkBankVerificationStatus: Token refreshed successfully');
      
      final callable = _functions.httpsCallable('checkBankVerificationStatus');
      final result = await callable.call();
      return Map<String, dynamic>.from(result.data);
    } on FirebaseFunctionsException catch (e) {
      debugPrint('[FunctionsService] checkBankVerificationStatus: FirebaseFunctionsException - Code: ${e.code}, Message: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('[FunctionsService] checkBankVerificationStatus: Unexpected error: $e');
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
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }
      debugPrint('[FunctionsService] reuploadVerificationDocument: Current user UID: ${user.uid}');
      await user.getIdToken(true);
      debugPrint('[FunctionsService] reuploadVerificationDocument: Token refreshed successfully');
      
      final callable = _functions.httpsCallable('reuploadVerificationDocument');
      final result = await callable.call({
        'documentType': documentType,
        'documentUrl': documentUrl,
      });
      return Map<String, dynamic>.from(result.data);
    } on FirebaseFunctionsException catch (e) {
      debugPrint('[FunctionsService] reuploadVerificationDocument: FirebaseFunctionsException - Code: ${e.code}, Message: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('[FunctionsService] reuploadVerificationDocument: Unexpected error: $e');
      rethrow;
    }
  }


}

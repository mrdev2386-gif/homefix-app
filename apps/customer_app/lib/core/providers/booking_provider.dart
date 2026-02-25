import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/booking_service.dart';
import '../models/booking.dart';

/// Price tolerance for booking validation (5% variance allowed)
const double kPriceTolerancePercent = 0.05;

class BookingProvider extends ChangeNotifier {
  final BookingService _bookingService = BookingService();
  
  bool _isBooking = false;
  bool get isBooking => _isBooking;

  /// Live verification before creating a booking request
  /// 
  /// Validates:
  /// - Service exists and is active
  /// - Technician exists, is active, and is approved
  /// - SubService is valid (if provided)
  /// - Price matches within tolerance
  /// - CategoryId is present
  /// - District is normalized
  Future<Map<String, dynamic>> createBookingRequest({
    required String serviceId,
    required String technicianId,
    required String categoryId,
    required String categoryName,
    required String scheduledDate,
    required String scheduledTime,
    required Map<String, dynamic> address,
    required double price,
    String? subcategoryId,
    int? durationMinutes,
    String? couponCode,
  }) async {
    _isBooking = true;
    notifyListeners();
    
    try {
      final db = _bookingService.db;
      
      // ─────────────────────────────────────────────────────────────────────
      // 1. RE-FETCH AND VERIFY SERVICE
      // ─────────────────────────────────────────────────────────────────────
      DocumentSnapshot? techServiceDoc;
      DocumentSnapshot? globalServiceDoc;
      
      try {
        techServiceDoc = await db.collection('technicians').doc(technicianId)
            .collection('technician_services').doc(serviceId).get();
      } catch (e) {
        if (kDebugMode) debugPrint('⚠️ [BookingProvider] Error fetching tech service: $e');
      }
      
      if (techServiceDoc != null && techServiceDoc.exists) {
        final data = techServiceDoc.data() as Map<String, dynamic>?;
        if (data == null) {
          throw Exception('Service data missing');
        }
        // Check if service is active and published
        if (data['status'] != 'active' || data['isPublished'] == false) {
          throw Exception('This service is no longer available. Please select another.');
        }
        
        // Verify subService is valid if provided
        if (subcategoryId != null && subcategoryId.isNotEmpty) {
          final subServiceId = data['subServiceId'];
          if (subServiceId != subcategoryId) {
            throw Exception('Sub-service has changed. Please refresh and try again.');
          }
        }
        
        // Price integrity check - verify against stored price
        final storedPrice = ((data['price'] ?? data['finalPrice'] ?? 0) as num).toDouble();
        final priceDiff = (price - storedPrice).abs();
        final tolerance = storedPrice * kPriceTolerancePercent;
        if (priceDiff > tolerance && storedPrice > 0) {
          if (kDebugMode) debugPrint('⚠️ [BookingProvider] Price mismatch: stored=$storedPrice, provided=$price, diff=$priceDiff, tolerance=$tolerance');
          throw Exception('Price has changed. Please refresh and try again.');
        }
      } else {
        // Fallback to global service check
        globalServiceDoc = await db.collection('categories').doc(categoryId)
            .collection('services').doc(serviceId).get();
            
        if (!globalServiceDoc.exists) {
          throw Exception('Service not found. It may have been removed.');
        }
        final globalData = globalServiceDoc.data() as Map<String, dynamic>?;
        if (globalData == null) {
          throw Exception('Global service data missing');
        }
        if (globalData['isActive'] == false) {
          throw Exception('This service is currently inactive.');
        }
        
        // Price integrity check for global service
        final storedPrice = ((globalData['price'] ?? 0) as num).toDouble();
        final priceDiff = (price - storedPrice).abs();
        final tolerance = storedPrice * kPriceTolerancePercent;
        if (priceDiff > tolerance && storedPrice > 0) {
          throw Exception('Price has changed. Please refresh and try again.');
        }
      }

      // ─────────────────────────────────────────────────────────────────────
      // 2. RE-FETCH AND VERIFY TECHNICIAN
      // ─────────────────────────────────────────────────────────────────────
      final techDoc = await db.collection('technicians').doc(technicianId).get();
      if (!techDoc.exists) {
        throw Exception('Technician no longer exists.');
      }
      final techData = techDoc.data();
      if (techData == null) {
        throw Exception('Technician data missing');
      }
      
      // Check if technician is active
      if (techData['isActive'] == false) {
        throw Exception('Technician is currently unavailable. Please try another.');
      }
      
      // Check technician status - must be approved
      final techStatus = (techData['status'] ?? '').toString().toLowerCase();
      final technicianApproved = techData['technicianApproved'] ?? techData['isVerified'] ?? false;
      if (techStatus != 'approved' && techStatus != 'active' && technicianApproved != true) {
        if (kDebugMode) debugPrint('⚠️ [BookingProvider] Technician not approved: status=$techStatus, approved=$technicianApproved');
        throw Exception('Technician is not approved for bookings. Please try another.');
      }

      // ─────────────────────────────────────────────────────────────────────
      // 3. VERIFY CATEGORY IS PRESENT
      // ─────────────────────────────────────────────────────────────────────
      if (categoryId.isEmpty) {
        throw Exception('Invalid category. Please re-select the service.');
      }
      
      // Verify category exists
      final categoryDoc = await db.collection('categories').doc(categoryId).get();
      if (!categoryDoc.exists) {
        throw Exception('Category not found. Please re-select the service.');
      }

      // ─────────────────────────────────────────────────────────────────────
      // 4. VERIFY DISTRICT/NORMALIZED ADDRESS
      // ─────────────────────────────────────────────────────────────────────
      final districtNormalized = address['districtNormalized'] ?? address['district'] ?? address['city'];
      if (districtNormalized == null || districtNormalized.toString().isEmpty) {
        if (kDebugMode) debugPrint('⚠️ [BookingProvider] Missing district/normalized address');
        // Try to get from technician's serviceable areas
        if (techData['serviceableDistricts'] != null) {
          final serviceableDistricts = List<String>.from(techData['serviceableDistricts']);
          if (serviceableDistricts.isEmpty) {
            throw Exception('Please set your location to a serviceable area.');
          }
        }
      }

      // ─────────────────────────────────────────────────────────────────────
      // 5. CREATE BOOKING REQUEST
      // ─────────────────────────────────────────────────────────────────────
      final response = await _bookingService.createBookingRequest(
        serviceId: serviceId,
        technicianId: technicianId,
        categoryId: categoryId,
        categoryName: categoryName,
        scheduledDate: scheduledDate,
        scheduledTime: scheduledTime,
        address: address,
        price: price,
        subcategoryId: subcategoryId,
        durationMinutes: durationMinutes,
        couponCode: couponCode,
      );
      return response;
    } catch (e) {
      rethrow;
    } finally {
      _isBooking = false;
      notifyListeners();
    }
  }

  Stream<List<Booking>> customerBookings(String customerId) {
    return _bookingService.getCustomerBookings(customerId);
  }

  Future<void> cancelBooking(String bookingId, {String reason = 'Cancelled by customer'}) async {
    await _bookingService.cancelBooking(bookingId, reason);
  }
}

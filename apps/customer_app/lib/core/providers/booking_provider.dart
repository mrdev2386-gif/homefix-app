import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/booking_service.dart';
import '../models/booking.dart';

/// Price tolerance for booking validation (₹1 strict tolerance)
const double kPriceToleranceRupees = 1.0;

class BookingProvider extends ChangeNotifier {
  final BookingService _bookingService = BookingService();
  
  bool _isBooking = false;
  bool get isBooking => _isBooking;

  /// Live verification before creating a booking request
  /// 
  /// Validates:
  /// - Service exists in technician_services collection (SOURCE OF TRUTH)
  /// - Technician exists, is active, and is approved
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
    int? quantity,
    int? durationMinutes,
    String? couponCode,
    String? paymentMode,
  }) async {
    _isBooking = true;
    notifyListeners();
    
    try {
      final db = _bookingService.db;
      
      // ─────────────────────────────────────────────────────────────────────
      // 1. RE-FETCH AND VERIFY SERVICE FROM technician_services (SOURCE OF TRUTH)
      // ─────────────────────────────────────────────────────────────────────
      print('[BOOKING_FLOW] serviceId received: $serviceId');
      print('[BOOKING_FLOW] Fetching from technician_services');
      
      final techServiceDoc = await db.collection('technician_services')
          .doc(serviceId).get();
      
      if (!techServiceDoc.exists) {
        throw Exception('Service not found. It may have been removed.');
      }
      
      final data = techServiceDoc.data() as Map<String, dynamic>?;
      if (data == null) {
        throw Exception('Service data missing');
      }
      
      // Check if service is approved (status='approved' is the source of truth)
      if (data['status'] != 'approved') {
        throw Exception('This service is no longer available. Please select another.');
      }
      
      // Price integrity check - verify against stored price (quantity-aware)
      // Strict ₹1 tolerance to prevent price manipulation
      final storedPrice = ((data['price'] ?? data['finalPrice'] ?? 0) as num).toDouble();
      final qty = quantity ?? 1;
      final expectedPrice = storedPrice * qty;
      final priceDiff = (price - expectedPrice).abs();
      
      if (priceDiff > kPriceToleranceRupees && expectedPrice > 0) {
        if (kDebugMode) debugPrint('⚠️ [BookingProvider] Price mismatch: stored=$storedPrice, qty=$qty, expected=$expectedPrice, provided=$price, diff=₹$priceDiff');
        throw Exception('Price has changed. Please refresh and try again.');
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
      print('[BOOKING_FLOW] Booking created successfully');
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
        quantity: quantity,
        durationMinutes: durationMinutes,
        couponCode: couponCode,
        paymentMode: paymentMode,
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

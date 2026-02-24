import 'package:flutter/material.dart';
import '../services/booking_service.dart';
import '../models/booking.dart';

class BookingProvider extends ChangeNotifier {
  final BookingService _bookingService = BookingService();
  
  bool _isBooking = false;
  bool get isBooking => _isBooking;

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
      
      // 1. Re-fetch and verify service
      final techServiceDoc = await db.collection('technicians').doc(technicianId)
          .collection('technician_services').doc(serviceId).get();
      
      if (techServiceDoc.exists) {
        final data = techServiceDoc.data()!;
        if (data['status'] != 'active' || data['isPublished'] == false) {
          throw Exception('This service is no longer available. Please select another.');
        }
      } else {
        // Fallback global service check
        final globalServiceDoc = await db.collection('categories').doc(categoryId)
            .collection('services').doc(serviceId).get();
            
        if (!globalServiceDoc.exists) {
          throw Exception('Service not found. It may have been removed.');
        }
        if (globalServiceDoc.data()?['isActive'] == false) {
          throw Exception('This service is currently inactive.');
        }
      }

      // 2. Re-fetch and verify technician
      final techDoc = await db.collection('technicians').doc(technicianId).get();
      if (!techDoc.exists) {
        throw Exception('Technician no longer exists.');
      }
      final techData = techDoc.data()!;
      if (techData['isActive'] == false || (techData['status'] != 'approved' && techData['status'] != 'active')) {
        throw Exception('Technician is currently unavailable. Please try another.');
      }

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

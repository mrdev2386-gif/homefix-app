import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';

class BookingScreenUpdated {
  /// Display service options based on service features
  static Widget buildServiceOptionsSection({
    required Map<String, dynamic> service,
    required DateTime selectedBookingTime,
    required bool isUrgentSelected,
    required ValueChanged<bool> onUrgentChanged,
  }) {
    final urgentEnabled = service['urgentBooking']?['enabled'] == true;
    final nightEnabled = service['nightService']?['enabled'] == true;
    
    final hour = selectedBookingTime.hour;
    final isNightTime = hour >= 22 || hour < 6;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildBookingOption(
          title: 'Normal Booking',
          subtitle: 'Standard service',
          price: service['price'],
          isSelected: !isUrgentSelected,
          onTap: () => onUrgentChanged(false),
        ),

        if (urgentEnabled) ...[
          const SizedBox(height: 12),
          _buildBookingOption(
            title: 'Urgent Booking (Express)',
            subtitle: 'Arrival: ${service['urgentBooking']['arrivalTime']}',
            price: service['price'] + service['urgentBooking']['urgentFee'],
            isSelected: isUrgentSelected,
            onTap: () => onUrgentChanged(true),
            badge: '+₹${service['urgentBooking']['urgentFee']}',
          ),
        ],

        if (isNightTime && nightEnabled) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF5E6),
              border: Border.all(color: const Color(0xFFFFA500)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.nightlight, color: Color(0xFFFFA500), size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Night Service (10 PM - 6 AM)',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        service['nightService']['nightCharge'] > 0
                            ? 'Additional charge: ₹${service['nightService']['nightCharge']}'
                            : 'No additional charge',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  static Widget _buildBookingOption({
    required String title,
    required String subtitle,
    required double price,
    required bool isSelected,
    required VoidCallback onTap,
    String? badge,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF0F4FF) : Colors.white,
          border: Border.all(
            color: isSelected ? const Color(0xFF6366F1) : const Color(0xFFE2E8F0),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? const Color(0xFF6366F1) : const Color(0xFFE2E8F0),
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Center(
                      child: Icon(Icons.check, size: 14, color: Color(0xFF6366F1)),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₹${price.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF6366F1),
                  ),
                ),
                if (badge != null) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF6B6B).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      badge,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFFFF6B6B),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Calculate final price - night time auto-detected by Cloud Function
  static Future<Map<String, dynamic>> calculateFinalPrice({
    required String serviceId,
    required String technicianId,
    required DateTime bookingTime,
    required bool isUrgentBooking,
  }) async {
    try {
      final callable = FirebaseFunctions.instanceFor(region: 'us-central1')
          .httpsCallable('calculateBookingPrice');

      final result = await callable.call({
        'serviceId': serviceId,
        'technicianId': technicianId,
        'bookingTime': bookingTime.toIso8601String(),
        'isUrgentBooking': isUrgentBooking,
      });

      return {
        'success': true,
        'finalPrice': result.data['finalPrice'],
        'breakdown': result.data['breakdown'],
        'isNightTime': result.data['isNightTime'],
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Validate booking options
  static String? validateBookingOptions({
    required Map<String, dynamic> service,
    required DateTime bookingTime,
    required bool isUrgentBooking,
  }) {
    if (isUrgentBooking) {
      if (service['urgentBooking']?['enabled'] != true) {
        return 'Urgent booking is not available for this service';
      }
    }

    final hour = bookingTime.hour;
    final isNightTime = hour >= 22 || hour < 6;
    
    if (isNightTime) {
      if (service['nightService']?['enabled'] != true) {
        return 'Night service is not available for this service';
      }
    }

    return null;
  }
}

/**
 * Usage in Booking Screen:
 * 
 * DateTime _selectedBookingTime = DateTime.now();
 * bool _isUrgentSelected = false;
 * 
 * // Display options
 * BookingScreenUpdated.buildServiceOptionsSection(
 *   service: serviceData,
 *   selectedBookingTime: _selectedBookingTime,
 *   isUrgentSelected: _isUrgentSelected,
 *   onUrgentChanged: (value) => setState(() => _isUrgentSelected = value),
 * )
 * 
 * // Validate before booking
 * final validation = BookingScreenUpdated.validateBookingOptions(
 *   service: serviceData,
 *   bookingTime: _selectedBookingTime,
 *   isUrgentBooking: _isUrgentSelected,
 * );
 * 
 * if (validation != null) {
 *   showError(validation);
 *   return;
 * }
 * 
 * // Calculate price (night time auto-detected)
 * final priceResult = await BookingScreenUpdated.calculateFinalPrice(
 *   serviceId: service['id'],
 *   technicianId: service['technicianId'],
 *   bookingTime: _selectedBookingTime,
 *   isUrgentBooking: _isUrgentSelected,
 * );
 * 
 * if (priceResult['success']) {
 *   final finalPrice = priceResult['finalPrice'];
 *   final isNightTime = priceResult['isNightTime'];
 *   
 *   // Create booking with finalPrice
 *   final booking = {
 *     'basePrice': service['price'],
 *     'isUrgentBooking': _isUrgentSelected,
 *     'urgentFee': _isUrgentSelected ? service['urgentBooking']['urgentFee'] : null,
 *     'isNightBooking': isNightTime,
 *     'nightCharge': isNightTime ? service['nightService']['nightCharge'] : null,
 *     'finalPrice': finalPrice,
 *     'priceBreakdown': priceResult['breakdown'],
 *   };
 * }
 */

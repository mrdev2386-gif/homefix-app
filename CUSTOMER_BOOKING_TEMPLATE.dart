// Customer Booking Screen - Service Features Integration
// File: apps/customer_app/lib/features/booking/booking_screen.dart
// This is a template showing how to integrate urgent booking and night service

import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';

class BookingScreenTemplate {
  /// Display service options based on service features
  static Widget buildServiceOptionsSection({
    required Map<String, dynamic> service,
    required bool isUrgentSelected,
    required bool isNightSelected,
    required ValueChanged<bool> onUrgentChanged,
    required ValueChanged<bool> onNightChanged,
  }) {
    final urgentEnabled = service['urgentBooking']?['enabled'] == true;
    final nightEnabled = service['nightService']?['enabled'] == true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Normal Booking Option (always available)
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

        if (nightEnabled) ...[
          const SizedBox(height: 12),
          _buildNightServiceOption(
            enabled: nightEnabled,
            nightCharge: service['nightService']['nightCharge'],
            isSelected: isNightSelected,
            onChanged: onNightChanged,
          ),
        ],
      ],
    );
  }

  /// Build individual booking option card
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

  /// Build night service option
  static Widget _buildNightServiceOption({
    required bool enabled,
    required int nightCharge,
    required bool isSelected,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFFFF5E6) : Colors.white,
        border: Border.all(
          color: isSelected ? const Color(0xFFFFA500) : const Color(0xFFE2E8F0),
          width: isSelected ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Checkbox(
            value: isSelected,
            onChanged: (value) => onChanged(value ?? false),
            activeColor: const Color(0xFFFFA500),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Night Service (10 PM - 6 AM)',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  nightCharge > 0
                      ? 'Additional charge: ₹$nightCharge'
                      : 'No additional charge',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          if (nightCharge > 0)
            Text(
              '+₹$nightCharge',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFFFFA500),
              ),
            ),
        ],
      ),
    );
  }

  /// Calculate final price using Cloud Function
  static Future<Map<String, dynamic>> calculateFinalPrice({
    required String serviceId,
    required String technicianId,
    required bool isUrgentBooking,
    required bool isNightBooking,
  }) async {
    try {
      final callable = FirebaseFunctions.instanceFor(region: 'us-central1')
          .httpsCallable('calculateBookingPrice');

      final result = await callable.call({
        'serviceId': serviceId,
        'technicianId': technicianId,
        'isUrgentBooking': isUrgentBooking,
        'isNightBooking': isNightBooking,
      });

      return {
        'success': true,
        'finalPrice': result.data['finalPrice'],
        'breakdown': result.data['breakdown'],
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
    required bool isUrgentBooking,
    required bool isNightBooking,
  }) {
    // Urgent booking validation
    if (isUrgentBooking) {
      if (service['urgentBooking']?['enabled'] != true) {
        return 'Urgent booking is not available for this service';
      }
    }

    // Night booking validation
    if (isNightBooking) {
      if (service['nightService']?['enabled'] != true) {
        return 'Night service is not available for this service';
      }
    }

    return null; // Valid
  }
}

/**
 * Usage in Booking Screen:
 * 
 * bool _isUrgentSelected = false;
 * bool _isNightSelected = false;
 * 
 * // Display options
 * BookingScreenTemplate.buildServiceOptionsSection(
 *   service: serviceData,
 *   isUrgentSelected: _isUrgentSelected,
 *   isNightSelected: _isNightSelected,
 *   onUrgentChanged: (value) => setState(() => _isUrgentSelected = value),
 *   onNightChanged: (value) => setState(() => _isNightSelected = value),
 * )
 * 
 * // Calculate price before booking
 * final priceResult = await BookingScreenTemplate.calculateFinalPrice(
 *   serviceId: service['id'],
 *   technicianId: service['technicianId'],
 *   isUrgentBooking: _isUrgentSelected,
 *   isNightBooking: _isNightSelected,
 * );
 * 
 * if (priceResult['success']) {
 *   final finalPrice = priceResult['finalPrice'];
 *   // Create booking with finalPrice
 * }
 */

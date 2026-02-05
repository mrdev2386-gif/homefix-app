import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/models/booking.dart';

class BookingCard extends StatelessWidget {
  final Booking booking;
  final VoidCallback onTap;

  const BookingCard({
    super.key,
    required this.booking,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Service Title and Status
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        booking.serviceTitle,
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    _buildStatusBadge(booking.status),
                  ],
                ),
                const SizedBox(height: 12),

                // Booking ID
                Row(
                  children: [
                    Icon(Icons.tag, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 6),
                    Text(
                      'ID: ${booking.id.substring(0, 8).toUpperCase()}',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Scheduled Date & Time
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 6),
                    Text(
                      DateFormat('MMM dd, yyyy • hh:mm a').format(booking.scheduledAt),
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Address
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _getAddressString(booking.addressSnapshot),
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          color: Colors.grey[700],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                // Technician Info (if assigned)
                if (booking.technicianName != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.person, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 6),
                      Text(
                        'Technician: ${booking.technicianName}',
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],

                const Divider(height: 24),

                // Footer: Price and View Details
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Amount',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '₹${booking.finalAmount.toStringAsFixed(0)}',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF6366F1),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Text(
                          'View Details',
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            color: const Color(0xFF6366F1),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.arrow_forward_ios,
                          size: 12,
                          color: Color(0xFF6366F1),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color backgroundColor;
    Color textColor;
    String displayText;

    switch (status.toLowerCase()) {
      case 'pending':
        backgroundColor = Colors.orange.shade50;
        textColor = Colors.orange.shade700;
        displayText = 'Pending';
        break;
      case 'assigned':
      case 'accepted':
        backgroundColor = Colors.blue.shade50;
        textColor = Colors.blue.shade700;
        displayText = 'Assigned';
        break;
      case 'on_the_way':
        backgroundColor = Colors.purple.shade50;
        textColor = Colors.purple.shade700;
        displayText = 'On the Way';
        break;
      case 'started':
      case 'in_progress':
        backgroundColor = Colors.indigo.shade50;
        textColor = Colors.indigo.shade700;
        displayText = 'In Progress';
        break;
      case 'completed':
        backgroundColor = Colors.green.shade50;
        textColor = Colors.green.shade700;
        displayText = 'Completed';
        break;
      case 'cancelled':
        backgroundColor = Colors.red.shade50;
        textColor = Colors.red.shade700;
        displayText = 'Cancelled';
        break;
      default:
        backgroundColor = Colors.grey.shade50;
        textColor = Colors.grey.shade700;
        displayText = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        displayText,
        style: GoogleFonts.outfit(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  String _getAddressString(Map<String, dynamic> addressSnapshot) {
    if (addressSnapshot.isEmpty) return 'Address not available';
    
    final street = addressSnapshot['street'] ?? '';
    final area = addressSnapshot['area'] ?? '';
    final city = addressSnapshot['city'] ?? '';
    
    final parts = [street, area, city].where((s) => s.isNotEmpty).toList();
    return parts.isEmpty ? 'Address not available' : parts.join(', ');
  }
}

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
                // ═══════════════════════════════════════════════════════════
                // TOP ROW: Service Name + Status Badge
                // ═══════════════════════════════════════════════════════════
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        booking.serviceTitle,
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF1F2937),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 12),
                    _buildStatusBadge(booking.status),
                  ],
                ),
                const SizedBox(height: 12),

                // ═══════════════════════════════════════════════════════════
                // MIDDLE: Technician + Date/Time + Price
                // ═══════════════════════════════════════════════════════════
                // Technician (if assigned)
                if (booking.technicianName != null && booking.technicianName!.isNotEmpty) ...[
                  _buildInfoRow(
                    icon: Icons.person_outline_rounded,
                    iconColor: const Color(0xFF6366F1),
                    text: booking.technicianName!,
                    textStyle: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF4B5563),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],

                // Scheduled Date & Time
                _buildInfoRow(
                  icon: Icons.calendar_today_outlined,
                  iconColor: const Color(0xFF6366F1),
                  text: _formatScheduledDateTime(),
                  textStyle: GoogleFonts.outfit(
                    fontSize: 13,
                    color: const Color(0xFF4B5563),
                  ),
                ),
                const SizedBox(height: 8),

                // Address (compact)
                _buildInfoRow(
                  icon: Icons.location_on_outlined,
                  iconColor: const Color(0xFF6366F1),
                  text: _getAddressString(booking.addressSnapshot),
                  textStyle: GoogleFonts.outfit(
                    fontSize: 13,
                    color: const Color(0xFF6B7280),
                  ),
                  maxLines: 1,
                ),

                const SizedBox(height: 16),
                Container(
                  height: 1,
                  color: const Color(0xFFE5E7EB),
                ),
                const SizedBox(height: 16),

                // ═══════════════════════════════════════════════════════════
                // BOTTOM ROW: Price + View Details Button
                // ═══════════════════════════════════════════════════════════
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Price
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Amount',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF9CA3AF),
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '₹${booking.finalAmount.toStringAsFixed(0)}',
                          style: GoogleFonts.outfit(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF6366F1),
                          ),
                        ),
                      ],
                    ),
                    // View Details Button
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF6366F1).withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'View Details',
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.arrow_forward_rounded,
                            size: 14,
                            color: Colors.white,
                          ),
                        ],
                      ),
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

  Widget _buildInfoRow({
    required IconData icon,
    required Color iconColor,
    required String text,
    required TextStyle textStyle,
    int maxLines = 2,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 16,
          color: iconColor,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: textStyle,
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  String _formatScheduledDateTime() {
    try {
      return DateFormat('MMM dd, yyyy • hh:mm a').format(booking.scheduledAt);
    } catch (e) {
      return 'Scheduled: ${booking.scheduledTime ?? "Not set"}';
    }
  }

  Widget _buildStatusBadge(String status) {
    Color backgroundColor;
    Color textColor;
    String displayText;
    IconData? icon;

    switch (status.toLowerCase()) {
      case 'pending':
      case 'pending_admin':
        backgroundColor = Colors.orange.shade50;
        textColor = Colors.orange.shade700;
        displayText = 'Pending';
        icon = Icons.hourglass_empty_rounded;
        break;
      case 'assigned':
      case 'accepted':
        backgroundColor = Colors.blue.shade50;
        textColor = Colors.blue.shade700;
        displayText = 'Assigned';
        icon = Icons.verified_user_rounded;
        break;
      case 'on_the_way':
        backgroundColor = Colors.purple.shade50;
        textColor = Colors.purple.shade700;
        displayText = 'On the Way';
        icon = Icons.directions_car_rounded;
        break;
      case 'started':
      case 'in_progress':
        backgroundColor = Colors.indigo.shade50;
        textColor = Colors.indigo.shade700;
        displayText = 'In Progress';
        icon = Icons.engineering_rounded;
        break;
      case 'completed':
        backgroundColor = Colors.green.shade50;
        textColor = Colors.green.shade700;
        displayText = 'Completed';
        icon = Icons.check_circle_rounded;
        break;
      case 'cancelled':
        backgroundColor = Colors.red.shade50;
        textColor = Colors.red.shade700;
        displayText = 'Cancelled';
        icon = Icons.cancel_rounded;
        break;
      case 'awaiting_payment':
        backgroundColor = Colors.amber.shade50;
        textColor = Colors.amber.shade700;
        displayText = 'Awaiting Payment';
        icon = Icons.payment_rounded;
        break;
      default:
        backgroundColor = Colors.grey.shade50;
        textColor = Colors.grey.shade700;
        displayText = status;
        icon ??= Icons.info_outline_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: textColor),
            const SizedBox(width: 4),
          ],
          Text(
            displayText,
            style: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  String _getAddressString(Map<String, dynamic> addressSnapshot) {
    if (addressSnapshot.isEmpty) return 'Address not available';
    
    final street = addressSnapshot['street'] ?? '';
    final area = addressSnapshot['area'] ?? addressSnapshot['locality'] ?? '';
    final city = addressSnapshot['city'] ?? addressSnapshot['district'] ?? '';
    
    final parts = [street, area, city].where((s) => s.toString().isNotEmpty).toList();
    return parts.isEmpty ? 'Address not available' : parts.join(', ');
  }
}

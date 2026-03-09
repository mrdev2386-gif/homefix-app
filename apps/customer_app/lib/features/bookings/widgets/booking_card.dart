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
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ═══════════════════════════════════════════════════════════
              // TOP SECTION: Gradient Header with Service Name + Status
              // ═══════════════════════════════════════════════════════════
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_getStatusColor(booking.status).withOpacity(0.08), Colors.white],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Service Icon
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [_getStatusColor(booking.status), _getStatusColor(booking.status).withOpacity(0.7)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: _getStatusColor(booking.status).withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.home_repair_service_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            booking.serviceTitle,
                            style: GoogleFonts.outfit(
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF111827),
                              height: 1.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          _buildStatusBadge(booking.status),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // ═══════════════════════════════════════════════════════════
              // MIDDLE SECTION: Details
              // ═══════════════════════════════════════════════════════════
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // Technician (if assigned)
                    if (booking.technicianName != null && booking.technicianName!.isNotEmpty) ...[
                      _buildEnhancedInfoRow(
                        icon: Icons.person_rounded,
                        iconColor: const Color(0xFF6366F1),
                        label: 'Technician',
                        value: booking.technicianName!,
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Scheduled Date & Time
                    _buildEnhancedInfoRow(
                      icon: Icons.calendar_today_rounded,
                      iconColor: const Color(0xFF10B981),
                      label: 'Scheduled',
                      value: _formatScheduledDateTime(),
                    ),
                    const SizedBox(height: 12),

                    // Address
                    _buildEnhancedInfoRow(
                      icon: Icons.location_on_rounded,
                      iconColor: const Color(0xFFEF4444),
                      label: 'Location',
                      value: _getAddressString(booking.addressSnapshot),
                      maxLines: 2,
                    ),

                    const SizedBox(height: 20),
                    
                    // Divider
                    Container(
                      height: 1,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            Color(0xFFE5E7EB),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ═══════════════════════════════════════════════════════════
                    // BOTTOM ROW: Price + View Details Button
                    // ═══════════════════════════════════════════════════════════
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Price with gradient background
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFF6366F1).withOpacity(0.1),
                                const Color(0xFF8B5CF6).withOpacity(0.05),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: const Color(0xFF6366F1).withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'TOTAL AMOUNT',
                                style: GoogleFonts.outfit(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF6366F1),
                                  letterSpacing: 1,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '₹${booking.finalAmount.toStringAsFixed(0)}',
                                style: GoogleFonts.outfit(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                  color: const Color(0xFF111827),
                                  height: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // View Details Button
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF6366F1).withOpacity(0.4),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'View Details',
                                style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(
                                Icons.arrow_forward_rounded,
                                size: 16,
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedInfoRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    int maxLines = 1,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 18,
            color: iconColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF9CA3AF),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF374151),
                ),
                maxLines: maxLines,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
      case 'pending_admin':
        return Colors.orange;
      case 'technician_pending':
        return Colors.blue;
      case 'awaiting_payment':
        return Colors.purple;
      case 'confirmed':
      case 'assigned':
      case 'accepted':
        return Colors.green;
      case 'on_the_way':
      case 'started':
      case 'in_progress':
        return Colors.teal;
      case 'completed':
        return Colors.grey;
      case 'cancelled':
        return Colors.red;
      default:
        return const Color(0xFF6366F1);
    }
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
        icon = Icons.schedule_rounded;
        break;
      case 'technician_pending':
        backgroundColor = Colors.blue.shade50;
        textColor = Colors.blue.shade700;
        displayText = 'Finding Technician';
        icon = Icons.person_search_rounded;
        break;
      case 'awaiting_payment':
        backgroundColor = Colors.purple.shade50;
        textColor = Colors.purple.shade700;
        displayText = 'Payment Pending';
        icon = Icons.payment_rounded;
        break;
      case 'confirmed':
        backgroundColor = Colors.green.shade50;
        textColor = Colors.green.shade700;
        displayText = 'Confirmed';
        icon = Icons.verified_rounded;
        break;
      case 'assigned':
      case 'accepted':
        backgroundColor = Colors.blue.shade50;
        textColor = Colors.blue.shade700;
        displayText = 'Assigned';
        icon = Icons.check_circle_outline_rounded;
        break;
      case 'on_the_way':
        backgroundColor = Colors.teal.shade50;
        textColor = Colors.teal.shade700;
        displayText = 'On the Way';
        icon = Icons.directions_car_rounded;
        break;
      case 'started':
      case 'in_progress':
        backgroundColor = Colors.teal.shade50;
        textColor = Colors.teal.shade700;
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
      default:
        backgroundColor = Colors.grey.shade50;
        textColor = Colors.grey.shade600;
        displayText = 'Processing';
        icon = Icons.hourglass_empty_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: textColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ...[
          Icon(icon, size: 13, color: textColor),
          const SizedBox(width: 5),
        ],
          Text(
            displayText,
            style: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: textColor,
              letterSpacing: 0.3,
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

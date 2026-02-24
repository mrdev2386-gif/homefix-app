import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../../core/models/matched_technician.dart';
import '../../../core/widgets/safe_network_image.dart';
import '../../../core/providers/checkout_provider.dart';
import 'package:customer_app/core/theme/app_theme.dart';

class TechnicianSelectionScreen extends StatefulWidget {
  final List<MatchedTechnician> technicians;
  final String serviceId;
  final String? subServiceId;

  const TechnicianSelectionScreen({
    super.key, 
    required this.technicians,
    required this.serviceId,
    this.subServiceId,
  });

  @override
  State<TechnicianSelectionScreen> createState() => _TechnicianSelectionScreenState();
}

class _TechnicianSelectionScreenState extends State<TechnicianSelectionScreen> {
  MatchedTechnician? _selectedTechnician;

  void _handleTechnicianSelect(MatchedTechnician technician) {
    setState(() {
      _selectedTechnician = technician;
    });
    
    // Navigate to booking confirmation or show bottom sheet
    _showBookingBottomSheet(technician);
  }

  void _showBookingBottomSheet(MatchedTechnician technician) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Technician summary
              Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundImage: technician.photoUrl != null
                        ? CachedNetworkImageProvider(technician.photoUrl!)
                        : null,
                    child: technician.photoUrl == null
                        ? const Icon(Icons.person, size: 32)
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          technician.name,
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.star_rounded, color: Colors.orange, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              '${technician.rating.toStringAsFixed(1)} (${technician.totalCompletedOrders} jobs)',
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Details
              _buildDetailRow(Icons.access_time_rounded, 'Arrival in', '${technician.estimatedArrivalMinutes} min'),
              _buildDetailRow(Icons.location_on_rounded, 'Distance', '${technician.distanceKm.toStringAsFixed(1)} km'),
              const SizedBox(height: 24),
              // Confirm button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    // TODO: Navigate to booking confirmation screen
                    _confirmBooking(technician);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    'Confirm Booking',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Cancel button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    'Choose Another Professional',
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: AppTheme.primaryColor),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppTheme.textColor,
            ),
          ),
        ],
      ),
    );
  }

  void _confirmBooking(MatchedTechnician technician) {
    // Set the selected technician in checkout provider
    final checkoutProvider = Provider.of<CheckoutProvider>(context, listen: false);
    checkoutProvider.setSelectedTechnician(technician.id, technician.name);
    
    // Navigate to checkout
    Navigator.of(context).pushNamed('/checkout');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Professional',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppTheme.textColor,
              ),
            ),
            Text(
              '${widget.technicians.length} professionals available',
              style: GoogleFonts.outfit(
                fontSize: 13,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
        titleSpacing: 0,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: widget.technicians.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final technician = widget.technicians[index];
          return _TechnicianCard(
            technician: technician,
            isSelected: _selectedTechnician?.id == technician.id,
            onTap: () => _handleTechnicianSelect(technician),
          );
        },
      ),
    );
  }
}

class _TechnicianCard extends StatelessWidget {
  final MatchedTechnician technician;
  final bool isSelected;
  final VoidCallback onTap;

  const _TechnicianCard({
    required this.technician,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor.withValues(alpha: 0.05) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Profile image with status indicator
              Stack(
                children: [
                  Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(34),
                      child: technician.photoUrl != null
                          ? SafeNetworkImage(
                              imageUrl: technician.photoUrl!,
                              width: 68,
                              height: 68,
                              fit: BoxFit.cover,
                            )
                          : const Icon(Icons.person, size: 32, color: Colors.grey),
                    ),
                  ),
                  // Online indicator
                  Positioned(
                    bottom: 2,
                    right: 2,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            technician.name,
                            style: GoogleFonts.outfit(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textColor,
                            ),
                          ),
                        ),
                        if (technician.score >= 0.8)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.green.shade100, Colors.green.shade50],
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.star_rounded, color: Colors.green.shade600, size: 12),
                                const SizedBox(width: 4),
                                Text(
                                  'Top Rated',
                                  style: GoogleFonts.outfit(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.green.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Rating and reviews
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.orange.shade50, Colors.orange.shade100.withOpacity(0.5)],
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star_rounded, color: Colors.orange, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                technician.rating.toStringAsFixed(1),
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.orange.shade800,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          '${technician.totalCompletedOrders} jobs',
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Distance and ETA
                    Row(
                      children: [
                        _buildInfoChip(Icons.access_time_rounded, '${technician.estimatedArrivalMinutes} min', Colors.blue.shade500),
                        const SizedBox(width: 16),
                        _buildInfoChip(Icons.location_on_rounded, '${technician.distanceKm.toStringAsFixed(1)} km', Colors.grey[600]!),
                      ],
                    ),
                  ],
                ),
              ),
              // Arrow indicator
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text, Color iconColor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: iconColor),
        const SizedBox(width: 4),
        Text(
          text,
          style: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }
}

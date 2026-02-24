import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:customer_app/core/models/service.dart';
import '../../../core/widgets/safe_network_image.dart';
import '../../../core/theme/app_colors.dart';
import 'package:customer_app/core/theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../technicians/presentation/technician_list_screen.dart';

class ServiceGridIcon extends StatefulWidget {
  final HomeService service;

  const ServiceGridIcon({super.key, required this.service});

  @override
  State<ServiceGridIcon> createState() => _ServiceGridIconState();
}

class _ServiceGridIconState extends State<ServiceGridIcon> {
  bool _isNavigating = false;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        if (_isNavigating) return;
        _isNavigating = true;

        try {
          HapticFeedback.lightImpact();
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => TechnicianListScreen(service: widget.service)),
          );
        } finally {
          if (mounted) {
            _isNavigating = false;
          }
        }
      },
      borderRadius: BorderRadius.circular(24),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                child: SafeNetworkImage(
                  imageUrl: widget.service.imageUrl,
                  width: double.infinity,
                  height: double.infinity,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.service.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: AppTheme.textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '₹${widget.service.basePrice.toStringAsFixed(0)}',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star_rounded, size: 12, color: Colors.orange),
                            const SizedBox(width: 2),
                            Text(
                              widget.service.rating.toStringAsFixed(1),
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.w900,
                                fontSize: 10,
                                color: Colors.orange,
                              ),
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
    );
  }
}

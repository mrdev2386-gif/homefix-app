import 'package:flutter/material.dart';
import 'package:customer_app/core/models/service.dart';
import '../../../../core/widgets/safe_network_image.dart';
import '../../services/presentation/service_details_screen.dart';
import 'package:google_fonts/google_fonts.dart';

class ServiceCardHorizontal extends StatefulWidget {
  final HomeService service;

  const ServiceCardHorizontal({super.key, required this.service});

  @override
  State<ServiceCardHorizontal> createState() => _ServiceCardHorizontalState();
}

class _ServiceCardHorizontalState extends State<ServiceCardHorizontal> {
  bool _isNavigating = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        if (_isNavigating) return;
        _isNavigating = true;

        try {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ServiceDetailsScreen(
                serviceId: widget.service.id,
                categoryId: widget.service.category,
                serviceName: widget.service.title,
                serviceData: widget.service,
              ),
            ),
          );
        } finally {
          if (mounted) {
            _isNavigating = false;
          }
        }
      },
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 16),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 100,
              child: Stack(
                children: [
                  SafeNetworkImage(
                    imageUrl: widget.service.imageUrl,
                    width: 160,
                    height: 100,
                    fit: BoxFit.cover,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                ],
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
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, size: 14, color: Colors.orange),
                      const SizedBox(width: 4),
                      Text(
                        widget.service.rating.toString(),
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold, 
                          fontSize: 12,
                          color: Colors.grey[700],
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

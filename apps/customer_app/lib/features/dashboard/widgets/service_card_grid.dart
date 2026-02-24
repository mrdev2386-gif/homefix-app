import 'package:flutter/material.dart';
import 'package:customer_app/core/models/service.dart';
import '../../../../core/widgets/safe_network_image.dart';
import '../../services/presentation/service_details_screen.dart';
import 'package:google_fonts/google_fonts.dart';

class ServiceCardGrid extends StatefulWidget {
  final HomeService service;

  const ServiceCardGrid({super.key, required this.service});

  @override
  State<ServiceCardGrid> createState() => _ServiceCardGridState();
}

class _ServiceCardGridState extends State<ServiceCardGrid> {
  bool _isNavigating = false;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
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
        borderRadius: BorderRadius.circular(16),
        splashColor: const Color(0xFF6366F1).withOpacity(0.1),
        child: Container(
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
              Expanded(
                child: Stack(
                  children: [
                    SafeNetworkImage(
                      imageUrl: widget.service.imageUrl, 
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    ),
                    if(widget.service.isTopService)
                      Positioned(
                        top: 8, left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6366F1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'TOP', 
                            style: GoogleFonts.outfit(
                              color: Colors.white, 
                              fontSize: 10, 
                              fontWeight: FontWeight.bold
                            )
                          ),
                        ),
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
      ),
    );
  }
}

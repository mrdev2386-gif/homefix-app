import 'package:flutter/material.dart';
import '../../../../core/models/service.dart';
import '../../../../core/widgets/safe_network_image.dart';
import '../../technicians/presentation/technician_list_screen.dart';
import 'package:google_fonts/google_fonts.dart';

class ServiceCardHorizontal extends StatelessWidget {
  final HomeService service;

  const ServiceCardHorizontal({super.key, required this.service});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => TechnicianListScreen(service: service)),
        );
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
                    imageUrl: service.imageUrl,
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
                    service.title,
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
                        service.rating.toString(),
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

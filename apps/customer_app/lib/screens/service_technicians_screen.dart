import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:intl/intl.dart';
import '../core/app_theme.dart';
import '../core/services/services_catalog.dart';
import '../core/widgets/safe_network_image.dart';
import 'service_booking_screen.dart';

class ServiceTechniciansScreen extends StatefulWidget {
  final String category; 
  final double userLat;
  final double userLng;

  const ServiceTechniciansScreen({
    super.key,
    required this.category,
    required this.userLat,
    required this.userLng,
  });

  @override
  State<ServiceTechniciansScreen> createState() => _ServiceTechniciansScreenState();
}

class _ServiceTechniciansScreenState extends State<ServiceTechniciansScreen> {
  late ServiceItem _service;
  bool _isLoading = true;
  List<Map<String, dynamic>> _technicians = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    // Fallback if not found in catalog (should fetch from Firestore really)
    try {
        _service = ServicesCatalog.services.firstWhere((s) => s.id == widget.category);
    } catch (e) {
        _service = ServiceItem(id: widget.category, title: 'Service', imagePath: 'assets/services/ac.png', price: 999, durationMins: 60, category: 'general');
    }
    _fetchRankedTechnicians();
  }

  Future<void> _fetchRankedTechnicians() async {
    try {
        final result = await FirebaseFunctions.instance.httpsCallable('getRankedTechnicians').call({
            'serviceId': widget.category,
            'lat': widget.userLat,
            'lng': widget.userLng,
            'date': DateTime.now().toIso8601String(), // Ideally user selects date first, but simplified flow
        });
        
        final list = result.data as List<dynamic>;
        setState(() {
            _technicians = list.map((e) => Map<String, dynamic>.from(e)).toList();
            _isLoading = false;
        });

    } catch (e) {
        setState(() {
            _error = e.toString();
            _isLoading = false;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFB),
      appBar: AppBar(
        title: Text(_service.title, style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator()) 
        : _error != null 
           ? Center(child: Text("Error: $_error"))
           : Column(
            children: [
              _buildStatsHeader(_technicians.length),
              Expanded(
                child: _technicians.isEmpty 
                    ? _buildEmptyState() 
                    : ListView.builder(
                        padding: const EdgeInsets.all(20),
                        itemCount: _technicians.length,
                        itemBuilder: (context, index) {
                          return _buildTechCard(_technicians[index]);
                        },
                      ),
              ),
            ],
          ),
    );
  }

  Widget _buildStatsHeader(int count) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      color: AppTheme.primaryColor.withOpacity(0.05),
      child: Text("$count experts available near you", style: GoogleFonts.outfit(color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildEmptyState() {
     return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
         const Icon(Icons.person_off, size: 64, color: Colors.grey),
         const SizedBox(height: 16),
         const Text("No experts found nearby."),
         TextButton(onPressed: _fetchRankedTechnicians, child: const Text("Retry"))
     ]));
  }

  Widget _buildTechCard(Map<String, dynamic> tech) {
    final tags = List<String>.from(tech['tags'] ?? []);
    return GestureDetector(
      onTap: () {
          // Pass tech info to Booking Screen
           Navigator.push(context, MaterialPageRoute(
               builder: (_) => ServiceBookingScreen(
                   service: _service, 
                   preSelectedTech: tech // Pass map
               )
           ));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipOval(
                      child: SafeNetworkImage(
                        imageUrl: tech['photoUrl'],
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        fallbackUrl: 'https://ui-avatars.com/api/?name=Expert&background=random&size=128',
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(tech['name'] ?? 'Expert', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 4),
                          Row(children: [
                              const Icon(Icons.star, color: Colors.amber, size: 16),
                              Text(" ${tech['ratingAvg']?.toStringAsFixed(1) ?? '4.0'}", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                              Text(" (${tech['jobsDone'] ?? 0} jobs)", style: GoogleFonts.outfit(color: Colors.grey, fontSize: 12)),
                          ]),
                          const SizedBox(height: 4),
                          Text("${tech['distanceKm']} km away", style: GoogleFonts.outfit(color: Colors.green, fontSize: 12, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                    if (tech['isVerified'] == true) const Icon(Icons.verified, color: Colors.blue, size: 20),
                  ],
                ),
                if(tags.isNotEmpty) Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Wrap(
                        spacing: 8,
                        children: tags.map((t) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: Colors.amber.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                            child: Text(t, style: GoogleFonts.outfit(fontSize: 10, color: Colors.amber[800], fontWeight: FontWeight.bold))
                        )).toList()
                    )
                )
            ]
        ),
      ),
    );
  }
}

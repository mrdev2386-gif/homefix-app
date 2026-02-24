import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/models/technician.dart';
import 'package:customer_app/core/models/service.dart';
import '../../../core/widgets/safe_network_image.dart';
import 'package:customer_app/core/theme/app_theme.dart';
import '../../booking/presentation/slot_selection_screen.dart';
import 'package:google_fonts/google_fonts.dart';

class TechnicianListScreen extends StatelessWidget {
  final HomeService? service;
  final String? categoryId;
  final String? categoryName;

  const TechnicianListScreen({
    super.key, 
    this.service,
    this.categoryId,
    this.categoryName,
  });

  @override
  Widget build(BuildContext context) {
    // Determine title
    final String title = categoryName ?? service?.title ?? 'Experts';
    
    // Determine query
    Query query = FirebaseFirestore.instance.collection('technicians')
      .where('status', isEqualTo: 'active')
      .where('isApproved', isEqualTo: true)
      .where('isOnline', isEqualTo: true);
    if (categoryId != null) {
      query = query.where('supportedCategories', arrayContains: categoryId);
    } else if (service != null) {
      query = query.where('skills', arrayContains: service!.title);
    } else {
      // Default query or empty
      query = query.limit(20);
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          title,
          style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (service != null) _buildServiceSummary(),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Text(
              'Available Professionals',
              style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w900, color: AppTheme.subtitleColor, letterSpacing: 0.5),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: query.snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data == null || snapshot.data!.docs.isEmpty) {
                  return _buildEmpty();
                }

                final technicians = snapshot.data!.docs
                    .map((doc) => Technician.fromFirestore(doc))
                    .toList();

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                  physics: const BouncingScrollPhysics(),
                  itemCount: technicians.length,
                  itemBuilder: (context, index) {
                    return _buildTechCard(context, technicians[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceSummary() {
    if (service == null) return const SizedBox();
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SafeNetworkImage(
              imageUrl: service!.imageUrl,
              width: 50,
              height: 50,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  service!.title,
                  style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w800),
                ),
                Text(
                  '₹${service!.basePrice.toStringAsFixed(0)} base price',
                  style: GoogleFonts.outfit(color: AppTheme.primaryColor, fontSize: 13, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: AppTheme.accentColor, borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.info_outline_rounded, color: AppTheme.primaryColor, size: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildTechCard(BuildContext context, Technician tech) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: SafeNetworkImage(
                      imageUrl: tech.photoUrl ?? '',
                      width: 70,
                      height: 70,
                      fallbackUrl: 'https://ui-avatars.com/api/?name=${tech.name}&background=6366F1&color=fff',
                    ),
                  ),
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                      child: const Icon(Icons.verified_rounded, color: AppTheme.successColor, size: 14),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            tech.name,
                            style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textColor),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Row(
                          children: [
                            const Icon(Icons.star_rounded, color: Colors.orange, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              tech.rating.toStringAsFixed(1),
                              style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 14),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${tech.jobsDone}+ Jobs Completed',
                      style: GoogleFonts.outfit(color: AppTheme.subtitleColor, fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      children: tech.skills.take(3).map((s) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: AppTheme.accentColor, borderRadius: BorderRadius.circular(8)),
                        child: Text(s, style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.primaryColor)),
                      )).toList(),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    // View Profile
                  },
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 48),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  child: const Text('View Profile'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    if (service != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SlotSelectionScreen(
                            service: service!,
                            preSelectedTechId: tech.id,
                          ),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please select a service first'))
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(minimumSize: const Size(0, 48)),
                  child: const Text('Book Expert'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(color: AppTheme.accentColor, shape: BoxShape.circle),
            child: const Icon(Icons.engineering_rounded, size: 64, color: AppTheme.primaryColor),
          ),
          const SizedBox(height: 24),
          Text(
            'Professionals on their way',
            style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            'We are onboarding more experts for this service.',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(color: AppTheme.subtitleColor, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

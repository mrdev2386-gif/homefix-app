import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class CustomRequestStatusWidget extends StatelessWidget {
  const CustomRequestStatusWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox.shrink();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('custom_requests')
          .where('customerId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .limit(1)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox.shrink();
        }

        final data = snapshot.data!.docs.first.data() as Map<String, dynamic>;
        return _buildStatusCard(data);
      },
    );
  }

  Widget _buildStatusCard(Map<String, dynamic> data) {
    final title = data['title'] ?? 'Custom Request';
    final category = data['category'] ?? '';
    final description = data['description'] ?? '';
    final budget = data['budget'];
    final location = data['location'] ?? '';
    final status = data['status'] ?? 'submitted';
    final createdAt = data['createdAt'];
    final images = (data['images'] as List<dynamic>?)?.cast<String>() ?? [];

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 30,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildModernHeader(title, status),
          _buildModernContent(category, description, budget, location, createdAt, images),
          _buildModernTimeline(status),
        ],
      ),
    );
  }

  Widget _buildModernHeader(String title, String status) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                _buildModernStatusBadge(status),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: const Icon(
              Icons.assignment_outlined,
              color: Colors.white,
              size: 28,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernStatusBadge(String status) {
    final statusConfig = _getStatusConfig(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            statusConfig['label'],
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernContent(String category, String description, dynamic budget, String location, dynamic createdAt, List<String> images) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (category.isNotEmpty) _buildModernDetailRow(Icons.category_outlined, 'Category', category),
          if (description.isNotEmpty) _buildModernDetailRow(Icons.description_outlined, 'Description', description),
          if (budget != null) _buildModernDetailRow(Icons.currency_rupee, 'Budget', '₹${budget.toString()}'),
          if (location.isNotEmpty) _buildModernDetailRow(Icons.location_on_outlined, 'Location', location),
          _buildModernDetailRow(Icons.access_time, 'Created', _formatDate(createdAt)),
          if (images.isNotEmpty) ...[
            const SizedBox(height: 20),
            _buildModernImagePreview(images),
          ],
        ],
      ),
    );
  }

  Widget _buildModernDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF6B7280),
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1A1A1A),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernImagePreview(List<String> images) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.image_outlined, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 16),
            Text(
              'Images (${images.length})',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF6B7280),
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 90,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: images.length,
            itemBuilder: (context, index) {
              return Container(
                margin: const EdgeInsets.only(right: 16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    images[index],
                    width: 90,
                    height: 90,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.grey[200]!, Colors.grey[100]!],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.image_not_supported, color: Color(0xFF9CA3AF)),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildModernTimeline(String currentStatus) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFFF8F9FA), Colors.grey[50]!],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Request Timeline',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 20),
          _buildModernTimelineSteps(currentStatus),
        ],
      ),
    );
  }

  Widget _buildModernTimelineSteps(String currentStatus) {
    final steps = [
      {'key': 'submitted', 'label': 'Request Submitted', 'icon': Icons.send_outlined},
      {'key': 'admin_review', 'label': 'Admin Review', 'icon': Icons.admin_panel_settings_outlined},
      {'key': 'technician_assigned', 'label': 'Technician Assigned', 'icon': Icons.person_add_outlined},
      {'key': 'accepted', 'label': 'Technician Accepted', 'icon': Icons.check_circle_outline},
      {'key': 'in_progress', 'label': 'Service In Progress', 'icon': Icons.build_outlined},
      {'key': 'completed', 'label': 'Service Completed', 'icon': Icons.task_alt_outlined},
    ];

    return Column(
      children: steps.asMap().entries.map((entry) {
        final index = entry.key;
        final step = entry.value;
        final isCompleted = _isStepCompleted(step['key'] as String, currentStatus);
        final isLast = index == steps.length - 1;

        return Row(
          children: [
            Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: isCompleted ? const LinearGradient(
                      colors: [Color(0xFF10B981), Color(0xFF059669)],
                    ) : null,
                    color: isCompleted ? null : const Color(0xFFE5E7EB),
                    shape: BoxShape.circle,
                    boxShadow: isCompleted ? [
                      BoxShadow(
                        color: const Color(0xFF10B981).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ] : null,
                  ),
                  child: Icon(
                    step['icon'] as IconData,
                    color: isCompleted ? Colors.white : const Color(0xFF9CA3AF),
                    size: 18,
                  ),
                ),
                if (!isLast)
                  Container(
                    width: 3,
                    height: 40,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      gradient: isCompleted ? const LinearGradient(
                        colors: [Color(0xFF10B981), Color(0xFF059669)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ) : null,
                      color: isCompleted ? null : const Color(0xFFE5E7EB),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(bottom: isLast ? 0 : 40),
                child: Text(
                  step['label'] as String,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: isCompleted ? FontWeight.w700 : FontWeight.w500,
                    color: isCompleted ? const Color(0xFF10B981) : const Color(0xFF6B7280),
                  ),
                ),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  bool _isStepCompleted(String stepKey, String currentStatus) {
    final statusOrder = ['submitted', 'admin_review', 'technician_assigned', 'accepted', 'in_progress', 'completed'];
    final currentIndex = statusOrder.indexOf(currentStatus);
    final stepIndex = statusOrder.indexOf(stepKey);
    return stepIndex <= currentIndex;
  }

  Map<String, dynamic> _getStatusConfig(String status) {
    final configs = {
      'submitted': {'label': 'SUBMITTED', 'icon': Icons.send},
      'admin_review': {'label': 'UNDER REVIEW', 'icon': Icons.admin_panel_settings},
      'technician_assigned': {'label': 'ASSIGNED', 'icon': Icons.person_add},
      'accepted': {'label': 'ACCEPTED', 'icon': Icons.check_circle},
      'in_progress': {'label': 'IN PROGRESS', 'icon': Icons.build},
      'completed': {'label': 'COMPLETED', 'icon': Icons.task_alt},
    };
    return configs[status] ?? {'label': status.toUpperCase(), 'icon': Icons.info};
  }

  String _formatDate(dynamic createdAt) {
    try {
      if (createdAt is Timestamp) {
        return DateFormat('dd MMM yyyy, hh:mm a').format(createdAt.toDate());
      }
    } catch (_) {}
    return 'Recently';
  }
}
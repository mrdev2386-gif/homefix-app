import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';

class CustomRequestStatusWidget extends StatelessWidget {
  const CustomRequestStatusWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox.shrink();

    return StreamBuilder<QuerySnapshot>(\n      stream: FirebaseFirestore.instance
          .collection('custom_requests')
          .where('customerId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .limit(1)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()));
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox.shrink();
        }

        final doc = snapshot.data!.docs.first;
        final data = doc.data() as Map<String, dynamic>;
        return _buildStatusCard(context, doc.id, data);
      },
    );
  }

  Widget _buildStatusCard(BuildContext context, String docId, Map<String, dynamic> data) {
    final title = data['title'] ?? 'Custom Request';
    final category = data['category'] ?? '';
    final description = data['description'] ?? '';
    final budget = data['budget'];
    final status = data['status'] ?? 'submitted';
    final createdAt = data['createdAt'];
    final images = (data['images'] as List<dynamic>?)?.cast<String>() ?? [];

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Active Request',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      title,
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              _buildStatusBadge(status),
            ],
          ),
          const SizedBox(height: 16),
          if (category.isNotEmpty) _buildDetailRow(Icons.category, category),
          if (description.isNotEmpty) _buildDetailRow(Icons.description, description),
          if (budget != null) _buildDetailRow(Icons.currency_rupee, '₹${budget.toString()}'),
          _buildDetailRow(Icons.access_time, _formatDate(createdAt)),
          if (images.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: images.length,
                itemBuilder: (context, index) {
                  return Container(
                    margin: const EdgeInsets.only(right: 8),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        images[index],
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 80,
                          height: 80,
                          color: Colors.grey[200],
                          child: const Icon(Icons.image_not_supported),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
          const Divider(height: 32),
          Text(
            'Request Timeline',
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildTimeline(status),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => _deleteRequest(context, docId, images),
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            label: const Text('Delete Request', style: TextStyle(color: Colors.red)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final config = _getStatusConfig(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: config['color'].withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        config['label'],
        style: GoogleFonts.outfit(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: config['color'],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.outfit(fontSize: 14, color: Colors.grey[800]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline(String currentStatus) {
    final steps = [
      {'key': 'submitted', 'label': 'Request Submitted'},
      {'key': 'admin_review', 'label': 'Admin Review'},
      {'key': 'technician_assigned', 'label': 'Technician Assigned'},
      {'key': 'accepted', 'label': 'Technician Accepted'},
      {'key': 'in_progress', 'label': 'Service In Progress'},
      {'key': 'completed', 'label': 'Service Completed'},
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
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isCompleted ? Colors.green : Colors.grey[300],
                    shape: BoxShape.circle,
                  ),
                  child: isCompleted
                      ? const Icon(Icons.check, color: Colors.white, size: 16)
                      : null,
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 30,
                    color: isCompleted ? Colors.green : Colors.grey[300],
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(bottom: isLast ? 0 : 30),
                child: Text(
                  step['label'] as String,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: isCompleted ? FontWeight.w600 : FontWeight.normal,
                    color: isCompleted ? Colors.green : Colors.grey[600],
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
    return currentIndex >= 0 && stepIndex >= 0 && stepIndex <= currentIndex;
  }

  Map<String, dynamic> _getStatusConfig(String status) {
    final configs = {
      'submitted': {'label': 'SUBMITTED', 'color': Colors.blue},
      'admin_review': {'label': 'UNDER REVIEW', 'color': Colors.orange},
      'technician_assigned': {'label': 'ASSIGNED', 'color': Colors.purple},
      'accepted': {'label': 'ACCEPTED', 'color': Colors.green},
      'in_progress': {'label': 'IN PROGRESS', 'color': Colors.teal},
      'completed': {'label': 'COMPLETED', 'color': Colors.green},
    };
    return configs[status] ?? {'label': status.toUpperCase(), 'color': Colors.grey};
  }

  String _formatDate(dynamic createdAt) {
    try {
      if (createdAt is Timestamp) {
        return DateFormat('dd MMM yyyy, hh:mm a').format(createdAt.toDate());
      }
    } catch (_) {}
    return 'Recently';
  }

  Future<void> _deleteRequest(BuildContext context, String docId, List<String> images) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Request'),
        content: const Text('Are you sure you want to delete this request?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      // Delete images from storage
      for (final imageUrl in images) {
        try {
          await FirebaseStorage.instance.refFromURL(imageUrl).delete();
        } catch (e) {
          debugPrint('Failed to delete image: $e');
        }
      }

      // Delete document
      await FirebaseFirestore.instance.collection('custom_requests').doc(docId).delete();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Request deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete: $e')),
        );
      }
    }
  }
}

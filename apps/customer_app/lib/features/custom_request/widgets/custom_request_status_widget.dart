import 'package:flutter/material.dart';
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
          .where('userId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .limit(1)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          children: snapshot.data!.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return _buildRequestCard(data);
          }).toList(),
        );
      },
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> data) {
    final status = data['status'] as String? ?? 'pending_admin_review';
    final title = data['title'] as String? ?? 'Custom Request';
    final category = data['category'] as String? ?? 'Service';
    final description = data['description'] as String? ?? '';
    final location = data['location'] as String? ?? '';
    final budget = data['budget'] as dynamic;
    final images = (data['images'] as List<dynamic>?)?.cast<String>() ?? [];
    final createdAt = data['createdAt'];

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title and Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                _buildStatusBadge(status),
              ],
            ),
            const SizedBox(height: 16),
            
            // Request Details
            _buildDetailRow('Category', category, Icons.category),
            const SizedBox(height: 8),
            if (description.isNotEmpty) ...[_buildDetailRow('Description', description, Icons.description), const SizedBox(height: 8)],
            if (budget != null) ...[_buildDetailRow('Budget', '₹${budget.toString()}', Icons.currency_rupee), const SizedBox(height: 8)],
            if (location.isNotEmpty) ...[_buildDetailRow('Location', location, Icons.location_on), const SizedBox(height: 8)],
            _buildDetailRow('Created', _formatDate(createdAt), Icons.access_time),
            
            // Images Preview
            if (images.isNotEmpty) ...[const SizedBox(height: 12), _buildImagePreview(images)],
            
            // Tracking Timeline
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            Text(
              'Request Timeline',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            _buildTrackingTimeline(status),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildImagePreview(List<String> images) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Images (${images.length})',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 70,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: images.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    images[index],
                    width: 70,
                    height: 70,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 70,
                      height: 70,
                      color: Colors.grey[300],
                      child: const Icon(Icons.image_not_supported),
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

  Widget _buildTrackingTimeline(String status) {
    final steps = [
      {'label': 'Request Submitted', 'key': 'submitted'},
      {'label': 'Admin Review', 'key': 'admin_review'},
      {'label': 'Technician Assigned', 'key': 'technician_assigned'},
      {'label': 'Technician Accepted', 'key': 'accepted'},
      {'label': 'Service In Progress', 'key': 'in_progress'},
      {'label': 'Service Completed', 'key': 'completed'},
    ];

    return Column(
      children: steps.map((step) {
        final isCompleted = _isStepCompleted(step['key']!, status);
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _buildTrackingStep(step['label']!, isCompleted),
        );
      }).toList(),
    );
  }

  bool _isStepCompleted(String stepKey, String currentStatus) {
    switch (stepKey) {
      case 'submitted':
        return true; // Always completed
      case 'admin_review':
        return !['pending_admin_review', 'rejected'].contains(currentStatus);
      case 'technician_assigned':
        return ['technician_assigned', 'accepted', 'in_progress', 'completed'].contains(currentStatus);
      case 'accepted':
        return ['accepted', 'in_progress', 'completed'].contains(currentStatus);
      case 'in_progress':
        return ['in_progress', 'completed'].contains(currentStatus);
      case 'completed':
        return currentStatus == 'completed';
      default:
        return false;
    }
  }

  Widget _buildTrackingStep(String label, bool completed) {
    return Row(
      children: [
        Icon(
          completed ? Icons.check_circle : Icons.radio_button_unchecked,
          color: completed ? Colors.green : Colors.grey,
          size: 18,
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: completed ? FontWeight.w600 : FontWeight.w400,
            color: completed ? Colors.green[700] : Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    final colors = {
      'pending_admin_review': Colors.orange,
      'approved': Colors.blue,
      'technician_assigned': Colors.purple,
      'accepted': Colors.green,
      'in_progress': Colors.teal,
      'completed': Colors.teal,
      'rejected': Colors.red,
    };
    final displayTexts = {
      'pending_admin_review': 'PENDING',
      'approved': 'APPROVED',
      'technician_assigned': 'ASSIGNED',
      'accepted': 'ACCEPTED',
      'in_progress': 'IN PROGRESS',
      'completed': 'COMPLETED',
      'rejected': 'REJECTED',
    };

    final color = colors[status] ?? Colors.grey;
    final displayText = displayTexts[status] ?? status.toUpperCase();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        displayText,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  String _formatDate(dynamic createdAt) {
    try {
      if (createdAt is Timestamp) {
        return DateFormat('dd MMM yyyy').format(createdAt.toDate());
      } else if (createdAt is String) {
        final parsed = DateTime.tryParse(createdAt);
        if (parsed != null) {
          return DateFormat('dd MMM yyyy').format(parsed);
        }
      }
    } catch (_) {}
    return 'Recently';
  }
}

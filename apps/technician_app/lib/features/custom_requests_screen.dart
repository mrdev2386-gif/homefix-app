import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:provider/provider.dart';
import 'package:technician_app/core/services/auth_service.dart';
import 'package:technician_app/core/theme/app_theme.dart';
import 'package:technician_app/core/firebase/firebase_functions.dart';

class CustomRequestsScreen extends StatefulWidget {
  const CustomRequestsScreen({super.key});

  @override
  State<CustomRequestsScreen> createState() => _CustomRequestsScreenState();
}

class _CustomRequestsScreenState extends State<CustomRequestsScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseFunctions _functions = FirebaseFunctionsService.instance;

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final technicianId = auth.currentUser?.uid;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Custom Service Requests',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _db
            .collection('custom_requests')
            .where('technicianId', isEqualTo: technicianId)
            .where('status', whereIn: ['technician_assigned', 'accepted'])
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text('No requests assigned', style: GoogleFonts.outfit(fontSize: 16, color: Colors.grey[600])),
                ],
              ),
            );
          }

          final requests = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final request = requests[index].data() as Map<String, dynamic>;
              final requestId = requests[index].id;

              return _buildRequestCard(context, requestId, request);
            },
          );
        },
      ),
    );
  }

  Widget _buildRequestCard(BuildContext context, String requestId, Map<String, dynamic> request) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              request['title'] ?? 'Custom Request',
              style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              request['description'] ?? '',
              style: GoogleFonts.outfit(color: Colors.grey[600], fontSize: 13),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.category, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(request['category'] ?? '', style: GoogleFonts.outfit(fontSize: 12)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text('${request['preferredDate']} at ${request['preferredTime']}', style: GoogleFonts.outfit(fontSize: 12)),
              ],
            ),
            if (request['budget'] != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.currency_rupee, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text('Budget: ₹${request['budget']}', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600)),
                ],
              ),
            ],
            if ((request['images'] as List?)?.isNotEmpty ?? false) ...[
              const SizedBox(height: 12),
              SizedBox(
                height: 80,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: (request['images'] as List).length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          request['images'][index],
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _declineRequest(requestId),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('Decline', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _acceptRequest(requestId),
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('Accept', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _acceptRequest(String requestId) async {
    try {
      final callable = _functions.httpsCallable('acceptCustomRequest');
      await callable.call({'requestId': requestId});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Request accepted! Booking created.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _declineRequest(String requestId) async {
    try {
      final callable = _functions.httpsCallable('rejectCustomRequest');
      await callable.call({'requestId': requestId});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Request declined')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }
}

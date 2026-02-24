import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/providers/technician_provider.dart';
import '../../core/models/custom_request.dart';
import '../../core/services/functions_service.dart';

class CustomRequestDetailScreen extends StatefulWidget {
  final String requestId;

  const CustomRequestDetailScreen({super.key, required this.requestId});

  @override
  State<CustomRequestDetailScreen> createState() => _CustomRequestDetailScreenState();
}

class _CustomRequestDetailScreenState extends State<CustomRequestDetailScreen> {
  CustomRequest? _request;
  bool _isLoading = true;
  bool _isAccepting = false;
  final FunctionsService _functionsService = FunctionsService();

  @override
  void initState() {
    super.initState();
    _fetchRequestDetails();
  }

  Future<void> _fetchRequestDetails() async {
    try {
      final result = await _functionsService.getCustomRequestDetail(widget.requestId);
      
      if (mounted) {
        setState(() {
          _request = CustomRequest.fromMap(
            result['request'] as Map<String, dynamic>,
            documentId: widget.requestId,
          );
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching request details: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading request: $e')),
        );
      }
    }
  }

  Future<void> _acceptRequest() async {
    final techProvider = Provider.of<TechnicianProvider>(context, listen: false);
    if (techProvider.technician == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete your profile first')),
      );
      return;
    }

    setState(() {
      _isAccepting = true;
    });

    try {
      final result = await _functionsService.technicianRespondServiceRequest(widget.requestId, 'accept');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Request accepted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isAccepting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Request Details')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_request == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Request Details')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 60, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                'Request not found',
                style: GoogleFonts.poppins(fontSize: 18),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    final request = _request!;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Request Details',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderCard(request),
            const SizedBox(height: 12),
            _buildDescriptionCard(request),
            if (request.imageUrls.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildImagesCard(request),
            ],
            const SizedBox(height: 12),
            _buildScheduleCard(request),
            const SizedBox(height: 12),
            _buildLocationCard(request),
            const SizedBox(height: 12),
            _buildCustomerCard(request),
            const SizedBox(height: 120), // Space for bottom buttons
          ],
        ),
      ),
      bottomSheet: _buildBottomActions(request),
    );
  }

  Widget _buildHeaderCard(CustomRequest request) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: request.urgency.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: request.urgency.color, width: 1),
                  ),
                  child: Text(
                    request.urgency.displayName.toUpperCase(),
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: request.urgency.color,
                    ),
                  ),
                ),
                const Spacer(),
                Chip(
                  label: Text(
                    request.categoryName ?? 'General',
                    style: GoogleFonts.poppins(fontSize: 12),
                  ),
                  backgroundColor: Colors.grey[200],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              request.title,
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            if (request.budgetMin != null || request.budgetMax != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF2E7D32).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Budget: ${_formatBudget(request.budgetMin, request.budgetMax)}',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF2E7D32),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDescriptionCard(CustomRequest request) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.description, color: Colors.grey[600], size: 20),
                const SizedBox(width: 8),
                Text(
                  'Description',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              request.description,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.black87,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagesCard(CustomRequest request) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.photo_library, color: Colors.grey[600], size: 20),
                const SizedBox(width: 8),
                Text(
                  'Photos (${request.imageUrls.length})',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: request.imageUrls.length,
                itemBuilder: (context, index) {
                  return Container(
                    margin: const EdgeInsets.only(right: 8),
                    width: 120,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      image: DecorationImage(
                        image: CachedNetworkImageProvider(request.imageUrls[index]),
                        fit: BoxFit.cover,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleCard(CustomRequest request) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.calendar_today, color: Colors.grey[600], size: 20),
                const SizedBox(width: 8),
                Text(
                  'Preferred Schedule',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildInfoTile(
                    icon: Icons.event,
                    label: 'Date',
                    value: request.preferredDate,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildInfoTile(
                    icon: Icons.access_time,
                    label: 'Time Slot',
                    value: request.preferredTime,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationCard(CustomRequest request) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.location_on, color: Colors.grey[600], size: 20),
                const SizedBox(width: 8),
                Text(
                  'Service Location',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_on, color: Color(0xFF2E7D32)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (request.address.label != null)
                          Text(
                            request.address.label!,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700],
                            ),
                          ),
                        Text(
                          request.address.address,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                        if (request.address.city != null)
                          Text(
                            request.address.city!,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerCard(CustomRequest request) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person, color: Colors.grey[600], size: 20),
                const SizedBox(width: 8),
                Text(
                  'Customer',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person, color: Colors.grey),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.customerName,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (request.customerPhone.isNotEmpty)
                      Text(
                        request.customerPhone,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions(CustomRequest request) {
    if (request.status != RequestStatus.pending && request.status.value != 'technician_pending') {
      return const SizedBox.shrink(); // Hide if already accepted/rejected/booked
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _isAccepting ? null : () => _respondToRequest('reject'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Reject',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: _isAccepting ? null : () => _respondToRequest('accept'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isAccepting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        'Accept Request',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _respondToRequest(String action) async {
    final techProvider = Provider.of<TechnicianProvider>(context, listen: false);
    if (techProvider.technician == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete your profile first')),
      );
      return;
    }

    setState(() {
      _isAccepting = true;
    });

    try {
      String? reason;
      if (action == 'reject') {
        reason = 'Technician declined the request';
      }

      final result = await _functionsService.technicianRespondServiceRequest(widget.requestId, action, reason: reason);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Successfully updated request.'),
            backgroundColor: action == 'accept' ? Colors.green : Colors.orange,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isAccepting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatBudget(double? min, double? max) {
    if (min == null && max == null) return 'Not specified';
    if (min != null && max == null) return '₹${min.round()}+';
    if (min == null && max != null) return 'Up to ₹${max.round()}';
    return '₹${min.round()} - ₹${max.round()}';
  }
}

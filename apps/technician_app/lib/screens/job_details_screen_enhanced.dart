import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:technician_app/core/models/booking.dart';
import 'package:technician_app/core/services/functions_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shimmer/shimmer.dart';

class JobDetailsScreenEnhanced extends StatefulWidget {
  final String bookingId;

  const JobDetailsScreenEnhanced({super.key, required this.bookingId});

  @override
  State<JobDetailsScreenEnhanced> createState() => _JobDetailsScreenEnhancedState();
}

class _JobDetailsScreenEnhancedState extends State<JobDetailsScreenEnhanced> {
  final FunctionsService _functionsService = FunctionsService();
  bool _isProcessing = false;
  final TextEditingController _otpController = TextEditingController();

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _updateStatus(String newStatus, {String? otp}) async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      await _functionsService.updateBookingStatus(widget.bookingId, newStatus, otp: otp);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Status updated to ${newStatus.replaceAll('_', ' ')}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _reportIssue(String reason) async {
    try {
      await _functionsService.reportBookingIssue(widget.bookingId, reason);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Issue reported successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showOtpDialog(String nextStatus) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                'Verify OTP',
                style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: InputDecoration(
                labelText: 'Enter OTP',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _updateStatus(nextStatus, otp: _otpController.text);
                  _otpController.clear();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text('Verify', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showIssueDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                'Report Issue',
                style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 16),
            Flexible(child: _issueOption('Customer not reachable')),
            Flexible(child: _issueOption('Customer asked to reschedule')),
            Flexible(child: _issueOption('Wrong address')),
            Flexible(child: _issueOption('Other')),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _issueOption(String reason) {
    return ListTile(
      title: Text(reason, style: GoogleFonts.plusJakartaSans()),
      onTap: () => _reportIssue(reason),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('bookings').doc(widget.bookingId).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final booking = Booking.fromFirestore(snapshot.data!);

          return SafeArea(
            child: Column(
              children: [
                _buildAppBar(),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      await Future.delayed(const Duration(seconds: 1));
                    },
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.only(bottom: 100),
                      child: Column(
                        children: [
                          _buildStatusHeader(booking),
                          const SizedBox(height: 16),
                          _buildCustomerCard(booking),
                          const SizedBox(height: 16),
                          _buildServiceDetails(booking),
                          const SizedBox(height: 16),
                          _buildEarningsSummary(booking),
                          const SizedBox(height: 16),
                          _buildTimeline(booking),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                ),
                _buildActionButtons(booking),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back),
          ),
          Text(
            'Job Details',
            style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          IconButton(
            onPressed: _showIssueDialog,
            icon: const Icon(Icons.report_problem_outlined),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusHeader(Booking booking) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Job #${booking.bookingId.substring(0, 8)}',
                style: GoogleFonts.plusJakartaSans(fontSize: 14, color: const Color(0xFF64748B)),
              ),
              _buildStatusChip(booking.status),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            booking.serviceTitle,
            style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.calendar_today, size: 16, color: Color(0xFF64748B)),
              const SizedBox(width: 6),
              Text(
                booking.scheduledTime,
                style: GoogleFonts.plusJakartaSans(fontSize: 14, color: const Color(0xFF64748B)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'pending':
        color = const Color(0xFFF59E0B);
        break;
      case 'confirmed':
        color = const Color(0xFF6366F1);
        break;
      case 'on_the_way':
        color = const Color(0xFF8B5CF6);
        break;
      case 'in_progress':
      case 'started':
        color = const Color(0xFF10B981);
        break;
      case 'completed':
        color = const Color(0xFF64748B);
        break;
      case 'cancelled':
        color = const Color(0xFFEF4444);
        break;
      default:
        color = const Color(0xFF64748B);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.toUpperCase().replaceAll('_', ' '),
        style: GoogleFonts.plusJakartaSans(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildCustomerCard(Booking booking) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
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
          Text(
            'Customer Information',
            style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.person, color: Color(0xFF6366F1), size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking.customerName,
                      style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      booking.addressSnapshot['fullAddress'] ?? 'Address not available',
                      style: GoogleFonts.plusJakartaSans(fontSize: 13, color: const Color(0xFF64748B)),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final phone = booking.addressSnapshot['phone'] ?? '';
                    if (phone.isNotEmpty) {
                      final uri = Uri.parse('tel:$phone');
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri);
                      }
                    }
                  },
                  icon: const Icon(Icons.call, size: 18),
                  label: const Text('Call'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF6366F1),
                    side: const BorderSide(color: Color(0xFF6366F1)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final address = booking.addressSnapshot['fullAddress'] ?? '';
                    if (address.isNotEmpty) {
                      final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}');
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      }
                    }
                  },
                  icon: const Icon(Icons.navigation, size: 18),
                  label: const Text('Navigate'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildServiceDetails(Booking booking) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
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
          Text(
            'Service Details',
            style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildDetailRow('Service', booking.serviceTitle),
          if (booking.problemDescription != null && booking.problemDescription!.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildDetailRow('Description', booking.problemDescription!),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: GoogleFonts.plusJakartaSans(fontSize: 14, color: const Color(0xFF64748B)),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  Widget _buildEarningsSummary(Booking booking) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withOpacity(0.2),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Earnings Summary',
            style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 16),
          _buildEarningRow('Service Price', '₹${booking.price.toStringAsFixed(0)}'),
          const SizedBox(height: 8),
          _buildEarningRow('Platform Fee', '₹${(booking.price - booking.finalAmount).toStringAsFixed(0)}'),
          const Divider(color: Colors.white24, height: 24),
          _buildEarningRow('Your Earning', '₹${booking.finalAmount.toStringAsFixed(0)}', isBold: true),
        ],
      ),
    );
  }

  Widget _buildEarningRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            color: Colors.white70,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: isBold ? 20 : 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildTimeline(Booking booking) {
    final steps = [
      {'label': 'Booking Created', 'status': 'pending', 'completed': true},
      {'label': 'Accepted', 'status': 'confirmed', 'completed': booking.status != 'pending'},
      if (booking.status == 'on_the_way' || booking.status == 'in_progress' || booking.status == 'completed')
        {'label': 'On The Way', 'status': 'on_the_way', 'completed': booking.status != 'confirmed'},
      {'label': 'Job Started', 'status': 'in_progress', 'completed': booking.status == 'in_progress' || booking.status == 'completed'},
      {'label': 'Job Completed', 'status': 'completed', 'completed': booking.status == 'completed'},
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
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
          Text(
            'Job Timeline',
            style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ...steps.asMap().entries.map((entry) {
            final index = entry.key;
            final step = entry.value;
            final isLast = index == steps.length - 1;
            return _buildTimelineStep(
              step['label'] as String,
              step['completed'] as bool,
              isLast,
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildTimelineStep(String label, bool completed, bool isLast) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: completed ? const Color(0xFF10B981) : const Color(0xFFE2E8F0),
                shape: BoxShape.circle,
              ),
              child: completed
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color: completed ? const Color(0xFF10B981) : const Color(0xFFE2E8F0),
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: completed ? FontWeight.w600 : FontWeight.normal,
                color: completed ? const Color(0xFF0F172A) : const Color(0xFF64748B),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(Booking booking) {
    if (booking.status == 'completed' || booking.status == 'cancelled') {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: _buildButtonsForStatus(booking.status),
      ),
    );
  }

  Widget _buildButtonsForStatus(String status) {
    if (status == 'pending') {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _isProcessing ? null : () => _updateStatus('cancelled'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFEF4444),
                side: const BorderSide(color: Color(0xFFEF4444)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: _isProcessing
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Reject'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _isProcessing ? null : () => _updateStatus('confirmed'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 0,
              ),
              child: _isProcessing
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Accept Job'),
            ),
          ),
        ],
      );
    } else if (status == 'confirmed' || status == 'on_the_way') {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _isProcessing ? null : () => _showOtpDialog('in_progress'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF10B981),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(vertical: 14),
            elevation: 0,
          ),
          child: _isProcessing
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Start Job'),
        ),
      );
    } else if (status == 'in_progress' || status == 'started') {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _isProcessing ? null : () => _showOtpDialog('completed'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6366F1),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(vertical: 14),
            elevation: 0,
          ),
          child: _isProcessing
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Complete Job'),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}

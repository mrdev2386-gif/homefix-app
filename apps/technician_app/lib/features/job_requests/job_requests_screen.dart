import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/services/booking_service.dart';
import '../../core/models/booking.dart';
import '../../core/providers/technician_provider.dart';
import '../../core/widgets/safe_network_image.dart';
import 'package:shimmer/shimmer.dart';

class JobRequestsScreen extends StatefulWidget {
  const JobRequestsScreen({super.key});

  @override
  State<JobRequestsScreen> createState() => _JobRequestsScreenState();
}

class _JobRequestsScreenState extends State<JobRequestsScreen> {
  final BookingService _bookingService = BookingService();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TechnicianProvider>(context);
    final tech = provider.technician;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          "Job Assignments",
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.tune_rounded),
          ),
        ],
      ),
      body: tech == null
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<List<Booking>>(
              stream: _bookingService.getPendingBookings(tech.uid),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Text('Error loading requests: ${snapshot.error}', textAlign: TextAlign.center),
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    itemCount: 3,
                    itemBuilder: (context, index) => _buildSkeletonCard(),
                  );
                }

                final bookings = snapshot.data ?? [];

                // DEBUG: Log booking data to identify field structure
                if (bookings.isNotEmpty) {
                  debugPrint('=== JOB REQUESTS DEBUG ===');
                  debugPrint('Total bookings received: ${bookings.length}');
                  for (var i = 0; i < bookings.length && i < 3; i++) {
                    final b = bookings[i];
                    debugPrint('--- Booking ${i + 1} ---');
                    debugPrint('ID: ${b.bookingId}');
                    debugPrint('Service: ${b.serviceTitle}');
                    debugPrint('Image: ${b.serviceImage ?? "NULL"}');
                    debugPrint('Address fields: ${b.addressSnapshot.keys.toList()}');
                    debugPrint('Address data: ${b.addressSnapshot}');
                    debugPrint('Status: ${b.status}');
                  }
                  debugPrint('=========================');
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    // Just wait a moment since Stream is real-time
                    await Future.delayed(const Duration(milliseconds: 500));
                  },
                  child: bookings.isEmpty
                      ? Stack(
                          children: [
                            ListView(), // Empty list view to allow Pull-to-refresh
                            _buildEmptyState(),
                          ],
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          physics: const AlwaysScrollableScrollPhysics(
                            parent: BouncingScrollPhysics(),
                          ),
                          itemCount: bookings.length,
                          itemBuilder: (context, index) {
                            return _buildCompactJobCard(bookings[index], tech);
                          },
                        ),
                );
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: const Color(0xFFEEF2FF),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.inbox_outlined, size: 48, color: Color(0xFF6366F1)),
            ),
            const SizedBox(height: 24),
            Text(
              "No new job requests",
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "New jobs will appear here once an administrator assigns them to you.",
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                color: const Color(0xFF64748B),
                fontSize: 15,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactJobCard(Booking b, dynamic tech) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showJobDetails(b, tech),
          borderRadius: BorderRadius.circular(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Section: Image + Service Info
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [const Color(0xFF6366F1).withOpacity(0.08), Colors.white],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Service Image Thumbnail
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SafeNetworkImage(
                        imageUrl: b.serviceImage,
                        height: 80,
                        width: 80,
                        borderRadius: 0,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            b.serviceTitle,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF111827),
                              height: 1.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              "₹${b.finalAmount.toInt()}",
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Middle Section: Details
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.access_time_rounded, size: 14, color: Color(0xFFD97706)),
                          const SizedBox(width: 4),
                          Text(
                            "New Job Request",
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFFD97706),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Date & Time
                    _buildCompactInfoRow(
                      icon: Icons.calendar_today_rounded,
                      iconColor: const Color(0xFF10B981),
                      value: DateFormat('MMM dd, yyyy • hh:mm a').format(b.scheduledAt),
                    ),
                    const SizedBox(height: 10),
                    
                    // Address (2 lines max)
                    _buildCompactInfoRow(
                      icon: Icons.location_on_rounded,
                      iconColor: const Color(0xFFEF4444),
                      value: _getCompactAddress(b.addressSnapshot),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),
                    
                    // Divider
                    Container(
                      height: 1,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            Color(0xFFE5E7EB),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _isLoading ? null : () => _showConfirmationDialog(
                              b.bookingId,
                              'reject',
                            ),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(0, 44),
                              foregroundColor: const Color(0xFFEF4444),
                              side: BorderSide(
                                color: _isLoading ? const Color(0xFFE2E8F0) : const Color(0xFFEF4444),
                                width: 1.5,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 16,
                                    width: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF94A3B8)),
                                    ),
                                  )
                                : Text(
                                    "Decline",
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : () => _showConfirmationDialog(
                              b.bookingId,
                              'accept',
                            ),
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(0, 44),
                              backgroundColor: _isLoading ? const Color(0xFFE2E8F0) : const Color(0xFF6366F1),
                              disabledBackgroundColor: const Color(0xFFE2E8F0),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isLoading
                                ? Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const SizedBox(
                                        height: 16,
                                        width: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        "Processing...",
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFF64748B),
                                        ),
                                      ),
                                    ],
                                  )
                                : Text(
                                    "Accept Job",
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
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

  Widget _buildCompactInfoRow({
    required IconData icon,
    required Color iconColor,
    required String value,
    int maxLines = 1,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 16,
            color: iconColor,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF374151),
            ),
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  String _getCompactAddress(Map<String, dynamic> addressSnapshot) {
    final parts = <String>[];
    
    if (addressSnapshot['street'] != null && addressSnapshot['street'].toString().isNotEmpty) {
      parts.add(addressSnapshot['street'].toString());
    }
    if (addressSnapshot['area'] != null && addressSnapshot['area'].toString().isNotEmpty) {
      parts.add(addressSnapshot['area'].toString());
    }
    if (addressSnapshot['city'] != null && addressSnapshot['city'].toString().isNotEmpty) {
      parts.add(addressSnapshot['city'].toString());
    }
    
    return parts.isNotEmpty ? parts.join(', ') : 'Address not available';
  }

  void _showJobDetails(Booking b, dynamic tech) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Color(0xFFF8FAFC),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  children: [
                    Text(
                      "Job Details",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0xFFF1F5F9),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFullScreenJobCard(b, tech),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFullScreenJobCard(Booking b, dynamic tech) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero Section with Service Image
          Container(
            width: double.infinity,
            height: 240,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: SafeNetworkImage(
                    imageUrl: b.serviceImage,
                    height: 240,
                    width: double.infinity,
                    borderRadius: 0,
                  ),
                ),
                // Gradient overlay
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.7),
                      ],
                    ),
                  ),
                ),
                // Date badge
                Positioned(
                  top: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.calendar_today_rounded, size: 16, color: Color(0xFF6366F1)),
                        const SizedBox(width: 6),
                        Text(
                          DateFormat('MMM dd, yyyy').format(b.scheduledAt),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Service name and price
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        b.serviceTitle,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              "₹${b.finalAmount.toInt()}",
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "Estimated Earning",
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              color: Colors.white.withOpacity(0.9),
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
          const SizedBox(height: 20),
          
          // Status Label
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.access_time_rounded, size: 16, color: Color(0xFFD97706)),
                const SizedBox(width: 6),
                Text(
                  "Waiting for your response",
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFD97706),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // Full Address Section
          _buildInfoCard(
            title: "SERVICE LOCATION",
            icon: Icons.location_on_rounded,
            iconColor: const Color(0xFFEF4444),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getFullAddress(b.addressSnapshot),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    color: const Color(0xFF0F172A),
                    height: 1.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (b.addressSnapshot['landmark'] != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.place_outlined, size: 14, color: Color(0xFF64748B)),
                      const SizedBox(width: 4),
                      Text(
                        "Landmark: ${b.addressSnapshot['landmark']}",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // Customer Details Section
          _buildInfoCard(
            title: "CUSTOMER DETAILS",
            icon: Icons.person_rounded,
            iconColor: const Color(0xFF6366F1),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  b.customerName,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () => _makePhoneCall(b.addressSnapshot['phone'] ?? ''),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF10B981)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.phone, size: 18, color: Color(0xFF10B981)),
                        const SizedBox(width: 8),
                        Text(
                          b.addressSnapshot['phone']?.toString() ?? 'No phone',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF10B981),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // Job Info Section
          _buildInfoCard(
            title: "JOB INFORMATION",
            icon: Icons.info_outline_rounded,
            iconColor: const Color(0xFF8B5CF6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow("Scheduled Time", b.scheduledTime),
                const SizedBox(height: 12),
                _buildInfoRow(
                  "Payment Type",
                  b.paymentMode == 'pay_before_work' ? 'Online Payment' : 'Cash on Service',
                ),
                if (b.problemDescription != null) ...[
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 12),
                  Text(
                    "CUSTOMER INSTRUCTIONS",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF94A3B8),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    b.problemDescription!,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      color: const Color(0xFF475569),
                      height: 1.6,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 18, color: iconColor),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF94A3B8),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            color: const Color(0xFF64748B),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }

  String _getFullAddress(Map<String, dynamic> addressSnapshot) {
    final parts = <String>[];
    
    if (addressSnapshot['street'] != null && addressSnapshot['street'].toString().isNotEmpty) {
      parts.add(addressSnapshot['street'].toString());
    }
    if (addressSnapshot['area'] != null && addressSnapshot['area'].toString().isNotEmpty) {
      parts.add(addressSnapshot['area'].toString());
    }
    if (addressSnapshot['city'] != null && addressSnapshot['city'].toString().isNotEmpty) {
      parts.add(addressSnapshot['city'].toString());
    }
    if (addressSnapshot['pincode'] != null && addressSnapshot['pincode'].toString().isNotEmpty) {
      parts.add(addressSnapshot['pincode'].toString());
    }
    
    return parts.isNotEmpty ? parts.join(', ') : 'Address not available';
  }

  void _makePhoneCall(String phoneNumber) async {
    if (phoneNumber.isEmpty) return;
    final uri = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _showConfirmationDialog(String bookingId, String action) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: action == 'accept' 
                      ? const Color(0xFFEEF2FF) 
                      : const Color(0xFFFEE2E2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  action == 'accept' ? Icons.check_circle_outline : Icons.cancel_outlined,
                  size: 48,
                  color: action == 'accept' 
                      ? const Color(0xFF6366F1) 
                      : const Color(0xFFEF4444),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                action == 'accept' ? "Accept this job?" : "Decline this job?",
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                action == 'accept'
                    ? "You will be assigned to this job and the customer will be notified."
                    : "This job will be reassigned to another technician.",
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: const Color(0xFF64748B),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 48),
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        "Cancel",
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _handleAction(bookingId, action);
                      },
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(0, 48),
                        backgroundColor: action == 'accept' 
                            ? const Color(0xFF6366F1) 
                            : const Color(0xFFEF4444),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        action == 'accept' ? "Yes, Accept" : "Yes, Decline",
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleAction(String bookingId, String action) async {
    if (!mounted) return;
    
    // Set loading state and disable buttons
    setState(() {
      _isLoading = true;
    });
    
    try {
      if (action == 'accept') {
        await _bookingService.acceptBooking(bookingId);
      } else {
        await _bookingService.rejectBooking(bookingId);
      }
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        // Clear any existing snackbars before showing new one
        ScaffoldMessenger.of(context).clearSnackBars();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  action == 'accept' ? Icons.check_circle : Icons.info_outline,
                  color: Colors.white,
                ),
                const SizedBox(width: 12),
                Text(
                  action == 'accept' 
                      ? "Job accepted successfully" 
                      : "Job declined",
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            backgroundColor: action == 'accept' 
                ? const Color(0xFF10B981) 
                : const Color(0xFFF59E0B),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
        
        // Stream will auto-update UI when Firestore changes
        // No manual refresh needed - real-time listener handles it
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        // Clear any existing snackbars before showing error
        ScaffoldMessenger.of(context).clearSnackBars();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Failed to ${action} job. Please try again.",
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () => _showConfirmationDialog(bookingId, action),
            ),
          ),
        );
      }
    }
  }

  Widget _buildSkeletonCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.grey.shade100),
      ),
      padding: const EdgeInsets.all(20),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[200]!,
        highlightColor: Colors.grey[100]!,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(width: 64, height: 64, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18))),
                const SizedBox(width: 16),
                Flexible(
                  fit: FlexFit.loose,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(width: 80, height: 12, color: Colors.white),
                      const SizedBox(height: 8),
                      Container(width: 120, height: 24, color: Colors.white),
                    ],
                  ),
                ),
                Container(width: 60, height: 24, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10))),
              ],
            ),
            const SizedBox(height: 20),
            Container(width: 200, height: 20, color: Colors.white),
            const SizedBox(height: 12),
            Container(width: double.infinity, height: 14, color: Colors.white),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(child: Container(height: 52, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)))),
                const SizedBox(width: 12),
                Expanded(child: Container(height: 52, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}


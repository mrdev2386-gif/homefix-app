import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:customer_app/core/services/auth_service.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/models/booking.dart';
import '../../../core/utils/booking_status_utils.dart';
import '../widgets/booking_card.dart';
import '../widgets/booking_shimmer.dart';
import '../widgets/status_filter_chips.dart';
import 'booking_detail_screen.dart';

class BookingHistoryScreen extends StatefulWidget {
  final VoidCallback? onNavigateToHome;
  
  const BookingHistoryScreen({super.key, this.onNavigateToHome});

  @override
  State<BookingHistoryScreen> createState() => _BookingHistoryScreenState();
}

class _BookingHistoryScreenState extends State<BookingHistoryScreen> {
  String _selectedStatus = 'all';
  bool _isInitialLoad = true;

  @override
  void initState() {
    super.initState();
    // FIX: Add timeout to prevent infinite loading
    _startLoadingTimeout();
  }
  
  /// Timeout mechanism - if no data after 10 seconds, stop showing loading
  Future<void> _startLoadingTimeout() async {
    await Future.delayed(const Duration(seconds: 10));
    if (mounted && _isInitialLoad) {
      debugPrint('[BOOKING_STREAM] ⏱️ Loading timeout reached, stopping shimmer');
      setState(() => _isInitialLoad = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    final user = authService.currentUser;

    if (user == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8F9FE),
        appBar: AppBar(
          title: Text(
            'My Bookings',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
        body: _buildGuestEmptyState(),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            title: Text(
              'My Bookings',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            elevation: 0,
            pinned: true,
            floating: true,
            snap: true,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(65),
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                child: StatusFilterChips(
                  selectedStatus: _selectedStatus,
                  onStatusChanged: (status) {
                    setState(() {
                      _selectedStatus = status;
                    });
                  },
                ),
              ),
            ),
          ),
        ],
        body: StreamBuilder<List<Booking>>(
          stream: firestoreService.streamBookings(user.uid),
          builder: (context, snapshot) {
            // Mark initial load complete after first data arrives
            if (snapshot.hasData && _isInitialLoad) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  setState(() => _isInitialLoad = false);
                }
              });
            }
            
            debugPrint('[BOOKING_STREAM] Connection: ${snapshot.connectionState}, hasError: ${snapshot.hasError}');
            
            // Initial loading state with shimmer
            if (snapshot.connectionState == ConnectionState.waiting && _isInitialLoad) {
              return const BookingListShimmer(itemCount: 5);
            }

            // Error state with retry
            if (snapshot.hasError) {
              debugPrint('[BOOKING_STREAM] Error: ${snapshot.error}');
              return _buildErrorState(snapshot.error.toString());
            }

            final allBookings = snapshot.data ?? [];
            debugPrint('[BOOKING_STREAM] Loaded: ${allBookings.length} bookings');
            
            // Filter bookings by status
            final filteredBookings = _selectedStatus == 'all'
                ? allBookings
                : allBookings.where((b) => sanitizeBookingStatus(b.status) == _selectedStatus).toList();

            // Empty state
            if (filteredBookings.isEmpty) {
              return _buildEmptyState();
            }

            return RefreshIndicator(
              onRefresh: () async {
                // Stream will auto-refresh - just add small delay for UX
                await Future.delayed(const Duration(milliseconds: 500));
              },
              color: const Color(0xFF4A6CF7),
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                itemCount: filteredBookings.length,
                itemBuilder: (context, index) {
                  final booking = filteredBookings[index];
                  return BookingCard(
                    booking: booking,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BookingDetailScreen(booking: booking),
                        ),
                      );
                    },
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildGuestEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF4A6CF7).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.login_rounded,
                size: 64,
                color: Color(0xFF4A6CF7),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Please login to view bookings',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Sign in to track your service bookings',
              style: GoogleFonts.outfit(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.receipt_long_outlined,
                size: 64,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _selectedStatus == 'all' 
                  ? 'No bookings yet'
                  : 'No $_selectedStatus bookings',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _selectedStatus == 'all'
                  ? 'Book a service and track it here'
                  : 'Your $_selectedStatus bookings will appear here',
              style: GoogleFonts.outfit(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            if (_selectedStatus == 'all') ...[
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () {
                  widget.onNavigateToHome?.call();
                },
                icon: const Icon(Icons.add_home_work_outlined),
                label: Text(
                  'Book a Service',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4A6CF7),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 64,
                color: Colors.red[300],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Unable to load bookings',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please check your connection and try again',
              style: GoogleFonts.outfit(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                setState(() => _isInitialLoad = true);
              },
              icon: const Icon(Icons.refresh_rounded),
              label: Text(
                'Retry',
                style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4A6CF7),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

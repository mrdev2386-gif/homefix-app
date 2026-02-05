import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/models/booking.dart';
import '../widgets/booking_card.dart';
import '../widgets/status_filter_chips.dart';
import 'booking_detail_screen.dart';

class BookingHistoryScreen extends StatefulWidget {
  const BookingHistoryScreen({super.key});

  @override
  State<BookingHistoryScreen> createState() => _BookingHistoryScreenState();
}

class _BookingHistoryScreenState extends State<BookingHistoryScreen> {
  String _selectedStatus = 'all';

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    final user = authService.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Booking History', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.login, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'Please login to view bookings',
                style: GoogleFonts.outfit(fontSize: 16, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        title: Text('My Bookings', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Status Filter
          Container(
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
          const SizedBox(height: 8),
          
          // Bookings List
          Expanded(
            child: StreamBuilder<List<Booking>>(
              stream: firestoreService.streamBookings(user.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                        const SizedBox(height: 16),
                        Text(
                          'Error loading bookings',
                          style: GoogleFonts.outfit(fontSize: 16, color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          snapshot.error.toString(),
                          style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey[500]),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                final allBookings = snapshot.data ?? [];
                
                // Filter bookings by status
                final filteredBookings = _selectedStatus == 'all'
                    ? allBookings
                    : allBookings.where((b) => b.status == _selectedStatus).toList();

                if (filteredBookings.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          _selectedStatus == 'all' 
                              ? 'No bookings yet'
                              : 'No ${_selectedStatus} bookings',
                          style: GoogleFonts.outfit(fontSize: 16, color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Your bookings will appear here',
                          style: GoogleFonts.outfit(fontSize: 14, color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    // Stream will auto-refresh
                    await Future.delayed(const Duration(milliseconds: 500));
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
        ],
      ),
    );
  }
}

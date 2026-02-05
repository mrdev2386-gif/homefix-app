import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/app_theme.dart';
import '../core/providers/auth_provider.dart';
import '../core/providers/booking_provider.dart';
import '../core/models/booking.dart';
import 'package:intl/intl.dart';
import 'review_screen.dart';

class BookingsTab extends StatelessWidget {
  const BookingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: Text("My Bookings", style: GoogleFonts.outfit(color: AppTheme.textColor, fontWeight: FontWeight.bold)),
          bottom: TabBar(
            labelColor: AppTheme.primaryColor,
            unselectedLabelColor: Colors.grey,
            indicatorColor: AppTheme.primaryColor,
            labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold),
            tabs: const [Tab(text: "Upcoming"), Tab(text: "History")],
          ),
        ),
        body: const TabBarView(children: [BookingList(isHistory: false), BookingList(isHistory: true)]),
      ),
    );
  }
}

class BookingList extends StatelessWidget {
  final bool isHistory;
  const BookingList({super.key, required this.isHistory});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final bookingProvider = Provider.of<BookingProvider>(context);
    final user = authProvider.customer;
    final firebaseUser = authProvider.currentUser; // I should add this getter to AuthProvider or use FirebaseAuth

    if (firebaseUser == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_outline_rounded, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text("Login to view your bookings", 
              style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[700])),
            const SizedBox(height: 8),
            Text("Track your service requests easily", 
              style: GoogleFonts.outfit(color: Colors.grey[500])),
          ],
        ),
      );
    }

    if (user == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return StreamBuilder<List<Booking>>(
      stream: bookingProvider.customerBookings(user.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        final allBookings = snapshot.data ?? [];
        final bookings = allBookings.where((b) {
          final isDone = b.status == 'completed' || b.status == 'cancelled';
          return isHistory ? isDone : !isDone;
        }).toList();

        if (bookings.isEmpty) {
          return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(isHistory ? Icons.history : Icons.event_available, size: 64, color: Colors.grey[200]), const SizedBox(height: 16), Text(isHistory ? "No past bookings" : "No upcoming bookings", style: GoogleFonts.outfit(fontWeight: FontWeight.bold))]));
        }

        return ListView.builder(padding: const EdgeInsets.all(20), itemCount: bookings.length, itemBuilder: (context, index) => _buildBookingCard(context, bookingProvider, bookings[index]));
      },
    );
  }

  Widget _buildBookingCard(BuildContext context, BookingProvider provider, Booking b) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade100), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(b.serviceTitle, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)), _buildStatusBadge(b.status)]),
          const SizedBox(height: 8),
          Text("${DateFormat('EEE, MMM d').format(b.scheduledAt)}", style: GoogleFonts.outfit(color: Colors.grey, fontSize: 13)),
          const Divider(height: 24),
          Row(children: [const Icon(Icons.location_on, size: 14, color: Colors.grey), const SizedBox(width: 4), Expanded(child: Text(b.addressSnapshot['fullAddress'] ?? 'No address', maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey)))]),
          const SizedBox(height: 16),
          if (b.status == 'completed')
            ElevatedButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ReviewScreen(bookingId: b.id, customerId: b.customerId, technicianId: b.technicianId ?? ''))),
              child: const Text("Rate Service"),
            )
          else if (b.status == 'pending' || b.status == 'accepted')
            Row(
              children: [
                Expanded(child: OutlinedButton(onPressed: () => provider.cancelBooking(b.id), style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red)), child: const Text("Cancel"))),
                if (b.technicianId != null) ...[const SizedBox(width: 12), Expanded(child: ElevatedButton.icon(onPressed: () => launchUrl(Uri.parse('tel:9508322397')), icon: const Icon(Icons.call, size: 16), label: const Text("Call Technican")))],
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color = Colors.grey;
    if (status == 'pending') color = Colors.orange;
    if (status == 'accepted' || status == 'on_the_way' || status == 'started') color = Colors.blue;
    if (status == 'completed') color = Colors.green;
    if (status == 'cancelled') color = Colors.red;
    return Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Text(status.toUpperCase(), style: GoogleFonts.outfit(fontSize: 10, color: color, fontWeight: FontWeight.bold)));
  }
}

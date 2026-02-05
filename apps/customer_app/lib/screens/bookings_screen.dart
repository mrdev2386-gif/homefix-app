import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../core/models/booking.dart';
import '../core/theme/app_theme.dart';
import 'booking_details_screen.dart';

class BookingsScreen extends StatelessWidget {
  const BookingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Center(child: Text('Please login'));

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: const Text('My Bookings', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.white,
          elevation: 0,
          bottom: const TabBar(
            labelColor: Colors.blue,
            unselectedLabelColor: Colors.grey,
            tabs: [
              Tab(text: 'Active'),
              Tab(text: 'History'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _BookingList(userId: user.uid, isActive: true),
            _BookingList(userId: user.uid, isActive: false),
          ],
        ),
      ),
    );
  }
}

class _BookingList extends StatelessWidget {
  final String userId;
  final bool isActive;

  const _BookingList({required this.userId, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bookings')
          .where('customerId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
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
                Icon(Icons.calendar_month, size: 60, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text(
                  isActive ? 'No active bookings' : 'No booking history',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        final allDocs = snapshot.data!.docs;
        final bookings = allDocs.map((d) => Booking.fromFirestore(d)).where((b) {
          final isCompleted = ['completed', 'cancelled', 'rejected'].contains(b.status);
          return isActive ? !isCompleted : isCompleted;
        }).toList();

        if (bookings.isEmpty) {
          return Center(
            child: Text(
              isActive ? 'No active bookings' : 'No booking history',
              style: const TextStyle(color: Colors.grey),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: bookings.length,
          separatorBuilder: (_, __) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            final booking = bookings[index];
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BookingDetailsScreen(bookingId: booking.id),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.05),
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
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getStatusColor(booking.status).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            booking.status.toUpperCase(),
                            style: TextStyle(
                              color: _getStatusColor(booking.status),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Text(
                          DateFormat('MMM dd, yyyy').format(booking.scheduledAt),
                          style: TextStyle(color: Colors.grey[600], fontSize: 13),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      booking.serviceTitle,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 16, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat.jm().format(booking.scheduledAt),
                          style: TextStyle(color: Colors.grey[600], fontSize: 13),
                        ),
                        const SizedBox(width: 16),
                        Icon(Icons.currency_rupee, size: 16, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Text(
                          '${booking.finalAmount}',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    if (booking.technicianName != null) ...[
                      const Divider(height: 24),
                      Row(
                        children: [
                          const CircleAvatar(
                            radius: 12,
                            backgroundColor: Colors.blue,
                            child: Icon(Icons.person, size: 14, color: Colors.white),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            booking.technicianName!,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending': return Colors.orange;
      case 'confirmed': return Colors.blue;
      case 'in_progress': return Colors.purple;
      case 'completed': return Colors.green;
      case 'cancelled': return Colors.red;
      default: return Colors.grey;
    }
  }
}

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/models/booking.dart';

class BookingDetailsScreen extends StatelessWidget {
  final String bookingId;
  const BookingDetailsScreen({super.key, required this.bookingId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Booking Details'),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        titleTextStyle: const TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('bookings').doc(bookingId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Booking not found'));
          }

          final booking = Booking.fromFirestore(snapshot.data!);
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(booking),
                const SizedBox(height: 20),
                if (booking.technicianId != null) 
                  _buildTechnicianCard(context, booking),
                const SizedBox(height: 20),
                _buildTimeline(booking),
                const SizedBox(height: 20),
                _buildPaymentInfo(booking),
                const SizedBox(height: 30),
                if (booking.status == 'pending' || booking.status == 'confirmed')
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: () => _cancelBooking(context),
                      child: const Text('Cancel Booking'),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(Booking booking) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  booking.serviceTitle,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  booking.status.toUpperCase(),
                  style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow(Icons.calendar_today, DateFormat.yMMMd().format(booking.scheduledAt)),
          const SizedBox(height: 8),
          _buildInfoRow(Icons.access_time, DateFormat.jm().format(booking.scheduledAt)),
          const SizedBox(height: 8),
          _buildInfoRow(Icons.location_on, booking.addressSnapshot['fullAddress'] ?? 'Unknown Address'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: const TextStyle(color: Colors.black87))),
      ],
    );
  }

  Widget _buildTechnicianCard(BuildContext context, Booking booking) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: Colors.blue,
            child: Icon(Icons.person, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  booking.technicianName ?? 'Technician',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const Text(
                  'Assigned Professional',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
               // Call technician logic
               ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Calling functionality coming soon')));
            },
            icon: const Icon(Icons.phone, color: Colors.green),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline(Booking booking) {
    final steps = [
      {'title': 'Booking Placed', 'status': 'pending'},
      {'title': 'Technician Assigned', 'status': 'confirmed'},
      {'title': 'Service Started', 'status': 'in_progress'},
      {'title': 'Service Completed', 'status': 'completed'},
    ];

    int currentStep = 0;
    if (booking.status == 'confirmed') currentStep = 1;
    if (booking.status == 'in_progress') currentStep = 2;
    if (booking.status == 'completed') currentStep = 3;
    if (booking.status == 'cancelled') currentStep = -1;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Status Timeline', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 20),
          if (booking.status == 'cancelled')
            const Text('This booking has been cancelled.', style: TextStyle(color: Colors.red)),
          if (booking.status != 'cancelled')
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: steps.length,
              itemBuilder: (context, index) {
                final step = steps[index];
                final isCompleted = index <= currentStep;
                final isLast = index == steps.length - 1;

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: isCompleted ? Colors.blue : Colors.grey[300],
                            shape: BoxShape.circle,
                          ),
                          child: isCompleted ? const Icon(Icons.check, size: 10, color: Colors.white) : null,
                        ),
                        if (!isLast)
                          Container(
                            width: 2,
                            height: 30,
                            color: isCompleted ? Colors.blue : Colors.grey[300],
                          ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Text(
                      step['title'] as String,
                      style: TextStyle(
                        color: isCompleted ? Colors.black87 : Colors.grey,
                        fontWeight: isCompleted ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildPaymentInfo(Booking booking) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _buildPaymentRow('Service Price', '₹${booking.price}'),
          if (booking.discountAmount > 0)
            _buildPaymentRow('Discount', '-₹${booking.discountAmount}', color: Colors.green),
          const Divider(height: 24),
          _buildPaymentRow('Total Amount', '₹${booking.finalAmount}', isBold: true),
        ],
      ),
    );
  }

  Widget _buildPaymentRow(String label, String value, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(
            color: Colors.grey[600],
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          )),
          Text(value, style: TextStyle(
            color: color ?? Colors.black87,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            fontSize: isBold ? 16 : 14,
          )),
        ],
      ),
    );
  }

  void _cancelBooking(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Booking?'),
        content: const Text('Are you sure you want to cancel this service?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await FirebaseFirestore.instance.collection('bookings').doc(bookingId).update({
                'status': 'cancelled',
                'updatedAt': FieldValue.serverTimestamp(),
              });
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Booking cancelled')));
              }
            },
            child: const Text('Yes, Cancel', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

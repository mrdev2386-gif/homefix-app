import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/models/booking.dart';
import '../../../core/services/firestore_service.dart';

class BookingDetailsScreen extends StatelessWidget {
  final String bookingId;
  const BookingDetailsScreen({super.key, required this.bookingId});

  @override
  Widget build(BuildContext context) {
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);

    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFE),
      appBar: AppBar(
        title: const Text('Booking Details', style: TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<Booking>(
        stream: firestoreService.streamBookingDetail(bookingId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData) {
            return const Center(child: Text('Booking not found'));
          }

          final booking = snapshot.data!;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatusCard(booking),
                const SizedBox(height: 24),
                _buildSectionTitle('Service Information'),
                const SizedBox(height: 12),
                _buildInfoCard([
                  _buildInfoRow('Service', booking.serviceTitle),
                  _buildInfoRow('Price', '₹${booking.price}'),
                  _buildInfoRow('Date', DateFormat('MMM d, yyyy').format(booking.scheduledAt)),
                  _buildInfoRow('Time', DateFormat('h:mm a').format(booking.scheduledAt)),
                ]),
                const SizedBox(height: 24),
                _buildSectionTitle('Technician Details'),
                const SizedBox(height: 12),
                _buildTechnicianCard(booking),
                const SizedBox(height: 24),
                _buildSectionTitle('Booking Timeline'),
                const SizedBox(height: 12),
                _buildTimeline(booking),
                const SizedBox(height: 40),
                if (booking.status == 'pending' || booking.status == 'accepted' || booking.status == 'scheduled')
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        // Handle Cancel
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Cancel Booking', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusCard(Booking booking) {
    Color statusColor;
    IconData statusIcon;
    switch (booking.status.toLowerCase()) {
      case 'completed':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'cancelled':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      case 'in_progress':
        statusColor = Colors.blue;
        statusIcon = Icons.running_with_errors;
        break;
      default:
        statusColor = Colors.orange;
        statusIcon = Icons.hourglass_empty;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(statusIcon, color: statusColor, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  booking.status.toUpperCase(),
                  style: TextStyle(color: statusColor, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1),
                ),
                const SizedBox(height: 4),
                Text(
                  _getStatusMessage(booking.status),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getStatusMessage(String status) {
    switch (status.toLowerCase()) {
      case 'accepted': return 'Technician has accepted your booking.';
      case 'scheduled': return 'Your service is scheduled.';
      case 'on_the_way': return 'Technician is on the way!';
      case 'in_progress': return 'Work is currently in progress.';
      case 'completed': return 'Service completed successfully.';
      case 'cancelled': return 'This booking was cancelled.';
      default: return 'Waiting for technician to confirm.';
    }
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.5));
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(children: children),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildTechnicianCard(Booking booking) {
    final techId = booking.technicianId;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.grey[200],
            child: const Icon(Icons.person, color: Colors.grey),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (techId != null && techId.isNotEmpty) 
                      ? 'Technician ID: ${techId.substring(0, 8)}' 
                      : 'Assigning...',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const Text('Professional Partner', style: TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          if (techId != null && techId.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.phone, color: Color(0xFF6366F1)),
              onPressed: () {},
            ),
        ],
      ),
    );
  }

  Widget _buildTimeline(Booking booking) {
    final List<String> stages = ['requested', 'accepted', 'scheduled', 'on_the_way', 'in_progress', 'completed'];
    int currentStage = stages.indexOf(booking.status.toLowerCase());
    if (currentStage == -1) currentStage = 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: stages.asMap().entries.map((entry) {
          int index = entry.key;
          String stage = entry.value;
          bool isCompleted = index <= currentStage;
          bool isLast = index == stages.length - 1;

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: isCompleted ? const Color(0xFF6366F1) : Colors.grey[200],
                      shape: BoxShape.circle,
                    ),
                    child: isCompleted ? const Icon(Icons.check, size: 12, color: Colors.white) : null,
                  ),
                  if (!isLast)
                    Container(
                      width: 2,
                      height: 30,
                      color: isCompleted ? const Color(0xFF6366F1) : Colors.grey[200],
                    ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    stage.replaceAll('_', ' ').toUpperCase(),
                    style: TextStyle(
                      fontWeight: isCompleted ? FontWeight.bold : FontWeight.normal,
                      color: isCompleted ? Colors.black : Colors.grey,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

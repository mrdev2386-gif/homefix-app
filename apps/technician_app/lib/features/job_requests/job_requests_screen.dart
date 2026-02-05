import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/firestore/booking_service.dart';
import '../../core/models/booking.dart';
import '../../core/providers/technician_provider.dart';
import '../../core/widgets/safe_network_image.dart';

class JobRequestsScreen extends StatefulWidget {
  const JobRequestsScreen({super.key});

  @override
  State<JobRequestsScreen> createState() => _JobRequestsScreenState();
}

class _JobRequestsScreenState extends State<JobRequestsScreen> {
  final BookingService _bookingService = BookingService();

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TechnicianProvider>(context);
    final tech = provider.technician;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text("New Job Requests", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.filter_list_rounded),
          ),
        ],
      ),
      body: tech == null
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<List<Booking>>(
              stream: _bookingService.getAvailableBookings(tech.skills),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                final bookings = snapshot.data ?? [];
                
                if (bookings.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: bookings.length,
                  itemBuilder: (context, index) {
                    return _buildRequestCard(bookings[index], tech);
                  },
                );
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.search_rounded, size: 64, color: Colors.grey[300]),
          ),
          const SizedBox(height: 24),
          Text(
            "Searching for tasks...",
            style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF475569)),
          ),
          const SizedBox(height: 8),
          Text(
            "New opportunities matching your skills\nwill appear here.",
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(color: const Color(0xFF94A3B8)),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestCard(Booking b, dynamic tech) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              SafeNetworkImage(
                imageUrl: b.serviceImage,
                height: 140,
                width: double.infinity,
                borderRadius: 20,
              ),
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)],
                  ),
                  child: Text(
                    "₹${b.price.toInt()}",
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: const Color(0xFF10B981)),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(b.serviceTitle, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.location_on_rounded, size: 14, color: Color(0xFF6366F1)),
                    const SizedBox(width: 4),
                    Text(b.addressSnapshot['area'] ?? 'Nearby Area', style: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFF64748B))),
                    const Spacer(),
                    const Icon(Icons.calendar_today_rounded, size: 14, color: Color(0xFF6366F1)),
                    const SizedBox(width: 4),
                    Text(DateFormat('MMM dd').format(b.scheduledAt), style: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFF64748B))),
                  ],
                ),
                const SizedBox(height: 16),
                if (b.problemDescription != null) ...[
                  Text("Problem Description:", style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF94A3B8))),
                  const SizedBox(height: 4),
                  Text(b.problemDescription!, style: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFF475569))),
                  const SizedBox(height: 20),
                ],
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {},
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 48),
                          foregroundColor: const Color(0xFFEF4444),
                          side: const BorderSide(color: Color(0xFFEF4444)),
                        ),
                        child: const Text("Ignore"),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _showQuoteModal(context, b, tech),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(0, 48),
                        ),
                        child: const Text("Send Quote"),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showQuoteModal(BuildContext context, Booking booking, dynamic tech) {
    final priceController = TextEditingController(text: booking.price.toInt().toString());
    final noteController = TextEditingController();
    DateTime selectedDate = booking.scheduledAt;
    String selectedTime = booking.scheduledTime;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 24),
                Text("Send Your Quote", style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text("Offer your best price and schedule for this task.", style: GoogleFonts.outfit(color: const Color(0xFF64748B))),
                const SizedBox(height: 32),
                
                Text("Proposed Price (₹)", style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextField(
                  controller: priceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(prefixIcon: Icon(Icons.currency_rupee_rounded)),
                ),
                const SizedBox(height: 24),

                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Visit Date", style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          InkWell(
                            onTap: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: selectedDate,
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now().add(const Duration(days: 30)),
                              );
                              if (date != null) setModalState(() => selectedDate = date);
                            },
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
                              child: Row(
                                children: [
                                  const Icon(Icons.calendar_today_rounded, size: 16, color: Color(0xFF6366F1)),
                                  const SizedBox(width: 8),
                                  Text(DateFormat('dd MMM').format(selectedDate)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Visit Time", style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          InkWell(
                            onTap: () async {
                              final time = await showTimePicker(
                                context: context,
                                initialTime: TimeOfDay.now(),
                              );
                              if (time != null) setModalState(() => selectedTime = time.format(context));
                            },
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
                              child: Row(
                                children: [
                                  const Icon(Icons.access_time_rounded, size: 16, color: Color(0xFF6366F1)),
                                  const SizedBox(width: 8),
                                  Text(selectedTime),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                Text("Optional Note", style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextField(
                  controller: noteController,
                  maxLines: 3,
                  decoration: const InputDecoration(hintText: "E.g. I can bring all necessary tools..."),
                ),
                const SizedBox(height: 32),
                
                ElevatedButton(
                  onPressed: () {
                    final price = double.tryParse(priceController.text) ?? booking.price;
                    _bookingService.sendQuote(
                      bookingId: booking.bookingId, 
                      technicianId: tech.uid, 
                      technicianName: tech.name, 
                      price: price, 
                      date: selectedDate, 
                      time: selectedTime,
                      note: noteController.text,
                    ).then((_) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Quote sent successfully!")));
                    });
                  },
                  child: const Text("Send Proposal"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

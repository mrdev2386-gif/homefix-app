import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../core/app_theme.dart';
import '../core/models/service.dart';
import '../core/models/address.dart';
import '../core/models/coupon.dart';
import '../core/providers/auth_provider.dart';
import '../core/firestore/coupon_service.dart';
import '../core/widgets/safe_network_image.dart';
import 'package:intl/intl.dart';
import '../features/booking/presentation/booking_confirmation_screen.dart';
import 'addresses_screen.dart';

class ServiceBookingScreen extends StatefulWidget {
  final dynamic service;
  final Map<String, dynamic>? preSelectedTech;

  const ServiceBookingScreen({super.key, required this.service, this.preSelectedTech});

  @override
  State<ServiceBookingScreen> createState() => _ServiceBookingScreenState();
}

class _ServiceBookingScreenState extends State<ServiceBookingScreen> {
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  String _selectedSlot = "10:00 AM - 11:00 AM"; // Default
  // In a real app, these should be dynamically fetched from availability/technician/{techId}/slots
  final List<String> _slots = [
    "09:00 AM - 10:00 AM", "10:00 AM - 11:00 AM", "11:00 AM - 12:00 PM",
    "02:00 PM - 03:00 PM", "04:00 PM - 05:00 PM"
  ];

  @override
  Widget build(BuildContext context) {
    // Navigate straight to Payment/Confirmation flow? 
    // Or collect address first.
    // Let's use the local state to collect options, then push BookingConfirmationScreen which handles the actual Cloud Function call.
    
    // We reuse the existing _build... methods logic but simplified for brevity in this turn.
    // The previous implementation had a full UI but was using BookingProvider client-side creation.
    // We must REDIRECT to BookingConfirmationScreen which does the Transactional createBooking.

    return Scaffold(
        appBar: AppBar(title: Text("Book ${widget.service.title}")),
        body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
                children: [
                    // Technician Info
                    if(widget.preSelectedTech != null)
                        ListTile(
                            leading: ClipOval(
                              child: SafeNetworkImage(
                                imageUrl: widget.preSelectedTech!['photoUrl'],
                                width: 40,
                                height: 40,
                                fit: BoxFit.cover,
                                fallbackUrl: 'https://ui-avatars.com/api/?name=Expert&background=random&size=128',
                              ),
                            ),
                            title: Text(widget.preSelectedTech!['name']),
                            subtitle: Text("Rating: ${widget.preSelectedTech!['ratingAvg']}"),
                            tileColor: Colors.white,
                        ),
                    const Divider(),
                    // Date & Time
                    const Text("Select Date & Time", style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(
                        height: 60,
                        child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: 7,
                            itemBuilder: (ctx, i) {
                                final d = DateTime.now().add(Duration(days: i+1));
                                final selected = d.day == _selectedDate.day;
                                return GestureDetector(
                                    onTap: () => setState(() => _selectedDate = d),
                                    child: Container(
                                        margin: const EdgeInsets.all(4),
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                            color: selected ? Colors.black : Colors.white,
                                            border: Border.all(color: Colors.grey)
                                        ),
                                        child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                                Text(DateFormat('MMM').format(d), style: TextStyle(color: selected?Colors.white:Colors.black, fontSize: 10)),
                                                Text("${d.day}", style: TextStyle(color: selected?Colors.white:Colors.black, fontWeight: FontWeight.bold))
                                            ]
                                        )
                                    ),
                                );
                            }
                        )
                    ),
                    const SizedBox(height: 10),
                    Wrap(spacing: 8, children: _slots.map((s) => ChoiceChip(
                        label: Text(s),
                        selected: _selectedSlot == s,
                        onSelected: (b) => setState(() => _selectedSlot = s)
                    )).toList()),
                    const SizedBox(height: 20),
                     ElevatedButton(
                        onPressed: () async {
                             if(widget.preSelectedTech == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please go back and select a technician")));
                                  return;
                             }
                             
                             // Select Address
                             final selectedAddress = await Navigator.push(
                               context,
                               MaterialPageRoute(builder: (context) => const AddressesScreen(isSelectionMode: true)),
                             );

                             if (selectedAddress != null && context.mounted) {
                               Navigator.push(context, MaterialPageRoute(builder: (_) => BookingConfirmationScreen(
                                   service: _serviceToMap(),
                                   date: _selectedDate,
                                   address: selectedAddress as Address,
                                   slot: {
                                       'id': 'slot_${_selectedSlot.replaceAll(' ', '_')}', // Mock Slot ID
                                       'startTime': _selectedSlot,
                                       'techId': widget.preSelectedTech!['uid'],
                                       'techName': widget.preSelectedTech!['name']
                                   }
                               )));
                             }
                        },
                        child: const Text("Proceed to Payment"),
                        style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50), backgroundColor: Colors.black, foregroundColor: Colors.white),
                    )
                ]
            )
        )
    );
  }

  Map<String, dynamic> _serviceToMap() {
       return {
            'id': widget.service.id,
            'title': widget.service.title,
            'price': widget.service.price ?? 500, // Handle missing price
            'imagePath': widget.service.imagePath
       };
  }
}

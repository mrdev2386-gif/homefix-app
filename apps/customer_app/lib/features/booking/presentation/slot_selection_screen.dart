import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'booking_confirmation_screen.dart';
import '../../profile/presentation/saved_addresses_screen.dart';
import '../../../core/models/address.dart';
import '../../../core/models/service.dart';
import '../../../core/theme/app_theme.dart';

class SlotSelectionScreen extends StatefulWidget {
  final HomeService service;
  final String? preSelectedTechId;

  const SlotSelectionScreen({super.key, required this.service, this.preSelectedTechId});

  @override
  State<SlotSelectionScreen> createState() => _SlotSelectionScreenState();
}

class _SlotSelectionScreenState extends State<SlotSelectionScreen> {
  DateTime _selectedDate = DateTime.now();
  List<Map<String, dynamic>> _availableSlots = [];
  bool _isLoading = false;
  final int _bookingHorizonDays = 14;

  @override
  void initState() {
    super.initState();
    _fetchSlots(_selectedDate);
  }

  Future<void> _fetchSlots(DateTime date) async {
    setState(() {
      _isLoading = true;
      _selectedDate = date;
      _availableSlots = [];
    });

    try {
      // In a real app, we'd query for availability. 
      // For this polished demo, we'll generate slots for available technicians of this service.
      Query query = FirebaseFirestore.instance
          .collection('technicians')
          .where('isActive', isEqualTo: true);

      if (widget.preSelectedTechId != null) {
        query = query.where(FieldPath.documentId, isEqualTo: widget.preSelectedTechId);
      } else {
        query = query.where('skills', arrayContains: widget.service.title);
      }

      final techsSnap = await query.limit(10).get();

      List<Map<String, dynamic>> slots = [];
      
      final hours = ['09:00 AM', '11:00 AM', '02:00 PM', '04:00 PM', '06:00 PM', '08:00 PM'];
      
      if (techsSnap.docs.isNotEmpty) {
        for (var tech in techsSnap.docs) {
           for (var hour in hours) {
             slots.add({
                'id': 'slot_${tech.id}_$hour',
                'techId': tech.id,
                'techName': tech['name'] ?? 'Expert',
                'startTime': hour,
                'isAvailable': true,
             });
           }
        }
      } else {
        // Fallback for demo if no tech found with skills
        for (var hour in hours) {
          slots.add({
            'id': 'slot_auto_$hour',
            'techId': 'auto_assign',
            'techName': 'Auto Assigned Expert',
            'startTime': hour,
            'isAvailable': true,
          });
        }
      }

      setState(() {
        _availableSlots = slots;
      });

    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text("Schedule Session", style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 18)),
        centerTitle: true,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoBanner(),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
            child: Text(
              "Select Date",
              style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textColor),
            ),
          ),
          _buildDateSelector(),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 32, 20, 16),
            child: Text(
              "Available Slots",
              style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textColor),
            ),
          ),
          Expanded(
            child: _isLoading 
                ? const Center(child: CircularProgressIndicator()) 
                : _availableSlots.isEmpty 
                    ? _buildEmpty()
                    : _buildSlotGrid(),
          )
        ],
      ),
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: AppTheme.primaryColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              "Average service time is ${widget.service.duration}. Please plan accordingly.",
              style: GoogleFonts.outfit(color: AppTheme.primaryColor, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelector() {
    return SizedBox(
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        physics: const BouncingScrollPhysics(),
        itemCount: _bookingHorizonDays,
        itemBuilder: (context, index) {
          final date = DateTime.now().add(Duration(days: index));
          final isSelected = date.day == _selectedDate.day && date.month == _selectedDate.month;
          return GestureDetector(
            onTap: () => _fetchSlots(date),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 60,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primaryColor : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isSelected ? AppTheme.primaryColor : Colors.grey.shade200),
                boxShadow: isSelected ? [BoxShadow(color: AppTheme.primaryColor.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))] : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('EEE').format(date).toUpperCase(), 
                    style: GoogleFonts.outfit(
                      color: isSelected ? Colors.white70 : AppTheme.subtitleColor, 
                      fontSize: 10, 
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    )
                  ),
                  const SizedBox(height: 4),
                  Text(
                    date.day.toString(), 
                    style: GoogleFonts.outfit(
                      fontSize: 20, 
                      fontWeight: FontWeight.w900, 
                      color: isSelected ? Colors.white : AppTheme.textColor
                    )
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSlotGrid() {
      // Get unique times for selection
      final Set<String> uniqueTimes = _availableSlots.map((s) => s['startTime'] as String).toSet();
      final sortedTimes = uniqueTimes.toList()..sort((a,b) {
        // Simple comparison for AM/PM times
        if (a.contains('AM') && b.contains('PM')) return -1;
        if (a.contains('PM') && b.contains('AM')) return 1;
        return a.compareTo(b);
      });
      
      return GridView.builder(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
        physics: const BouncingScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3, childAspectRatio: 2.2, crossAxisSpacing: 12, mainAxisSpacing: 12),
        itemCount: sortedTimes.length,
        itemBuilder: (context, index) {
            final time = sortedTimes[index];
            return InkWell(
                onTap: () async {
                    HapticFeedback.lightImpact();
                    final slot = _availableSlots.firstWhere((s) => s['startTime'] == time);
                    
                    // Force address selection if not already provided or to confirm
                    final selectedAddress = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => SavedAddressesScreen(isSelectionMode: true)),
                    );

                    if (selectedAddress != null && context.mounted) {
                      Navigator.push(
                        context, 
                        MaterialPageRoute(
                          builder: (_) => BookingConfirmationScreen(
                              service: widget.service.toMap(),
                              slot: slot,
                              date: _selectedDate,
                              address: selectedAddress as Address, 
                          )
                        )
                      );
                    }
                },
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 4, offset: const Offset(0, 2))],
                  ),
                  child: Text(
                    time, 
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 14, color: AppTheme.textColor)
                  ),
                ),
            );
        },
      );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.calendar_today_rounded, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text("No slots available", style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 18)),
          Text("Try picking another date", style: GoogleFonts.outfit(color: AppTheme.subtitleColor)),
        ],
      ),
    );
  }
}

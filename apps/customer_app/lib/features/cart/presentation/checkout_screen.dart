import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:customer_app/core/theme/app_theme.dart';
import '../../../core/providers/checkout_provider.dart';
import '../../../core/providers/cart_provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/location_provider.dart';
import '../../../core/providers/booking_provider.dart';
import 'package:customer_app/core/services/functions_service.dart';
import 'package:customer_app/core/models/address.dart';
import '../../profile/presentation/saved_addresses_screen.dart';
import '../../home/main_wrapper_screen.dart';
import '../../../core/constants/navigation_constants.dart';
import 'booking_status_screen.dart';
import '../../payment/presentation/payment_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  int _currentStep = 0;
  bool _isProcessing = false;
  bool _submitLock = false; // Duplicate-submit guard
  String _paymentMode = 'after_work'; // Pay After Work by default

  final List<String> _steps = ['Address', 'Schedule', 'Summary'];

  @override
  void initState() {
    super.initState();
    // Auto-select first saved address if none selected
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _autoSelectFirstAddress();
    });
  }

  void _autoSelectFirstAddress() {
    final checkout = Provider.of<CheckoutProvider>(context, listen: false);
    final locationProvider = Provider.of<LocationProvider>(context, listen: false);
    
    // If no address selected but location provider has one, use it
    if (checkout.selectedAddress == null && locationProvider.selectedAddress != null) {
      checkout.setAddress(locationProvider.selectedAddress!);
    }
  }

  void _nextStep() {
    if (_currentStep < _steps.length - 1) {
      setState(() => _currentStep++);
    } else {
      _finishBooking();
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    } else {
      Navigator.pop(context);
    }
  }

  Future<void> _finishBooking() async {
    print("BOOKING CONFIRM BUTTON CLICKED");
    
    // ── Duplicate-submit guard ──────────────────────────────────────────────
    if (_submitLock || _isProcessing) {
      debugPrint('⚠️ [Checkout] Submit already in progress – ignoring duplicate tap');
      return;
    }

    final checkout = Provider.of<CheckoutProvider>(context, listen: false);

    // ── Pre-flight validation ───────────────────────────────────────────────
    if (checkout.selectedAddress == null) {
      _showError('Please select a delivery address.');
      return;
    }
    if (checkout.selectedDate == null || checkout.selectedTimeSlot == null) {
      _showError('Please select a date and time slot.');
      return;
    }
    if (checkout.items.isEmpty) {
      _showError('Your cart is empty. Please add services first.');
      return;
    }

    // Validate every cart item has the required IDs
    for (final item in checkout.items) {
      if (item.categoryId.isEmpty) {
        _showError('Service "${item.serviceName}" is missing category info. Please remove and re-add it.');
        return;
      }
      if (item.serviceId.isEmpty) {
        _showError('Service "${item.serviceName}" has an invalid ID. Please remove and re-add it.');
        return;
      }
    }

    // ── Get authenticated user ──────────────────────────────────────────────
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      _showError('You must be logged in to place a booking.');
      return;
    }

    setState(() {
      _isProcessing = true;
      _submitLock = true;
    });

    try {
      final bookingProvider = Provider.of<BookingProvider>(context, listen: false);

      // ── Build scheduled datetime ────────────────────────────────────────
      final scheduledDate = checkout.selectedDate!;
      final timeSlot = checkout.selectedTimeSlot!;
      // Parse time slot like "09:00 AM" into hours/minutes
      final scheduledAt = _buildScheduledAt(scheduledDate, timeSlot);

      // ── NEW BOOKING FLOW: Check if technician is selected ─────────────
      if (checkout.hasSelectedTechnician) {
        final firstItem = checkout.items.isNotEmpty ? checkout.items.first : null;
        if (firstItem == null) throw Exception('No service selected. Please add a service first.');

        // PAY BEFORE WORK: payment first, booking created only after verified payment
        if (_paymentMode == 'before_work') {
          _showError('Pay Before Work is not yet available. Please select Pay After Work.');
          return;
        }

        // PAY AFTER WORK: create booking first, pay later
        final result = await bookingProvider.createBookingRequest(
          serviceId: firstItem.serviceId,
          technicianId: checkout.selectedTechnicianId!,
          categoryId: firstItem.categoryId,
          categoryName: firstItem.categoryName,
          scheduledDate: scheduledDate.toIso8601String(),
          scheduledTime: timeSlot,
          address: checkout.selectedAddress!.toMap(),
          subcategoryId: firstItem.subServiceId,
          paymentMode: _paymentMode,
        );

        final bookingId = result['bookingId'] as String?;
        if (bookingId == null || bookingId.isEmpty) {
          throw Exception('Server returned no bookingId. Please try again.');
        }

        try {
          await Provider.of<CartProvider>(context, listen: false).clearCart();
          Provider.of<CheckoutProvider>(context, listen: false).clear();
        } catch (_) {}

        if (!mounted) return;
        _showBookingPendingSheet(bookingId);
        return;
      }

      if (checkout.selectedTechnicianId == null) {
        throw Exception('Please select a technician before booking.');
      }
    } on Exception catch (e) {
      debugPrint('❌ [Checkout] Booking failed: $e');
      if (mounted) {
        _showError('Booking failed: ${e.toString().replaceAll('Exception: ', '')}');
      }
    } catch (e, stack) {
      debugPrint('❌ [Checkout] Unexpected error: $e\n$stack');
      if (mounted) {
        _showError('An unexpected error occurred. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _submitLock = false;
        });
      }
    }
  }

  /// Parses a time slot string like "09:00 AM" and combines with the date.
  DateTime _buildScheduledAt(DateTime date, String timeSlot) {
    try {
      final format = DateFormat('hh:mm a');
      final parsed = format.parse(timeSlot);
      return DateTime(date.year, date.month, date.day, parsed.hour, parsed.minute);
    } catch (_) {
      // Fallback: use noon on the selected date
      return DateTime(date.year, date.month, date.day, 12, 0);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.errorColor,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showSearchingSheet(String bookingId) {
    // Navigation lock to prevent double navigation
    bool hasNavigated = false;
    
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.search_rounded, color: AppTheme.primaryColor, size: 64),
            ),
            const SizedBox(height: 24),
            Text(
              'Booking Received!',
              style: GoogleFonts.outfit(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: AppTheme.textColor,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'We\'re searching for the best technician near you. You\'ll be notified once one is assigned.',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(color: AppTheme.subtitleColor, fontSize: 15),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  // Prevent duplicate navigation
                  if (hasNavigated) return;
                  hasNavigated = true;
                  
                  // Safety check: ensure widget is still mounted
                  if (!mounted) return;
                  
                  // Navigate to MainWrapperScreen with Bookings tab selected and focus on this booking
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (context) => MainWrapperScreen(
                        initialIndex: NavigationConstants.bookingsTabIndex,
                        focusBookingId: bookingId,
                      ),
                    ),
                    (route) => false,
                  );
                },
                child: const Text('Track Booking'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// NEW FLOW: Show when booking is pending admin approval
  void _showBookingPendingSheet(String bookingId) {
    // Navigation lock to prevent double navigation
    bool hasNavigated = false;
    
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.hourglass_empty_rounded, color: Colors.orange, size: 64),
            ),
            const SizedBox(height: 24),
            Text(
              'Booking Submitted!',
              style: GoogleFonts.outfit(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: AppTheme.textColor,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Your booking is pending admin approval. You\'ll be notified once it\'s approved.',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(color: AppTheme.subtitleColor, fontSize: 15),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  // Prevent duplicate navigation
                  if (hasNavigated) return;
                  hasNavigated = true;
                  
                  // Safety check: ensure widget is still mounted
                  if (!mounted) return;
                  
                  // Navigate to MainWrapperScreen with Bookings tab selected and focus on this booking
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (context) => MainWrapperScreen(
                        initialIndex: NavigationConstants.bookingsTabIndex,
                        focusBookingId: bookingId,
                      ),
                    ),
                    (route) => false,
                  );
                },
                child: const Text('Track Booking'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSuccessSheet(String bookingId) {
    // Navigation lock to prevent double navigation
    bool hasNavigated = false;
    
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: AppTheme.successColor.withOpacity(0.1), shape: BoxShape.circle),
              child: const Icon(Icons.check_circle_rounded, color: AppTheme.successColor, size: 64),
            ),
            const SizedBox(height: 24),
            Text(
              'Booking Confirmed!',
              style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w900, color: AppTheme.textColor),
            ),
            const SizedBox(height: 12),
            Text(
              'Your professional is being assigned. You can track everything in your bookings.',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(color: AppTheme.subtitleColor, fontSize: 15),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  // Prevent duplicate navigation
                  if (hasNavigated) return;
                  hasNavigated = true;
                  
                  // Safety check: ensure widget is still mounted
                  if (!mounted) return;
                  
                  // Navigate to MainWrapperScreen with Bookings tab selected and focus on this booking
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (context) => MainWrapperScreen(
                        initialIndex: NavigationConstants.bookingsTabIndex,
                        focusBookingId: bookingId,
                      ),
                    ),
                    (route) => false,
                  );
                },
                child: const Text('Track Booking'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        title: Text('Checkout', style: GoogleFonts.outfit(fontWeight: FontWeight.w800)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppTheme.textColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: _isProcessing ? null : _prevStep,
        ),
      ),
      body: Column(
        children: [
          _buildStepperHeader(),
          Expanded(
            child: _buildStepContent(),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildStepperHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(_steps.length, (index) {
          final isCompleted = index < _currentStep;
          final isActive = index == _currentStep;
          
          return Row(
            children: [
              Column(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isActive || isCompleted ? AppTheme.primaryColor : Colors.grey.shade200,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: isCompleted 
                        ? const Icon(Icons.check, color: Colors.white, size: 16)
                        : Text(
                            '${index + 1}',
                            style: GoogleFonts.outfit(
                              color: isActive ? Colors.white : Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _steps[index],
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      fontWeight: isActive ? FontWeight.w800 : FontWeight.w500,
                      color: isActive ? AppTheme.primaryColor : Colors.grey,
                    ),
                  ),
                ],
              ),
              if (index < _steps.length - 1)
                Container(
                  width: 40,
                  height: 2,
                  margin: const EdgeInsets.only(left: 8, right: 8, bottom: 14),
                  color: isCompleted ? AppTheme.primaryColor : Colors.grey.shade200,
                ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildAddressStep();
      case 1:
        return _buildScheduleStep();
      case 2:
        return _buildSummaryStep();
      default:
        return const SizedBox();
    }
  }

  Widget _buildAddressStep() {
    final checkout = Provider.of<CheckoutProvider>(context);
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Booking Address',
            style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textColor),
          ),
          const SizedBox(height: 16),
          if (checkout.selectedAddress != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.primaryColor.withOpacity(0.5)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_on, color: AppTheme.primaryColor),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(checkout.selectedAddress!.label, style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                        Text(checkout.selectedAddress!.fullAddress, style: GoogleFonts.outfit(color: Colors.grey, fontSize: 13)),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: _pickAddress,
                    child: const Text('Change'),
                  ),
                ],
              ),
            )
          else
            InkWell(
              onTap: _pickAddress,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 40),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade300, style: BorderStyle.none),
                ),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.add_location_alt_outlined, size: 48, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      Text('Add or Select Address', style: GoogleFonts.outfit(color: Colors.grey, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _pickAddress() async {
    final address = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SavedAddressesScreen(isSelectionMode: true)),
    );
    if (address != null && mounted) {
      Provider.of<CheckoutProvider>(context, listen: false).setAddress(address as Address);
    }
  }

  Widget _buildScheduleStep() {
    final checkout = Provider.of<CheckoutProvider>(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'When should we arrive?',
            style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textColor),
          ),
          const SizedBox(height: 16),
          _buildDateSelector(),
          const SizedBox(height: 32),
          Text(
            'Select Time Slot',
            style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textColor),
          ),
          const SizedBox(height: 16),
          _buildSlotGrid(),
        ],
      ),
    );
  }

  Widget _buildDateSelector() {
    final checkout = Provider.of<CheckoutProvider>(context);
    final selectedDate = checkout.selectedDate ?? DateTime.now();

    return SizedBox(
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 14,
        itemBuilder: (context, index) {
          final date = DateTime.now().add(Duration(days: index));
          final isSelected = DateFormat('yyyy-MM-dd').format(date) == 
                             DateFormat('yyyy-MM-dd').format(selectedDate);
          
          return GestureDetector(
            onTap: () {
              Provider.of<CheckoutProvider>(context, listen: false)
                  .setDateTime(date, checkout.selectedTimeSlot ?? '09:00 AM');
            },
            child: Container(
              width: 64,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primaryColor : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isSelected ? AppTheme.primaryColor : Colors.grey.shade200),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('EEE').format(date).toUpperCase(),
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      color: isSelected ? Colors.white70 : Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    date.day.toString(),
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      color: isSelected ? Colors.white : AppTheme.textColor,
                      fontWeight: FontWeight.w800,
                    ),
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
    final checkout = Provider.of<CheckoutProvider>(context);
    final slots = ['09:00 AM', '11:00 AM', '01:00 PM', '03:00 PM', '05:00 PM', '07:00 PM'];
    
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: slots.map((slot) {
        final isSelected = checkout.selectedTimeSlot == slot;
        return GestureDetector(
          onTap: () {
            Provider.of<CheckoutProvider>(context, listen: false)
                .setDateTime(checkout.selectedDate ?? DateTime.now(), slot);
          },
          child: Container(
            width: (MediaQuery.of(context).size.width.clamp(300, 1000) - 64) / 3,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.primaryColor : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isSelected ? AppTheme.primaryColor : Colors.grey.shade200),
            ),
            child: Center(
              child: Text(
                slot,
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: isSelected ? Colors.white : AppTheme.textColor,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSummaryStep() {
    final checkout = Provider.of<CheckoutProvider>(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Service Details Card
          _buildModernCard(
            'Service Details',
            Icons.build_rounded,
            AppTheme.primaryColor,
            Column(
              children: [
                ...checkout.items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          width: 50,
                          height: 50,
                          color: Colors.grey[200],
                          child: item.serviceImage.isNotEmpty
                              ? Image.network(item.serviceImage, fit: BoxFit.cover)
                              : Icon(Icons.build, color: Colors.grey[400]),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.serviceName,
                              style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 14),
                            ),
                            if (item.subServiceName != null)
                              Text(
                                item.subServiceName!,
                                style: GoogleFonts.outfit(color: Colors.grey[600], fontSize: 12),
                              ),
                            Text(
                              'Qty: ${item.quantity}',
                              style: GoogleFonts.outfit(color: Colors.grey[600], fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '₹${item.totalPrice.toStringAsFixed(0)}',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 16, color: AppTheme.primaryColor),
                      ),
                    ],
                  ),
                )),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // Schedule Card
          _buildModernCard(
            'Schedule',
            Icons.schedule_rounded,
            Colors.orange,
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.calendar_today, color: Colors.orange, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        checkout.selectedDate != null 
                            ? DateFormat('EEEE, d MMMM yyyy').format(checkout.selectedDate!)
                            : 'Date not selected',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 14),
                      ),
                      Text(
                        checkout.selectedTimeSlot ?? 'Time not selected',
                        style: GoogleFonts.outfit(color: Colors.grey[600], fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // Location Card
          _buildModernCard(
            'Service Location',
            Icons.location_on_rounded,
            Colors.green,
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.home, color: Colors.green, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        checkout.selectedAddress?.label ?? 'Address',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 14),
                      ),
                      Text(
                        checkout.selectedAddress?.fullAddress ?? 'No address selected',
                        style: GoogleFonts.outfit(color: Colors.grey[600], fontSize: 13),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.map, color: Colors.blue, size: 16),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // Price Breakdown Card
          _buildPriceBreakdownCard(checkout),
          const SizedBox(height: 24),
          
          // Payment Options Card
          _buildPaymentOptionsCard(),
        ],
      ),
    );
  }

  Widget _buildPaymentOptionsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
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
                  color: Colors.purple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.account_balance_wallet, color: Colors.purple, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'Payment Mode',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: AppTheme.textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          RadioListTile<String>(
            title: Text('Pay Before Work', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
            subtitle: Text('Pay online via Razorpay before service starts', style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey[600])),
            value: 'before_work',
            groupValue: _paymentMode,
            onChanged: (val) {
              if (val != null) setState(() => _paymentMode = val);
            },
            activeColor: AppTheme.primaryColor,
            contentPadding: EdgeInsets.zero,
          ),
          RadioListTile<String>(
            title: Text('Pay After Work', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
            subtitle: Text('Generate QR for technician when completed', style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey[600])),
            value: 'after_work',
            groupValue: _paymentMode,
            onChanged: (val) {
              if (val != null) setState(() => _paymentMode = val);
            },
            activeColor: AppTheme.primaryColor,
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  Widget _buildModernCard(String title, IconData icon, Color iconColor, Widget child) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
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
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: AppTheme.textColor,
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

  Widget _buildPriceBreakdownCard(CheckoutProvider checkout) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.receipt_long, color: AppTheme.primaryColor, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'Price Breakdown',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: AppTheme.textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _priceRow('Subtotal', checkout.subtotal),
          const SizedBox(height: 16),
          Container(
            height: 1,
            color: Colors.grey[200],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Amount',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  color: AppTheme.textColor,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '₹${checkout.grandTotal.toStringAsFixed(0)}',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }



  Widget _priceRow(String label, double val) {
    return SizedBox(
      width: double.infinity,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.outfit(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              '₹${val.toStringAsFixed(0)}',
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: AppTheme.textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    final checkout = Provider.of<CheckoutProvider>(context);
    bool canContinue = false;
    if (_currentStep == 0) canContinue = checkout.selectedAddress != null;
    if (_currentStep == 1) canContinue = checkout.selectedDate != null && checkout.selectedTimeSlot != null;
    if (_currentStep == 2) canContinue = true;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Price',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₹${checkout.grandTotal.toStringAsFixed(0)}',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w900,
                      fontSize: 20,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            SizedBox(
              width: 160,
              height: 56,
              child: ElevatedButton(
                onPressed: canContinue && !_isProcessing && !_submitLock ? _nextStep : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  disabledBackgroundColor: Colors.grey[300],
                ),
                child: _isProcessing
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_currentStep == 2)
                          const Icon(Icons.check_circle_outline, size: 18)
                        else
                          const Icon(Icons.arrow_forward, size: 18),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            _currentStep == 2 ? 'Confirm' : 'Continue',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

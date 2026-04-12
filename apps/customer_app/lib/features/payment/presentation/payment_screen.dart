import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../../core/services/functions_service.dart';
import '../../../core/models/booking.dart';
import '../../../core/services/booking_service.dart';

class PaymentScreen extends StatefulWidget {
  final String bookingId;

  const PaymentScreen({super.key, required this.bookingId});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  late Razorpay _razorpay;
  bool _isLoading = false;
  bool _isPaymentInProgress = false; // STEP 5: Prevent multiple clicks
  String? _errorMessage;
  Booking? _booking;
  String? _pendingOrderId; // STEP 7: Track pending payment
  String? _pendingPaymentId;
  String? _pendingSignature;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    _loadBooking();
    _checkPendingPayment(); // STEP 7: Check for pending payment on init
  }

  Future<void> _loadBooking() async {
    try {
      final booking = await BookingService().getBooking(widget.bookingId);
      setState(() => _booking = booking);
      if (booking != null && 
          (booking.paymentStatus == 'processing' || booking.paymentStatus == 'failed')) {
        _checkPendingPayment();
      }
    } catch (e) {
      setState(() => _errorMessage = 'Failed to load booking: $e');
    }
  }

  // STEP 7: Check for pending payment (fallback recovery)
  Future<void> _checkPendingPayment() async {
    try {
      final booking = await BookingService().getBooking(widget.bookingId);
      
      // If payment is processing or failed, show verify button
      if (booking?.paymentStatus == 'processing' || booking?.paymentStatus == 'failed') {
        setState(() {
          _errorMessage = 'Payment verification pending. Tap "Verify Payment" to check status.';
        });
      }
    } catch (e) {
      // Ignore errors in background check
    }
  }

  Future<void> _initiatePayment() async {
    if (_booking == null || _isPaymentInProgress) return; // STEP 5: Check lock

    setState(() {
      _isLoading = true;
      _isPaymentInProgress = true; // STEP 5: Set lock
      _errorMessage = null;
    });

    try {
      // STEP 1: Create payment order on backend (NEVER hardcode amount/orderId)
      final orderResponse = await FunctionsService().createPaymentOrder(
        bookingId: widget.bookingId,
      );

      if (!orderResponse['success']) {
        throw Exception(orderResponse['error'] ?? 'Failed to create order');
      }

      // STEP 1: Get all values from backend
      final orderId = orderResponse['orderId'];
      final amount = orderResponse['amount']; // Backend-controlled amount
      final keyId = orderResponse['keyId']; // Backend-controlled key
      final customerEmail = orderResponse['customerEmail'] ?? '';
      final customerPhone = orderResponse['customerPhone'] ?? '';

      // STEP 8: Validate backend response
      if (orderId == null || amount == null || keyId == null) {
        throw Exception('Invalid order response from backend');
      }

      // STEP 2: Open Razorpay with backend-provided values
      var options = {
        'key': keyId, // NEVER hardcode - use backend value
        'order_id': orderId, // Backend-generated order ID
        'amount': (amount * 100).toInt(), // STEP 2: Amount in paise, matches backend
        'currency': 'INR',
        'name': 'HomeFix',
        'description': 'Payment for booking #${_booking!.id}',
        'prefill': {
          'contact': customerPhone,
          'email': customerEmail,
        },
        'theme': {
          'color': '#6366F1',
        },
      };

      _razorpay.open(options);
      
      setState(() => _isLoading = false); // Remove loading, keep lock until payment completes
    } catch (e) {
      // STEP 8: Error handling
      setState(() {
        _errorMessage = 'Payment initialization failed: $e';
        _isLoading = false;
        _isPaymentInProgress = false; // Release lock on error
      });
    }
  }

  // STEP 3: Handle payment success - ONLY backend verifies
  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    try {
      setState(() => _isLoading = true);

      // STEP 8: Validate response
      if (response.orderId == null || response.paymentId == null || response.signature == null) {
        throw Exception('Invalid payment response from Razorpay');
      }

      // STEP 3: Verify payment on backend (NEVER trust client)
      final verifyResponse = await FunctionsService().verifyPayment(
        bookingId: widget.bookingId,
        razorpayOrderId: response.orderId!,
        razorpayPaymentId: response.paymentId!,
        razorpaySignature: response.signature!,
      );

      if (verifyResponse['success']) {
        // STEP 6: Retry loop with fresh data fetch to wait for Firestore sync
        bool bookingConfirmed = false;
        for (int i = 0; i < 5; i++) {
          await Future.delayed(const Duration(seconds: 1));
          final updatedBooking = await BookingService().getBooking(widget.bookingId);
          setState(() => _booking = updatedBooking);
          if (updatedBooking?.bookingStatus == 'paid') {
            bookingConfirmed = true;
            break;
          }
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Payment successful! Your booking is confirmed.'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
          Navigator.pop(context, true); // Return success
        }
      } else {
        throw Exception(verifyResponse['error'] ?? 'Payment verification failed');
      }
    } catch (e) {
      // STEP 8: Error handling
      if (mounted) {
        setState(() {
          _errorMessage = 'Verification failed: $e. Please contact support if amount was deducted.';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Verification failed: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
        _isPaymentInProgress = false; // STEP 5: Release lock
      });
    }
  }

  // STEP 4: Handle payment failure
  void _handlePaymentError(PaymentFailureResponse response) async {
    try {
      // STEP 4: Call handlePaymentFailure on backend
      // Note: PaymentFailureResponse doesn't have orderId/paymentId, use empty strings
      await FunctionsService().handlePaymentFailure(
        bookingId: widget.bookingId,
        razorpayOrderId: '',
        razorpayPaymentId: '',
        errorCode: response.code.toString(),
        errorDescription: response.message ?? 'Payment failed',
      );
    } catch (e) {
      // Log error but don't block UI
      if (kDebugMode) debugPrint('Failed to log payment failure: $e');
    }

    // STEP 8: Show error to user
    if (mounted) {
      setState(() {
        _errorMessage = 'Payment failed: ${response.message}. You can try again.';
        _isPaymentInProgress = false; // STEP 5: Release lock
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment failed: ${response.message}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'Retry',
            textColor: Colors.white,
            onPressed: _initiatePayment,
          ),
        ),
      );
    }
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('External wallet: ${response.walletName}')),
    );
    setState(() => _isPaymentInProgress = false); // Release lock
  }

  // STEP 6: Refresh booking state from Firestore after payment
  Future<void> _refreshBookingState() async {
    try {
      final updatedBooking = await BookingService().getBooking(widget.bookingId);
      setState(() => _booking = updatedBooking);
      
      // Verify booking status is actually paid
      if (updatedBooking?.bookingStatus != 'paid') {
        throw Exception('Booking status not updated to paid');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Failed to refresh booking state: $e');
      // Don't throw - payment might still be processing
    }
  }

  // STEP 7: Manual verification for pending payments
  Future<void> _verifyPendingPayment() async {
    if (_booking == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Try to verify with existing order details
      final booking = await BookingService().getBooking(widget.bookingId);
      final orderId = booking?.razorpayOrderId;
      
      if (orderId == null) {
        throw Exception('No order ID found for this booking');
      }

      // Show dialog to user
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Verify Payment'),
            content: const Text('Checking payment status with backend...'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ],
          ),
        );
      }

      // Refresh booking to check if payment was processed
      await _refreshBookingState();
      
      if (mounted) {
        Navigator.pop(context); // Close dialog
        
        if (_booking!.bookingStatus == 'paid') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Payment verified successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        } else {
          setState(() {
            _errorMessage = 'Payment not yet confirmed. Please try again or contact support.';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close dialog
        setState(() {
          _errorMessage = 'Verification failed: $e';
        });
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        title: Text('Payment', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: _booking == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Payment Summary
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Payment Summary',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildSummaryRow('Service', _booking!.serviceTitle),
                        const SizedBox(height: 12),
                        _buildSummaryRow('Amount', '₹${_booking!.finalAmount.toStringAsFixed(0)}'),
                        const Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total to Pay',
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '₹${_booking!.finalAmount.toStringAsFixed(0)}',
                              style: GoogleFonts.outfit(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF6366F1),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Error Message
                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: GoogleFonts.outfit(color: Colors.red.shade700),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Payment Method Info
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F9FF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF0369A1).withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info, color: Color(0xFF0369A1), size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Payment after service completion. Secure Razorpay checkout.',
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              color: const Color(0xFF0369A1),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Pay Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: (_isLoading || _isPaymentInProgress) ? null : _initiatePayment, // STEP 5: Disable when locked
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6366F1),
                        disabledBackgroundColor: Colors.grey[300],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              _isPaymentInProgress ? 'PROCESSING...' : 'PAY ₹${_booking!.finalAmount.toStringAsFixed(0)}',
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // STEP 7: Verify Payment Button (for pending payments)
                  if (_booking!.paymentStatus == 'processing' || _booking!.paymentStatus == 'failed') ...[
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton.icon(
                        onPressed: _isLoading ? null : _verifyPendingPayment,
                        icon: const Icon(Icons.refresh),
                        label: Text(
                          'Verify Payment Status',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF6366F1)),
                          foregroundColor: const Color(0xFF6366F1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Cancel Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.grey),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(fontSize: 14, color: Colors.grey[600]),
        ),
        Text(
          value,
          style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

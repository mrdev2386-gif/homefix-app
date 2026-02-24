import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:customer_app/core/services/functions_service.dart';
import 'package:customer_app/core/theme/app_theme.dart';
import '../../cart/presentation/booking_status_screen.dart';

class PaymentScreen extends StatefulWidget {
  final String bookingId;
  final double amount;

  const PaymentScreen({
    super.key,
    required this.bookingId,
    required this.amount,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  late Razorpay _razorpay;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  Future<void> _startPayment() async {
    setState(() => _isLoading = true);
    try {
      final functions = Provider.of<FunctionsService>(context, listen: false);
      final orderData = await functions.initiateRazorpayPayment(widget.bookingId);

      var options = {
        'key': orderData['key'],
        'amount': orderData['amount'],
        'name': 'HomeFix',
        'order_id': orderData['orderId'],
        'description': 'Booking ID: ${widget.bookingId}',
        'timeout': 300, // in seconds
        'prefill': {
          'contact': '', // Optional: can be passed from profile
          'email': ''
        }
      };

      _razorpay.open(options);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to initiate payment: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    setState(() => _isLoading = true);
    try {
      final functions = Provider.of<FunctionsService>(context, listen: false);
      await functions.verifyRazorpayPayment({
        'bookingId': widget.bookingId,
        'razorpay_order_id': response.orderId,
        'razorpay_payment_id': response.paymentId,
        'razorpay_signature': response.signature,
      });

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => BookingStatusScreen(bookingId: widget.bookingId)),
          (route) => false,
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment verification failed: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Payment Failed: ${response.message}'), backgroundColor: Colors.red),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    // Handle external wallet if needed
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Payment', style: GoogleFonts.outfit(fontWeight: FontWeight.w800)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppTheme.textColor,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.payment_rounded, size: 80, color: AppTheme.primaryColor),
              ),
              const SizedBox(height: 32),
              Text(
                'Payment for Booking',
                style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.normal, color: AppTheme.subtitleColor),
              ),
              const SizedBox(height: 8),
              Text(
                '₹${widget.amount.toStringAsFixed(2)}',
                style: GoogleFonts.outfit(fontSize: 48, fontWeight: FontWeight.w900, color: AppTheme.primaryColor),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _startPayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          'PAY SECURELY',
                          style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
                        ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Secure payment via Razorpay',
                style: GoogleFonts.outfit(color: Colors.grey, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

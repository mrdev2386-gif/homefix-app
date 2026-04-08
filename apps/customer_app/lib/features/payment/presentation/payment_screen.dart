import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:customer_app/core/services/functions_service.dart';
import 'package:customer_app/core/theme/app_theme.dart';

/// Unified payment screen.
///
/// Two modes:
/// 1. Pre-payment (Pay Before Work): pass [bookingParams], no bookingId yet.
///    Flow: createPrePaymentOrder → Razorpay → verifyAndCreateBooking → pop(bookingId)
///
/// 2. Post-booking payment (existing): pass [bookingId].
///    Flow: initiateRazorpayPayment → Razorpay → verifyRazorpayPayment → pop(true)
class PaymentScreen extends StatefulWidget {
  /// For Pay Before Work: booking details to create order without a booking doc.
  final Map<String, dynamic>? bookingParams;

  /// For existing post-booking payment.
  final String? bookingId;

  const PaymentScreen({super.key, this.bookingParams, this.bookingId})
      : assert(bookingParams != null || bookingId != null,
            'Either bookingParams or bookingId must be provided');

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  late Razorpay _razorpay;
  bool _isLoading = false;
  double? _displayAmount;
  String? _razorpayOrderId; // stored after createPrePaymentOrder
  String? _error;

  bool get _isPrePayment => widget.bookingParams != null;

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
    if (_isLoading) return;
    setState(() { _isLoading = true; _error = null; });

    try {
      final functions = Provider.of<FunctionsService>(context, listen: false);
      Map<String, dynamic> orderData;

      if (_isPrePayment) {
        // Step 1: create order without booking
        orderData = await functions.createPrePaymentOrder(widget.bookingParams!);
        _razorpayOrderId = orderData['orderId'] as String;
      } else {
        // Existing flow: order tied to existing booking
        orderData = await functions.initiateRazorpayPayment(widget.bookingId!);
        _razorpayOrderId = orderData['orderId'] as String?;
      }

      final amountPaise = (orderData['amount'] as num).toInt();
      setState(() => _displayAmount = amountPaise / 100);

      _razorpay.open({
        'key': orderData['key'],
        'amount': amountPaise,
        'order_id': orderData['orderId'],
        'name': 'HomeFix',
        'description': 'Service Payment',
        'timeout': 300,
        'prefill': {'contact': '', 'email': ''},
      });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    if (!mounted) return;
    setState(() { _isLoading = true; _error = null; });

    try {
      final functions = Provider.of<FunctionsService>(context, listen: false);

      if (_isPrePayment) {
        // Step 2: verify + create booking atomically
        final result = await functions.verifyAndCreateBooking({
          'razorpayOrderId': response.orderId ?? _razorpayOrderId,
          'razorpayPaymentId': response.paymentId,
          'razorpaySignature': response.signature,
        });
        final bookingId = result['bookingId'] as String;
        if (mounted) Navigator.of(context).pop(bookingId); // return bookingId to checkout
      } else {
        // Existing flow: verify only
        await functions.verifyRazorpayPayment({
          'bookingId': widget.bookingId,
          'razorpayOrderId': response.orderId,
          'razorpayPaymentId': response.paymentId,
          'razorpaySignature': response.signature,
        });
        if (mounted) Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) setState(() { _error = 'Verification failed: $e'; _isLoading = false; });
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    if (mounted) setState(() { _error = response.message ?? 'Payment failed. Please try again.'; _isLoading = false; });
  }

  void _handleExternalWallet(ExternalWalletResponse response) {}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Pay Before Work', style: GoogleFonts.outfit(fontWeight: FontWeight.w800)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppTheme.textColor,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(null),
        ),
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
                'Secure Online Payment',
                style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.textColor),
              ),
              const SizedBox(height: 8),
              if (_displayAmount != null)
                Text(
                  '₹${_displayAmount!.toStringAsFixed(0)}',
                  style: GoogleFonts.outfit(fontSize: 48, fontWeight: FontWeight.w900, color: AppTheme.primaryColor),
                )
              else
                Text(
                  'Amount confirmed by server',
                  style: GoogleFonts.outfit(fontSize: 14, color: AppTheme.subtitleColor),
                ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(12)),
                  child: Text(_error!, style: GoogleFonts.outfit(color: Colors.red, fontSize: 13)),
                ),
              ],
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
                      : Text('PAY SECURELY', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
                ),
              ),
              const SizedBox(height: 16),
              Text('Secured by Razorpay', style: GoogleFonts.outfit(color: Colors.grey, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }
}

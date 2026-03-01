import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/app_theme.dart';

/// Customer QR Payment Screen
/// 
/// Shows the QR code for paying at technician's location
/// Supports both online payment and pay-after-service
class QRPaymentScreen extends StatefulWidget {
  final String bookingId;
  final double amount;
  final String technicianName;
  final String serviceName;

  const QRPaymentScreen({
    super.key,
    required this.bookingId,
    required this.amount,
    required this.technicianName,
    required this.serviceName,
  });

  @override
  State<QRPaymentScreen> createState() => _QRPaymentScreenState();
}

class _QRPaymentScreenState extends State<QRPaymentScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  String? _qrImageUrl;
  String? _paymentStatus;
  bool _isLoading = true;
  String? _error;
  Timer? _pollingTimer;
  DateTime? _expiresAt;

  @override
  void initState() {
    super.initState();
    _loadPaymentDetails();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadPaymentDetails() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Get payment details from booking
      final doc = await _firestore
          .collection('bookings')
          .doc(widget.bookingId)
          .collection('payment')
          .doc('qr')
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          _qrImageUrl = data['qrImageUrl'];
          _paymentStatus = data['status'];
          _expiresAt = data['expiresAt']?.toDate();
          _isLoading = false;
        });

        // Start polling if not paid
        if (_paymentStatus != 'paid') {
          _startPolling();
        }
      } else {
        setState(() {
          _error = 'Payment QR not found. Please contact support.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      try {
        final doc = await _firestore
            .collection('bookings')
            .doc(widget.bookingId)
            .collection('payment')
            .doc('qr')
            .get();

        if (doc.exists) {
          final status = doc.data()?['status'];
          if (status == 'paid' && mounted) {
            timer.cancel();
            setState(() {
              _paymentStatus = 'paid';
            });
            _showSuccessDialog();
          }
        }
      } catch (e) {
        // Ignore polling errors
      }
    });
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 32),
            SizedBox(width: 8),
            Text('Payment Successful'),
          ],
        ),
        content: Text(
          'Your payment of ₹${widget.amount} has been received. '
          'The technician has been notified.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context, true);
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pay for Service'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorWidget()
              : _buildContent(),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadPaymentDetails,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    final isPaid = _paymentStatus == 'paid';
    final isExpired = _expiresAt != null && DateTime.now().isAfter(_expiresAt!);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Service Info Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      const CircleAvatar(
                        backgroundColor: Colors.grey,
                        child: Icon(Icons.person, color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.technicianName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              widget.serviceName,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Amount to Pay',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        '₹${widget.amount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Payment Status
          if (isPaid)
            _buildSuccessStatus()
          else if (isExpired)
            _buildExpiredStatus()
          else
            _buildPaymentInstructions(),
        ],
      ),
    );
  }

  Widget _buildPaymentInstructions() {
    return Column(
      children: [
        // QR Code
        if (_qrImageUrl != null)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                const Text(
                  'Scan QR to Pay',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: _qrImageUrl!,
                    width: 200,
                    height: 200,
                    fit: BoxFit.contain,
                    placeholder: (context, url) => const SizedBox(
                      width: 200,
                      height: 200,
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    errorWidget: (context, url, error) => const Icon(
                      Icons.qr_code,
                      size: 100,
                      color: Colors.grey,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (_expiresAt != null)
                  Text(
                    'Expires in ${_getTimeRemaining()}',
                    style: const TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),
        const SizedBox(height: 24),

        // Alternative Payment Methods
        const Text(
          'Or pay using',
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 16),
        
        // UPI Apps
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildUPIApp('GPay', 'assets/upi/gpay.png'),
            _buildUPIApp('PhonePe', 'assets/upi/phonepe.png'),
            _buildUPIApp('Paytm', 'assets/upi/paytm.png'),
          ],
        ),
        const SizedBox(height: 24),

        // Manual Payment Option
        OutlinedButton.icon(
          onPressed: () {
            // Show manual payment options
            _showManualPaymentOptions();
          },
          icon: const Icon(Icons.more_horiz),
          label: const Text('Other Payment Options'),
        ),
      ],
    );
  }

  Widget _buildUPIApp(String name, String iconPath) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Icon(
              Icons.apps,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            name,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessStatus() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          const Icon(
            Icons.check_circle,
            color: Colors.green,
            size: 80,
          ),
          const SizedBox(height: 16),
          const Text(
            'Payment Successful!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '₹${widget.amount.toStringAsFixed(2)} paid successfully',
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  Widget _buildExpiredStatus() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          const Icon(
            Icons.access_time,
            color: Colors.orange,
            size: 80,
          ),
          const SizedBox(height: 16),
          const Text(
            'QR Code Expired',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.orange,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Please ask the technician to generate a new QR code',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadPaymentDetails,
            child: const Text('Refresh'),
          ),
        ],
      ),
    );
  }

  void _showManualPaymentOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Other Payment Options',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.credit_card),
              title: const Text('Credit/Debit Card'),
              onTap: () {
                Navigator.pop(context);
                // Navigate to card payment
              },
            ),
            ListTile(
              leading: const Icon(Icons.account_balance),
              title: const Text('Net Banking'),
              onTap: () {
                Navigator.pop(context);
                // Navigate to net banking
              },
            ),
            ListTile(
              leading: const Icon(Icons.wallet),
              title: const Text('UPI'),
              onTap: () {
                Navigator.pop(context);
                // Open UPI payment
              },
            ),
          ],
        ),
      ),
    );
  }

  String _getTimeRemaining() {
    if (_expiresAt == null) return '';
    final remaining = _expiresAt!.difference(DateTime.now());
    if (remaining.isNegative) return 'Expired';
    if (remaining.inMinutes > 0) {
      return '${remaining.inMinutes} min ${remaining.inSeconds % 60} sec';
    }
    return '${remaining.inSeconds} sec';
  }
}

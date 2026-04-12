import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/wallet.dart';
import '../models/wallet_transaction.dart';
import '../models/payout.dart';
import '../models/booking_payment.dart';
import 'functions_service.dart';
import '../firebase/firebase_functions.dart';

/// Wallet Service - Secure Bridge to Cloud Functions
/// 
/// SECURITY: All wallet operations go through Cloud Functions
/// Client NEVER directly writes to wallet collections
class WalletService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FunctionsService _functionsService = FunctionsService();
  
  /// Get current technician ID
  String? get _technicianId => _auth.currentUser?.uid;

  /// Get technician wallet balance
  Future<TechnicianWallet> getWallet() async {
    final technicianId = _technicianId;
    if (technicianId == null) {
      throw Exception('User not authenticated');
    }

    final doc = await _firestore
        .collection('wallets')
        .doc(technicianId)
        .get();

    return TechnicianWallet.fromFirestore(doc);
  }

  /// Request withdrawal - goes through Cloud Function
  /// PHASE 4: Added balance assertion and idempotency
  Future<WithdrawalResult> requestWithdrawal({
    required double amount,
    required String bankAccountId,
  }) async {
    final technicianId = _technicianId;
    if (technicianId == null) {
      throw Exception('User not authenticated');
    }

    // PHASE 4: Final balance assertion guard - check before making request
    final wallet = await getWallet();
    if (wallet.availableBalance < amount) {
      throw WalletException('Insufficient balance. Available: ₹${wallet.availableBalance.toStringAsFixed(2)}');
    }

    try {
      // PHASE 4: Generate idempotency key to prevent double withdrawals
      final idempotencyKey = '${technicianId}_${DateTime.now().millisecondsSinceEpoch}';
      
      // Call Cloud Function
      final callable = FirebaseFunctionsService.instance
          .httpsCallable('requestWithdrawal');
      
      final result = await callable.call({
        'technicianId': technicianId,
        'amount': amount,
        'bankAccountId': bankAccountId,
        'idempotencyKey': idempotencyKey,
      });

      return WithdrawalResult.fromMap(result.data);
    } on FirebaseFunctionsException catch (e) {
      throw WalletException(e.message ?? 'Withdrawal failed');
    } catch (e) {
      throw WalletException('Withdrawal failed: $e');
    }
  }

  /// Get transaction history
  Future<List<WalletTransaction>> getTransactionHistory({
    int limit = 20,
    String? startAfter,
  }) async {
    final technicianId = _technicianId;
    if (technicianId == null) {
      throw Exception('User not authenticated');
    }

    try {
      final callable = FirebaseFunctionsService.instance
          .httpsCallable('getTransactionHistory');
      
      final result = await callable.call({
        'technicianId': technicianId,
        'limit': limit,
        if (startAfter != null) 'startAfter': startAfter,
      });

      final data = result.data as Map<String, dynamic>;
      final transactions = (data['transactions'] as List)
          .map((t) => _parseTransaction(t))
          .toList();

      return transactions;
    } catch (e) {
      throw WalletException('Failed to fetch transactions: $e');
    }
  }

  /// Get payout history
  Future<List<TechnicianPayout>> getPayoutHistory({int limit = 20}) async {
    final technicianId = _technicianId;
    if (technicianId == null) {
      throw Exception('User not authenticated');
    }

    try {
      final callable = FirebaseFunctionsService.instance
          .httpsCallable('getTechnicianPayoutHistory');
      
      final result = await callable.call({
        'technicianId': technicianId,
        'limit': limit,
      });

      final data = result.data as Map<String, dynamic>;
      final payouts = (data['payouts'] as List)
          .map((p) => _parsePayout(p))
          .toList();

      return payouts;
    } catch (e) {
      throw WalletException('Failed to fetch payout history: $e');
    }
  }

  /// Generate QR code for booking payment
  Future<QRPaymentResult> generateBookingQR(String bookingId) async {
    final technicianId = _technicianId;
    if (technicianId == null) {
      throw Exception('User not authenticated');
    }

    try {
      final callable = FirebaseFunctionsService.instance
          .httpsCallable('generateBookingQR');
      
      final result = await callable.call({
        'bookingId': bookingId,
      });

      return QRPaymentResult.fromMap(result.data);
    } catch (e) {
      throw WalletException('Failed to generate QR: $e');
    }
  }

  /// Generate QR code for technician wallet payments
  /// Customers can scan this to pay directly to wallet (10% platform fee)
  Future<QRPaymentResult> generateTechnicianWalletQR() async {
    final technicianId = _technicianId;
    if (technicianId == null) {
      throw Exception('User not authenticated');
    }

    try {
      final callable = FirebaseFunctionsService.instance
          .httpsCallable('generateTechnicianWalletQR');
      
      final result = await callable.call({});

      return QRPaymentResult.fromMap(result.data);
    } catch (e) {
      throw WalletException('Failed to generate wallet QR: $e');
    }
  }

  /// Get booking payment status
  Future<BookingPayment?> getBookingPayment(String bookingId) async {
    try {
      final doc = await _firestore
          .collection('bookings')
          .doc(bookingId)
          .collection('payment')
          .doc('qr')
          .get();

      if (!doc.exists) return null;
      return BookingPayment.fromFirestore(doc);
    } catch (e) {
      return null;
    }
  }

  /// Create Razorpay order for wallet credit
  Future<RazorpayOrderResult> createRazorpayOrder(double amount) async {
    try {
      final result = await _functionsService.createRazorpayOrder(
        amount: amount,
        notes: 'Wallet credit',
      );
      return RazorpayOrderResult.fromMap(result);
    } catch (e) {
      throw WalletException('Failed to create order: $e');
    }
  }

  /// Listen to wallet changes in real-time
  Stream<TechnicianWallet> watchWallet() {
    final technicianId = _technicianId;
    if (technicianId == null) {
      return Stream.error('User not authenticated');
    }

    return _firestore
        .collection('wallets')
        .doc(technicianId)
        .snapshots()
        .map((doc) => TechnicianWallet.fromFirestore(doc));
  }

  /// Listen to transaction changes
  Stream<List<WalletTransaction>> watchTransactions({int limit = 20}) {
    final technicianId = _technicianId;
    if (technicianId == null) {
      return Stream.error('User not authenticated');
    }

    return _firestore
        .collection('walletTransactions')
        .where('userId', isEqualTo: technicianId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => WalletTransaction.fromFirestore(doc))
            .toList());
  }

  WalletTransaction _parseTransaction(Map<String, dynamic> data) {
    // Convert Firestore timestamp
    final createdAt = data['createdAt'] != null
        ? DateTime.parse(data['createdAt'])
        : DateTime.now();
    
    return WalletTransaction(
      txnId: data['txnId'] ?? '',
      type: _parseTransactionType(data['type']),
      source: _parseTransactionSource(data['source']),
      status: _parseTransactionStatus(data['status']),
      amount: (data['amount'] ?? 0).toDouble(),
      fee: data['fee']?.toDouble(),
      referenceId: data['referenceId'],
      description: data['description'],
      createdAt: createdAt,
    );
  }

  TransactionType _parseTransactionType(String? type) {
    switch (type) {
      case 'credit':
        return TransactionType.credit;
      case 'debit':
        return TransactionType.debit;
      case 'payout':
        return TransactionType.payout;
      case 'hold':
        return TransactionType.hold;
      case 'release':
        return TransactionType.release;
      default:
        return TransactionType.credit;
    }
  }

  TransactionSource _parseTransactionSource(String? source) {
    switch (source) {
      case 'booking':
        return TransactionSource.booking;
      case 'withdrawal':
        return TransactionSource.withdrawal;
      case 'adjustment':
        return TransactionSource.adjustment;
      case 'refund':
        return TransactionSource.refund;
      case 'commission':
        return TransactionSource.commission;
      case 'bonus':
        return TransactionSource.bonus;
      default:
        return TransactionSource.booking;
    }
  }

  TransactionStatus _parseTransactionStatus(String? status) {
    switch (status) {
      case 'pending':
        return TransactionStatus.pending;
      case 'completed':
        return TransactionStatus.completed;
      case 'failed':
        return TransactionStatus.failed;
      default:
        return TransactionStatus.pending;
    }
  }

  TechnicianPayout _parsePayout(Map<String, dynamic> data) {
    return TechnicianPayout(
      id: data['payoutId'] ?? '',
      technicianId: data['technicianId'] ?? '',
      amount: (data['amount'] ?? 0).toDouble(),
      fee: (data['fee'] ?? 0).toDouble(),
      netAmount: (data['netAmount'] ?? 0).toDouble(),
      status: _parsePayoutStatus(data['status']),
      razorpayPayoutId: data['razorpayPayoutId'],
      failureReason: data['failureReason'],
      createdAt: data['createdAt'] != null
          ? DateTime.parse(data['createdAt'])
          : DateTime.now(),
      processedAt: data['processedAt'] != null
          ? DateTime.parse(data['processedAt'])
          : null,
    );
  }

  PayoutStatus _parsePayoutStatus(String? status) {
    switch (status) {
      case 'initiated':
        return PayoutStatus.initiated;
      case 'processing':
        return PayoutStatus.processing;
      case 'success':
        return PayoutStatus.success;
      case 'failed':
        return PayoutStatus.failed;
      case 'cancelled':
        return PayoutStatus.cancelled;
      default:
        return PayoutStatus.initiated;
    }
  }
}

/// Result class for withdrawal
class WithdrawalResult {
  final bool success;
  final String? payoutId;
  final String message;
  final bool alreadyCredited;

  WithdrawalResult({
    required this.success,
    this.payoutId,
    required this.message,
    this.alreadyCredited = false,
  });

  factory WithdrawalResult.fromMap(Map<String, dynamic> data) {
    return WithdrawalResult(
      success: data['success'] ?? false,
      payoutId: data['payoutId'],
      message: data['message'] ?? '',
      alreadyCredited: data['alreadyCredited'] ?? false,
    );
  }
}

/// Result class for QR generation
class QRPaymentResult {
  final bool success;
  final String? qrImageUrl;
  final String? qrId;
  final String? expiresAt;
  final String? error;

  QRPaymentResult({
    required this.success,
    this.qrImageUrl,
    this.qrId,
    this.expiresAt,
    this.error,
  });

  factory QRPaymentResult.fromMap(Map<String, dynamic> data) {
    return QRPaymentResult(
      success: data['success'] ?? false,
      qrImageUrl: data['qrImageUrl'],
      qrId: data['qrId'],
      expiresAt: data['expiresAt'],
      error: data['error'],
    );
  }

  DateTime? get expiresAtDateTime {
    if (expiresAt == null) return null;
    return DateTime.tryParse(expiresAt!);
  }
}

/// Result class for Razorpay order
class RazorpayOrderResult {
  final bool success;
  final String? orderId;
  final double? amount;
  final String? currency;
  final String? error;

  RazorpayOrderResult({
    required this.success,
    this.orderId,
    this.amount,
    this.currency,
    this.error,
  });

  factory RazorpayOrderResult.fromMap(Map<String, dynamic> data) {
    return RazorpayOrderResult(
      success: data['success'] ?? false,
      orderId: data['orderId'],
      amount: data['amount']?.toDouble(),
      currency: data['currency'],
      error: data['error'],
    );
  }
}

/// Custom exception for wallet errors
class WalletException implements Exception {
  final String message;
  
  WalletException(this.message);
  
  @override
  String toString() => message;
}

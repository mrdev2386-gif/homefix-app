import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../models/wallet_transaction.dart';

/// Customer Wallet Service - Secure Bridge to Cloud Functions
/// 
/// SECURITY: All wallet operations go through Cloud Functions
/// Client NEVER directly writes to wallet collections
class WalletService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  /// Get current customer ID
  String? get _customerId => _auth.currentUser?.uid;

  /// Get wallet balance as a stream for realtime updates
  Stream<double> watchBalance() {
    final customerId = _customerId;
    if (customerId == null) {
      return Stream.error('User not authenticated');
    }
    
    return _firestore
        .collection('customers')
        .doc(customerId)
        .snapshots()
        .map((doc) => (doc.data()?['walletBalance'] ?? 0.0).toDouble());
  }

  /// Get wallet balance once
  Future<double> getBalance() async {
    final customerId = _customerId;
    if (customerId == null) {
      throw Exception('User not authenticated');
    }
    
    final doc = await _firestore
        .collection('customers')
        .doc(customerId)
        .get();
    
    return (doc.data()?['walletBalance'] ?? 0.0).toDouble();
  }

  /// Watch wallet transactions in realtime
  Stream<List<WalletTransaction>> watchTransactions({int limit = 20}) {
    final customerId = _customerId;
    if (customerId == null) {
      return Stream.error('User not authenticated');
    }
    
    return _firestore
        .collection('customers')
        .doc(customerId)
        .collection('wallet_transactions')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => WalletTransaction.fromFirestore(doc))
            .toList());
  }

  /// Get transaction history with pagination
  Future<List<WalletTransaction>> getTransactionHistory({
    int limit = 20,
    String? startAfter,
  }) async {
    final customerId = _customerId;
    if (customerId == null) {
      throw Exception('User not authenticated');
    }

    try {
      // Try to use Cloud Function first
      final callable = FirebaseFunctions.instance
          .httpsCallable('getCustomerTransactionHistory');
      
      final result = await callable.call({
        'customerId': customerId,
        'limit': limit,
        if (startAfter != null) 'startAfter': startAfter,
      });

      final data = result.data as Map<String, dynamic>;
      final transactions = (data['transactions'] as List?)
          ?.map((t) => _parseTransaction(t))
          .toList() ?? [];

      return transactions;
    } catch (e) {
      // Fallback to direct Firestore query
      debugPrint('Using fallback transaction query: $e');
      return _getTransactionsFromFirestore(customerId, limit, startAfter);
    }
  }

  /// Fallback: Get transactions directly from Firestore
  Future<List<WalletTransaction>> _getTransactionsFromFirestore(
    String customerId,
    int limit,
    String? startAfter,
  ) async {
    QuerySnapshot snapshot;
    
    if (startAfter != null) {
      final startDoc = await _firestore
          .collection('customers')
          .doc(customerId)
          .collection('wallet_transactions')
          .doc(startAfter)
          .get();
      
      snapshot = await _firestore
          .collection('customers')
          .doc(customerId)
          .collection('wallet_transactions')
          .orderBy('createdAt', descending: true)
          .startAfterDocument(startDoc)
          .limit(limit)
          .get();
    } else {
      snapshot = await _firestore
          .collection('customers')
          .doc(customerId)
          .collection('wallet_transactions')
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();
    }
    
    return snapshot.docs
        .map((doc) => WalletTransaction.fromFirestore(doc))
        .toList();
  }

  WalletTransaction _parseTransaction(Map<String, dynamic> data) {
    final createdAt = data['createdAt'] != null
        ? DateTime.parse(data['createdAt'])
        : DateTime.now();
    
    return WalletTransaction(
      txnId: data['txnId'] ?? '',
      type: data['type'] ?? 'credit',
      amount: (data['amount'] ?? 0).toDouble(),
      reason: data['reason'] ?? '',
      relatedBookingId: data['relatedBookingId'],
      createdAt: createdAt,
    );
  }

  /// Add wallet money (via referral/bonus) - called from Cloud Functions
  /// WARNING: Client should NEVER call this directly
  Future<Map<String, dynamic>> addWalletMoney({
    required double amount,
    required String reason,
    String? relatedBookingId,
  }) async {
    final customerId = _customerId;
    if (customerId == null) {
      throw Exception('User not authenticated');
    }

    try {
      final callable = FirebaseFunctions.instance
          .httpsCallable('addWalletMoney');
      
      final result = await callable.call({
        'customerId': customerId,
        'amount': amount,
        'reason': reason,
        if (relatedBookingId != null) 'relatedBookingId': relatedBookingId,
      });

      return result.data as Map<String, dynamic>;
    } catch (e) {
      throw WalletException('Failed to add wallet money: $e');
    }
  }

  /// Use wallet balance for payment
  Future<Map<String, dynamic>> useWalletForPayment({
    required String bookingId,
    required double amount,
  }) async {
    final customerId = _customerId;
    if (customerId == null) {
      throw Exception('User not authenticated');
    }

    // First check if customer has sufficient balance
    final balance = await getBalance();
    if (balance < amount) {
      throw WalletException('Insufficient wallet balance');
    }

    try {
      final callable = FirebaseFunctions.instance
          .httpsCallable('useWalletForPayment');
      
      final result = await callable.call({
        'customerId': customerId,
        'bookingId': bookingId,
        'amount': amount,
      });

      return result.data as Map<String, dynamic>;
    } catch (e) {
      throw WalletException('Failed to use wallet balance: $e');
    }
  }
}

/// Custom exception for wallet errors
class WalletException implements Exception {
  final String message;
  
  WalletException(this.message);
  
  @override
  String toString() => message;
}

// Debug print helper
void debugPrint(String message) {
  assert(() {
    print('[WalletService] $message');
    return true;
  }());
}


import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/wallet_transaction.dart';

class WalletService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get uid => _auth.currentUser?.uid;

  /// Watch real-time balance from root wallets collection
  Stream<double> watchBalance() {
    if (uid == null) return Stream.value(0.0);
    return _db.collection('wallets').doc(uid).snapshots().map((doc) {
      if (!doc.exists) return 0.0;
      return (doc.data()?['balance'] ?? 0.0).toDouble();
    });
  }

  /// Get current balance once
  Future<double> getBalance() async {
    if (uid == null) return 0.0;
    final doc = await _db.collection('wallets').doc(uid).get();
    if (!doc.exists) return 0.0;
    return (doc.data()?['balance'] ?? 0.0).toDouble();
  }

  /// Watch transaction history from root walletTransactions
  Stream<List<WalletTransaction>> watchTransactions({int limit = 20}) {
    if (uid == null) return Stream.value([]);
    return _db
        .collection('walletTransactions')
        .where('userId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => WalletTransaction.fromFirestore(doc))
            .toList());
  }

  /// Get transaction history once (for pagination)
  Future<List<WalletTransaction>> getTransactionHistory({int limit = 20, String? startAfter}) async {
    if (uid == null) return [];
    
    Query query = _db
        .collection('walletTransactions')
        .where('userId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .limit(limit);

    if (startAfter != null) {
      final lastDoc = await _db.collection('walletTransactions').doc(startAfter).get();
      if (lastDoc.exists) {
        query = query.startAfterDocument(lastDoc);
      }
    }

    final snapshot = await query.get();
    return snapshot.docs.map((doc) => WalletTransaction.fromFirestore(doc)).toList();
  }
}

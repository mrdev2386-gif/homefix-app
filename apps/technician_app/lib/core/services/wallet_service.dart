
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/wallet.dart';
import '../models/earning.dart';
import '../models/payout.dart';

class WalletService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<TechnicianWallet> getWallet(String techId) {
    return _db
        .collection('technicians')
        .doc(techId)
        .collection('wallet')
        .doc('main')
        .snapshots()
        .map((doc) => TechnicianWallet.fromFirestore(doc));
  }

  Stream<List<TechnicianEarning>> getEarnings(String techId) {
    return _db
        .collection('technicians')
        .doc(techId)
        .collection('earnings')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => TechnicianEarning.fromFirestore(doc))
            .toList());
  }

  Stream<List<TechnicianPayout>> getPayouts(String techId) {
    return _db
        .collection('payouts')
        .where('technicianId', '==', techId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => TechnicianPayout.fromFirestore(doc))
            .toList());
  }
}

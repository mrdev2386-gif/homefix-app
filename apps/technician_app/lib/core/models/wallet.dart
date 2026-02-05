
import 'package:cloud_firestore/cloud_firestore.dart';

class TechnicianWallet {
  final double availableBalance;
  final double pendingBalance;
  final double lifetimeEarnings;
  final DateTime? lastPayoutAt;
  final DateTime updatedAt;

  TechnicianWallet({
    required this.availableBalance,
    required this.pendingBalance,
    required this.lifetimeEarnings,
    this.lastPayoutAt,
    required this.updatedAt,
  });

  factory TechnicianWallet.fromFirestore(DocumentSnapshot doc) {
    if (!doc.exists) {
        return TechnicianWallet(
            availableBalance: 0,
            pendingBalance: 0,
            lifetimeEarnings: 0,
            updatedAt: DateTime.now(),
        );
    }
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return TechnicianWallet(
      availableBalance: (data['availableBalance'] ?? 0.0).toDouble(),
      pendingBalance: (data['pendingBalance'] ?? 0.0).toDouble(),
      lifetimeEarnings: (data['lifetimeEarnings'] ?? 0.0).toDouble(),
      lastPayoutAt: data['lastPayoutAt'] != null 
          ? (data['lastPayoutAt'] as Timestamp).toDate() 
          : null,
      updatedAt: data['updatedAt'] != null 
          ? (data['updatedAt'] as Timestamp).toDate() 
          : DateTime.now(),
    );
  }
}

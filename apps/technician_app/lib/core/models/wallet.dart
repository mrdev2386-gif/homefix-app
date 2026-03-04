import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/firestore_safe_parser.dart';

/// Enhanced Technician Wallet Model - Production Safe
/// 
/// Firestore Collection: technician_wallets/{techId}
/// 
/// SECURITY: Client NEVER writes wallet balance directly
/// All balance updates MUST go through Cloud Functions
class TechnicianWallet {
  final String technicianId;
  final double availableBalance;  // Can be withdrawn immediately
  final double pendingBalance;   // Waiting for admin approval
  final double onHoldBalance;    // Under dispute/verification
  final double lifetimeEarnings;  // Total earned (for display only)
  final DateTime? lastPayoutAt;
  final DateTime updatedAt;
  final String? kycStatus;       // verified, pending, rejected
  final String? bankAccountId;  // Linked bank account for payouts

  TechnicianWallet({
    required this.technicianId,
    required this.availableBalance,
    required this.pendingBalance,
    required this.onHoldBalance,
    required this.lifetimeEarnings,
    this.lastPayoutAt,
    required this.updatedAt,
    this.kycStatus,
    this.bankAccountId,
  });

  /// Create empty wallet for new technicians
  factory TechnicianWallet.empty(String technicianId) {
    return TechnicianWallet(
      technicianId: technicianId,
      availableBalance: 0.0,
      pendingBalance: 0.0,
      onHoldBalance: 0.0,
      lifetimeEarnings: 0.0,
      updatedAt: DateTime.now(),
      kycStatus: 'pending',
    );
  }

  factory TechnicianWallet.fromFirestore(DocumentSnapshot doc) {
    if (!doc.exists) {
      return TechnicianWallet.empty(doc.id);
    }
    final data = FirestoreSafeParser.toSafeMap(doc.data());
    return TechnicianWallet(
      technicianId: doc.id,
      availableBalance: FirestoreSafeParser.toSafeDouble(data['availableBalance']),
      pendingBalance: FirestoreSafeParser.toSafeDouble(data['pendingBalance']),
      onHoldBalance: FirestoreSafeParser.toSafeDouble(data['onHoldBalance']),
      lifetimeEarnings: FirestoreSafeParser.toSafeDouble(data['lifetimeEarnings']),
      lastPayoutAt: data['lastPayoutAt'] != null 
          ? FirestoreSafeParser.toSafeDateTime(data['lastPayoutAt']) 
          : null,
      updatedAt: FirestoreSafeParser.toSafeDateTime(data['updatedAt']),
      kycStatus: FirestoreSafeParser.toSafeString(data['kycStatus'], fallback: 'pending'),
      bankAccountId: data['bankAccountId'],
    );
  }

  /// Convert to Firestore map (for Cloud Functions only)
  /// WARNING: Never expose write access to client
  Map<String, dynamic> toMap() {
    return {
      'availableBalance': availableBalance,
      'pendingBalance': pendingBalance,
      'onHoldBalance': onHoldBalance,
      'lifetimeEarnings': lifetimeEarnings,
      'lastPayoutAt': lastPayoutAt != null ? Timestamp.fromDate(lastPayoutAt!) : null,
      'updatedAt': Timestamp.fromDate(updatedAt),
      'kycStatus': kycStatus,
      'bankAccountId': bankAccountId,
    };
  }

  /// Get total balance (available + pending)
  double get totalBalance => availableBalance + pendingBalance;

  /// Check if technician can withdraw
  bool get canWithdraw => 
      kycStatus == 'verified' && 
      availableBalance > 0 &&
      bankAccountId != null;

  /// Check if KYC is pending
  bool get isKycPending => kycStatus == 'pending';

  /// Check if KYC is verified
  bool get isKycVerified => kycStatus == 'verified';
}

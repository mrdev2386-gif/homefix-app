import 'package:cloud_firestore/cloud_firestore.dart';

/// Bank Account Status Enum
enum BankAccountStatus {
  pending,
  verified,
  rejected,
  dormant,
}

/// Technician Bank Account Model
/// 
/// Firestore Collection: technician_bank_accounts/{accountId}
/// 
/// SECURITY:
/// - Bank details stored with encryption in production
/// - Only verified accounts can receive payouts
/// - Account numbers masked in UI
class TechnicianBankAccount {
  final String id;
  final String technicianId;
  final String bankName;
  final String accountNumber;      // In production, encrypt this
  final String ifscCode;
  final String? branchName;
  final String accountHolderName;
  final BankAccountStatus status;
  final DateTime createdAt;
  final DateTime? verifiedAt;
  final String? verifiedBy;
  final String? rejectionReason;
  
  // For payout tracking
  final String? razorpayFundAccountId;

  TechnicianBankAccount({
    required this.id,
    required this.technicianId,
    required this.bankName,
    required this.accountNumber,
    required this.ifscCode,
    this.branchName,
    required this.accountHolderName,
    required this.status,
    required this.createdAt,
    this.verifiedAt,
    this.verifiedBy,
    this.rejectionReason,
    this.razorpayFundAccountId,
  });

  factory TechnicianBankAccount.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return TechnicianBankAccount(
      id: doc.id,
      technicianId: data['technicianId'] ?? '',
      bankName: data['bankName'] ?? '',
      accountNumber: data['accountNumber'] ?? '',
      ifscCode: data['ifscCode'] ?? '',
      branchName: data['branchName'],
      accountHolderName: data['accountHolderName'] ?? '',
      status: _parseBankAccountStatus(data['status']),
      createdAt: data['createdAt'] != null 
          ? (data['createdAt'] as Timestamp).toDate() 
          : DateTime.now(),
      verifiedAt: data['verifiedAt'] != null 
          ? (data['verifiedAt'] as Timestamp).toDate() 
          : null,
      verifiedBy: data['verifiedBy'],
      rejectionReason: data['rejectionReason'],
      razorpayFundAccountId: data['razorpayFundAccountId'],
    );
  }

  /// Convert to Firestore map
  Map<String, dynamic> toMap() {
    return {
      'technicianId': technicianId,
      'bankName': bankName,
      'accountNumber': accountNumber,
      'ifscCode': ifscCode,
      'branchName': branchName,
      'accountHolderName': accountHolderName,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'verifiedAt': verifiedAt != null ? Timestamp.fromDate(verifiedAt!) : null,
      'verifiedBy': verifiedBy,
      'rejectionReason': rejectionReason,
      'razorpayFundAccountId': razorpayFundAccountId,
    };
  }

  /// Check if account is verified for payouts
  bool get isVerified => status == BankAccountStatus.verified;

  /// Get masked account number for display
  String get maskedAccountNumber {
    if (accountNumber.length < 4) return '****';
    return '****${accountNumber.substring(accountNumber.length - 4)}';
  }

  /// Get masked IFSC code
  String get maskedIfsc {
    if (ifscCode.length < 4) return '****';
    return '${ifscCode.substring(0, 3)}****${ifscCode.substring(ifscCode.length - 2)}';
  }

  static BankAccountStatus _parseBankAccountStatus(String? status) {
    switch (status) {
      case 'pending':
        return BankAccountStatus.pending;
      case 'verified':
        return BankAccountStatus.verified;
      case 'rejected':
        return BankAccountStatus.rejected;
      case 'dormant':
        return BankAccountStatus.dormant;
      default:
        return BankAccountStatus.pending;
    }
  }
}

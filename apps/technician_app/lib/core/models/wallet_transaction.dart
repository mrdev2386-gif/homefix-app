import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/firestore_safe_parser.dart';

/// Transaction Type Enum
enum TransactionType {
  credit,
  debit,
  payout,
  hold,
  release,
}

/// Transaction Source Enum
enum TransactionSource {
  booking,       // Payment from customer booking
  withdrawal,    // Payout to bank account
  adjustment,    // Admin adjustment
  refund,        // Customer refund
  commission,    // Platform commission
  bonus,         // Incentive/bonus
}

/// Transaction Status Enum
enum TransactionStatus {
  pending,
  completed,
  failed,
}

/// Enhanced Wallet Transaction Model - Append-Only & Audit Safe
/// 
/// Firestore Collection: technician_wallets/{techId}/transactions/{txnId}
/// 
/// SECURITY: 
/// - Append-only (no updates allowed)
/// - Immutable once created
/// - Full audit trail with metadata
class WalletTransaction {
  final String txnId;
  final TransactionType type;
  final TransactionSource source;
  final TransactionStatus status;
  final double amount;
  final double? fee;              // Transaction fee if any
  final String? referenceId;     // bookingId or payoutId
  final String? description;
  final DateTime createdAt;
  
  // Audit fields
  final String? createdBy;       // UID of who created (cloud function)
  final String? ipAddress;       // IP for audit
  final String? idempotencyKey;  // Prevent duplicate transactions

  WalletTransaction({
    required this.txnId,
    required this.type,
    required this.source,
    required this.status,
    required this.amount,
    this.fee,
    this.referenceId,
    this.description,
    required this.createdAt,
    this.createdBy,
    this.ipAddress,
    this.idempotencyKey,
  });

  factory WalletTransaction.fromFirestore(DocumentSnapshot doc) {
    final data = FirestoreSafeParser.toSafeMap(doc.data());
    return WalletTransaction(
      txnId: doc.id,
      type: _parseTransactionType(data['type']),
      source: _parseTransactionSource(data['source']),
      status: _parseTransactionStatus(data['status']),
      amount: FirestoreSafeParser.toSafeDouble(data['amount']),
      fee: data['fee'] != null ? FirestoreSafeParser.toSafeDouble(data['fee']) : null,
      referenceId: data['referenceId'],
      description: data['description'],
      createdAt: FirestoreSafeParser.toSafeDateTime(data['createdAt']),
      createdBy: data['createdBy'],
      ipAddress: data['ipAddress'],
      idempotencyKey: data['idempotencyKey'],
    );
  }

  /// Convert to Firestore map (for Cloud Functions only)
  /// WARNING: Never expose write access to client
  Map<String, dynamic> toMap() {
    return {
      'type': type.name,
      'source': source.name,
      'status': status.name,
      'amount': amount,
      'fee': fee,
      'referenceId': referenceId,
      'description': description,
      'createdAt': Timestamp.fromDate(createdAt),
      'createdBy': createdBy,
      'ipAddress': ipAddress,
      'idempotencyKey': idempotencyKey,
    };
  }

  /// Check if this is a credit transaction
  bool get isCredit => type == TransactionType.credit;

  /// Check if this is a payout transaction
  bool get isPayout => type == TransactionType.payout;

  /// Check if this is completed
  bool get isCompleted => status == TransactionStatus.completed;

  /// Check if this is pending
  bool get isPending => status == TransactionStatus.pending;

  /// Get display type string
  String get displayType {
    switch (type) {
      case TransactionType.credit:
        return 'Credit';
      case TransactionType.debit:
        return 'Debit';
      case TransactionType.payout:
        return 'Payout';
      case TransactionType.hold:
        return 'On Hold';
      case TransactionType.release:
        return 'Released';
    }
  }

  /// Get display source string
  String get displaySource {
    switch (source) {
      case TransactionSource.booking:
        return 'Booking';
      case TransactionSource.withdrawal:
        return 'Withdrawal';
      case TransactionSource.adjustment:
        return 'Adjustment';
      case TransactionSource.refund:
        return 'Refund';
      case TransactionSource.commission:
        return 'Commission';
      case TransactionSource.bonus:
        return 'Bonus';
    }
  }

  /// Get display status string
  String get displayStatus {
    switch (status) {
      case TransactionStatus.pending:
        return 'Pending';
      case TransactionStatus.completed:
        return 'Completed';
      case TransactionStatus.failed:
        return 'Failed';
    }
  }

  static TransactionType _parseTransactionType(String? type) {
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

  static TransactionSource _parseTransactionSource(String? source) {
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

  static TransactionStatus _parseTransactionStatus(String? status) {
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
}

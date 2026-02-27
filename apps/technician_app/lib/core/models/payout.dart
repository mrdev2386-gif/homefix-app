import 'package:cloud_firestore/cloud_firestore.dart';

/// Payout Status Enum
enum PayoutStatus {
  initiated,
  processing,
  success,
  failed,
  cancelled,
}

/// Technician Payout Model - Idempotent & Audit Safe
/// 
/// Firestore Collection: technician_payouts/{payoutId}
/// 
/// SECURITY:
/// - Idempotency key prevents duplicate payouts
/// - Status updates only via Cloud Functions
/// - Full audit trail
class TechnicianPayout {
  final String id;
  final String technicianId;
  final double amount;
  final double fee;              // Payout fee deducted
  final double netAmount;        // Amount received by technician
  final PayoutStatus status;
  final String? razorpayPayoutId;
  final String? razorpayBatchId;
  final String? failureReason;
  final String? bankAccountId;
  final String? bankName;
  final String? bankAccountNumber; // Masked
  final String? ifscCode;         // Masked
  final DateTime createdAt;
  final DateTime? processedAt;
  
  // Idempotency
  final String? idempotencyKey;
  
  // Audit
  final String? processedBy;     // Cloud function name
  final int retryCount;

  TechnicianPayout({
    required this.id,
    required this.technicianId,
    required this.amount,
    required this.fee,
    required this.netAmount,
    required this.status,
    this.razorpayPayoutId,
    this.razorpayBatchId,
    this.failureReason,
    this.bankAccountId,
    this.bankName,
    this.bankAccountNumber,
    this.ifscCode,
    required this.createdAt,
    this.processedAt,
    this.idempotencyKey,
    this.processedBy,
    this.retryCount = 0,
  });

  factory TechnicianPayout.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return TechnicianPayout(
      id: doc.id,
      technicianId: data['technicianId'] ?? '',
      amount: (data['amount'] ?? 0.0).toDouble(),
      fee: (data['fee'] ?? 0.0).toDouble(),
      netAmount: (data['netAmount'] ?? 0.0).toDouble(),
      status: _parsePayoutStatus(data['status']),
      razorpayPayoutId: data['razorpayPayoutId'],
      razorpayBatchId: data['razorpayBatchId'],
      failureReason: data['failureReason'],
      bankAccountId: data['bankAccountId'],
      bankName: data['bankName'],
      bankAccountNumber: data['bankAccountNumber'],
      ifscCode: data['ifscCode'],
      createdAt: data['createdAt'] != null 
          ? (data['createdAt'] as Timestamp).toDate() 
          : DateTime.now(),
      processedAt: data['processedAt'] != null 
          ? (data['processedAt'] as Timestamp).toDate() 
          : null,
      idempotencyKey: data['idempotencyKey'],
      processedBy: data['processedBy'],
      retryCount: data['retryCount'] ?? 0,
    );
  }

  /// Convert to Firestore map (for Cloud Functions only)
  Map<String, dynamic> toMap() {
    return {
      'technicianId': technicianId,
      'amount': amount,
      'fee': fee,
      'netAmount': netAmount,
      'status': status.name,
      'razorpayPayoutId': razorpayPayoutId,
      'razorpayBatchId': razorpayBatchId,
      'failureReason': failureReason,
      'bankAccountId': bankAccountId,
      'bankName': bankName,
      'bankAccountNumber': bankAccountNumber,
      'ifscCode': ifscCode,
      'createdAt': Timestamp.fromDate(createdAt),
      'processedAt': processedAt != null ? Timestamp.fromDate(processedAt!) : null,
      'idempotencyKey': idempotencyKey,
      'processedBy': processedBy,
      'retryCount': retryCount,
    };
  }

  /// Check if payout is successful
  bool get isSuccess => status == PayoutStatus.success;

  /// Check if payout is failed
  bool get isFailed => status == PayoutStatus.failed;

  /// Check if payout is pending/processing
  bool get isPending => 
      status == PayoutStatus.initiated || 
      status == PayoutStatus.processing;

  /// Get display status string
  String get displayStatus {
    switch (status) {
      case PayoutStatus.initiated:
        return 'Initiated';
      case PayoutStatus.processing:
        return 'Processing';
      case PayoutStatus.success:
        return 'Success';
      case PayoutStatus.failed:
        return 'Failed';
      case PayoutStatus.cancelled:
        return 'Cancelled';
    }
  }

  /// Get masked bank account for display
  String get maskedAccount {
    if (bankAccountNumber == null || bankAccountNumber!.length < 4) {
      return '****';
    }
    return '****${bankAccountNumber!.substring(bankAccountNumber!.length - 4)}';
  }

  static PayoutStatus _parsePayoutStatus(String? status) {
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

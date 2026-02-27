import 'package:cloud_firestore/cloud_firestore.dart';

/// QR Payment Status Enum
enum QRPaymentStatus {
  pending,
  generated,
  scanned,
  paid,
  failed,
  expired,
  refunded,
}

/// Booking QR Payment Model
/// 
/// Firestore Collection: bookings/{bookingId}/payment
/// 
/// SECURITY:
/// - QR is generated server-side only
/// - Payment status updated via webhook only
/// - Technician cannot fake payment status
class BookingPayment {
  final String bookingId;
  final String technicianId;
  final double amount;
  final QRPaymentStatus status;
  final String? qrId;             // Razorpay QR ID
  final String? qrImageUrl;       // Generated QR image URL
  final String? paymentId;        // Razorpay payment ID after success
  final String? razorpayOrderId;
  final DateTime createdAt;
  final DateTime? paidAt;
  final DateTime? expiresAt;
  final String? failureReason;
  
  // Customer info for audit
  final String? customerId;
  final String? customerPhone;

  BookingPayment({
    required this.bookingId,
    required this.technicianId,
    required this.amount,
    required this.status,
    this.qrId,
    this.qrImageUrl,
    this.paymentId,
    this.razorpayOrderId,
    required this.createdAt,
    this.paidAt,
    this.expiresAt,
    this.failureReason,
    this.customerId,
    this.customerPhone,
  });

  factory BookingPayment.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return BookingPayment(
      bookingId: doc.id,
      technicianId: data['technicianId'] ?? '',
      amount: (data['amount'] ?? 0.0).toDouble(),
      status: _parseQRPaymentStatus(data['status']),
      qrId: data['qrId'],
      qrImageUrl: data['qrImageUrl'],
      paymentId: data['paymentId'],
      razorpayOrderId: data['razorpayOrderId'],
      createdAt: data['createdAt'] != null 
          ? (data['createdAt'] as Timestamp).toDate() 
          : DateTime.now(),
      paidAt: data['paidAt'] != null 
          ? (data['paidAt'] as Timestamp).toDate() 
          : null,
      expiresAt: data['expiresAt'] != null 
          ? (data['expiresAt'] as Timestamp).toDate() 
          : null,
      failureReason: data['failureReason'],
      customerId: data['customerId'],
      customerPhone: data['customerPhone'],
    );
  }

  /// Convert to Firestore map
  Map<String, dynamic> toMap() {
    return {
      'technicianId': technicianId,
      'amount': amount,
      'status': status.name,
      'qrId': qrId,
      'qrImageUrl': qrImageUrl,
      'paymentId': paymentId,
      'razorpayOrderId': razorpayOrderId,
      'createdAt': Timestamp.fromDate(createdAt),
      'paidAt': paidAt != null ? Timestamp.fromDate(paidAt!) : null,
      'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
      'failureReason': failureReason,
      'customerId': customerId,
      'customerPhone': customerPhone,
    };
  }

  /// Check if payment is successful
  bool get isPaid => status == QRPaymentStatus.paid;

  /// Check if payment is pending
  bool get isPending => status == QRPaymentStatus.pending || status == QRPaymentStatus.generated;

  /// Check if QR has expired
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  /// Get display status string
  String get displayStatus {
    switch (status) {
      case QRPaymentStatus.pending:
        return 'Pending';
      case QRPaymentStatus.generated:
        return 'QR Generated';
      case QRPaymentStatus.scanned:
        return 'Scanned';
      case QRPaymentStatus.paid:
        return 'Paid';
      case QRPaymentStatus.failed:
        return 'Failed';
      case QRPaymentStatus.expired:
        return 'Expired';
      case QRPaymentStatus.refunded:
        return 'Refunded';
    }
  }

  static QRPaymentStatus _parseQRPaymentStatus(String? status) {
    switch (status) {
      case 'pending':
        return QRPaymentStatus.pending;
      case 'generated':
        return QRPaymentStatus.generated;
      case 'scanned':
        return QRPaymentStatus.scanned;
      case 'paid':
        return QRPaymentStatus.paid;
      case 'failed':
        return QRPaymentStatus.failed;
      case 'expired':
        return QRPaymentStatus.expired;
      case 'refunded':
        return QRPaymentStatus.refunded;
      default:
        return QRPaymentStatus.pending;
    }
  }
}

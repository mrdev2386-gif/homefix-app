import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/firestore_safe_parser.dart';

class Booking {
  final String bookingId;
  final String customerId;
  final String customerName;
  final String serviceId;
  final String serviceTitle;
  final String? serviceImage;
  final String? problemDescription;
  final String? assignedTechnicianId;
  final String? assignedTechnicianName;
  final String slotId;
  final DateTime scheduledAt;
  final String scheduledTime;
  final String status;
  final String paymentStatus;
  final String? paymentMode; // 'pay_before_work' or 'pay_after_work'
  final double price;
  final double finalAmount;
  final Map<String, dynamic> addressSnapshot;
  final String? category;
  final String? description;
  final DateTime createdAt;
  final Map<String, dynamic>? quoteData;

  String get id => bookingId;

  Booking({
    required this.bookingId,
    required this.customerId,
    required this.customerName,
    required this.serviceId,
    required this.serviceTitle,
    this.serviceImage,
    this.problemDescription,
    this.assignedTechnicianId,
    this.assignedTechnicianName,
    required this.slotId,
    required this.scheduledAt,
    required this.scheduledTime,
    required this.status,
    this.paymentStatus = 'unpaid',
    this.paymentMode,
    required this.price,
    required this.finalAmount,
    required this.addressSnapshot,
    this.category,
    this.description,
    required this.createdAt,
    this.quoteData,
  });

  factory Booking.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Booking(
      bookingId: data['bookingId'] ?? doc.id,
      customerId: data['customerId'] ?? '',
      customerName: data['customerName'] ?? 'Customer',
      serviceId: data['serviceId'] ?? '',
      serviceTitle: data['serviceTitle'] ?? data['serviceName'] ?? '',
      serviceImage: data['serviceImage'],
      problemDescription: data['problemDescription'] ?? data['description'],
      assignedTechnicianId: data['technicianId'] ?? data['assignedTechnicianId'],
      assignedTechnicianName: data['technicianName'] ?? data['assignedTechnicianName'],
      slotId: data['slotId'] ?? '',
      scheduledAt: data['scheduledAt'] != null 
          ? (data['scheduledAt'] as Timestamp).toDate() 
          : (data['scheduledDate'] != null ? (data['scheduledDate'] as Timestamp).toDate() : DateTime.now()),
      scheduledTime: data['scheduledTime'] ?? '',
      status: FirestoreSafeParser.toSafeString(data['status'] ?? data['bookingStatus'], fallback: 'pending'),
      paymentStatus: FirestoreSafeParser.toSafeString(data['paymentStatus'], fallback: 'unpaid'),
      paymentMode: data['paymentMode']?.toString(),
      price: FirestoreSafeParser.toSafeDouble(data['price']),
      finalAmount: FirestoreSafeParser.toSafeDouble(data['finalAmount'] ?? data['price']),
      addressSnapshot: FirestoreSafeParser.toSafeMap(data['addressSnapshot'] ?? data['address']),
      category: data['category']?.toString(),
      description: data['description']?.toString(),
      createdAt: data['createdAt'] != null ? (data['createdAt'] as Timestamp).toDate() : DateTime.now(),
      quoteData: data['quoteData'] != null ? Map<String, dynamic>.from(data['quoteData']) : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'bookingId': bookingId,
      'customerId': customerId,
      'customerName': customerName,
      'serviceId': serviceId,
      'serviceTitle': serviceTitle,
      'serviceImage': serviceImage,
      'problemDescription': problemDescription,
      'technicianId': assignedTechnicianId,
      'technicianName': assignedTechnicianName,
      'slotId': slotId,
      'scheduledAt': Timestamp.fromDate(scheduledAt),
      'scheduledTime': scheduledTime,
      'status': status,
      'paymentStatus': paymentStatus,
      'paymentMode': paymentMode,
      'price': price,
      'finalAmount': finalAmount,
      'addressSnapshot': addressSnapshot,
      'category': category,
      'description': description,
      'createdAt': Timestamp.fromDate(createdAt),
      'quoteData': quoteData,
    };
  }
}

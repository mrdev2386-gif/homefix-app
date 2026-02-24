import 'package:cloud_firestore/cloud_firestore.dart';

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
  final double price;
  final double finalAmount;
  final Map<String, dynamic> addressSnapshot;
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
    required this.price,
    required this.finalAmount,
    required this.addressSnapshot,
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
      serviceTitle: data['serviceTitle'] ?? '',
      serviceImage: data['serviceImage'],
      problemDescription: data['problemDescription'],
      assignedTechnicianId: data['assignedTechnicianId'],
      assignedTechnicianName: data['assignedTechnicianName'],
      slotId: data['slotId'] ?? '',
      scheduledAt: data['scheduledAt'] != null 
          ? (data['scheduledAt'] as Timestamp).toDate() 
          : (data['scheduledDate'] != null ? (data['scheduledDate'] as Timestamp).toDate() : DateTime.now()),
      scheduledTime: data['scheduledTime'] ?? '',
      status: data['status'] ?? 'pending',
      price: (data['price'] ?? 0.0).toDouble(),
      finalAmount: (data['finalAmount'] ?? 0.0).toDouble(),
      addressSnapshot: Map<String, dynamic>.from(data['addressSnapshot'] ?? data['address'] ?? {}),
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
      'assignedTechnicianId': assignedTechnicianId,
      'assignedTechnicianName': assignedTechnicianName,
      'slotId': slotId,
      'scheduledAt': Timestamp.fromDate(scheduledAt),
      'scheduledTime': scheduledTime,
      'status': status,
      'price': price,
      'finalAmount': finalAmount,
      'addressSnapshot': addressSnapshot,
      'createdAt': Timestamp.fromDate(createdAt),
      'quoteData': quoteData,
    };
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';

class Booking {
  final String id;
  final String customerId;
  final String? customerName;
  final String? technicianId;
  final String? technicianName;
  final List<Map<String, dynamic>> services;
  final String? serviceId;
  final String serviceTitle;
  final DateTime scheduledAt;
  final DateTime? scheduledDate;
  final String? scheduledTime;
  final Map<String, dynamic> addressSnapshot;
  final String status;
  final String paymentStatus;
  final String? razorpayOrderId;
  final bool isRated;
  final String? ratingId;
  final double price;
  final String? couponCode;
  final double discountAmount;
  final double finalAmount;
  final DateTime createdAt;
  final DateTime updatedAt;

  Booking({
    required this.id,
    required this.customerId,
    this.customerName,
    this.technicianId,
    this.technicianName,
    required this.services,
    this.serviceId,
    required this.serviceTitle,
    required this.scheduledAt,
    this.scheduledDate,
    this.scheduledTime,
    required this.addressSnapshot,
    required this.status,
    this.paymentStatus = 'pending',
    this.razorpayOrderId,
    this.isRated = false,
    this.ratingId,
    required this.price,
    this.couponCode,
    this.discountAmount = 0.0,
    required this.finalAmount,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Booking.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final servicesList = List<Map<String, dynamic>>.from(data['services'] ?? []);
    
    return Booking(
      id: doc.id,
      customerId: (data['customerId'] ?? '').toString(),
      customerName: data['customerName']?.toString(),
      technicianId: (data['assignedTechnicianId'] ?? data['technicianId'])?.toString(),
      technicianName: (data['assignedTechnicianName'] ?? data['technicianName'])?.toString(),
      services: servicesList,
      serviceId: (data['serviceId'] ?? data['serviceKey'] ?? (servicesList.isNotEmpty ? servicesList[0]['id'] : '')).toString(),
      serviceTitle: (data['serviceTitle'] ?? data['serviceName'] ?? (servicesList.isNotEmpty ? servicesList[0]['name'] : 'Service')).toString(),
      scheduledAt: data['scheduledAt'] is Timestamp 
          ? (data['scheduledAt'] as Timestamp).toDate() 
          : DateTime.now(),
      scheduledDate: data['scheduledDate'] is Timestamp 
          ? (data['scheduledDate'] as Timestamp).toDate() 
          : null,
      scheduledTime: data['scheduledTime']?.toString(),
      addressSnapshot: Map<String, dynamic>.from(data['addressSnapshot'] ?? {}),
      status: (data['status'] ?? 'pending').toString(),
      paymentStatus: (data['paymentStatus'] ?? 'pending').toString(),
      razorpayOrderId: data['razorpayOrderId']?.toString(),
      isRated: data['isRated'] ?? false,
      ratingId: data['ratingId']?.toString(),
      price: double.tryParse((data['price'] ?? data['totalAmount'] ?? 0.0).toString()) ?? 0.0,
      couponCode: data['couponCode']?.toString(),
      discountAmount: double.tryParse((data['discountAmount'] ?? 0.0).toString()) ?? 0.0,
      finalAmount: double.tryParse((data['finalAmount'] ?? 0.0).toString()) ?? 0.0,
      createdAt: data['createdAt'] is Timestamp 
          ? (data['createdAt'] as Timestamp).toDate() 
          : DateTime.now(),
      updatedAt: data['updatedAt'] is Timestamp 
          ? (data['updatedAt'] as Timestamp).toDate() 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'customerId': customerId,
      'customerName': customerName,
      'assignedTechnicianId': technicianId,
      'assignedTechnicianName': technicianName,
      'services': services,
      'serviceId': serviceId,
      'serviceTitle': serviceTitle,
      'scheduledAt': Timestamp.fromDate(scheduledAt),
      'scheduledDate': scheduledDate != null ? Timestamp.fromDate(scheduledDate!) : null,
      'scheduledTime': scheduledTime,
      'addressSnapshot': addressSnapshot,
      'status': status,
      'paymentStatus': paymentStatus,
      'razorpayOrderId': razorpayOrderId,
      'isRated': isRated,
      'ratingId': ratingId,
      'price': price,
      'couponCode': couponCode,
      'discountAmount': discountAmount,
      'finalAmount': finalAmount,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}

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
  final String bookingStatus;
  final List<Map<String, dynamic>>? statusHistory;
  final String paymentStatus;
  final String? paymentMode; // 'pay_before_work' or 'pay_after_work'
  final String? razorpayOrderId;
  final bool isRated;
  final String? ratingId;
  final double price;
  final String? couponCode;
  final double discountAmount;
  final double finalAmount;
  final String? description;
  final String? category;
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
    required this.bookingStatus,
    this.statusHistory,
    this.paymentStatus = 'pending',
    this.paymentMode,
    this.razorpayOrderId,
    this.isRated = false,
    this.ratingId,
    required this.price,
    this.couponCode,
    this.discountAmount = 0.0,
    required this.finalAmount,
    this.description,
    this.category,
    required this.createdAt,
    required this.updatedAt,
  });

  // Backward compatibility getter
  String get status => bookingStatus;

  factory Booking.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final servicesList = List<Map<String, dynamic>>.from(data['services'] ?? []);
    
    return Booking(
      id: doc.id,
      customerId: (data['customerId'] ?? '').toString(),
      customerName: data['customerName']?.toString(),
      technicianId: (data['technicianId'] ?? data['assignedTechnicianId'])?.toString(),
      technicianName: (data['technicianName'] ?? data['assignedTechnicianName'])?.toString(),
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
      addressSnapshot: Map<String, dynamic>.from(data['addressSnapshot'] ?? data['address'] ?? {}),
      bookingStatus: (data['bookingStatus'] ?? 'pending').toString(),
      statusHistory: data['statusHistory'] != null 
          ? List<Map<String, dynamic>>.from(data['statusHistory'])
          : null,
      paymentStatus: (data['paymentStatus'] ?? 'pending').toString(),
      paymentMode: data['paymentMode']?.toString(),
      razorpayOrderId: data['razorpayOrderId']?.toString(),
      isRated: data['isRated'] ?? false,
      ratingId: data['ratingId']?.toString(),
      price: double.tryParse((data['price'] ?? data['totalAmount'] ?? 0.0).toString()) ?? 0.0,
      couponCode: data['couponCode']?.toString(),
      discountAmount: double.tryParse((data['discountAmount'] ?? 0.0).toString()) ?? 0.0,
      finalAmount: double.tryParse((data['finalAmount'] ?? data['price'] ?? data['totalAmount'] ?? 0.0).toString()) ?? 0.0,
      description: data['description']?.toString(),
      category: data['category']?.toString(),
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
      'technicianId': technicianId,
      'technicianName': technicianName,
      'services': services,
      'serviceId': serviceId,
      'serviceTitle': serviceTitle,
      'scheduledAt': Timestamp.fromDate(scheduledAt),
      'scheduledDate': scheduledDate != null ? Timestamp.fromDate(scheduledDate!) : null,
      'scheduledTime': scheduledTime,
      'addressSnapshot': addressSnapshot,
      'bookingStatus': bookingStatus,
      'statusHistory': statusHistory,
      'paymentStatus': paymentStatus,
      'paymentMode': paymentMode,
      'razorpayOrderId': razorpayOrderId,
      'isRated': isRated,
      'ratingId': ratingId,
      'price': price,
      'couponCode': couponCode,
      'discountAmount': discountAmount,
      'finalAmount': finalAmount,
      'description': description,
      'category': category,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}

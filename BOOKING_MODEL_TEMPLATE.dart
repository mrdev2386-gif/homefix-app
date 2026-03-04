// Booking Model - Customer App Integration
// File: apps/customer_app/lib/core/models/booking.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class Booking {
  final String id;
  final String customerId;
  final String technicianId;
  final String serviceId;
  final double basePrice;
  
  // Service Features
  final bool isUrgentBooking;
  final String? urgentArrivalTime;
  final int? urgentFee;
  
  final bool isNightBooking;
  final int? nightCharge;
  
  // Final Price (calculated by Cloud Function)
  final double finalPrice;
  final Map<String, dynamic>? priceBreakdown;
  
  // Booking Details
  final DateTime bookingDate;
  final String timeSlot;
  final String address;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  Booking({
    required this.id,
    required this.customerId,
    required this.technicianId,
    required this.serviceId,
    required this.basePrice,
    this.isUrgentBooking = false,
    this.urgentArrivalTime,
    this.urgentFee,
    this.isNightBooking = false,
    this.nightCharge,
    required this.finalPrice,
    this.priceBreakdown,
    required this.bookingDate,
    required this.timeSlot,
    required this.address,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create from Firestore document
  factory Booking.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return Booking(
      id: doc.id,
      customerId: data['customerId'] ?? '',
      technicianId: data['technicianId'] ?? '',
      serviceId: data['serviceId'] ?? '',
      basePrice: (data['basePrice'] ?? 0.0).toDouble(),
      isUrgentBooking: data['isUrgentBooking'] ?? false,
      urgentArrivalTime: data['urgentArrivalTime'],
      urgentFee: data['urgentFee'],
      isNightBooking: data['isNightBooking'] ?? false,
      nightCharge: data['nightCharge'],
      finalPrice: (data['finalPrice'] ?? 0.0).toDouble(),
      priceBreakdown: data['priceBreakdown'],
      bookingDate: (data['bookingDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      timeSlot: data['timeSlot'] ?? '',
      address: data['address'] ?? '',
      status: data['status'] ?? 'pending',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Convert to map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'customerId': customerId,
      'technicianId': technicianId,
      'serviceId': serviceId,
      'basePrice': basePrice,
      'isUrgentBooking': isUrgentBooking,
      if (urgentArrivalTime != null) 'urgentArrivalTime': urgentArrivalTime,
      if (urgentFee != null) 'urgentFee': urgentFee,
      'isNightBooking': isNightBooking,
      if (nightCharge != null) 'nightCharge': nightCharge,
      'finalPrice': finalPrice,
      if (priceBreakdown != null) 'priceBreakdown': priceBreakdown,
      'bookingDate': Timestamp.fromDate(bookingDate),
      'timeSlot': timeSlot,
      'address': address,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Get formatted price breakdown
  String getPriceBreakdownText() {
    StringBuffer buffer = StringBuffer();
    buffer.writeln('Base Price: ₹${basePrice.toStringAsFixed(0)}');
    
    if (isUrgentBooking && urgentFee != null) {
      buffer.writeln('Urgent Fee: +₹$urgentFee');
    }
    
    if (isNightBooking && nightCharge != null && nightCharge! > 0) {
      buffer.writeln('Night Charge: +₹$nightCharge');
    }
    
    buffer.write('Total: ₹${finalPrice.toStringAsFixed(0)}');
    return buffer.toString();
  }

  @override
  String toString() {
    return 'Booking(id: $id, status: $status, finalPrice: $finalPrice)';
  }
}

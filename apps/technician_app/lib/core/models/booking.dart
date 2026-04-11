import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/firestore_safe_parser.dart';

/// Centralized booking status constants.
/// Use ONLY these values when querying or comparing booking statuses to
/// prevent case-sensitivity bugs and silent Firestore query mismatches.
class BookingStatus {
  BookingStatus._();

  static const String pending    = 'pending';
  static const String assigned   = 'assigned';
  static const String accepted   = 'accepted';
  static const String enRoute    = 'en_route';
  static const String inProgress = 'in_progress';
  static const String completed  = 'completed';
  static const String cancelled  = 'cancelled';
  static const String rejected   = 'rejected';

  static const List<String> activeStatuses = [assigned, accepted, enRoute, inProgress];
  static const List<String> terminalStatuses = [completed, cancelled, rejected];
}

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
  
  /// Get formatted address string from addressSnapshot
  String get address {
    if (addressSnapshot.isEmpty) return 'Address not available';
    
    // Try different field names for address
    final addressStr = addressSnapshot['address'] ?? 
                      addressSnapshot['fullAddress'] ?? 
                      addressSnapshot['formattedAddress'] ?? '';
    
    if (addressStr.isNotEmpty) return addressStr.toString();
    
    // Build address from components
    final parts = <String>[];
    if (addressSnapshot['street'] != null) parts.add(addressSnapshot['street'].toString());
    if (addressSnapshot['city'] != null) parts.add(addressSnapshot['city'].toString());
    if (addressSnapshot['state'] != null) parts.add(addressSnapshot['state'].toString());
    if (addressSnapshot['pincode'] != null) parts.add(addressSnapshot['pincode'].toString());
    
    return parts.isNotEmpty ? parts.join(', ') : 'Address not available';
  }

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
    
    // Safe Timestamp parsing for scheduledAt
    DateTime scheduledAt;
    final scheduledAtRaw = data['scheduledAt'] ?? data['scheduledDate'];
    if (scheduledAtRaw is Timestamp) {
      scheduledAt = scheduledAtRaw.toDate();
    } else if (scheduledAtRaw is String) {
      scheduledAt = DateTime.tryParse(scheduledAtRaw) ?? DateTime.now();
    } else {
      scheduledAt = DateTime.now();
    }
    
    // Safe Timestamp parsing for createdAt
    DateTime createdAt;
    final createdAtRaw = data['createdAt'];
    if (createdAtRaw is Timestamp) {
      createdAt = createdAtRaw.toDate();
    } else if (createdAtRaw is String) {
      createdAt = DateTime.tryParse(createdAtRaw) ?? DateTime.now();
    } else {
      createdAt = DateTime.now();
    }
    
    // Handle multiple field names for service image
    final serviceImage = data['serviceImage'] ?? 
                        data['imageUrl'] ?? 
                        data['image'] ?? 
                        data['serviceImageUrl'];
    
    // Handle multiple field names for address
    final addressData = data['addressSnapshot'] ?? 
                       data['address'] ?? 
                       data['location'] ?? 
                       <String, dynamic>{};
    
    return Booking(
      bookingId: data['bookingId'] ?? doc.id,
      customerId: data['customerId'] ?? '',
      customerName: data['customerName'] ?? data['customer']?['name'] ?? 'Customer',
      serviceId: data['serviceId'] ?? '',
      serviceTitle: data['serviceTitle'] ?? data['serviceName'] ?? data['service']?['name'] ?? 'Service',
      serviceImage: serviceImage?.toString(),
      problemDescription: data['problemDescription'] ?? data['description'] ?? data['problem'],
      assignedTechnicianId: data['technicianId'] ?? data['assignedTechnicianId'],
      assignedTechnicianName: data['technicianName'] ?? data['assignedTechnicianName'],
      slotId: data['slotId'] ?? '',
      scheduledAt: scheduledAt,
      scheduledTime: data['scheduledTime'] ?? '',
      status: FirestoreSafeParser.toSafeString(data['bookingStatus'], fallback: 'pending'),
      paymentStatus: FirestoreSafeParser.toSafeString(data['paymentStatus'], fallback: 'unpaid'),
      paymentMode: data['paymentMode']?.toString(),
      price: FirestoreSafeParser.toSafeDouble(data['price'] ?? data['amount']),
      finalAmount: FirestoreSafeParser.toSafeDouble(data['finalAmount'] ?? data['price'] ?? data['amount']),
      addressSnapshot: addressData is Map<String, dynamic> ? addressData : <String, dynamic>{},
      category: data['category']?.toString(),
      description: data['description']?.toString(),
      createdAt: createdAt,
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
      'bookingStatus': status,
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
  
  /// Debug helper to log booking data
  Map<String, dynamic> toJson() {
    return {
      'bookingId': bookingId,
      'customerId': customerId,
      'customerName': customerName,
      'serviceId': serviceId,
      'serviceTitle': serviceTitle,
      'serviceImage': serviceImage ?? 'NO_IMAGE',
      'address': address,
      'price': price,
      'finalAmount': finalAmount,
      'status': status,
      'scheduledAt': scheduledAt.toIso8601String(),
      'scheduledTime': scheduledTime,
    };
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../utils/safe_parsing.dart';

// Simple dedupe set for cart warnings - prevents spam on rebuilds
final Set<String> _loggedCartWarnings = {};

class CartItem {
  final String id;
  final String categoryId;
  final String categoryName;
  final String serviceId;
  final String? subServiceId; // Required for booking - only subServices are bookable
  final String? subServiceName;
  final String serviceName;
  final String serviceImage;
  final double price;
  final int quantity;
  final double totalPrice;
  final String? technicianId;
  final double finalPriceSnapshot; // AUDIT: Mandatory price snapshot
  final DateTime? scheduledAt;

  // Validation getter - checks if cart item has all required fields
  bool get isValid =>
      technicianId != null &&
      technicianId!.isNotEmpty &&
      serviceId.isNotEmpty &&
      categoryId.isNotEmpty &&
      categoryName.isNotEmpty &&
      finalPriceSnapshot > 0;

  CartItem({
    required this.id,
    required this.categoryId,
    required this.categoryName,
    required this.serviceId,
    this.subServiceId,
    this.subServiceName,
    required this.serviceName,
    required this.serviceImage,
    required this.price,
    this.quantity = 1,
    required this.totalPrice,
    this.technicianId,
    required this.finalPriceSnapshot,
    this.scheduledAt,
  }) {
    // DEV ONLY: Ensure mandatory fields are present (only in debug mode)
    if (kDebugMode) {
      assert(serviceId.isNotEmpty, 'serviceId is mandatory');
      assert(technicianId != null && technicianId!.isNotEmpty, 'technicianId is mandatory');
      assert(categoryId.isNotEmpty, 'categoryId is mandatory');
      assert(categoryName.isNotEmpty, 'categoryName is mandatory');
      assert(finalPriceSnapshot > 0, 'price snapshot must be valid');
    }
  }

  factory CartItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    
    // Parse with safe parsing - allow null for legacy data
    final technicianId = SafeParsing.safeString(data['technicianId']);
    final serviceId = SafeParsing.safeString(data['serviceId']);
    final categoryId = SafeParsing.safeString(data['categoryId']);
    final categoryName = SafeParsing.safeString(data['categoryName'], defaultValue: 'General');
    final finalPriceSnapshot = SafeParsing.safeDouble(data['finalPriceSnapshot'] ?? data['price']);
    
    // RUNTIME GUARD: Log error if critical data missing but don't crash (deduped)
    final warningKey = '${doc.id}_${technicianId.isEmpty}';
    if (!_loggedCartWarnings.contains(warningKey)) {
      if (technicianId.isEmpty) {
        debugPrint('⚠️ [CartItem] Missing technicianId for cart item ${doc.id} - legacy data detected');
        _loggedCartWarnings.add(warningKey);
      } else if (serviceId.isEmpty) {
        debugPrint('⚠️ [CartItem] Missing serviceId for cart item ${doc.id}');
        _loggedCartWarnings.add(warningKey);
      } else if (categoryId.isEmpty) {
        debugPrint('⚠️ [CartItem] Missing categoryId for cart item ${doc.id}');
        _loggedCartWarnings.add(warningKey);
      } else if (finalPriceSnapshot <= 0) {
        debugPrint('⚠️ [CartItem] Invalid price snapshot for cart item ${doc.id}');
        _loggedCartWarnings.add(warningKey);
      }
    }
    
    return CartItem(
      id: doc.id,
      categoryId: categoryId,
      categoryName: categoryName,
      serviceId: serviceId,
      subServiceId: SafeParsing.safeString(data['subServiceId']).isNotEmpty 
          ? SafeParsing.safeString(data['subServiceId']) 
          : null,
      subServiceName: SafeParsing.safeString(data['subServiceName']).isNotEmpty 
          ? SafeParsing.safeString(data['subServiceName']) 
          : null,
      serviceName: SafeParsing.safeString(data['serviceName']),
      serviceImage: SafeParsing.safeString(data['serviceImage']),
      price: SafeParsing.safeDouble(data['price']),
      quantity: SafeParsing.safeInt(data['quantity'], defaultValue: 1),
      totalPrice: SafeParsing.safeDouble(data['totalPrice']),
      technicianId: technicianId.isNotEmpty ? technicianId : null,
      finalPriceSnapshot: finalPriceSnapshot,
      scheduledAt: data['scheduledAt'] != null 
          ? (data['scheduledAt'] as Timestamp).toDate() 
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'categoryId': categoryId,
      'categoryName': categoryName,
      'serviceId': serviceId,
      'subServiceId': subServiceId ?? '',
      'subServiceName': subServiceName ?? '',
      'serviceName': serviceName,
      'serviceImage': serviceImage,
      'price': price,
      'quantity': quantity,
      'totalPrice': totalPrice,
      'technicianId': technicianId ?? '',
      'finalPriceSnapshot': finalPriceSnapshot,
      'scheduledAt': scheduledAt != null ? Timestamp.fromDate(scheduledAt!) : null,
    };
  }

  CartItem copyWith({
    String? id,
    String? categoryId,
    String? categoryName,
    String? serviceId,
    String? subServiceId,
    String? subServiceName,
    String? serviceName,
    String? serviceImage,
    double? price,
    int? quantity,
    double? totalPrice,
    String? technicianId,
    DateTime? scheduledAt,
  }) {
    return CartItem(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      serviceId: serviceId ?? this.serviceId,
      subServiceId: subServiceId ?? this.subServiceId,
      subServiceName: subServiceName ?? this.subServiceName,
      serviceName: serviceName ?? this.serviceName,
      serviceImage: serviceImage ?? this.serviceImage,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      totalPrice: totalPrice ?? this.totalPrice,
      technicianId: technicianId ?? this.technicianId,
      finalPriceSnapshot: finalPriceSnapshot ?? this.finalPriceSnapshot,
      scheduledAt: scheduledAt ?? this.scheduledAt,
    );
  }
}

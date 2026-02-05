import 'package:cloud_firestore/cloud_firestore.dart';

class ServiceRequest {
  final String id;
  final String customerId;
  final String title;
  final String description;
  final List<String> imageUrls;
  final String status; // open, quoted, accepted, cancelled, completed
  final DateTime preferredDateTime;
  final Map<String, dynamic>? address;
  final DateTime createdAt;

  ServiceRequest({
    required this.id,
    required this.customerId,
    required this.title,
    required this.description,
    this.imageUrls = const [],
    this.status = 'open',
    required this.preferredDateTime,
    this.address,
    required this.createdAt,
  });

  factory ServiceRequest.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ServiceRequest(
      id: doc.id,
      customerId: data['customerId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      status: data['status'] ?? 'open',
      preferredDateTime: (data['preferredDateTime'] as Timestamp).toDate(),
      address: data['address'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'customerId': customerId,
      'title': title,
      'description': description,
      'imageUrls': imageUrls,
      'status': status,
      'preferredDateTime': Timestamp.fromDate(preferredDateTime),
      'address': address,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

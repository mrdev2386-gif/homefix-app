import 'package:cloud_firestore/cloud_firestore.dart';

class Category {
  final String id;
  final String title;
  final String iconUrl;
  final int order;
  final bool enabled;
  final bool isNew;
  final String? description;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Category({
    required this.id,
    required this.title,
    required this.iconUrl,
    required this.order,
    this.enabled = true,
    this.isNew = false,
    this.description,
    this.createdAt,
    this.updatedAt,
  });

  factory Category.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return Category(
      id: doc.id,
      title: (data['title'] ?? data['name'] ?? 'Category').toString(),
      iconUrl: (data['iconUrl'] ?? data['imageUrl'] ?? '').toString(),
      order: int.tryParse((data['order'] ?? 0).toString()) ?? 0,
      enabled: data['enabled'] ?? data['isActive'] ?? true,
      isNew: data['isNew'] ?? false,
      description: data['description']?.toString(),
      createdAt: data['createdAt'] is Timestamp ? (data['createdAt'] as Timestamp).toDate() : null,
      updatedAt: data['updatedAt'] is Timestamp ? (data['updatedAt'] as Timestamp).toDate() : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'iconUrl': iconUrl,
      'order': order,
      'enabled': enabled,
      'isNew': isNew,
      'description': description,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}

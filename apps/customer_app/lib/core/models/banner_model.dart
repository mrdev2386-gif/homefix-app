import 'package:cloud_firestore/cloud_firestore.dart';

class BannerModel {
  final String id;
  final String imageUrl;
  final String title; // Added
  final String subtitle; // Added
  final String targetScreen;
  final String targetId;
  final bool active;
  final int order;

  BannerModel({
    required this.id,
    required this.imageUrl,
    this.title = '', // Added default
    this.subtitle = '', // Added default
    required this.targetScreen,
    required this.targetId,
    required this.active,
    required this.order,
  });

  factory BannerModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return BannerModel(
      id: doc.id,
      imageUrl: (data['imageUrl'] ?? data['image'] ?? '').toString(),
      title: (data['title'] ?? '').toString(),
      subtitle: (data['subtitle'] ?? '').toString(),
      targetScreen: (data['targetScreen'] ?? '').toString(),
      targetId: (data['targetId'] ?? '').toString(),
      active: data['active'] ?? data['isActive'] ?? true,
      order: int.tryParse((data['order'] ?? 0).toString()) ?? 0,
    );
  }
}

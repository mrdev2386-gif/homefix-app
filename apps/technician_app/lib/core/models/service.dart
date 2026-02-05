import 'package:cloud_firestore/cloud_firestore.dart';

class HomeService {
  final String id;
  final String key;
  final String title;
  final String imageAssetPath;
  final double basePrice;
  final bool isActive;

  HomeService({
    required this.id,
    required this.key,
    required this.title,
    required this.imageAssetPath,
    required this.basePrice,
    required this.isActive,
  });

  factory HomeService.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return HomeService(
      id: doc.id,
      key: data['serviceId'] ?? data['key'] ?? '',
      title: data['name'] ?? data['title'] ?? '',
      imageAssetPath: data['image'] ?? data['imageUrl'] ?? data['imageAssetPath'] ?? '',
      basePrice: (data['price'] ?? data['basePrice'] ?? 0.0).toDouble(),
      isActive: data['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'serviceId': key,
      'name': title,
      'image': imageAssetPath,
      'price': basePrice,
      'isActive': isActive,
    };
  }
}

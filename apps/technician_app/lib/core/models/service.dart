import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/firestore_safe_parser.dart';

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
    final data = FirestoreSafeParser.toSafeMap(doc.data());
    return HomeService(
      id: doc.id,
      key: FirestoreSafeParser.toSafeString(data['serviceId'] ?? data['key']),
      title: FirestoreSafeParser.toSafeString(data['name'] ?? data['title']),
      imageAssetPath: FirestoreSafeParser.toSafeString(data['image'] ?? data['imageUrl'] ?? data['imageAssetPath']),
      basePrice: FirestoreSafeParser.toSafeDouble(data['price'] ?? data['basePrice']),
      isActive: FirestoreSafeParser.toSafeBool(data['isActive'], fallback: true),
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

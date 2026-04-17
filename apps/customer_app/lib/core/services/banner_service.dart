import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/banner_model.dart';

class BannerService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Stream active home banners (limited to 10)
  /// DEPRECATED: Use getHomeBannersOnce() for better scalability
  @Deprecated('Use getHomeBannersOnce() instead for better performance')
  Stream<List<BannerModel>> streamHomeBanners() {
    return _db
        .collection('home_banners')
        .where('isActive', isEqualTo: true)
        .orderBy('order')
        .limit(10) // FIX: Limit to 10 banners to prevent excessive data fetching
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => BannerModel.fromFirestore(doc))
            .toList())
        .handleError((error) {
          if (kDebugMode) debugPrint('❌ [BannerService] Stream error: $error');
          // Return empty list on error to prevent UI crash
          return <BannerModel>[];
        });
  }

  /// Get active home banners once (limited to 10)
  /// SCALABILITY: Converted from stream to one-time fetch
  /// Returns empty list on error instead of throwing
  Future<List<BannerModel>> getHomeBannersOnce() async {
    try {
      final snapshot = await _db
          .collection('home_banners')
          .where('isActive', isEqualTo: true)
          .orderBy('order')
          .limit(10)
          .get();
      
      return snapshot.docs
          .map((doc) => BannerModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      if (kDebugMode) debugPrint('❌ [BannerService] Failed to fetch banners: $e');
      return [];
    }
  }
}

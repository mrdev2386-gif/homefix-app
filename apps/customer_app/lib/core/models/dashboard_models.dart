
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../constants/app_constants.dart';



class CleaningCategory {
  final String id;
  final String name;
  final String imageUrl; // Unified: using imageUrl instead of iconUrl
  final bool isActive;
  final int order;

  CleaningCategory({
    required this.id,
    required this.name,
    required this.imageUrl,
    this.isActive = true,
    this.order = 0,
  });

  factory CleaningCategory.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return CleaningCategory(
      id: doc.id,
      name: (data['name'] ?? data['title'] ?? '').toString(),
      imageUrl: (() {
        final img = (data['imageUrl'] ?? data['iconUrl'])?.toString().trim();
        if (img != null && img.isNotEmpty) return img;
        
        if (kDebugMode) {
          debugPrint('⚠️ [CleaningCategory Model] No image found for ${doc.id}. Using global fallback.');
        }
        return AppConstants.fallbackServiceImage;
      })(),
      isActive: data['isActive'] ?? true,
      order: int.tryParse((data['order'] ?? 0).toString()) ?? 0,
    );
  }
}

class CleaningEssential {
  final String id;
  final String title;
  final String imageUrl;
  final String categoryId;
  final int order;
  final bool isActive;

  CleaningEssential({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.categoryId,
    this.order = 0,
    this.isActive = true,
  });

  factory CleaningEssential.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return CleaningEssential(
      id: doc.id,
      title: (data['title'] ?? data['name'] ?? '').toString(),
      imageUrl: (() {
        final img = (data['imageUrl'] ?? data['iconUrl'] ?? data['image'])?.toString().trim();
        if (img != null && img.isNotEmpty) return img;
        
        if (kDebugMode) {
          debugPrint('⚠️ [CleaningEssential Model] No image found for ${doc.id}. Using global fallback.');
        }
        return AppConstants.fallbackServiceImage;
      })(),
      categoryId: (data['categoryKey'] ?? data['categoryId'] ?? data['category'] ?? doc.id).toString(),
      order: int.tryParse((data['order'] ?? 0).toString()) ?? 0,
      isActive: data['isActive'] ?? true,
    );
  }
}

class ServiceSpotlight {
  final String id;
  final String serviceId;
  final String title;
  final String imageUrl;
  final double price;
  final double rating;
  final int availableTechnicians;

  ServiceSpotlight({
    required this.id,
    required this.serviceId,
    required this.title,
    required this.imageUrl,
    required this.price,
    required this.rating,
    this.availableTechnicians = 0,
  });

  factory ServiceSpotlight.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ServiceSpotlight(
      id: doc.id,
      serviceId: (data['serviceId'] ?? data['id'] ?? '').toString(),
      title: (data['title'] ?? data['name'] ?? 'Service').toString(),
      imageUrl: (() {
        final img = (data['imageUrl'] ?? data['image'] ?? data['thumbnail'])?.toString().trim();
        if (img != null && img.isNotEmpty) return img;
        
        if (kDebugMode) {
          debugPrint('⚠️ [ServiceSpotlight Model] No image found for ${doc.id}. Using global fallback.');
        }
        return AppConstants.fallbackServiceImage;
      })(),
      price: double.tryParse((data['price'] ?? data['basePrice'] ?? 0.0).toString()) ?? 0.0,
      rating: double.tryParse((data['rating'] ?? 4.5).toString()) ?? 4.5,
      availableTechnicians: int.tryParse((data['availableTechnicians'] ?? 0).toString()) ?? 0,
    );
  }
  
  ServiceSpotlight copyWith({int? availableTechnicians}) {
    return ServiceSpotlight(
      id: id,
      serviceId: serviceId,
      title: title,
      imageUrl: imageUrl,
      price: price,
      rating: rating,
      availableTechnicians: availableTechnicians ?? this.availableTechnicians,
    );
  }
}

class ServiceBanner {
  final String id;
  final String imageUrl;
  final bool isActive;
  final int order;
  final String title;
  final String description;

  ServiceBanner({
    required this.id,
    required this.imageUrl,
    this.isActive = true,
    this.order = 0,
    this.title = 'Special Offer',
    this.description = 'Check out our new services',
  });

  factory ServiceBanner.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ServiceBanner(
      id: doc.id,
      imageUrl: (() {
        final img = (data['imageUrl'] ?? data['bannerUrl'] ?? data['image'])?.toString().trim();
        if (img != null && img.isNotEmpty) return img;
        
        if (kDebugMode) {
          debugPrint('⚠️ [ServiceBanner Model] No image found for ${doc.id}. Using global fallback.');
        }
        return AppConstants.fallbackServiceImage;
      })(),
      isActive: data['isActive'] ?? true,
      order: int.tryParse((data['order'] ?? 0).toString()) ?? 0,
      title: (data['title'] ?? 'Special Offer').toString(),
      description: (data['description'] ?? data['subtitle'] ?? '').toString(),
    );
  }
}

class TechnicianCategory {
  final String id;
  final String name;
  final String imageUrl; // Unified from 'icon'
  final bool isActive;
  final int order;

  TechnicianCategory({
    required this.id,
    required this.name,
    required this.imageUrl,
    this.isActive = true,
    this.order = 0
  });

  factory TechnicianCategory.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return TechnicianCategory(
      id: doc.id,
      name: (data['name'] ?? '').toString(),
      imageUrl: (() {
        final img = (data['imageUrl'] ?? data['icon'])?.toString().trim();
        if (img != null && img.isNotEmpty) return img;
        
        if (kDebugMode) {
          debugPrint('⚠️ [TechnicianCategory Model] No image found for ${doc.id}. Using global fallback.');
        }
        return AppConstants.fallbackServiceImage;
      })(),
      isActive: data['isActive'] ?? true,
      order: int.tryParse((data['order'] ?? 0).toString()) ?? 0,
    );
  }
}

class TechnicianSubcategory {
  final String id;
  final String categoryId;
  final String? serviceId;
  final String name;
  final bool isActive;
  final int order;

  TechnicianSubcategory({
    required this.id,
    required this.categoryId,
    this.serviceId,
    required this.name,
    this.isActive = true,
    this.order = 0
  });

  factory TechnicianSubcategory.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return TechnicianSubcategory(
      id: doc.id,
      categoryId: (data['categoryId'] ?? '').toString(),
      serviceId: data['serviceId']?.toString(),
      name: (data['name'] ?? '').toString(),
      isActive: data['isActive'] ?? true,
      order: int.tryParse((data['order'] ?? 0).toString()) ?? 0,
    );
  }
}

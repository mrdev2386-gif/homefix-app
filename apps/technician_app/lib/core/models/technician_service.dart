import 'package:cloud_firestore/cloud_firestore.dart';

/// Technician Service Model
/// Represents a YouTube-style service listing created by a technician
/// 
/// Collection: technician_services/{serviceId}
class TechnicianService {
  final String id;
  final String technicianId;
  final String categoryId;
  final String subcategoryId;
  final String title;
  final String description;
  final List<String> tags;
  final double price;
  final int durationMinutes;
  final String imageUrl;
  final bool isActive;
  final bool isPublished;
  final bool technicianApproved;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? urgentBooking;
  final Map<String, dynamic>? nightService;

  TechnicianService({
    required this.id,
    required this.technicianId,
    required this.categoryId,
    required this.subcategoryId,
    required this.title,
    required this.description,
    required this.tags,
    required this.price,
    required this.durationMinutes,
    required this.imageUrl,
    required this.isActive,
    this.isPublished = false,
    this.technicianApproved = false,
    required this.createdAt,
    required this.updatedAt,
    this.urgentBooking,
    this.nightService,
  });

  /// Create from Firestore document
  factory TechnicianService.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    // Handle tags - could be array or null
    List<String> tagsList = [];
    if (data['tags'] != null) {
      if (data['tags'] is List) {
        tagsList = List<String>.from(data['tags']);
      } else if (data['tags'] is String) {
        tagsList = (data['tags'] as String).split(',').map((e) => e.trim()).toList();
      }
    }

    // Handle timestamps
    DateTime createdAt = DateTime.now();
    DateTime updatedAt = DateTime.now();
    
    if (data['createdAt'] != null) {
      if (data['createdAt'] is Timestamp) {
        createdAt = (data['createdAt'] as Timestamp).toDate();
      } else if (data['createdAt'] is String) {
        createdAt = DateTime.tryParse(data['createdAt']) ?? DateTime.now();
      }
    }
    
    if (data['updatedAt'] != null) {
      if (data['updatedAt'] is Timestamp) {
        updatedAt = (data['updatedAt'] as Timestamp).toDate();
      } else if (data['updatedAt'] is String) {
        updatedAt = DateTime.tryParse(data['updatedAt']) ?? DateTime.now();
      }
    }

    return TechnicianService(
      id: data['id'] ?? doc.id,
      technicianId: data['technicianId'] ?? '',
      categoryId: data['categoryId'] ?? '',
      subcategoryId: data['subcategoryId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      tags: tagsList,
      price: (data['price'] ?? 0.0).toDouble(),
      durationMinutes: (data['durationMinutes'] ?? 0).toInt(),
      imageUrl: data['imageUrl'] ?? '',
      isActive: data['isActive'] ?? true,
      isPublished: data['isPublished'] ?? false,
      technicianApproved: data['technicianApproved'] ?? false,
      createdAt: createdAt,
      updatedAt: updatedAt,
      urgentBooking: data['urgentBooking'] as Map<String, dynamic>?,
      nightService: data['nightService'] as Map<String, dynamic>?,
    );
  }

  /// Convert to map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'technicianId': technicianId,
      'categoryId': categoryId,
      'subcategoryId': subcategoryId,
      'title': title,
      'description': description,
      'tags': tags,
      'price': price,
      'durationMinutes': durationMinutes,
      'imageUrl': imageUrl,
      'isActive': isActive,
      'isPublished': isPublished,
      'technicianApproved': technicianApproved,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      if (urgentBooking != null) 'urgentBooking': urgentBooking,
      if (nightService != null) 'nightService': nightService,
    };
  }

  /// Create a copy with updated fields
  TechnicianService copyWith({
    String? id,
    String? technicianId,
    String? categoryId,
    String? subcategoryId,
    String? title,
    String? description,
    List<String>? tags,
    double? price,
    int? durationMinutes,
    String? imageUrl,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? urgentBooking,
    Map<String, dynamic>? nightService,
  }) {
    return TechnicianService(
      id: id ?? this.id,
      technicianId: technicianId ?? this.technicianId,
      categoryId: categoryId ?? this.categoryId,
      subcategoryId: subcategoryId ?? this.subcategoryId,
      title: title ?? this.title,
      description: description ?? this.description,
      tags: tags ?? this.tags,
      price: price ?? this.price,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      imageUrl: imageUrl ?? this.imageUrl,
      isActive: isActive ?? this.isActive,
      isPublished: isPublished ?? this.isPublished,
      technicianApproved: technicianApproved ?? this.technicianApproved,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      urgentBooking: urgentBooking ?? this.urgentBooking,
      nightService: nightService ?? this.nightService,
    );
  }

  /// Get formatted duration string
  String get formattedDuration {
    if (durationMinutes >= 60) {
      final hours = durationMinutes ~/ 60;
      final minutes = durationMinutes % 60;
      if (minutes > 0) {
        return '${hours}h ${minutes}m';
      }
      return '${hours}h';
    }
    return '${durationMinutes}m';
  }

  /// Get formatted price string
  String get formattedPrice {
    return '₹${price.toStringAsFixed(0)}';
  }

  @override
  String toString() {
    return 'TechnicianService(id: $id, title: $title, price: $price)';
  }
}

/// Input model for creating a new technician service
class CreateTechnicianServiceInput {
  final String categoryId;
  final String subcategoryId;
  final String title;
  final String description;
  final List<String> tags;
  final double price;
  final int durationMinutes;
  final String imageUrl;
  final Map<String, dynamic>? urgentBooking;
  final Map<String, dynamic>? nightService;

  CreateTechnicianServiceInput({
    required this.categoryId,
    required this.subcategoryId,
    required this.title,
    required this.description,
    this.tags = const [],
    required this.price,
    required this.durationMinutes,
    required this.imageUrl,
    this.urgentBooking,
    this.nightService,
  });

  /// Convert to map for Cloud Function
  Map<String, dynamic> toMap() {
    return {
      'categoryId': categoryId,
      'subcategoryId': subcategoryId,
      'title': title,
      'description': description,
      'tags': tags,
      'price': price,
      'durationMinutes': durationMinutes,
      'imageUrl': imageUrl,
      if (urgentBooking != null) 'urgentBooking': urgentBooking,
      if (nightService != null) 'nightService': nightService,
    };
  }

  /// Validate the input (client-side validation before sending to Cloud Function)
  String? validate() {
    if (categoryId.isEmpty) {
      return 'Please select a category';
    }
    if (subcategoryId.isEmpty) {
      return 'Please select a subcategory';
    }
    if (title.trim().length < 3) {
      return 'Title must be at least 3 characters';
    }
    if (description.trim().length < 20) {
      return 'Description must be at least 20 characters';
    }
    if (price <= 0) {
      return 'Price must be greater than 0';
    }
    if (durationMinutes <= 0) {
      return 'Duration must be greater than 0';
    }
    if (imageUrl.isEmpty) {
      return 'Please upload a service image';
    }
    return null; // Valid
  }
}

/// Input model for updating a technician service
class UpdateTechnicianServiceInput {
  final String serviceId;
  final String? title;
  final String? description;
  final List<String>? tags;
  final double? price;
  final int? durationMinutes;
  final String? imageUrl;
  final Map<String, dynamic>? urgentBooking;
  final Map<String, dynamic>? nightService;

  UpdateTechnicianServiceInput({
    required this.serviceId,
    this.title,
    this.description,
    this.tags,
    this.price,
    this.durationMinutes,
    this.imageUrl,
    this.urgentBooking,
    this.nightService,
  });

  /// Convert to map for Cloud Function (only includes non-null fields)
  Map<String, dynamic> toMap() {
    final Map<String, dynamic> map = {'serviceId': serviceId};
    
    if (title != null) map['title'] = title;
    if (description != null) map['description'] = description;
    if (tags != null) map['tags'] = tags;
    if (price != null) map['price'] = price;
    if (durationMinutes != null) map['durationMinutes'] = durationMinutes;
    if (imageUrl != null) map['imageUrl'] = imageUrl;
    if (urgentBooking != null) map['urgentBooking'] = urgentBooking;
    if (nightService != null) map['nightService'] = nightService;
    
    return map;
  }
}

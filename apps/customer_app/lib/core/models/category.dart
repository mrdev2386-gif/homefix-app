import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class Category {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final int order;
  final bool isActive;
  final int serviceCount;

  const Category({
    required this.id,
    required this.name,
    this.description = '',
    this.imageUrl = '',
    this.order = 0,
    this.isActive = true,
    this.serviceCount = 0,
  });

  String get title => name;
  String get iconUrl => imageUrl;
  bool get isNew => (order == 0);

  IconData get icon {
    final idLower = id.toLowerCase();
    final nameLower = name.toLowerCase();
    
    if (idLower.contains('clean') || nameLower.contains('clean')) return Icons.cleaning_services;
    if (idLower.contains('electric') || nameLower.contains('electric')) return Icons.electrical_services;
    if (idLower.contains('plumb') || nameLower.contains('plumb')) return Icons.plumbing;
    if (idLower.contains('ac') || nameLower.contains('ac')) return Icons.ac_unit;
    if (idLower.contains('carpenter') || nameLower.contains('carpenter')) return Icons.handyman;
    if (idLower.contains('paint') || nameLower.contains('paint')) return Icons.format_paint;
    if (idLower.contains('appliance') || nameLower.contains('appliance')) return Icons.kitchen;
    if (idLower.contains('salon') || nameLower.contains('salon')) return Icons.content_cut;
    if (idLower.contains('repair') || nameLower.contains('repair')) return Icons.build;
    
    return Icons.home_repair_service;
  }

  factory Category.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return Category(
      id: doc.id,
      name: (data['name'] ?? 'Category').toString(),
      description: (data['description'] ?? '').toString(),
      imageUrl: (data['imageUrl'] ?? data['iconUrl'] ?? '').toString(),
      order: (data['order'] ?? 0) as int,
      isActive: data['isActive'] ?? true,
      serviceCount: (data['serviceCount'] ?? 0) as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'order': order,
      'isActive': isActive,
      'serviceCount': serviceCount,
    };
  }

  Category copyWith({
    String? id,
    String? name,
    String? description,
    String? imageUrl,
    int? order,
    bool? isActive,
    int? serviceCount,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      order: order ?? this.order,
      isActive: isActive ?? this.isActive,
      serviceCount: serviceCount ?? this.serviceCount,
    );
  }
}

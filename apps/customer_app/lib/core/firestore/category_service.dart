import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/category.dart';

class CategoryService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Get all enabled categories ordered by order field
  Stream<List<Category>> getCategories() {
    return _db
        .collection('categories')
        .where('enabled', isEqualTo: true)
        .orderBy('order')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Category.fromFirestore(doc))
          .toList();
    });
  }

  /// Get single category by ID
  Future<Category?> getCategoryById(String categoryId) async {
    try {
      final doc = await _db.collection('categories').doc(categoryId).get();
      if (!doc.exists) return null;
      return Category.fromFirestore(doc);
    } catch (e) {
      debugPrint('Error fetching category: $e');
      return null;
    }
  }

  /// Search categories by title (client-side filtering)
  List<Category> searchCategories(List<Category> categories, String query) {
    if (query.isEmpty) return categories;
    
    final lowerQuery = query.toLowerCase();
    return categories.where((category) {
      return category.title.toLowerCase().contains(lowerQuery) ||
          (category.description?.toLowerCase().contains(lowerQuery) ?? false);
    }).toList();
  }
}

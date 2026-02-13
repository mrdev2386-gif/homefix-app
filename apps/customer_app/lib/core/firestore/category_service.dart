import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/category.dart';
import '../models/service.dart';
import '../models/sub_service.dart';

class CategoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get all active categories ordered by 'order' field
  Stream<List<Category>> getCategories() {
    return _firestore
        .collection('categories')
        .where('isActive', isEqualTo: true)
        .orderBy('order', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Category.fromFirestore(doc)).toList();
    });
  }

  /// Get single category by ID
  Future<Category?> getCategory(String categoryId) async {
    try {
      final doc = await _firestore.collection('categories').doc(categoryId).get();
      if (doc.exists) {
        return Category.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error fetching category: $e');
      return null;
    }
  }

  /// Get services for a specific category
  Stream<List<HomeService>> getServicesByCategory(String categoryId) {
    return _firestore
        .collection('categories')
        .doc(categoryId)
        .collection('services')
        .where('isActive', isEqualTo: true)
        .orderBy('order', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => HomeService.fromFirestore(doc)).toList();
    });
  }

  /// Get single service by ID within a category
  Future<HomeService?> getService(String categoryId, String serviceId) async {
    try {
      final doc = await _firestore
          .collection('categories')
          .doc(categoryId)
          .collection('services')
          .doc(serviceId)
          .get();
      if (doc.exists) {
        return HomeService.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error fetching service: $e');
      return null;
    }
  }

  /// Get sub-services for a specific service
  Stream<List<SubService>> getSubServices(String categoryId, String serviceId) {
    return _firestore
        .collection('categories')
        .doc(categoryId)
        .collection('services')
        .doc(serviceId)
        .collection('subServices')
        .where('isActive', isEqualTo: true)
        .orderBy('order', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => SubService.fromFirestore(doc)).toList();
    });
  }

  /// Check if a service has sub-services
  Future<bool> serviceHasSubServices(String categoryId, String serviceId) async {
    try {
      final snapshot = await _firestore
          .collection('categories')
          .doc(categoryId)
          .collection('services')
          .doc(serviceId)
          .collection('subServices')
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking sub-services: $e');
      return false;
    }
  }

  /// Search categories by name
  List<Category> searchCategories(List<Category> categories, String query) {
    if (query.isEmpty) return categories;
    final lowerQuery = query.toLowerCase();
    return categories
        .where((cat) => cat.name.toLowerCase().contains(lowerQuery))
        .toList();
  }
}

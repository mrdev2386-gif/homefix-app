import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/faq_model.dart';

/// FAQ Service - handles fetching FAQs from Firestore
/// 
/// Collection: faqs
/// 
/// Rules:
/// - Only fetches active FAQs (isActive == true)
/// - Orders by 'order' field if available
/// - Has fallback without orderBy if index is missing
class FaqService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'faqs';

  /// Fetch all active FAQs from Firestore
  /// 
  /// Tries to order by 'order' field first, falls back to unordered query
  /// if index is missing. Always returns non-null list.
  Future<List<FaqModel>> fetchFaqs() async {
    try {
      // First attempt: Try to fetch with orderBy
      final QuerySnapshot orderedSnapshot = await _firestore
          .collection(_collectionName)
          .where('isActive', isEqualTo: true)
          .orderBy('order', descending: false)
          .get();

      final faqs = orderedSnapshot.docs
          .map((doc) => FaqModel.fromFirestore(doc))
          .toList();
      
      debugPrint('[FAQ] fetched: ${faqs.length}');
      return faqs;
    } on FirebaseException catch (e) {
      // If index is missing, fallback to unordered query
      if (e.code == 'failed-precondition' || 
          e.message?.contains('index') == true) {
        debugPrint('[FAQ] Index missing, falling back to unordered query');
        return _fetchFaqsUnorderedSafe();
      }
      
      debugPrint('[FAQ] Firebase error: ${e.code} - ${e.message}');
      return _fetchFaqsUnorderedSafe();
    } catch (e) {
      debugPrint('[FAQ] Error fetching FAQs: $e');
      // Try fallback on any error
      try {
        return await _fetchFaqsUnorderedSafe();
      } catch (_) {
        return [];
      }
    }
  }

  /// Fallback method to fetch FAQs without orderBy - always returns non-null
  Future<List<FaqModel>> _fetchFaqsUnorderedSafe() async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection(_collectionName)
          .where('isActive', isEqualTo: true)
          .get();

      final faqs = snapshot.docs
          .map((doc) => FaqModel.fromFirestore(doc))
          .toList();

      // Sort locally by order
      faqs.sort((a, b) => a.order.compareTo(b.order));

      debugPrint('[FAQ] fetched: ${faqs.length}');
      return faqs;
    } catch (e) {
      debugPrint('[FAQ] Fallback error: $e');
      return [];
    }
  }

  /// Get a single FAQ by ID (not typically needed but useful for testing)
  Future<FaqModel?> getFaq(String faqId) async {
    try {
      final DocumentSnapshot doc = await _firestore
          .collection(_collectionName)
          .doc(faqId)
          .get();

      if (!doc.exists) {
        return null;
      }

      return FaqModel.fromFirestore(doc);
    } catch (e) {
      debugPrint('[FAQ] Error fetching FAQ $faqId: $e');
      return null;
    }
  }
}

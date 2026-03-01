import 'package:cloud_firestore/cloud_firestore.dart';

/// FAQ Model for Firestore
/// 
/// Collection: faqs
/// Document structure:
/// - question: String
/// - answer: String
/// - isActive: bool
/// - order: int
class FaqModel {
  final String id;
  final String question;
  final String answer;
  final bool isActive;
  final int order;

  FaqModel({
    required this.id,
    required this.question,
    required this.answer,
    required this.isActive,
    required this.order,
  });

  /// Create FaqModel from Firestore document
  factory FaqModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return FaqModel(
      id: doc.id,
      question: data['question'] as String? ?? '',
      answer: data['answer'] as String? ?? '',
      isActive: data['isActive'] as bool? ?? false,
      order: data['order'] as int? ?? 0,
    );
  }

  /// Convert to Firestore map (for creating/updating)
  Map<String, dynamic> toFirestore() {
    return {
      'question': question,
      'answer': answer,
      'isActive': isActive,
      'order': order,
    };
  }

  @override
  String toString() {
    return 'FaqModel(id: $id, question: $question, isActive: $isActive, order: $order)';
  }
}

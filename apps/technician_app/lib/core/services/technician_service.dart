import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/technician.dart';

class TechnicianService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  Future<void> saveTechnicianProfile(User user, {
    required List<String> skills,
  }) async {
    try {
      final callable = _functions.httpsCallable('updateTechnicianProfile');
      await callable.call({
        'name': user.displayName ?? 'Technician',
        'email': user.email ?? '',
        'phone': user.phoneNumber ?? '',
        'photoUrl': user.photoURL,
        'skills': skills,
      });
    } catch (e) {
      debugPrint("Error saving technician profile via CF: $e");
      rethrow;
    }
  }

  Future<void> updateOnlineStatus(String uid, bool isOnline) async {
    final callable = _functions.httpsCallable('toggleOnlineStatus');
    await callable.call({'isOnline': isOnline});
  }

  /// Update technician skills
  Future<void> updateSkills(String uid, List<String> skills) async {
    try {
      await _db.collection('technicians').doc(uid).update({
        'skills': skills,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('[TechnicianService] Skills updated successfully');
    } catch (e) {
      debugPrint('[TechnicianService] Error updating skills: $e');
      rethrow;
    }
  }
  Future<Technician?> getTechnician(String uid) async {
    final doc = await _db.collection('technicians').doc(uid).get();
    if (!doc.exists) return null;
    return Technician.fromFirestore(doc);
  }

  Stream<Technician?> getTechnicianStream(String uid) {
    return _db.collection('technicians').doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return Technician.fromFirestore(doc);
    }).handleError((e) {
      debugPrint('❌ [TechnicianService] Error fetching technician $uid: $e');
      return null;
    });
  }
}


import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/technician.dart';
import '../firebase/firebase_functions.dart';

class TechnicianService {
  late final FirebaseFirestore _db;
  late final FirebaseFunctions _functions;

  TechnicianService() {
    _db = FirebaseFirestore.instance;
    _functions = FirebaseFunctionsService.instance;
  }

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

  /// Update technician skills via Cloud Function (required by Firestore rules)
  Future<void> updateSkills(String uid, List<String> skills) async {
    try {
      // Use Cloud Function - Firestore rules block direct writes
      final callable = _functions.httpsCallable('updateTechnicianSkills');
      final result = await callable.call({
        'skills': skills,
      });
      
      if (result.data['success'] == true) {
        debugPrint('[WRITE VERIFY] technician skills updated via CF');
      } else {
        throw Exception(result.data['message'] ?? 'Failed to update skills');
      }
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


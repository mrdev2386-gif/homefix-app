import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/technician.dart';

class TechnicianService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> saveTechnicianProfile(User user, {
    required List<String> skills,
    double? lat,
    double? lng,
  }) async {
    try {
      final docRef = _db.collection('technicians').doc(user.uid);
      final doc = await docRef.get();

      final data = {
        'uid': user.uid,
        'name': user.displayName ?? 'Technician',
        'phone': user.phoneNumber ?? '',
        'email': user.email ?? '',
        'photoUrl': user.photoURL,
        'skills': skills,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (lat != null && lng != null) {
        data['geo'] = {'lat': lat, 'lng': lng};
      }

      if (!doc.exists) {
        data['isOnline'] = false;
        data['isVerified'] = false;
        data['rating'] = 4.5;
        data['jobsDone'] = 0;
        data['createdAt'] = FieldValue.serverTimestamp();
        await docRef.set(data);
      } else {
        await docRef.update(data);
      }
    } catch (e) {
      debugPrint("Error saving technician profile: $e");
      rethrow;
    }
  }

  Future<void> updateOnlineStatus(String uid, bool isOnline, {double? lat, double? lng}) async {
    final Map<String, dynamic> data = {
      'isOnline': isOnline,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (lat != null && lng != null) {
      data['geo'] = {'lat': lat, 'lng': lng};
    }
    await _db.collection('technicians').doc(uid).update(data);
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
    });
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/technician.dart';
import '../firebase/firebase_functions.dart';

/// ⚠️ DEPRECATED: Use FunctionsService for service management instead.
/// This service is kept for backward compatibility with profile operations only.
/// 
/// MIGRATION GUIDE:
/// - For service CRUD: Use FunctionsService (addService, updateService, deleteService)
/// - For profile updates: Use Cloud Functions via FunctionsService
/// - For profile reads: Use getTechnician() or getTechnicianStream() (still valid)
/// 
/// DO NOT add new methods to this service. All new operations should use FunctionsService.
class TechnicianService {
  late final FirebaseFirestore _db;
  late final FirebaseFunctions _functions;

  TechnicianService() {
    _db = FirebaseFirestore.instance;
    _functions = FirebaseFunctionsService.instance;
  }

  /// ❌ DEPRECATED: Use FunctionsService.updateTechnicianPersonalDetails() instead
  /// This method is BLOCKED and will throw an exception
  @Deprecated('Use FunctionsService via Cloud Functions')
  Future<void> saveTechnicianProfile(User user, {
    required List<String> skills,
  }) async {
    throw Exception(
      'Deprecated method blocked. Use FunctionsService.updateTechnicianPersonalDetails() via Cloud Functions.'
    );
  }

  /// ❌ DEPRECATED: Use FunctionsService.updateTechnicianPersonalDetails() instead
  /// This method is BLOCKED and will throw an exception
  @Deprecated('Use FunctionsService via Cloud Functions')
  Future<void> updateSkills(String uid, List<String> skills) async {
    throw Exception(
      'Deprecated method blocked. Use FunctionsService.updateTechnicianPersonalDetails() via Cloud Functions.'
    );
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


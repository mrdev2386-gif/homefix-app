import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileAddressService {
  static final _firestore = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  static Future<Map<String, dynamic>?> getPrimaryAddress() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (!doc.exists) return null;

      final data = doc.data() as Map<String, dynamic>;
      return {
        'primaryAddress': data['primaryAddress'] ?? '',
        'district': data['district'] ?? '',
        'state': data['state'] ?? '',
        'pincode': data['pincode'] ?? '',
      };
    } catch (e) {
      print('Error fetching address: $e');
      return null;
    }
  }

  static Future<void> updatePrimaryAddress({
    required String address,
    required String district,
    required String state,
    required String pincode,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      await _firestore.collection('users').doc(user.uid).update({
        'primaryAddress': address,
        'district': district,
        'state': state,
        'pincode': pincode,
      });
    } catch (e) {
      throw Exception('Failed to update address: $e');
    }
  }

  static Stream<Map<String, dynamic>?> watchPrimaryAddress() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value(null);
    }

    return _firestore.collection('users').doc(user.uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      final data = doc.data() as Map<String, dynamic>;
      return {
        'primaryAddress': data['primaryAddress'] ?? '',
        'district': data['district'] ?? '',
        'state': data['state'] ?? '',
        'pincode': data['pincode'] ?? '',
      };
    });
  }
}

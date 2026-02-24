import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/technician.dart';

class TechnicianDiscoveryService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<Technician>> getNearbyTechnicians(String skill) {
    // For a real app, use GeoFirestore or big queries. 
    // Here we filter by skill and online status.
    return _db
        .collection('technicians')
        .where('isOnline', isEqualTo: true)
        .where('status', whereIn: ['active', 'approved'])
        .where('isApproved', isEqualTo: true)
        .where('skills', arrayContains: skill)
        .limit(20)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Technician.fromFirestore(doc)).toList());
  }

  Future<Technician?> getTechnician(String uid) async {
    final doc = await _db.collection('technicians').doc(uid).get();
    if (!doc.exists) return null;
    return Technician.fromFirestore(doc);
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/service.dart';

class ServiceCatalogService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<HomeService>> getActiveServices() {
    return _db
        .collection('services')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => HomeService.fromFirestore(doc)).toList());
  }

  // Seed initial services if collection is empty
  Future<void> seedServicesIfEmpty() async {
    final snapshot = await _db.collection('services').limit(1).get();
    if (snapshot.docs.isEmpty) {
      final List<Map<String, dynamic>> initialServices = [
        {
          'key': 'ac',
          'title': 'AC Repair & Service',
          'imageAssetPath': 'assets/services/ac.png',
          'basePrice': 499.0,
          'isActive': true,
        },
        {
          'key': 'cleaning',
          'title': 'Deep Cleaning',
          'imageAssetPath': 'assets/services/cleaning.png',
          'basePrice': 999.0,
          'isActive': true,
        },
        {
          'key': 'electrician',
          'title': 'Electrician',
          'imageAssetPath': 'assets/services/electrician.png',
          'basePrice': 199.0,
          'isActive': true,
        },
        {
          'key': 'plumbing',
          'title': 'Plumber',
          'imageAssetPath': 'assets/services/plumbing.png',
          'basePrice': 249.0,
          'isActive': true,
        },
        {
          'key': 'pest_control',
          'title': 'Pest Control',
          'imageAssetPath': 'assets/services/pest_control.png',
          'basePrice': 799.0,
          'isActive': true,
        },
        {
          'key': 'washing_machine',
          'title': 'Washing Machine Repair',
          'imageAssetPath': 'assets/services/washing_machine.png',
          'basePrice': 399.0,
          'isActive': true,
        },
      ];

      for (var service in initialServices) {
        await _db.collection('services').add(service);
      }
    }
  }
}

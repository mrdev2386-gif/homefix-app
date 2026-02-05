import 'package:cloud_firestore/cloud_firestore.dart';
import 'distance_utils.dart';

class TechnicianModel {
  final String uid;
  final String name;
  final List<String> skills;
  final bool isOnline;
  final bool isVerified;
  final double rating;
  final int jobsDone;
  final double lat;
  final double lng;
  double? distance;

  TechnicianModel({
    required this.uid,
    required this.name,
    required this.skills,
    required this.isOnline,
    required this.isVerified,
    required this.rating,
    required this.jobsDone,
    required this.lat,
    required this.lng,
    this.distance,
  });

  factory TechnicianModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return TechnicianModel(
      uid: doc.id,
      name: data['name'] ?? '',
      skills: List<String>.from(data['skills'] ?? []),
      isOnline: data['isOnline'] ?? false,
      isVerified: data['isVerified'] ?? false,
      rating: (data['rating'] ?? 0.0).toDouble(),
      jobsDone: data['jobsDone'] ?? 0,
      lat: (data['geo']?['lat'] ?? 0.0).toDouble(),
      lng: (data['geo']?['lng'] ?? 0.0).toDouble(),
    );
  }
}

class TechnicianService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Fetches technicians near the user (within 15km) filtered by category.
  Future<List<TechnicianModel>> getNearbyTechnicians({
    required double userLat,
    required double userLng,
    String? category,
    double radiusKm = 15.0,
  }) async {
    // Basic implementation: fetch all online & verified technicians and filter locally.
    // In production with 1000s of techs, use Geohash query.
    Query query = _db.collection('technicians')
        .where('isOnline', isEqualTo: true)
        .where('isVerified', isEqualTo: true);

    if (category != null) {
      query = query.where('skills', arrayContains: category.toLowerCase());
    }

    QuerySnapshot snapshot = await query.get();
    
    List<TechnicianModel> nearby = [];

    for (var doc in snapshot.docs) {
      final tech = TechnicianModel.fromFirestore(doc);
      final dist = DistanceUtils.calculateDistance(userLat, userLng, tech.lat, tech.lng);
      
      if (dist <= radiusKm) {
        tech.distance = dist;
        nearby.add(tech);
      }
    }

    // Sort by distance
    nearby.sort((a, b) => (a.distance ?? 0).compareTo(b.distance ?? 0));

    return nearby;
  }

  /// Gets the count of nearby technicians for multiple categories.
  Future<Map<String, int>> getNearbyCountsByCategories({
    required double userLat,
    required double userLng,
    required List<String> categories,
  }) async {
    // Optimization: fetch all online techs once and categorize locally.
    QuerySnapshot snapshot = await _db.collection('technicians')
        .where('isOnline', isEqualTo: true)
        .where('isVerified', isEqualTo: true)
        .get();

    Map<String, int> counts = {for (var cat in categories) cat: 0};

    for (var doc in snapshot.docs) {
      final tech = TechnicianModel.fromFirestore(doc);
      final dist = DistanceUtils.calculateDistance(userLat, userLng, tech.lat, tech.lng);
      
      if (dist <= 15.0) {
        for (var cat in categories) {
          if (tech.skills.contains(cat.toLowerCase())) {
            counts[cat] = (counts[cat] ?? 0) + 1;
          }
        }
      }
    }
    return counts;
  }
}

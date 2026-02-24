class MatchedTechnician {
  final String id;
  final String name;
  final String? photoUrl;
  final double rating;
  final int totalCompletedOrders;
  final double distanceKm;
  final int estimatedArrivalMinutes;
  final double score;

  const MatchedTechnician({
    required this.id,
    required this.name,
    this.photoUrl,
    required this.rating,
    required this.totalCompletedOrders,
    required this.distanceKm,
    required this.estimatedArrivalMinutes,
    required this.score,
  });

  factory MatchedTechnician.fromMap(Map<String, dynamic> map) {
    return MatchedTechnician(
      id: map['id'] ?? '',
      name: map['name'] ?? 'Technician',
      photoUrl: map['photoUrl'] as String?,
      rating: (map['rating'] ?? 0).toDouble(),
      totalCompletedOrders: map['totalCompletedOrders'] ?? 0,
      distanceKm: (map['distanceKm'] ?? 0).toDouble(),
      estimatedArrivalMinutes: map['estimatedArrivalMinutes'] ?? 0,
      score: (map['score'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'photoUrl': photoUrl,
      'rating': rating,
      'totalCompletedOrders': totalCompletedOrders,
      'distanceKm': distanceKm,
      'estimatedArrivalMinutes': estimatedArrivalMinutes,
      'score': score,
    };
  }
}

class MatchingResponse {
  final bool available;
  final int? technicianCount;
  final List<MatchedTechnician>? topTechnicians;
  final String? error;

  const MatchingResponse({
    required this.available,
    this.technicianCount,
    this.topTechnicians,
    this.error,
  });

  factory MatchingResponse.fromMap(Map<String, dynamic> map) {
    final List<dynamic>? techniciansList = map['topTechnicians'];
    final List<MatchedTechnician>? technicians = techniciansList?.map((t) => MatchedTechnician.fromMap(t)).toList();

    return MatchingResponse(
      available: map['available'] ?? false,
      technicianCount: map['technicianCount'] as int?,
      topTechnicians: technicians,
      error: map['error'] as String?,
    );
  }
}

class CustomerLocation {
  final double latitude;
  final double longitude;

  const CustomerLocation({
    required this.latitude,
    required this.longitude,
  });

  Map<String, dynamic> toMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}

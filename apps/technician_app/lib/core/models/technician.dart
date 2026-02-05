import 'package:cloud_firestore/cloud_firestore.dart';

class Technician {
  final String uid;
  final String name;
  final String phone;
  final String email;
  final String? photoUrl;
  final List<String> skills;
  final bool isOnline;
  final bool isVerified;
  final double avgRating;
  final int totalRatings;
  final Map<String, int> ratingBreakdown;
  final int jobsDone;
  final double? lat;
  final double? lng;
  final String? referralCode;
  final String? kycStatus;
  final DateTime createdAt;
  final DateTime updatedAt;

  Technician({
    required this.uid,
    required this.name,
    required this.phone,
    required this.email,
    this.photoUrl,
    required this.skills,
    required this.isOnline,
    required this.isVerified,
    required this.avgRating,
    required this.totalRatings,
    required this.ratingBreakdown,
    required this.jobsDone,
    this.lat,
    this.lng,
    this.referralCode,
    this.kycStatus,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Technician.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    Map<String, dynamic>? geo = data['geo'];

    // Convert skills string to list if necessary
    dynamic skillsData = data['skills'];
    List<String> skillsList = [];
    if (skillsData is String) {
      skillsList = skillsData.split(',').map((e) => e.trim()).toList();
    } else if (skillsData is List) {
      skillsList = List<String>.from(skillsData);
    }

    // Rating breakdown map
    Map<String, int> breakdown = {};
    if (data['ratingBreakdown'] != null) {
      (data['ratingBreakdown'] as Map).forEach((key, value) {
        breakdown[key.toString()] = (value as num).toInt();
      });
    } else {
      breakdown = {"1": 0, "2": 0, "3": 0, "4": 0, "5": 0};
    }

    return Technician(
      uid: data['uid'] ?? doc.id,
      name: data['name'] ?? '',
      phone: data['phone'] ?? data['phoneNumber'] ?? '',
      email: data['email'] ?? '',
      photoUrl: data['photoUrl'],
      skills: skillsList,
      isOnline: data['isOnline'] ?? false,
      isVerified: data['isVerified'] ?? false,
      avgRating: (data['avgRating'] ?? data['rating'] ?? 4.5).toDouble(),
      totalRatings: data['totalRatings'] ?? data['reviewCount'] ?? 0,
      ratingBreakdown: breakdown,
      jobsDone: data['jobsDone'] ?? 0,
      lat: geo != null ? (geo['lat'] as num?)?.toDouble() : null,
      lng: geo != null ? (geo['lng'] as num?)?.toDouble() : null,
      referralCode: data['referralCode'],
      kycStatus: data['kycStatus'],
      createdAt: data['createdAt'] != null ? (data['createdAt'] as Timestamp).toDate() : DateTime.now(),
      updatedAt: data['updatedAt'] != null ? (data['updatedAt'] as Timestamp).toDate() : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'phone': phone,
      'email': email,
      'photoUrl': photoUrl,
      'skills': skills,
      'isOnline': isOnline,
      'isVerified': isVerified,
      'avgRating': avgRating,
      'totalRatings': totalRatings,
      'ratingBreakdown': ratingBreakdown,
      'jobsDone': jobsDone,
      'geo': lat != null && lng != null ? {'lat': lat, 'lng': lng} : null,
      'referralCode': referralCode,
      'kycStatus': kycStatus,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}

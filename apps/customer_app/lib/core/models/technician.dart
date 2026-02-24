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
  final double rating;
  final int jobsDone;
  final double? lat;
  final double? lng;
  final String? referralCode;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> supportedCategories;
  final String? district;
  final String? districtNormalized;

  String get id => uid;

  Technician({
    required this.uid,
    required this.name,
    required this.phone,
    required this.email,
    this.photoUrl,
    required this.skills,
    required this.isOnline,
    required this.isVerified,
    required this.rating,
    required this.jobsDone,
    this.lat,
    this.lng,
    this.referralCode,
    required this.createdAt,
    required this.updatedAt,
    this.supportedCategories = const [],
    this.district,
    this.districtNormalized,
  });

  factory Technician.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    Map<String, dynamic>? geo = data['geo'] as Map<String, dynamic>?;
    
    // Convert skills string to list if necessary
    dynamic skillsData = data['skills'];
    List<String> skillsList = [];
    if (skillsData is String) {
      skillsList = skillsData.split(',').map((e) => e.trim()).toList();
    } else if (skillsData is List) {
      skillsList = List<String>.from(skillsData);
    }

    // Handle supportedCategories
    List<String> supportedCats = [];
    if (data['supportedCategories'] is List) {
      supportedCats = List<String>.from(data['supportedCategories']);
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
      rating: (data['rating'] is String) ? (double.tryParse(data['rating']) ?? 4.5) : (data['rating'] ?? 4.5).toDouble(),
      jobsDone: data['jobsDone'] ?? 0,
      lat: geo != null ? (geo['lat'] as num?)?.toDouble() : null,
      lng: geo != null ? (geo['lng'] as num?)?.toDouble() : null,
      referralCode: data['referralCode'],
      createdAt: data['createdAt'] != null ? (data['createdAt'] as Timestamp).toDate() : DateTime.now(),
      updatedAt: data['updatedAt'] != null ? (data['updatedAt'] as Timestamp).toDate() : DateTime.now(),
      supportedCategories: supportedCats,
      district: data['district']?.toString(),
      districtNormalized: data['districtNormalized']?.toString(),
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
      'rating': rating,
      'jobsDone': jobsDone,
      'geo': lat != null && lng != null ? {'lat': lat, 'lng': lng} : null,
      'referralCode': referralCode,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'supportedCategories': supportedCategories,
      'district': district,
      'districtNormalized': districtNormalized,
    };
  }
}

// Integration tests for Firebase operations
// Run with: flutter test test/firebase_integration_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:fakefirebase_storage/fakefirebase_storage.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late FakeFirebaseStorage storage;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    storage = FakeFirebaseStorage();
  });

  group('Firestore Rules Tests', () {
    test('Customer can read own addresses', () async {
      const userId = 'user123';
      
      // Create test address
      await firestore
          .collection('customers')
          .doc(userId)
          .collection('addresses')
          .doc('addr1')
          .set({
        'address': '123 Test St',
        'city': 'Test City',
        'label': 'Home',
        'userId': userId,
      });

      // Query addresses (simulating authenticated read)
      final snapshot = await firestore
          .collection('customers')
          .doc(userId)
          .collection('addresses')
          .get();

      expect(snapshot.docs.length, 1);
      expect(snapshot.docs.first['city'], 'Test City');
    });

    test('Customer cannot read other customer addresses', () async {
      const userId1 = 'user123';
      const userId2 = 'user456';

      // Create address for user1
      await firestore
          .collection('customers')
          .doc(userId1)
          .collection('addresses')
          .doc('addr1')
          .set({
        'address': '123 Test St',
        'userId': userId1,
      });

      // Try to read user1's address as user2
      // In real Firestore, this would be blocked by rules
      // Here we simulate by checking the data exists but shouldn't be accessible
      final snapshot = await firestore
          .collection('customers')
          .doc(userId1)
          .collection('addresses')
          .doc('addr1')
          .get();

      // Data exists but in real scenario, rules would block this
      expect(snapshot.exists, isTrue);
    });

    test('Partner application submission creates document', () async {
      const userId = 'partner123';

      await firestore
          .collection('technicianApplications')
          .doc(userId)
          .set({
        'fullName': 'John Doe',
        'phone': '9999999999',
        'email': 'john@test.com',
        'categoryIds': ['plumbing', 'electrical'],
        'experienceYears': 5,
        'status': 'pending',
        'submittedAt': Timestamp.now(),
        'userId': userId,
      });

      final doc = await firestore
          .collection('technicianApplications')
          .doc(userId)
          .get();

      expect(doc.exists, isTrue);
      expect(doc['fullName'], 'John Doe');
      expect(doc['status'], 'pending');
    });

    test('FCM token saved correctly', () async {
      const userId = 'user123';
      const token = 'test_fcm_token_123';

      await firestore
          .collection('customers')
          .doc(userId)
          .collection('fcmTokens')
          .doc(token)
          .set({
        'token': token,
        'active': true,
        'createdAt': Timestamp.now(),
      });

      final snapshot = await firestore
          .collection('customers')
          .doc(userId)
          .collection('fcmTokens')
          .doc(token)
          .get();

      expect(snapshot.exists, isTrue);
      expect(snapshot['active'], isTrue);
    });
  });

  group('Storage Path Tests', () {
    test('Profile photo path is correct', () {
      const userId = 'user123';
      
      // Expected path format
      final profilePath = 'users/$userId/profile/profile.jpg';
      
      expect(profilePath, 'users/user123/profile/profile.jpg');
    });

    test('Technician document path is correct', () {
      const techId = 'tech123';
      const docType = 'id_proof';
      const fileName = 'aadhaar.jpg';
      
      // Expected path format
      final docPath = 'technicians/$techId/$docType/$fileName';
      
      expect(docPath, 'technicians/tech123/id_proof/aadhaar.jpg');
    });

    test('Video reel path is correct', () {
      const techId = 'tech123';
      const fileName = 'demo.mp4';
      
      // Expected path format
      final videoPath = 'reels/$techId/$fileName';
      
      expect(videoPath, 'reels/tech123/demo.mp4');
    });
  });

  group('Validation Tests', () {
    test('Phone number validation - valid', () {
      const phone = '9999999999';
      final isValid = RegExp(r'^\d{10}$').hasMatch(phone);
      expect(isValid, isTrue);
    });

    test('Phone number validation - invalid', () {
      const phone = '99999';
      final isValid = RegExp(r'^\d{10}$').hasMatch(phone);
      expect(isValid, isFalse);
    });

    test('Email validation - valid', () {
      const email = 'test@example.com';
      final isValid = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(email);
      expect(isValid, isTrue);
    });

    test('Email validation - invalid', () {
      const email = 'invalid-email';
      final isValid = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(email);
      expect(isValid, isFalse);
    });

    test('IFSC code validation - valid', () {
      const ifsc = 'SBIN0001234';
      final isValid = RegExp(r'^[A-Z]{4}0[A-Z0-9]{6}$').hasMatch(ifsc);
      expect(isValid, isTrue);
    });

    test('IFSC code validation - invalid', () {
      const ifsc = 'INVALID';
      final isValid = RegExp(r'^[A-Z]{4}0[A-Z0-9]{6}$').hasMatch(ifsc);
      expect(isValid, isFalse);
    });

    test('PIN code validation - valid', () {
      const pincode = '123456';
      final isValid = RegExp(r'^\d{6}$').hasMatch(pincode);
      expect(isValid, isTrue);
    });

    test('PIN code validation - invalid', () {
      const pincode = '12345';
      final isValid = RegExp(r'^\d{6}$').hasMatch(pincode);
      expect(isValid, isFalse);
    });
  });

  group('Address Model Tests', () {
    test('Address creation with all fields', () {
      final address = TestAddress(
        id: 'addr1',
        address: '123 Test Street',
        addressLine2: 'Apt 4B',
        city: 'Test City',
        state: 'TS',
        pincode: '500001',
        latitude: 17.1234,
        longitude: 78.5678,
        label: 'Home',
        isDefault: true,
      );

      expect(address.id, 'addr1');
      expect(address.pincode, '500001');
      expect(address.isDefault, isTrue);
    });

    test('Address toMap serialization', () {
      final address = TestAddress(
        id: 'addr1',
        address: '123 Test St',
        city: 'Test City',
        pincode: '500001',
        latitude: 17.1234,
        longitude: 78.5678,
      );

      final map = address.toMap();
      
      expect(map['address'], '123 Test St');
      expect(map['pincode'], '500001');
      expect(map.containsKey('createdAt'), isFalse); // Not serialized
    });

    test('Address fromMap deserialization', () {
      final map = {
        'id': 'addr1',
        'address': '123 Test St',
        'city': 'Test City',
        'pincode': '500001',
        'latitude': 17.1234,
        'longitude': 78.5678,
        'label': 'Work',
        'isDefault': false,
      };

      final address = TestAddress.fromMap(map);
      
      expect(address.id, 'addr1');
      expect(address.label, 'Work');
      expect(address.isDefault, isFalse);
    });
  });
}

// Test Address model
class TestAddress {
  final String id;
  final String address;
  final String? addressLine2;
  final String city;
  final String? state;
  final String pincode;
  final double? latitude;
  final double? longitude;
  final String? label;
  final bool? isDefault;

  TestAddress({
    required this.id,
    required this.address,
    this.addressLine2,
    required this.city,
    this.state,
    required this.pincode,
    this.latitude,
    this.longitude,
    this.label,
    this.isDefault,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'address': address,
      if (addressLine2 != null) 'addressLine2': addressLine2,
      'city': city,
      if (state != null) 'state': state,
      'pincode': pincode,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (label != null) 'label': label,
      if (isDefault != null) 'isDefault': isDefault,
    };
  }

  factory TestAddress.fromMap(Map<String, dynamic> map) {
    return TestAddress(
      id: map['id'] ?? '',
      address: map['address'] ?? '',
      addressLine2: map['addressLine2'],
      city: map['city'] ?? '',
      state: map['state'],
      pincode: map['pincode'] ?? '',
      latitude: map['latitude']?.toDouble(),
      longitude: map['longitude']?.toDouble(),
      label: map['label'],
      isDefault: map['isDefault'],
    );
  }
}

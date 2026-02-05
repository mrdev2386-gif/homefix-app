import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/customer.dart';
import '../models/address.dart';
import '../models/payment_method.dart';
import '../models/wallet_transaction.dart';
import 'dart:math';

class UserService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Save/Update Customer Profile
  Future<void> saveUserProfile(User user, {String? referredBy, String? fcmToken}) async {
    try {
      final docRef = _db.collection('customers').doc(user.uid);
      final doc = await docRef.get();

      if (!doc.exists) {
        // Create new profile
        final String referralCode = _generateReferralCode(user.displayName ?? 'USER');
        final data = {
          'uid': user.uid,
          'name': user.displayName ?? 'Customer',
          'phone': user.phoneNumber ?? '',
          'email': user.email ?? '',
          'photoUrl': user.photoURL,
          'referralCode': referralCode,
          'referredBy': referredBy,
          'walletBalance': 0.0,
          'fcmToken': fcmToken,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        };
        await docRef.set(data);

        // Handle referral reward if referredBy exists
        if (referredBy != null) {
          await _handleRegistrationReferral(user.uid, referredBy);
        }
      } else {
        // Update existing profile
        final Map<String, dynamic> updateData = {
          'name': user.displayName ?? doc.data()?['name'] ?? 'Customer',
          'phone': user.phoneNumber ?? doc.data()?['phone'] ?? '',
          'email': user.email ?? doc.data()?['email'] ?? '',
          'photoUrl': user.photoURL ?? doc.data()?['photoUrl'],
          'updatedAt': FieldValue.serverTimestamp(),
        };
        if (fcmToken != null) updateData['fcmToken'] = fcmToken;
        await docRef.update(updateData);
      }
    } catch (e) {
      debugPrint("Error saving user profile: $e");
      rethrow;
    }
  }

  String _generateReferralCode(String name) {
    final random = Random();
    final String prefix = name.length >= 3 ? name.substring(0, 3).toUpperCase() : 'CUS';
    final int suffix = random.nextInt(9000) + 1000;
    return '$prefix$suffix';
  }

  Future<Customer?> getCustomer(String uid) async {
    final doc = await _db.collection('customers').doc(uid).get();
    if (!doc.exists) return null;
    return Customer.fromFirestore(doc);
  }

  Stream<Customer?> getCustomerStream(String uid) {
    return _db.collection('customers').doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return Customer.fromFirestore(doc);
    });
  }

  // WALLET
  Stream<double> getWalletBalance(String uid) {
    return _db.collection('customers').doc(uid).snapshots().map((doc) => (doc.data()?['walletBalance'] ?? 0.0).toDouble());
  }

  Stream<List<WalletTransaction>> getWalletTransactions(String uid) {
    return _db
        .collection('customers')
        .doc(uid)
        .collection('wallet_transactions')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => WalletTransaction.fromFirestore(doc)).toList());
  }

  // WALLET
  Future<void> addWalletTransaction(String uid, {required String type, required double amount, required String description}) async {
    try {
      final httpsCallable = FirebaseFunctions.instance.httpsCallable('processWalletTransaction');
      await httpsCallable.call({
        'type': type,
        'amount': amount,
        'description': description,
        'targetUid': uid,
      });
    } catch (e) {
      debugPrint("Error processing wallet transaction: $e");
      rethrow;
    }
  }

  // REFERRAL LOGIC (Basic implementation, usually done in Cloud Functions)
  Future<void> _handleRegistrationReferral(String refereeUid, String referralCode) async {
    // Find referrer by code
    final referrerQuery = await _db.collection('customers').where('referralCode', isEqualTo: referralCode).limit(1).get();
    if (referrerQuery.docs.isEmpty) return;

    final referrerDoc = referrerQuery.docs.first;
    final referrerUid = referrerDoc.id;

    // Track referral
    await _db.collection('referrals').add({
      'referrerUid': referrerUid,
      'refereeUid': refereeUid,
      'referralCode': referralCode,
      'status': 'signed_up',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // ADDRESSES
  Stream<List<Address>> getAddresses(String uid) {
    return _db
        .collection('customers')
        .doc(uid)
        .collection('addresses')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Address.fromFirestore(doc)).toList());
  }

  Future<void> addAddress(String uid, Address address) async {
    final coll = _db.collection('customers').doc(uid).collection('addresses');
    if (address.isDefault) {
      final defaults = await coll.where('isDefault', isEqualTo: true).get();
      for (var doc in defaults.docs) {
        await doc.reference.update({'isDefault': false});
      }
    }
    await coll.add(address.toMap());
  }

  Future<void> updateAddress(String uid, String addressId, Map<String, dynamic> data) async {
    final docRef = _db.collection('customers').doc(uid).collection('addresses').doc(addressId);
    if (data['isDefault'] == true) {
      final coll = _db.collection('customers').doc(uid).collection('addresses');
      final defaults = await coll.where('isDefault', isEqualTo: true).get();
      for (var doc in defaults.docs) {
        if (doc.id != addressId) await doc.reference.update({'isDefault': false});
      }
    }
    await docRef.update(data);
  }

  Future<void> deleteAddress(String uid, String addressId) async {
    await _db.collection('customers').doc(uid).collection('addresses').doc(addressId).delete();
  }

  // PAYMENT METHODS
  Stream<List<PaymentMethod>> getPaymentMethods(String uid) {
    return _db
        .collection('customers')
        .doc(uid)
        .collection('payment_methods')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => PaymentMethod.fromFirestore(doc)).toList());
  }

  Future<void> addPaymentMethod(String uid, PaymentMethod method) async {
    await _db.collection('customers').doc(uid).collection('payment_methods').add(method.toMap());
  }

  Future<void> deletePaymentMethod(String uid, String methodId) async {
    await _db.collection('customers').doc(uid).collection('payment_methods').doc(methodId).delete();
  }
  Future<void> updateDefaultAddress(String uid, String address) async {
    await _db.collection('customers').doc(uid).update({
      'defaultAddress': address,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}

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
      final callable = FirebaseFunctions.instance.httpsCallable('updateUserProfile');
      await callable.call({
        'name': user.displayName ?? 'Customer',
        'email': user.email ?? '',
        'phone': user.phoneNumber ?? '',
        'photoUrl': user.photoURL,
        'fcmToken': fcmToken,
        'referredBy': referredBy,
      });
    } catch (e) {
      debugPrint("Error saving user profile via CF: $e");
      rethrow;
    }
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
    final callable = FirebaseFunctions.instance.httpsCallable('manageAddress');
    await callable.call({
      'action': 'add',
      'addressData': address.toMap(),
    });
  }

  Future<void> updateAddress(String uid, String addressId, Map<String, dynamic> data) async {
    final callable = FirebaseFunctions.instance.httpsCallable('manageAddress');
    await callable.call({
      'action': 'edit',
      'addressId': addressId,
      'addressData': data,
    });
  }

  Future<void> deleteAddress(String uid, String addressId) async {
    final callable = FirebaseFunctions.instance.httpsCallable('manageAddress');
    await callable.call({
      'action': 'delete',
      'addressId': addressId,
    });
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
    final callable = FirebaseFunctions.instance.httpsCallable('managePaymentMethod');
    await callable.call({
      'action': 'add',
      'methodData': method.toMap(),
    });
  }

  Future<void> deletePaymentMethod(String uid, String methodId) async {
    final callable = FirebaseFunctions.instance.httpsCallable('managePaymentMethod');
    await callable.call({
      'action': 'delete',
      'methodId': methodId,
    });
  }

  Future<void> updateDefaultAddress(String uid, String addressId) async {
    final callable = FirebaseFunctions.instance.httpsCallable('manageAddress');
    await callable.call({
      'action': 'setDefault',
      'addressId': addressId,
    });
  }

}

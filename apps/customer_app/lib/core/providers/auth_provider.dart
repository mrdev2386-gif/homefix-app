import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../firestore/user_service.dart';
import '../models/user_model.dart';
import '../models/address.dart';
import '../models/payment_method.dart';
import '../models/wallet_transaction.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();
  
  UserModel? _customer;
  UserModel? get customer => _customer;

  User? get currentUser => _authService.currentUser;
  User? get user => _authService.currentUser;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  StreamSubscription<UserModel?>? _customerSubscription;

  AuthProvider() {
    _authService.authStateChanges.listen((user) {
      if (user != null) {
        _listenToCustomerData(user.uid);
      } else {
        _customerSubscription?.cancel();
        _customer = null;
        notifyListeners();
      }
    });
  }

  void _listenToCustomerData(String uid) {
    _customerSubscription?.cancel();
    _customerSubscription = _userService.getUserStream(uid).listen((c) {
      _customer = c;
      notifyListeners();
    }, onError: (e) {
      debugPrint("AuthProvider: Error in user stream: $e");
    });
  }

  @override
  void dispose() {
    _customerSubscription?.cancel();
    super.dispose();
  }

  Future<void> signInWithGoogle() async {
    _isLoading = true;
    notifyListeners();
    try {
      await _authService.signInWithGoogle();
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
  }

  // Wallet
  Stream<List<WalletTransaction>> get walletTransactions {
    if (_customer == null) return const Stream.empty();
    return _userService.getWalletTransactions(_customer!.uid);
  }

  // Address Management
  Future<void> addAddress(Address address) async {
    if (_customer == null) return;
    await _userService.addAddress(_customer!.uid, address);
  }

  Future<void> updateAddress(String addressId, Map<String, dynamic> data) async {
    if (_customer == null) return;
    await _userService.updateAddress(_customer!.uid, addressId, data);
  }

  Future<void> deleteAddress(String addressId) async {
    if (_customer == null) return;
    await _userService.deleteAddress(_customer!.uid, addressId);
  }

  Future<void> updateDefaultAddress(String address) async {
    if (_customer == null) return;
    await _userService.updateDefaultAddress(_customer!.uid, address);
  }

  /// Update default location with coordinates (for location picker updates)
  Future<void> updateDefaultLocation(String address, double latitude, double longitude) async {
    if (_customer == null) return;
    await _userService.updateDefaultLocation(_customer!.uid, address, latitude, longitude);
  }

  Stream<List<Address>> get addresses {
    if (_customer == null) return const Stream.empty();
    return _userService.getAddresses(_customer!.uid);
  }

  // Payment Management
  Future<void> addPaymentMethod(PaymentMethod method) async {
    if (_customer == null) return;
    await _userService.addPaymentMethod(_customer!.uid, method);
  }

  Future<void> deletePaymentMethod(String methodId) async {
    if (_customer == null) return;
    await _userService.deletePaymentMethod(_customer!.uid, methodId);
  }

  Stream<List<PaymentMethod>> get paymentMethods {
    if (_customer == null) return const Stream.empty();
    return _userService.getPaymentMethods(_customer!.uid);
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/category_service.dart';
import '../models/user_model.dart';
import '../models/address.dart';
import '../models/payment_method.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  CategoryService? _categoryService;
  
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
        _categoryService?.clearLocationCache();
        _listenToCustomerData(user.uid);
      } else {
        _categoryService?.clearLocationCache();
        _customerSubscription?.cancel();
        _customer = null;
        notifyListeners();
      }
    });
  }

  void setCategoryService(CategoryService categoryService) {
    _categoryService = categoryService;
  }

  void _listenToCustomerData(String uid) {
    _customerSubscription?.cancel();
    // TODO: Implement user data stream listening
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
    _categoryService?.clearLocationCache();
    await _authService.signOut();
  }

  Future<void> addAddress(Address address) async {
    // TODO: Implement address management
  }

  Future<void> updateAddress(String addressId, Map<String, dynamic> data) async {
    // TODO: Implement address management
  }

  Future<void> deleteAddress(String addressId) async {
    // TODO: Implement address management
  }

  Future<void> updateDefaultAddress(String address) async {
    // TODO: Implement address management
  }

  Stream<List<Address>> get addresses {
    return const Stream.empty();
  }

  Future<void> addPaymentMethod(PaymentMethod method) async {
    // TODO: Implement payment management
  }

  Future<void> deletePaymentMethod(String methodId) async {
    // TODO: Implement payment management
  }

  Stream<List<PaymentMethod>> get paymentMethods {
    return const Stream.empty();
  }
}

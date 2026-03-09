import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../services/category_service.dart';
import '../models/user_model.dart';
import '../models/address.dart';
import '../models/payment_method.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();
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
        // Clear location cache on login (if service is available)
        _categoryService?.clearLocationCache();
        _listenToCustomerData(user.uid);
      } else {
        // Clear location cache on logout (if service is available)
        _categoryService?.clearLocationCache();
        _customerSubscription?.cancel();
        _customer = null;
        notifyListeners();
      }
    });
  }

  // Initialize CategoryService reference
  void setCategoryService(CategoryService categoryService) {
    _categoryService = categoryService;
  }

  void _listenToCustomerData(String uid) {
    _customerSubscription?.cancel();
    _customerSubscription = _userService.streamUser(uid).listen((c) {
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
    // Clear location cache before signing out (if service is available)
    _categoryService?.clearLocationCache();
    await _authService.signOut();
  }

  // Address Management
  Future<void> addAddress(Address address) async {
    if (_customer == null) return;
    await _userService.addAddress(_customer!.uid, address);
    // Clear location cache after adding address (if service is available)
    _categoryService?.clearLocationCache();
  }

  Future<void> updateAddress(String addressId, Map<String, dynamic> data) async {
    if (_customer == null) return;
    await _userService.updateAddress(_customer!.uid, addressId, data);
    // Clear location cache after updating address (if service is available)
    _categoryService?.clearLocationCache();
  }

  Future<void> deleteAddress(String addressId) async {
    if (_customer == null) return;
    await _userService.deleteAddress(_customer!.uid, addressId);
    // Clear location cache after deleting address (if service is available)
    _categoryService?.clearLocationCache();
  }

  Future<void> updateDefaultAddress(String address) async {
    if (_customer == null) return;
    await _userService.updateDefaultAddress(_customer!.uid, address);
    // Clear location cache after changing primary address (if service is available)
    _categoryService?.clearLocationCache();
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

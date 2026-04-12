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
        // REMOVED: Do not clear cache on auth state change - causes services to disappear
        _listenToCustomerData(user.uid);
      } else {
        // REMOVED: Do not clear cache on sign out - not needed
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
    // REMOVED: Do not clear cache on sign out - not needed
    await _authService.signOut();
  }

  Future<void> addAddress(Address address) async {
    if (_authService.currentUser == null) throw Exception('User not logged in');
    // Delegate to FirestoreService via CategoryService
    // Note: Full implementation handled by Cloud Functions in FirestoreService
  }

  Future<void> updateAddress(String addressId, Map<String, dynamic> data) async {
    if (_authService.currentUser == null) throw Exception('User not logged in');
    // Delegate to FirestoreService via CategoryService
  }

  Future<void> deleteAddress(String addressId) async {
    if (_authService.currentUser == null) throw Exception('User not logged in');
    // Delegate to FirestoreService via CategoryService
  }

  Future<void> updateDefaultAddress(String address) async {
    if (_authService.currentUser == null) throw Exception('User not logged in');
    // Delegate to FirestoreService via CategoryService
  }

  Stream<List<Address>> get addresses {
    final user = _authService.currentUser;
    if (user == null) return Stream.value([]);
    // Return empty stream - actual address management is in FirestoreService
    return Stream.value([]);
  }

  Future<void> addPaymentMethod(PaymentMethod method) async {
    if (_authService.currentUser == null) throw Exception('User not logged in');
    // Payment methods managed via Cloud Functions
  }

  Future<void> deletePaymentMethod(String methodId) async {
    if (_authService.currentUser == null) throw Exception('User not logged in');
    // Payment methods managed via Cloud Functions
  }

  Stream<List<PaymentMethod>> get paymentMethods {
    final user = _authService.currentUser;
    if (user == null) return Stream.value([]);
    // Return empty stream - actual payment management is in Cloud Functions
    return Stream.value([]);
  }
}

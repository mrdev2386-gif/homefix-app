import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/address.dart';
import '../services/address_service.dart';
import '../services/category_service.dart';

/// District-based LocationProvider (GPS-less for production simplicity)
class LocationProvider extends ChangeNotifier {
  final CategoryService _categoryService = CategoryService();
  late final AddressService _addressService = AddressService(_categoryService);
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  
  String _currentAddress = 'Select your location';
  String? _selectedDistrict;
  Address? _selectedAddress;
  bool _isLoading = false;
  String? _userId;
  String? _errorMessage;

  String get currentAddress => _selectedAddress?.fullAddress ?? _currentAddress;
  String? get selectedDistrict => _selectedDistrict;
  Address? get selectedAddress => _selectedAddress;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasLocation => _selectedAddress != null || _selectedDistrict != null;

  /// Initialize with user ID and load saved district
  Future<void> initialize(String userId) async {
    _userId = userId;
    await loadSelectedDistrict();
  }

  /// Load user's selected district from Firestore
  Future<void> loadSelectedDistrict() async {
    if (_userId == null) return;
    
    try {
      _isLoading = true;
      notifyListeners();
      
      final userDoc = await _db.collection('customers').doc(_userId).get();
      if (userDoc.exists) {
        final data = userDoc.data();
        _selectedDistrict = data?['districtNormalized'] ?? data?['district']?.toString();
        
        if (_selectedDistrict != null && _selectedDistrict!.isNotEmpty) {
          _currentAddress = _selectedDistrict!;
        }
        
        debugPrint('[DISTRICT_DISPLAY] Loaded district from Firestore: $_selectedDistrict');
      }
    } catch (e) {
      debugPrint('[DISTRICT_DISPLAY] Error loading district: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Set selected district and persist to Firestore
  Future<bool> setSelectedDistrict(String district) async {
    if (_userId == null) {
      _errorMessage = 'User not logged in';
      return false;
    }

    _selectedDistrict = district;
    _currentAddress = district;
    _errorMessage = null;
    notifyListeners();

    try {
      _isLoading = true;
      notifyListeners();
      
      final normalizedDistrict = district.trim().toLowerCase();
      
      await _db.collection('customers').doc(_userId).update({
        'district': district,
        'districtNormalized': normalizedDistrict,
      });
      
      debugPrint('[DISTRICT_DISPLAY] District saved: $normalizedDistrict');
      return true;
    } catch (e) {
      debugPrint('[LocationProvider] Error saving district: $e');
      _errorMessage = 'Failed to save district';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Set selected address and persist to Firestore
  Future<void> setSelectedAddress(Address address) async {
    _selectedAddress = address;
    _currentAddress = address.fullAddress;
    _errorMessage = null;
    notifyListeners();

    if (_userId != null) {
      try {
        await _addressService.updateSelectedAddress(_userId!, address.id);
      } catch (e) {
        debugPrint('[LocationProvider] Error persisting selected address: $e');
      }
    }
  }

  /// Clear selected address
  void clearSelectedAddress() {
    _selectedAddress = null;
    _currentAddress = _selectedDistrict ?? 'Select your location';
    notifyListeners();
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }


}

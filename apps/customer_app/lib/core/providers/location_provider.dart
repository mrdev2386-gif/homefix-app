import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../models/address.dart';
import '../services/address_service.dart';

/// Production-ready LocationProvider with comprehensive error handling
class LocationProvider extends ChangeNotifier {
  final AddressService _addressService = AddressService();
  
  String _currentAddress = 'Fetching location...';
  Address? _selectedAddress;
  Position? _currentPosition;
  bool _isLoading = false;
  String? _userId;
  String? _errorMessage;

  String get currentAddress => _selectedAddress?.fullAddress ?? _currentAddress;
  Address? get selectedAddress => _selectedAddress;
  Position? get currentPosition => _currentPosition;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Initialize with user ID and load selected address
  Future<void> initialize(String userId) async {
    _userId = userId;
    await loadSelectedAddress();
  }

  /// Load the user's selected address from Firestore
  Future<void> loadSelectedAddress() async {
    if (_userId == null) return;
    
    try {
      final address = await _addressService.getSelectedAddress(_userId!);
      if (address != null) {
        _selectedAddress = address;
        _currentAddress = address.fullAddress;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[LocationProvider] Error loading selected address: $e');
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

  /// Check if location service is enabled
  Future<bool> _checkLocationService() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    debugPrint('[LocationProvider] Location service enabled: $serviceEnabled');
    
    if (!serviceEnabled) {
      _currentAddress = 'Location service disabled';
      _errorMessage = 'Please enable location services in your device settings';
      return false;
    }
    return true;
  }

  /// Check and request location permission
  Future<bool> _checkLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    debugPrint('[LocationProvider] Current permission: $permission');

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      debugPrint('[LocationProvider] Permission after request: $permission');
      
      if (permission == LocationPermission.denied) {
        _currentAddress = 'Location permission denied';
        _errorMessage = 'Location permission is required to find nearby services';
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _currentAddress = 'Location permission denied permanently';
      _errorMessage = 'Please enable location permission in app settings';
      return false;
    }

    debugPrint('[LocationProvider] Permission granted: ${permission == LocationPermission.always || permission == LocationPermission.whileInUse}');
    return permission == LocationPermission.always || permission == LocationPermission.whileInUse;
  }

  /// Fetch current location with comprehensive error handling
  Future<LocationResult> fetchCurrentLocation() async {
    if (_userId == null) {
      return LocationResult.error('Please login to use location services');
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Step 1: Check location service
      debugPrint('[LocationProvider] Step 1: Checking location service...');
      if (!await _checkLocationService()) {
        _isLoading = false;
        notifyListeners();
        return LocationResult.error(_errorMessage ?? 'Location service disabled');
      }

      // Step 2: Check permission
      debugPrint('[LocationProvider] Step 2: Checking permission...');
      if (!await _checkLocationPermission()) {
        _isLoading = false;
        notifyListeners();
        return LocationResult.error(_errorMessage ?? 'Location permission denied');
      }

      // Step 3: Get position
      debugPrint('[LocationProvider] Step 3: Fetching position...');
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      // Step 4: Reverse geocode
      debugPrint('[LocationProvider] Step 4: Reverse geocoding...');
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          debugPrint('[LocationProvider] ⚠️ Geocoding timeout, using coordinates only');
          return [];
        },
      );

      String addressText;
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        final addressParts = [
          place.name,
          place.subLocality,
          place.locality,
        ].where((part) => part != null && part.isNotEmpty).toList();
        
        addressText = addressParts.isNotEmpty 
            ? addressParts.join(', ') 
            : 'Lat: ${position.latitude.toStringAsFixed(4)}, Lng: ${position.longitude.toStringAsFixed(4)}';
        
        debugPrint('[LocationProvider] ✅ Address: $addressText');
      } else {
        addressText = 'Lat: ${position.latitude.toStringAsFixed(4)}, Lng: ${position.longitude.toStringAsFixed(4)}';
        debugPrint('[LocationProvider] ⚠️ No address found, using coordinates');
      }

      _currentAddress = addressText;
      _errorMessage = null;
      _isLoading = false;
      notifyListeners();

      return LocationResult.success(position, addressText);

    } on TimeoutException catch (e) {
      debugPrint('[LocationProvider] ❌ Timeout: $e');
      _currentAddress = 'Location request timed out';
      _errorMessage = 'Location request took too long. Please try again.';
      _isLoading = false;
      notifyListeners();
      return LocationResult.error(_errorMessage!);
      
    } on PermissionDeniedException catch (e) {
      debugPrint('[LocationProvider] ❌ Permission denied: $e');
      _currentAddress = 'Location permission denied';
      _errorMessage = 'Location permission is required';
      _isLoading = false;
      notifyListeners();
      return LocationResult.error(_errorMessage!);
      
    } on LocationServiceDisabledException catch (e) {
      debugPrint('[LocationProvider] ❌ Service disabled: $e');
      _currentAddress = 'Location service disabled';
      _errorMessage = 'Please enable location services';
      _isLoading = false;
      notifyListeners();
      return LocationResult.error(_errorMessage!);
      
    } catch (e) {
      debugPrint('[LocationProvider] ❌ Unexpected error: $e');
      _currentAddress = 'Location unavailable';
      _errorMessage = 'Unable to fetch location. Please try again.';
      _isLoading = false;
      notifyListeners();
      return LocationResult.error(_errorMessage!);
    }
  }

  /// Update current location and optionally save to Firestore
  Future<bool> updateCurrentLocation({bool saveToFirestore = false}) async {
    final result = await fetchCurrentLocation();
    
    if (result.isSuccess && saveToFirestore && result.position != null) {
      try {
        // Get detailed address for Firestore
        List<Placemark> placemarks = await placemarkFromCoordinates(
          result.position!.latitude,
          result.position!.longitude,
        ).timeout(const Duration(seconds: 10));

        if (placemarks.isNotEmpty) {
          Placemark place = placemarks[0];
          final fullAddress = [
            place.street,
            place.subLocality,
            place.locality,
            place.administrativeArea,
          ].where((part) => part != null && part.isNotEmpty).join(', ');

          final addressId = await _addressService.saveCurrentLocationAddress(
            userId: _userId!,
            latitude: result.position!.latitude,
            longitude: result.position!.longitude,
            fullAddress: fullAddress.isNotEmpty ? fullAddress : result.address,
            city: place.locality ?? 'Unknown',
            landmark: place.subLocality,
            pincode: place.postalCode,
          );

          // Load and set as selected
          final newAddress = await _addressService.getAddress(_userId!, addressId);
          if (newAddress != null) {
            await setSelectedAddress(newAddress);
          }
        }
      } catch (e) {
        debugPrint('[LocationProvider] Error saving to Firestore: $e');
        // Don't fail the whole operation if save fails
      }
    }

    return result.isSuccess;
  }

  /// Open location settings
  Future<void> openLocationSettings() async {
    try {
      await Geolocator.openLocationSettings();
    } catch (e) {
      debugPrint('[LocationProvider] Error opening location settings: $e');
    }
  }

  /// Open app settings for permission
  Future<void> openAppSettings() async {
    try {
      await Geolocator.openAppSettings();
    } catch (e) {
      debugPrint('[LocationProvider] Error opening app settings: $e');
    }
  }

  /// Clear selected address
  void clearSelectedAddress() {
    _selectedAddress = null;
    _currentAddress = 'Select location';
    notifyListeners();
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}

/// Result object for location operations
class LocationResult {
  final bool isSuccess;
  final Position? position;
  final String address;
  final String? error;

  LocationResult._({
    required this.isSuccess,
    this.position,
    required this.address,
    this.error,
  });

  factory LocationResult.success(Position position, String address) {
    return LocationResult._(
      isSuccess: true,
      position: position,
      address: address,
    );
  }

  factory LocationResult.error(String error) {
    return LocationResult._(
      isSuccess: false,
      address: '',
      error: error,
    );
  }
}


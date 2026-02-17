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
      // Open app settings for the user to manually enable
      await Geolocator.openAppSettings();
      debugPrint('[LocationProvider] Opened app settings for permanently denied permission');
      return false;
    }

    debugPrint('[LocationProvider] Permission granted: ${permission == LocationPermission.always || permission == LocationPermission.whileInUse}');
    return permission == LocationPermission.always || permission == LocationPermission.whileInUse;
  }

  /// Fetch current location with HARD safety flow
  Future<LocationResult> fetchCurrentLocation() async {
    if (_userId == null) {
      return LocationResult.error('Please login to use location services');
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Check if location services are enabled
      if (!await Geolocator.isLocationServiceEnabled()) {
        debugPrint('❌ LOCATION FAILED — service disabled');
        _errorMessage = 'Please enable location services in your device settings';
        _isLoading = false;
        notifyListeners();
        return LocationResult.error(_errorMessage!);
      }

      // 2. Permission flow
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('❌ LOCATION FAILED — permission denied forever');
        _errorMessage = 'Location permission is permanently denied. Please enable it in app settings.';
        _isLoading = false;
        notifyListeners();
        // Optionally open app settings
        return LocationResult.error(_errorMessage!);
      }

      if (permission == LocationPermission.denied) {
        debugPrint('❌ LOCATION FAILED — permission denied');
        _errorMessage = 'Location permission is required.';
        _isLoading = false;
        notifyListeners();
        return LocationResult.error(_errorMessage!);
      }

      // 3. Safe fetch with 15s timeout
      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        ).timeout(const Duration(seconds: 15));
      } catch (e) {
        debugPrint('⚠️ CURRENT POSITION TIMEOUT/FAILED ($e) — trying last known...');
        position = await Geolocator.getLastKnownPosition();
      }

      // 4. FINAL GUARD
      if (position == null) {
        debugPrint('❌ LOCATION FAILED — no position available');
        _errorMessage = 'Could not determine location. Please try again.';
        _isLoading = false;
        notifyListeners();
        return LocationResult.error(_errorMessage!);
      }
      
      debugPrint('✅ LOCATION SUCCESS — position obtained');
      _currentPosition = position;

      // 5. Reverse geocode (Best effort)
      List<Placemark> placemarks = [];
      try {
        placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        ).timeout(const Duration(seconds: 10));
      } catch (e) {
        debugPrint('⚠️ GEOCODING FAILED: $e');
      }

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
      } else {
        addressText = 'Lat: ${position.latitude.toStringAsFixed(4)}, Lng: ${position.longitude.toStringAsFixed(4)}';
      }

      _currentAddress = addressText;
      _errorMessage = null;
      _isLoading = false;
      notifyListeners();

      return LocationResult.success(position, addressText);

    } catch (e) {
      debugPrint('❌ UNEXPECTED LOCATION ERROR: $e');
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


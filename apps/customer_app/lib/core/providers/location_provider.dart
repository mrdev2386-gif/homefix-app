import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/address.dart';
import '../services/address_service.dart';

/// Enhanced LocationProvider with permission handling and address persistence
class LocationProvider extends ChangeNotifier {
  final AddressService _addressService = AddressService();
  
  String _currentAddress = 'Fetching location...';
  Address? _selectedAddress;
  Position? _currentPosition;
  bool _isLoading = false;
  String? _userId;

  String get currentAddress => _selectedAddress?.fullAddress ?? _currentAddress;
  Address? get selectedAddress => _selectedAddress;
  Position? get currentPosition => _currentPosition;
  bool get isLoading => _isLoading;

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
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[LocationProvider] Error loading selected address: $e');
    }
  }

  /// Set selected address and persist to Firestore
  Future<void> setSelectedAddress(Address address) async {
    _selectedAddress = address;
    notifyListeners();

    if (_userId != null) {
      try {
        await _addressService.updateSelectedAddress(_userId!, address.id);
      } catch (e) {
        debugPrint('[LocationProvider] Error persisting selected address: $e');
      }
    }
  }

  /// Check location permission status
  Future<PermissionStatus> checkLocationPermission() async {
    return await Permission.location.status;
  }

  /// Request location permission
  Future<PermissionStatus> requestLocationPermission() async {
    return await Permission.location.request();
  }

  /// Update current location with permission handling and Firestore save
  Future<bool> updateCurrentLocation({bool saveToFirestore = false}) async {
    if (_userId == null) {
      _currentAddress = 'Login required';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    notifyListeners();

    try {
      // Check if location service is enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _currentAddress = 'Enable Location';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Check permission
      PermissionStatus permission = await checkLocationPermission();
      
      if (permission.isDenied) {
        permission = await requestLocationPermission();
        if (permission.isDenied) {
          _currentAddress = 'Location Denied';
          _isLoading = false;
          notifyListeners();
          return false;
        }
      }

      if (permission.isPermanentlyDenied) {
        _currentAddress = 'Location Denied';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      _currentPosition = position;

      // Reverse geocode to get address
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        final addressParts = [
          place.name,
          place.subLocality,
          place.locality,
        ].where((part) => part != null && part.isNotEmpty).toList();
        
        _currentAddress = addressParts.join(', ');

        // Save to Firestore if requested
        if (saveToFirestore) {
          final fullAddress = [
            place.street,
            place.subLocality,
            place.locality,
            place.administrativeArea,
          ].where((part) => part != null && part.isNotEmpty).join(', ');

          final addressId = await _addressService.saveCurrentLocationAddress(
            userId: _userId!,
            latitude: position.latitude,
            longitude: position.longitude,
            fullAddress: fullAddress,
            city: place.locality ?? '',
            landmark: place.subLocality,
            pincode: place.postalCode,
          );

          // Load the newly created address and set as selected
          final newAddress = await _addressService.getAddress(_userId!, addressId);
          if (newAddress != null) {
            await setSelectedAddress(newAddress);
          }
        }

        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('[LocationProvider] Error updating location: $e');
      _currentAddress = 'Unavailable';
      _isLoading = false;
      notifyListeners();
      return false;
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  /// Open app settings for permission
  Future<void> openAppSettings() async {
    await openAppSettings();
  }

  /// Clear selected address
  void clearSelectedAddress() {
    _selectedAddress = null;
    notifyListeners();
  }
}


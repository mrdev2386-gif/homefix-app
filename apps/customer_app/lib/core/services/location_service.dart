import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Production-grade Location Service
/// Handles GPS location fetching, reverse geocoding, and Firestore persistence
class LocationService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  
  // Race condition prevention
  bool _isDetecting = false;

  /// Check if location service is enabled
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Check and request location permission
  Future<LocationPermissionStatus> checkAndRequestPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      
      if (permission == LocationPermission.denied) {
        return LocationPermissionStatus.denied;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return LocationPermissionStatus.deniedForever;
    }

    return LocationPermissionStatus.granted;
  }

  /// Fetch current GPS coordinates
  Future<Position> getCurrentPosition() async {
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
      timeLimit: const Duration(seconds: 15),
    );
  }

  /// Reverse geocode coordinates to readable address
  Future<LocationAddress> reverseGeocode(double latitude, double longitude) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        latitude,
        longitude,
      ).timeout(
        const Duration(seconds: 10),
      );

      if (placemarks.isEmpty) {
        // Graceful fallback to coordinates
        return _createFallbackAddress(latitude, longitude);
      }

      final place = placemarks.first;
      
      // Extract address components
      final locality = place.locality ?? '';
      final subLocality = place.subLocality ?? '';
      final administrativeArea = place.administrativeArea ?? '';
      final country = place.country ?? '';
      final postalCode = place.postalCode ?? '';
      final street = place.street ?? '';

      // Format with fallback chain: locality ?? subLocality ?? administrativeArea ?? "Unknown Location"
      final formattedAddress = locality.isNotEmpty
          ? locality
          : (subLocality.isNotEmpty
              ? subLocality
              : (administrativeArea.isNotEmpty
                  ? administrativeArea
                  : 'Unknown Location'));

      // Build full formatted address: "Deoghar, Jharkhand, India"
      final addressParts = <String>[];
      if (locality.isNotEmpty) addressParts.add(locality);
      if (administrativeArea.isNotEmpty) addressParts.add(administrativeArea);
      if (country.isNotEmpty) addressParts.add(country);
      
      final displayAddress = addressParts.isNotEmpty
          ? addressParts.join(', ')
          : formattedAddress;

      // Full address with more details
      final fullAddressParts = <String>[];
      if (street.isNotEmpty) fullAddressParts.add(street);
      if (subLocality.isNotEmpty) fullAddressParts.add(subLocality);
      if (locality.isNotEmpty) fullAddressParts.add(locality);
      if (administrativeArea.isNotEmpty) fullAddressParts.add(administrativeArea);
      if (postalCode.isNotEmpty) fullAddressParts.add(postalCode);

      final fullAddress = fullAddressParts.isNotEmpty
          ? fullAddressParts.join(', ')
          : displayAddress;

      return LocationAddress(
        formattedAddress: displayAddress,
        fullAddress: fullAddress,
        locality: locality,
        subLocality: subLocality,
        administrativeArea: administrativeArea,
        country: country,
        postalCode: postalCode,
        latitude: latitude,
        longitude: longitude,
      );
    } catch (e) {
      // Graceful fallback on any error
      _logDebug('Reverse geocoding failed: $e');
      return _createFallbackAddress(latitude, longitude);
    }
  }

  /// Create fallback address using coordinates
  LocationAddress _createFallbackAddress(double latitude, double longitude) {
    final coordsString = 'Lat: ${latitude.toStringAsFixed(4)}, Lng: ${longitude.toStringAsFixed(4)}';
    return LocationAddress(
      formattedAddress: coordsString,
      fullAddress: coordsString,
      locality: '',
      subLocality: '',
      administrativeArea: '',
      country: '',
      postalCode: '',
      latitude: latitude,
      longitude: longitude,
    );
  }

  /// Save address to Firestore: users/{uid}/profile/currentAddress
  Future<void> saveCurrentAddress({
    required String userId,
    required LocationAddress address,
  }) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('profile')
        .doc('currentAddress')
        .set({
      'formattedAddress': address.formattedAddress,
      'fullAddress': address.fullAddress,
      'locality': address.locality,
      'subLocality': address.subLocality,
      'administrativeArea': address.administrativeArea,
      'country': address.country,
      'postalCode': address.postalCode,
      'latitude': address.latitude,
      'longitude': address.longitude,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Open device location settings
  Future<void> openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }

  /// Open app settings for permissions
  Future<void> openAppSettings() async {
    await Geolocator.openAppSettings();
  }

  /// Complete location detection flow with UI dialogs
  /// Returns the fetched address or null if failed/cancelled
  /// CRITICAL: Saves to Firestore ONLY after user confirms via "Use This Location" button
  Future<LocationAddress?> detectLocationWithUI({
    required BuildContext context,
    required String userId,
  }) async {
    // Prevent race conditions - only one detection at a time
    if (_isDetecting) {
      _logDebug('Location detection already in progress, ignoring request');
      return null;
    }

    _isDetecting = true;
    bool isLoadingDialogShown = false;

    try {
      // Step 1: Check location service
      final serviceEnabled = await isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!context.mounted) return null;
        
        await _showErrorDialog(
          context: context,
          title: 'Location Service Disabled',
          message: 'Please enable location services to detect your address.',
          actionButtonText: 'Open Settings',
          onAction: openLocationSettings,
        );
        return null;
      }

      // Step 2: Check and request permission
      final permissionStatus = await checkAndRequestPermission();
      
      if (!context.mounted) return null;
      
      if (permissionStatus == LocationPermissionStatus.denied) {
        await _showErrorDialog(
          context: context,
          title: 'Permission Denied',
          message: 'Location permission is required to detect your address.',
          actionButtonText: 'Retry',
          onAction: () {
            // Don't recursively call - let user tap button again
          },
        );
        return null;
      }

      if (permissionStatus == LocationPermissionStatus.deniedForever) {
        await _showErrorDialog(
          context: context,
          title: 'Permission Permanently Denied',
          message: 'Please enable location permission from app settings.',
          actionButtonText: 'Open Settings',
          onAction: openAppSettings,
        );
        return null;
      }

      // Step 3: Show loading dialog
      if (!context.mounted) return null;
      
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text('Detecting location...'),
            ],
          ),
        ),
      );
      isLoadingDialogShown = true;

      // Step 4: Fetch GPS coordinates
      final position = await getCurrentPosition();

      // Step 5: Reverse geocode
      final address = await reverseGeocode(position.latitude, position.longitude);

      // Step 6: Close loading dialog safely
      if (context.mounted && isLoadingDialogShown) {
        Navigator.of(context, rootNavigator: true).pop();
        isLoadingDialogShown = false;
      }

      // Step 7: Show success dialog and wait for user confirmation
      if (!context.mounted) return null;
      
      final confirmed = await _showSuccessDialog(
        context: context,
        address: address,
        userId: userId,
      );

      // Step 8: Return address only if user confirmed
      return confirmed ? address : null;

    } catch (e) {
      _logDebug('Location detection error: $e');
      
      // Close loading dialog if open
      if (context.mounted && isLoadingDialogShown) {
        Navigator.of(context, rootNavigator: true).pop();
        isLoadingDialogShown = false;
      }

      // Show error dialog
      if (context.mounted) {
        await _showErrorDialog(
          context: context,
          title: 'Location Fetch Failed',
          message: 'Unable to fetch your location. Please try again.',
          actionButtonText: 'Retry',
          onAction: () {
            // Don't recursively call - let user tap button again
          },
        );
      }

      return null;
    } finally {
      _isDetecting = false;
    }
  }

  /// Show error dialog helper
  Future<void> _showErrorDialog({
    required BuildContext context,
    required String title,
    required String message,
    String? actionButtonText,
    VoidCallback? onAction,
  }) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onAction?.call();
            },
            child: Text(actionButtonText ?? 'OK'),
          ),
        ],
      ),
    );
  }

  /// Show success dialog helper
  /// Returns true if user confirmed, false if cancelled
  Future<bool> _showSuccessDialog({
    required BuildContext context,
    required LocationAddress address,
    required String userId,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirm Location'),
        content: Text('Use this address?\n\n${address.formattedAddress}'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop(false);
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              // Save to Firestore ONLY when user confirms
              try {
                await saveCurrentAddress(userId: userId, address: address);
                if (dialogContext.mounted) {
                  // Show success message before closing
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(
                      content: Text('Location updated successfully'),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                      duration: Duration(seconds: 2),
                    ),
                  );
                  // Wait a bit for user to see the snackbar
                  await Future.delayed(const Duration(milliseconds: 500));
                  Navigator.of(dialogContext).pop(true);
                }
              } catch (e) {
                _logDebug('Failed to save address: $e');
                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop(false);
                  // Show error
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Failed to save location. Please try again.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    
    return result ?? false;
  }

  /// Debug logging helper (only in debug mode)
  void _logDebug(String message) {
    if (kDebugMode) {
      debugPrint('[LocationService] $message');
    }
  }
}

/// Location address data model
class LocationAddress {
  final String formattedAddress; // "Deoghar, Jharkhand, India"
  final String fullAddress; // Full detailed address
  final String locality;
  final String subLocality;
  final String administrativeArea;
  final String country;
  final String postalCode;
  final double latitude;
  final double longitude;

  LocationAddress({
    required this.formattedAddress,
    required this.fullAddress,
    required this.locality,
    required this.subLocality,
    required this.administrativeArea,
    required this.country,
    required this.postalCode,
    required this.latitude,
    required this.longitude,
  });
}

/// Location permission status
enum LocationPermissionStatus {
  granted,
  denied,
  deniedForever,
}

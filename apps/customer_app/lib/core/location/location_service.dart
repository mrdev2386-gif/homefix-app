import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocationService {
  static const String _latKey = 'last_lat';
  static const String _lngKey = 'last_lng';
  static const String _addressKey = 'last_address';

  Future<Position?> getCurrentPosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return null;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return null;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      await _saveLastLocation(position);
      return position;
    } catch (e) {
      debugPrint("Error getting location: $e");
      return null;
    }
  }

  Future<void> _saveLastLocation(Position position) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_latKey, position.latitude);
    await prefs.setDouble(_lngKey, position.longitude);
    
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final address = "${place.subLocality}, ${place.locality}";
        await prefs.setString(_addressKey, address);
      }
    } catch (e) {
      debugPrint("Error geocoding: $e");
    }
  }

  Future<Map<String, dynamic>> getLastKnownLocation() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'lat': prefs.getDouble(_latKey),
      'lng': prefs.getDouble(_lngKey),
      'address': prefs.getString(_addressKey) ?? 'Select Location',
    };
  }
}

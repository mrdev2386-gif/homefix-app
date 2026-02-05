import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../models/address.dart';

class LocationProvider extends ChangeNotifier {
  String _currentAddress = 'Fetching location...';
  Address? _selectedAddress;
  Position? _currentPosition;

  String get currentAddress => _selectedAddress?.fullAddress ?? _currentAddress;
  Address? get selectedAddress => _selectedAddress;
  Position? get currentPosition => _currentPosition;

  void setSelectedAddress(Address address) {
    _selectedAddress = address;
    notifyListeners();
  }

  Future<void> updateCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _currentAddress = 'Enable Location';
        notifyListeners();
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _currentAddress = 'Location Denied';
          notifyListeners();
          return;
        }
      }

      Position position = await Geolocator.getCurrentPosition();
      _currentPosition = position;
      
      List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        _currentAddress = '${place.name}, ${place.subLocality}, ${place.locality}';
        notifyListeners();
      }
    } catch (e) {
      _currentAddress = 'Unavailable';
      notifyListeners();
    }
  }
}

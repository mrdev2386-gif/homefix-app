import 'package:shared_preferences/shared_preferences.dart';

class LocationService {
  static const String _stateKey = 'customer_state';
  static const String _districtKey = 'customer_district';

  Future<void> saveLocation(String state, String district) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_stateKey, state);
    await prefs.setString(_districtKey, district);
  }

  Future<Map<String, String?>> getLocation() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'state': prefs.getString(_stateKey),
      'district': prefs.getString(_districtKey),
    };
  }

  Future<String?> getState() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_stateKey);
  }

  Future<String?> getDistrict() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_districtKey);
  }

  Future<void> clearLocation() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_stateKey);
    await prefs.remove(_districtKey);
  }
}

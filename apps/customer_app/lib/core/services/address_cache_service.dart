import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class AddressCacheService {
  static const String _primaryAddressCacheKey = 'primary_address_cache';

  /// Cache primary address locally
  static Future<void> cachePrimaryAddress({
    required String addressId,
    required String district,
    required String area,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final cacheData = {
      'addressId': addressId,
      'district': district,
      'area': area,
      'cachedAt': DateTime.now().toIso8601String(),
    };
    await prefs.setString(_primaryAddressCacheKey, jsonEncode(cacheData));
  }

  /// Get cached primary address
  static Future<Map<String, String>?> getCachedPrimaryAddress() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(_primaryAddressCacheKey);
    if (cached == null) return null;

    try {
      final data = jsonDecode(cached) as Map<String, dynamic>;
      return {
        'addressId': data['addressId'] as String,
        'district': data['district'] as String,
        'area': data['area'] as String,
      };
    } catch (e) {
      return null;
    }
  }

  /// Clear cached primary address
  static Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_primaryAddressCacheKey);
  }
}

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/user_settings_service.dart';
import '../models/user_settings.dart';

class LocaleProvider extends ChangeNotifier {
  Locale _locale = const Locale('en');
  final UserSettingsService _settingsService = UserSettingsService();
  String? _userId;

  Locale get locale => _locale;

  LocaleProvider() {
    _loadSavedLocale();
  }

  /// Load saved locale from SharedPreferences on app start
  Future<void> _loadSavedLocale() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final languageCode = prefs.getString('language_code') ?? 'en';
      _locale = Locale(languageCode);
      notifyListeners();
    } catch (e) {
      debugPrint('[LocaleProvider] Error loading saved locale: $e');
    }
  }

  /// Set user ID and sync with Firestore
  void setUserId(String? userId) {
    _userId = userId;
    if (userId != null) {
      _syncWithFirestore();
    }
  }

  /// Sync locale with Firestore (load from Firestore if available)
  Future<void> _syncWithFirestore() async {
    if (_userId == null) return;

    try {
      final settings = await _settingsService.getUserSettings(_userId!);
      final firestoreLanguage = settings.preferences.language;
      
      if (firestoreLanguage != _locale.languageCode) {
        _locale = Locale(firestoreLanguage);
        
        // Update local cache
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('language_code', firestoreLanguage);
        
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[LocaleProvider] Error syncing with Firestore: $e');
    }
  }

  /// Change locale and persist to both SharedPreferences and Firestore
  Future<void> setLocale(Locale locale) async {
    if (_locale == locale) return;

    _locale = locale;
    notifyListeners();

    try {
      // Save to SharedPreferences (local cache)
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('language_code', locale.languageCode);

      // Save to Firestore (if user is logged in)
      if (_userId != null) {
        final settings = await _settingsService.getUserSettings(_userId!);
        final updatedPreferences = settings.preferences.copyWith(
          language: locale.languageCode,
        );
        await _settingsService.updatePreferenceSettings(
          _userId!,
          updatedPreferences,
        );
      }
    } catch (e) {
      debugPrint('[LocaleProvider] Error saving locale: $e');
    }
  }

  /// Clear locale (reset to English)
  Future<void> clearLocale() async {
    _locale = const Locale('en');
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('language_code');
    } catch (e) {
      debugPrint('[LocaleProvider] Error clearing locale: $e');
    }
  }
}

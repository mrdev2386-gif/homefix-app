import 'package:flutter/material.dart';
import '../services/user_settings_service.dart';

class LocaleProvider extends ChangeNotifier {
  final UserSettingsService _settingsService = UserSettingsService();

  Locale? _locale;
  String? _userId;

  Locale? get locale => _locale ?? const Locale('en');

  LocaleProvider();

  void setUserId(String? userId) {
    _userId = userId;
  }

  Future<void> initialize(String userId) async {
    _userId = userId;
    try {
      final settings = await _settingsService.getUserSettings(userId);
      if (settings != null) {
        final firestoreLanguage = settings.preferences.language;

        if (firestoreLanguage != _locale?.languageCode) {
          _locale = Locale(firestoreLanguage);
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('[LocaleProvider] Error initializing: $e');
    }
  }

  Future<void> setLocale(Locale locale) async {
    if (_locale == locale) return;

    _locale = locale;
    notifyListeners();

    try {
      if (_userId != null) {
        final settings = await _settingsService.getUserSettings(_userId!);
        final updatedData = {
          'language': locale.languageCode,
        };
        await _settingsService.updatePreferenceSettings(_userId!, updatedData);
      }
    } catch (e) {
      debugPrint('[LocaleProvider] Error saving locale: $e');
    }
  }
}

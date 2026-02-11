import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppLocalizations {
  final Locale locale;
  Map<String, String> _localizedStrings = {};

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  Future<bool> load() async {
    try {
      String jsonString = await rootBundle.loadString(
        'lib/l10n/${locale.languageCode}.json',
      );
      Map<String, dynamic> jsonMap = json.decode(jsonString);
      _localizedStrings = jsonMap.map((key, value) {
        return MapEntry(key, value.toString());
      });
      return true;
    } catch (e) {
      debugPrint('[AppLocalizations] Error loading ${locale.languageCode}.json: $e');
      // Fallback to English if loading fails
      if (locale.languageCode != 'en') {
        try {
          String jsonString = await rootBundle.loadString('lib/l10n/en.json');
          Map<String, dynamic> jsonMap = json.decode(jsonString);
          _localizedStrings = jsonMap.map((key, value) {
            return MapEntry(key, value.toString());
          });
        } catch (fallbackError) {
          debugPrint('[AppLocalizations] Fallback to English also failed: $fallbackError');
          // Use hardcoded fallbacks as last resort
          _localizedStrings = _getHardcodedFallbacks();
        }
      } else {
        // English failed, use hardcoded fallbacks
        _localizedStrings = _getHardcodedFallbacks();
      }
      return false;
    }
  }

  /// Hardcoded fallback strings to prevent crashes
  Map<String, String> _getHardcodedFallbacks() {
    return {
      'home': 'Home',
      'services': 'Services',
      'bookings': 'Bookings',
      'profile': 'Profile',
      'settings': 'Settings',
      'language': 'Language',
      'notifications': 'Notifications',
      'login': 'Login',
      'logout': 'Logout',
      'cancel': 'Cancel',
      'save': 'Save',
      'continue': 'Continue',
    };
  }

  String translate(String key, {Map<String, String>? params}) {
    String translation = _localizedStrings[key] ?? key;
    
    // Replace parameters if provided
    if (params != null) {
      params.forEach((paramKey, paramValue) {
        translation = translation.replaceAll('{$paramKey}', paramValue);
      });
    }
    
    return translation;
  }

  // Convenience getters for common translations
  String get home => translate('home');
  String get services => translate('services');
  String get bookings => translate('bookings');
  String get profile => translate('profile');
  String get settings => translate('settings');
  String get language => translate('language');
  String get notifications => translate('notifications');
  String get login => translate('login');
  String get logout => translate('logout');
  String get cancel => translate('cancel');
  String get save => translate('save');
  String get continueText => translate('continue');
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'hi'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    AppLocalizations localizations = AppLocalizations(locale);
    await localizations.load();
    return localizations;
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

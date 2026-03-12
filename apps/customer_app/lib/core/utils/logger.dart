import 'package:flutter/foundation.dart';

/// Centralized logging utility for HomeFix customer app
/// 
/// Features:
/// - Standardized log format with emoji prefixes
/// - Module-based categorization
/// - Spam reduction through log level filtering
/// - Debug-only logging in production
/// - Consistent formatting across the app
class AppLogger {
  static const String _prefix = '🏠 [HomeFix]';

  /// Log a debug message (only in debug mode)
  static void debug(String module, String message) {
    if (kDebugMode) {
      debugPrint('$_prefix [DEBUG] [$module] $message');
    }
  }

  /// Log an info message
  static void info(String module, String message) {
    if (kDebugMode) {
      debugPrint('$_prefix [INFO] [$module] $message');
    }
  }

  /// Log a warning message
  static void warning(String module, String message) {
    debugPrint('$_prefix [⚠️ WARNING] [$module] $message');
  }

  /// Log an error message
  static void error(String module, String message, [dynamic exception]) {
    debugPrint('$_prefix [❌ ERROR] [$module] $message');
    if (exception != null && kDebugMode) {
      debugPrint('$_prefix [ERROR_DETAIL] $exception');
    }
  }

  /// Log a critical error
  static void critical(String module, String message, [dynamic exception]) {
    debugPrint('$_prefix [🔴 CRITICAL] [$module] $message');
    if (exception != null) {
      debugPrint('$_prefix [CRITICAL_DETAIL] $exception');
    }
  }

  /// Log Firebase-related messages
  static void firebase(String operation, String message) {
    if (kDebugMode) {
      debugPrint('$_prefix [🔥 Firebase] [$operation] $message');
    }
  }

  /// Log Firestore-related messages
  static void firestore(String operation, String message) {
    if (kDebugMode) {
      debugPrint('$_prefix [📊 Firestore] [$operation] $message');
    }
  }

  /// Log service-related messages
  static void service(String serviceName, String message) {
    if (kDebugMode) {
      debugPrint('$_prefix [🔧 Service] [$serviceName] $message');
    }
  }

  /// Log UI-related messages
  static void ui(String screen, String message) {
    if (kDebugMode) {
      debugPrint('$_prefix [🎨 UI] [$screen] $message');
    }
  }

  /// Log network-related messages
  static void network(String operation, String message) {
    if (kDebugMode) {
      debugPrint('$_prefix [🌐 Network] [$operation] $message');
    }
  }

  /// Log authentication-related messages
  static void auth(String operation, String message) {
    if (kDebugMode) {
      debugPrint('$_prefix [🔐 Auth] [$operation] $message');
    }
  }

  /// Log data validation messages
  static void validation(String field, String message) {
    if (kDebugMode) {
      debugPrint('$_prefix [✓ Validation] [$field] $message');
    }
  }

  /// Log performance-related messages
  static void performance(String operation, Duration duration) {
    if (kDebugMode) {
      debugPrint('$_prefix [⏱️ Performance] [$operation] ${duration.inMilliseconds}ms');
    }
  }

  /// Log success messages
  static void success(String module, String message) {
    if (kDebugMode) {
      debugPrint('$_prefix [✅ Success] [$module] $message');
    }
  }

  /// Log data-related messages
  static void data(String collection, String message) {
    if (kDebugMode) {
      debugPrint('$_prefix [📦 Data] [$collection] $message');
    }
  }

  /// Log cleanup/maintenance messages
  static void cleanup(String operation, String message) {
    if (kDebugMode) {
      debugPrint('$_prefix [🧹 Cleanup] [$operation] $message');
    }
  }

  /// Log guard/security-related messages
  static void guard(String guardType, String message) {
    if (kDebugMode) {
      debugPrint('$_prefix [🛡️ Guard] [$guardType] $message');
    }
  }
}

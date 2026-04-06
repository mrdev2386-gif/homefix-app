import 'package:flutter/foundation.dart';

/// AppLogger — Centralized, structured logging for HomeFix Technician App.
///
/// Tags allow filtering by subsystem in logs. All output uses [debugPrint]
/// so logs are suppressed in release builds automatically.
class AppLogger {
  AppLogger._();

  // ── Low-level helpers ────────────────────────────────────────────────────

  static void _log(String tag, String message, {dynamic data, StackTrace? stackTrace}) {
    final dataStr = data != null ? '\n  ↳ $data' : '';
    debugPrint('[$tag] $message$dataStr');
    if (stackTrace != null) {
      debugPrint('  StackTrace: $stackTrace');
    }
  }

  // ── Public API ───────────────────────────────────────────────────────────

  /// General debug — only emitted in debug mode.
  static void d(String message) {
    if (kDebugMode) debugPrint('[DEBUG] $message');
  }

  /// General info.
  static void i(String message) => debugPrint('[INFO] $message');

  /// General warning.
  static void w(String message) => debugPrint('[WARN] $message');

  /// General error with optional error object and stack trace.
  static void e(String message, [dynamic error, StackTrace? stackTrace]) {
    _log('ERROR', message, data: error, stackTrace: stackTrace);
  }

  // ── Tagged convenience methods (match existing call sites) ───────────────

  /// Firebase subsystem log.
  static void firebase(String message, {dynamic data}) =>
      _log('FIREBASE', message, data: data);

  /// Firestore read / write log.
  static void firestore(String message, {dynamic data}) =>
      _log('FIRESTORE', message, data: data);

  /// Auth subsystem log.
  static void auth(String message, {dynamic data}) =>
      _log('AUTH', message, data: data);

  /// Provider / state-management log.
  static void provider(String message, {dynamic data}) =>
      _log('PROVIDER', message, data: data);

  /// Functions (Cloud Functions) log.
  static void functions(String message, {dynamic data}) =>
      _log('FUNCTIONS', message, data: data);

  /// Named info log — matches `AppLogger.info('TAG', 'msg', data: ...)`.
  static void info(String tag, String message, {dynamic data}) =>
      _log(tag, message, data: data);

  /// Named warning log — matches `AppLogger.warning('TAG', 'msg', data: ...)`.
  static void warning(String tag, String message, {dynamic data}) =>
      _log('⚠️ $tag', message, data: data);

  /// Named error log — matches `AppLogger.error('TAG', 'msg', data: ..., stackTrace: ...)`.
  static void error(String tag, String message,
      {dynamic data, StackTrace? stackTrace}) =>
      _log('❌ $tag', message, data: data, stackTrace: stackTrace);
}

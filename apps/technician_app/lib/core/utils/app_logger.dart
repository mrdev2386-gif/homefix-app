import 'package:flutter/foundation.dart';

/// Log level enum
enum LogLevel {
  debug('🔵'),
  info('ℹ️'),
  warning('⚠️'),
  error('❌');

  final String icon;
  const LogLevel(this.icon);
}

/// Centralized logging utility for the technician app
/// 
/// **RULES:**
/// - All logs ONLY print in debug mode (kDebugMode)
/// - Release builds have zero log output
/// - Never log sensitive data (tokens, passwords, PII)
/// - Use consistent tag format: [TAG] message
class AppLogger {
  // Private constructor
  AppLogger._();

  /// Log structured message (only in debug mode)
  static void log(
    String tag,
    String message, {
    LogLevel level = LogLevel.debug,
    dynamic data,
  }) {
    if (!kDebugMode) return;

    final logMessage = StringBuffer();
    logMessage.write('${level.icon} [$tag] $message');

    if (data != null) {
      logMessage.write(' | data: $data');
    }

    debugPrint(logMessage.toString());
  }

  /// Log debug info
  static void debug(String tag, String message, {dynamic data}) {
    log(tag, message, level: LogLevel.debug, data: data);
  }

  /// Log info
  static void info(String tag, String message, {dynamic data}) {
    log(tag, message, level: LogLevel.info, data: data);
  }

  /// Log warning
  static void warning(String tag, String message, {dynamic data}) {
    log(tag, message, level: LogLevel.warning, data: data);
  }

  /// Log error
  static void error(String tag, String message, {dynamic data, StackTrace? stackTrace}) {
    log(tag, message, level: LogLevel.error, data: data);
    if (stackTrace != null && kDebugMode) {
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  /// Log Firebase events
  static void firebase(String event, {dynamic data}) {
    log('FIREBASE', event, data: data);
  }

  /// Log auth events
  static void auth(String event, {dynamic data}) {
    log('AUTH', event, data: data);
  }

  /// Log Firestore operations
  static void firestore(String operation, {dynamic data}) {
    log('FIRESTORE', operation, data: data);
  }

  /// Log network operations
  static void network(String operation, {dynamic data}) {
    log('NETWORK', operation, data: data);
  }

  /// Log UI events
  static void ui(String event, {dynamic data}) {
    log('UI', event, data: data);
  }

  /// Log provider/state changes
  static void provider(String event, {dynamic data}) {
    log('PROVIDER', event, data: data);
  }
}

import 'dart:io';

/// Minimal connectivity helper - checks if device can reach internet
class ConnectivityHelper {
  /// Check if device has internet connectivity
  /// Returns true if connected, false otherwise
  static Future<bool> hasInternetConnection() async {
    try {
      // Try to lookup example.com (IANA reserved domain, reliable)
      final result = await InternetAddress.lookup('example.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        // Extra validation: small delay to ensure stable connection
        await Future.delayed(const Duration(milliseconds: 300));
        return true;
      }
      return false;
    } on SocketException catch (_) {
      return false;
    } catch (_) {
      return false;
    }
  }
}

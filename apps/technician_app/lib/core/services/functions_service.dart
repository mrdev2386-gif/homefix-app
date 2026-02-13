import 'package:cloud_functions/cloud_functions.dart';

class FunctionsService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  /// Technician: Get inbox of pending custom requests
  Future<Map<String, dynamic>> getTechnicianInbox({int limit = 20, String? startAfter}) async {
    try {
      HttpsCallable callable = _functions.httpsCallable('getTechnicianInbox');
      final result = await callable.call({
        'limit': limit,
        if (startAfter != null) 'startAfter': startAfter,
      });
      return Map<String, dynamic>.from(result.data);
    } catch (e) {
      rethrow;
    }
  }

  /// Technician: Accept a custom request
  Future<Map<String, dynamic>> acceptCustomRequest(String requestId) async {
    try {
      HttpsCallable callable = _functions.httpsCallable('acceptCustomRequest');
      final result = await callable.call({'requestId': requestId});
      return Map<String, dynamic>.from(result.data);
    } catch (e) {
      rethrow;
    }
  }

  /// Get custom request details
  Future<Map<String, dynamic>> getCustomRequestDetail(String requestId) async {
    try {
      HttpsCallable callable = _functions.httpsCallable('getCustomRequestDetail');
      final result = await callable.call({'requestId': requestId});
      return Map<String, dynamic>.from(result.data);
    } catch (e) {
      rethrow;
    }
  }
}

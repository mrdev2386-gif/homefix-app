import 'dart:async';
import 'dart:developer' as developer;
import 'package:cloud_functions/cloud_functions.dart';
import '../models/matched_technician.dart';
import 'functions_helper.dart';

/// Edge case protection for matching operations
class MatchingService {
  bool _isMatchingInProgress = false;
  int _matchingAttempts = 0;
  static const int _maxMatchingAttempts = 3;

  MatchingService();

  /// Reset matching state (call after successful booking)
  void resetMatchingState() {
    _isMatchingInProgress = false;
    _matchingAttempts = 0;
  }

  /// Match technicians for a service with optional subService
  /// Requires coordinates from LocationProvider
  Future<MatchingResponse> matchTechnicians({
    required String serviceId,
    required double latitude,
    required double longitude,
    String? subServiceId,
  }) async {
    // Edge case: Prevent duplicate matching requests
    if (_isMatchingInProgress) {
      developer.log('[MATCH] Matching already in progress, ignoring duplicate request');
      return const MatchingResponse(
        available: false,
        error: 'Matching already in progress. Please wait.',
      );
    }

    // Edge case: Too many failed attempts
    if (_matchingAttempts >= _maxMatchingAttempts) {
      developer.log('[MATCH] Too many matching attempts, reset needed');
      return const MatchingResponse(
        available: false,
        error: 'Multiple matching attempts failed. Please try again later.',
      );
    }

    // Edge case: Validate location coordinates
    if (latitude == 0 && longitude == 0) {
      return const MatchingResponse(
        available: false,
        error: 'Invalid location. Please try again.',
      );
    }

    _isMatchingInProgress = true;
    developer.log('[MATCH] START: service=$serviceId, lat=$latitude, lng=$longitude');

    // Call the Cloud Function V2 with timeout
    try {
      final callable = await FunctionsHelper.getCallable('matchTechniciansV2');
      final result = await callable.call(<String, dynamic>{
        'serviceId': serviceId,
        if (subServiceId != null) 'subServiceId': subServiceId,
        'location': {
          'latitude': latitude,
          'longitude': longitude,
        },
      }).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          _isMatchingInProgress = false;
          throw TimeoutException('Matching request timed out');
        },
      );

      final data = result.data as Map<String, dynamic>;
      
      // Edge case: Validate response
      if (!data.containsKey('available')) {
        _isMatchingInProgress = false;
        return const MatchingResponse(
          available: false,
          error: 'Invalid response from server.',
        );
      }

      developer.log('[MATCH] SUCCESS: available=${data['available']}');
      _matchingAttempts = 0; // Reset on success
      _isMatchingInProgress = false;
      return MatchingResponse.fromMap(data);
    } catch (e) {
      if (e is TimeoutException) {
        developer.log('[MATCH] Timeout: $e');
      } else if (e is FirebaseFunctionsException) {
        developer.log('[MATCH] Firebase error: ${e.message}');
      } else {
        developer.log('[MATCH] Unexpected error: $e');
      }
      _matchingAttempts++;
      _isMatchingInProgress = false;
      return MatchingResponse(
        available: false,
        error: e is TimeoutException 
          ? 'Request timed out. Please try again.'
          : e is FirebaseFunctionsException
            ? (e.message ?? 'Service temporarily unavailable. Please try again.')
            : 'An error occurred. Please try again.',
      );
    }
  }


  /// Check if technicians are available without UI
  /// Returns false on any error
  Future<bool> checkAvailability({
    required String serviceId,
    String? subServiceId,
  }) async {
    try {
      final response = await matchTechnicians(
        serviceId: serviceId,
        subServiceId: subServiceId,
        latitude: 0,
        longitude: 0,
      );
      return response.available;
    } catch (e) {
      developer.log('[MATCH] Availability check failed: $e');
      return false;
    }
  }
}


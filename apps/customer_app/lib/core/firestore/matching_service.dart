import 'dart:async';
import 'dart:developer' as developer;
import 'package:cloud_functions/cloud_functions.dart';
import '../models/matched_technician.dart';
import '../location/location_service.dart';

/// Edge case protection for matching operations
class MatchingService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;
  final LocationService _locationService;
  
  // Prevent duplicate matching requests
  bool _isMatchingInProgress = false;
  int _matchingAttempts = 0;
  static const int _maxMatchingAttempts = 3;

  MatchingService({LocationService? locationService}) 
    : _locationService = locationService ?? LocationService();

  /// Reset matching state (call after successful booking)
  void resetMatchingState() {
    _isMatchingInProgress = false;
    _matchingAttempts = 0;
  }

  /// Match technicians for a service with optional subService
  /// Includes edge case protection
  Future<MatchingResponse> matchTechnicians({
    required String serviceId,
    String? subServiceId,
  }) async {
    // Edge case: Prevent duplicate matching requests
    if (_isMatchingInProgress) {
      developer.log('[MATCH] Matching already in progress, ignoring duplicate request');
      return MatchingResponse(
        available: false,
        error: 'Matching already in progress. Please wait.',
      );
    }

    // Edge case: Too many failed attempts
    if (_matchingAttempts >= _maxMatchingAttempts) {
      developer.log('[MATCH] Too many matching attempts, reset needed');
      return MatchingResponse(
        available: false,
        error: 'Multiple matching attempts failed. Please try again later.',
      );
    }

    _isMatchingInProgress = true;
    
    try {
      // Edge case: Get customer location with timeout
      final location = await _locationService.getCurrentPosition().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          developer.log('[MATCH] Location fetch timed out');
          return null;
        },
      );
      
      if (location == null) {
        _isMatchingInProgress = false;
        return MatchingResponse(
          available: false,
          error: 'Unable to get your location. Please enable location services.',
        );
      }

      // Edge case: Validate location coordinates
      if (location.latitude == 0 && location.longitude == 0) {
        _isMatchingInProgress = false;
        return MatchingResponse(
          available: false,
          error: 'Invalid location. Please try again.',
        );
      }

      // Call the Cloud Function V2 with timeout
      final callable = _functions.httpsCallable('matchTechniciansV2');
      final result = await callable.call(<String, dynamic>{
        'serviceId': serviceId,
        if (subServiceId != null) 'subServiceId': subServiceId,
        'location': {
          'latitude': location.latitude,
          'longitude': location.longitude,
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
      if (data == null || !data.containsKey('available')) {
        _isMatchingInProgress = false;
        return MatchingResponse(
          available: false,
          error: 'Invalid response from server.',
        );
      }

      _matchingAttempts = 0; // Reset on success
      _isMatchingInProgress = false;
      return MatchingResponse.fromMap(data);

    } on TimeoutException catch (e) {
      developer.log('[MATCH] Timeout: $e');
      _matchingAttempts++;
      _isMatchingInProgress = false;
      return MatchingResponse(
        available: false,
        error: 'Request timed out. Please try again.',
      );
    } on FirebaseFunctionsException catch (e) {
      developer.log('[MATCH] Firebase error: ${e.message}');
      _matchingAttempts++;
      _isMatchingInProgress = false;
      return MatchingResponse(
        available: false,
        error: e.message ?? 'Service temporarily unavailable. Please try again.',
      );
    } catch (e) {
      developer.log('[MATCH] Unexpected error: $e');
      _matchingAttempts++;
      _isMatchingInProgress = false;
      return MatchingResponse(
        available: false,
        error: 'An error occurred. Please try again.',
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
      );
      return response.available;
    } catch (e) {
      developer.log('[MATCH] Availability check failed: $e');
      return false;
    }
  }
}

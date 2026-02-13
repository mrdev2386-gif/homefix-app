import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/providers/category_provider.dart';
import '../core/providers/auth_provider.dart';
import '../features/dashboard/widgets/dashboard_app_bar.dart';
import '../features/dashboard/widgets/dashboard_search_bar.dart';
import '../features/dashboard/widgets/category_card.dart';
import '../features/dashboard/widgets/service_card.dart';
import '../core/providers/service_provider.dart';
import '../core/providers/cart_provider.dart';
import '../core/providers/booking_provider.dart';
import '../core/models/service.dart';
import '../core/models/category.dart';
import '../core/models/cart_item.dart';
import '../core/models/dashboard_models.dart';
import '../core/services/location_service.dart';
import '../features/dashboard/widgets/banner_slider.dart';
import '../screens/request_service_screen.dart';
import '../features/booking/presentation/slot_selection_screen.dart';
import '../screens/addresses_screen.dart';
import '../core/models/address.dart';
import '../features/dashboard/widgets/professional_reels_section.dart';
import '../features/dashboard/widgets/cleaning_essentials_section.dart';
import '../features/dashboard/widgets/service_spotlight_section.dart';
import '../core/services/firestore_service.dart';
import '../core/theme/app_theme.dart';
import '../features/services/presentation/category_services_screen.dart';
import '../features/services/widgets/category_grid_card.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'dart:isolate';

/// Location state enum for managing UI states
enum LocationState {
  idle,
  loading,
  success,
  error,
  permissionFallback,
}

/// Exception for low GPS accuracy
class LocationAccuracyException implements Exception {
  final double accuracy;
  LocationAccuracyException(this.accuracy);
  
  @override
  String toString() => 'Location accuracy too low: ${accuracy}m';
}

/// Location cache model - STRENGTHENED with accuracy validation
class LocationCache {
  final double latitude;
  final double longitude;
  final double accuracy;
  final String address;
  final DateTime timestamp;

  static const double _maxAccuracyThreshold = 50.0; // meters
  static const Duration _cacheValidity = Duration(hours: 24);

  LocationCache({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.address,
    required this.timestamp,
  });

  /// Check if cache is valid (less than 24 hours old AND accuracy <= 50m)
  bool get isValid {
    final bool isFresh = DateTime.now().difference(timestamp) < _cacheValidity;
    final bool isAccurate = accuracy <= _maxAccuracyThreshold;
    return isFresh && isAccurate;
  }

  /// Check if accuracy is acceptable (meets threshold)
  bool get hasAcceptableAccuracy => accuracy <= _maxAccuracyThreshold;

  /// Get age of cache in hours
  double get ageInHours => DateTime.now().difference(timestamp).inMinutes / 60.0;

  /// Convert to JSON for SharedPreferences
  Map<String, dynamic> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
    'accuracy': accuracy,
    'address': address,
    'timestamp': timestamp.toIso8601String(),
  };

  /// Create from JSON
  factory LocationCache.fromJson(Map<String, dynamic> json) {
    return LocationCache(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      accuracy: (json['accuracy'] as num).toDouble(),
      address: json['address'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}

/// Debug logging utility for location operations
class LocationDebugLogger {
  static const String _tag = '[LOCATION]';

  static void log(String message) {
    debugPrint('$_tag $message');
  }

  static void logCacheUsed(LocationCache cache) {
    log('CACHE USED: lat=${cache.latitude.toStringAsFixed(6)}, '
        'lng=${cache.longitude.toStringAsFixed(6)}, '
        'accuracy=${cache.accuracy.toStringAsFixed(1)}m, '
        'age=${cache.ageInHours.toStringAsFixed(2)}h');
  }

  static void logCacheExpired(LocationCache cache, String reason) {
    log('CACHE EXPIRED: $reason - '
        'accuracy=${cache.accuracy.toStringAsFixed(1)}m, '
        'age=${cache.ageInHours.toStringAsFixed(2)}h');
  }

  static void logFreshFetchSuccess(double accuracy) {
    log('FRESH FETCH SUCCESS: accuracy=${accuracy.toStringAsFixed(1)}m');
  }

  static void logAccuracyRejected(double accuracy) {
    log('ACCURACY REJECTED: accuracy=${accuracy.toStringAsFixed(1)}m > 50m threshold');
  }

  static void logBackgroundRefreshResult({required bool success, double? newAccuracy}) {
    if (success) {
      log('BACKGROUND REFRESH SUCCESS: newAccuracy=${newAccuracy?.toStringAsFixed(1)}m');
    } else {
      log('BACKGROUND REFRESH FAILED: keeping cached location');
    }
  }

  static void logNetworkFallback(double lat, double lng) {
    log('NETWORK FALLBACK: using coordinates - lat=$lat, lng=$lng');
  }
}

/// SharedPreferences helper for location caching - IMPROVED with accuracy
class LocationCacheHelper {
  static const String _cacheKey = 'cached_location';
  static const Duration _cacheValidity = Duration(hours: 24);
  static const double _maxAccuracyThreshold = 50.0;

  /// Save location to cache WITH accuracy
  static Future<void> saveLocation({
    required double latitude,
    required double longitude,
    required double accuracy,
    required String address,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final cache = LocationCache(
      latitude: latitude,
      longitude: longitude,
      accuracy: accuracy,
      address: address,
      timestamp: DateTime.now(),
    );
    await prefs.setString(_cacheKey, cache.toJson().toString());
    LocationDebugLogger.log('Cache saved: accuracy=${accuracy.toStringAsFixed(1)}m');
  }

  /// Get cached location if valid (including accuracy check)
  static Future<LocationCache?> getCachedLocation() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_cacheKey);
    if (jsonString == null) {
      LocationDebugLogger.log('Cache miss: no cached location exists');
      return null;
    }

    try {
      // Parse cache JSON
      final values = _parseCacheJson(jsonString);
      if (values == null) {
        LocationDebugLogger.log('Cache miss: failed to parse cache');
        return null;
      }

      final cache = LocationCache(
        latitude: double.parse(values['latitude']!),
        longitude: double.parse(values['longitude']!),
        accuracy: double.parse(values['accuracy']!),
        address: values['address']!,
        timestamp: DateTime.parse(values['timestamp']!),
      );

      // Check cache validity including accuracy
      if (!cache.isValid) {
        final expiredReason = cache.ageInHours >= 24 
            ? 'expired (age > 24h)' 
            : 'poor accuracy (${cache.accuracy.toStringAsFixed(1)}m)';
        LocationDebugLogger.logCacheExpired(cache, expiredReason);
        return null;
      }

      LocationDebugLogger.logCacheUsed(cache);
      return cache;
    } catch (e) {
      LocationDebugLogger.log('Cache error: $e');
      return null;
    }
  }

  /// Parse cache JSON string
  static Map<String, String>? _parseCacheJson(String jsonString) {
    try {
      final map = <String, String>{};
      final entries = jsonString
          .replaceAll('{', '')
          .replaceAll('}', '')
          .split(', ')
          .map((e) => e.split(': '));
      
      for (final entry in entries) {
        if (entry.length >= 2) {
          final key = entry[0].trim();
          final value = entry[1].trim().replaceAll('"', '');
          map[key] = value;
        }
      }
      return map;
    } catch (e) {
      return null;
    }
  }

  /// Clear cached location
  static Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cacheKey);
    LocationDebugLogger.log('Cache cleared');
  }

  /// Check if cache exists and is valid
  static Future<bool> hasValidCache() async {
    final cache = await getCachedLocation();
    return cache != null;
  }
}

/// Isolate function for non-blocking reverse geocoding
Future<LocationAddress> _reverseGeocodeIsolate(Map<String, double> params) async {
  final service = LocationService();
  return await service.reverseGeocode(
    params['latitude']!,
    params['longitude']!,
  );
}

/// Modern location bottom sheet widget with animated states - HARDENED
class ModernLocationSheet extends StatefulWidget {
  final VoidCallback onClose;

  const ModernLocationSheet({
    super.key,
    required this.onClose,
  });

  @override
  State<ModernLocationSheet> createState() => _ModernLocationSheetState();
}

class _ModernLocationSheetState extends State<ModernLocationSheet> with SingleTickerProviderStateMixin {
  LocationState _locationState = LocationState.idle;
  String _address = '';
  String _errorMessage = '';
  LocationCache? _cachedLocation;
  bool _isRefreshing = false;
  bool _hasShownSnackbar = false; // Prevent duplicate snackbars
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _checkCachedLocation();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// Check for cached location on init - with accuracy validation
  Future<void> _checkCachedLocation() async {
    final cache = await LocationCacheHelper.getCachedLocation();
    if (cache != null && mounted) {
      setState(() {
        _cachedLocation = cache;
      });
    }
  }

  /// Apply cached location instantly - with accuracy check
  Future<void> _applyCachedLocation() async {
    if (_cachedLocation == null) return;

    // Double-check accuracy before using
    if (!_cachedLocation!.hasAcceptableAccuracy) {
      LocationDebugLogger.logAccuracyRejected(_cachedLocation!.accuracy);
      // Force fresh fetch instead
      await _fetchLocation();
      return;
    }

    final authProvider = context.read<AuthProvider>();
    
    // Update UI instantly
    if (!mounted) return;
    setState(() {
      _address = _cachedLocation!.address;
      _locationState = LocationState.success;
    });
    _animationController.forward(from: 0.0);

    // FIX: Use updateDefaultLocation with coordinates
    await authProvider.updateDefaultLocation(
      _cachedLocation!.address,
      _cachedLocation!.latitude,
      _cachedLocation!.longitude,
    );

    if (!mounted) return;

    // Show success BEFORE closing - FIX: Show snackbar in parent context
    _showSuccessSnackBar(context, 'Location updated from cache');
    
    // Close after delay
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        widget.onClose();
      }
    });

    // Refresh location silently in background (don't block UI)
    _refreshLocationInBackground();
  }

  /// Refresh location silently in background - IMPROVED stability
  Future<void> _refreshLocationInBackground() async {
    if (_isRefreshing) return;
    _isRefreshing = true;

    try {
      final permissionStatus = await LocationService().checkAndRequestPermission();
      if (permissionStatus != LocationPermissionStatus.granted) {
        LocationDebugLogger.log('Background refresh: permission denied');
        return;
      }

      final position = await LocationService().getCurrentPosition().timeout(
        const Duration(seconds: 10),
      );

      // Validate accuracy
      if (position.accuracy > 50) {
        LocationDebugLogger.logAccuracyRejected(position.accuracy);
        LocationDebugLogger.logBackgroundRefreshResult(success: false);
        return;
      }

      // Attempt reverse geocoding with network safety
      String? address;
      try {
        final addressResult = await compute(_reverseGeocodeIsolate, {
          'latitude': position.latitude,
          'longitude': position.longitude,
        });
        address = addressResult.formattedAddress;
      } catch (e) {
        // Network error - keep coordinates and use fallback
        LocationDebugLogger.log('Reverse geocoding failed: $e');
        LocationDebugLogger.logNetworkFallback(position.latitude, position.longitude);
        address = 'Lat: ${position.latitude.toStringAsFixed(4)}, Lng: ${position.longitude.toStringAsFixed(4)}';
      }

      // Update cache
      await LocationCacheHelper.saveLocation(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        address: address,
      );

      LocationDebugLogger.logBackgroundRefreshResult(
        success: true, 
        newAccuracy: position.accuracy
      );
    } on TimeoutException {
      LocationDebugLogger.log('Background refresh: timeout');
      LocationDebugLogger.logBackgroundRefreshResult(success: false);
    } catch (e) {
      LocationDebugLogger.log('Background refresh error: $e');
      LocationDebugLogger.logBackgroundRefreshResult(success: false);
    } finally {
      _isRefreshing = false;
    }
  }

  /// Fetch fresh location - IMPROVED with network safety
  Future<void> _fetchLocation() async {
    if (_locationState == LocationState.loading) return;

    if (!mounted) return;
    setState(() {
      _locationState = LocationState.loading;
      _errorMessage = '';
      _hasShownSnackbar = false;
    });

    _animationController.forward(from: 0.0);

    try {
      final authProvider = context.read<AuthProvider>();
      
      // Check permission first
      final permissionStatus = await LocationService().checkAndRequestPermission();
      
      if (!mounted) return;

      // Handle permission denied with fallback UI
      if (permissionStatus == LocationPermissionStatus.denied ||
          permissionStatus == LocationPermissionStatus.deniedForever) {
        if (!mounted) return;
        setState(() {
          _locationState = LocationState.permissionFallback;
        });
        _animationController.forward(from: 0.0);
        return;
      }

      // Fetch position with timeout
      final position = await LocationService().getCurrentPosition().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Location request timed out');
        },
      );

      if (!mounted) return;

      // GPS accuracy validation (requirement: >50m shows error)
      if (position.accuracy > 50) {
        if (!mounted) return;
        setState(() {
          _locationState = LocationState.error;
          _errorMessage = 'Low GPS accuracy (${position.accuracy.toStringAsFixed(0)}m). Please move to an open area and try again.';
        });
        _animationController.forward(from: 0.0);
        
        // Show modern error snackbar - only once
        if (!_hasShownSnackbar && mounted) {
          _hasShownSnackbar = true;
          _showAccuracyErrorSnackBar(position.accuracy);
        }
        LocationDebugLogger.logAccuracyRejected(position.accuracy);
        return;
      }

      // Non-blocking reverse geocoding using compute isolate - with network safety
      String? address;
      try {
        final addressResult = await compute(_reverseGeocodeIsolate, {
          'latitude': position.latitude,
          'longitude': position.longitude,
        });
        address = addressResult.formattedAddress;
      } catch (e) {
        // Network error - use coordinates as fallback
        LocationDebugLogger.log('Reverse geocoding failed: $e');
        LocationDebugLogger.logNetworkFallback(position.latitude, position.longitude);
        address = 'Lat: ${position.latitude.toStringAsFixed(4)}, Lng: ${position.longitude.toStringAsFixed(4)}';
      }

      if (!mounted) return;

      // Save to cache WITH accuracy
      await LocationCacheHelper.saveLocation(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        address: address,
      );

      LocationDebugLogger.logFreshFetchSuccess(position.accuracy);

      // Update address
      if (!mounted) return;
      setState(() {
        _address = address ?? 'Unknown location';
        _locationState = LocationState.success;
      });

      _animationController.forward(from: 0.0);

      // Update in auth provider with coordinates
      await authProvider.updateDefaultLocation(
        address,
        position.latitude,
        position.longitude,
      );

      if (!mounted) return;

      // Show success BEFORE closing - FIX: Show snackbar in parent context
      _showSuccessSnackBar(context, 'Location updated successfully');
      
      // Close after delay
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          widget.onClose();
        }
      });

    } on TimeoutException {
      if (!mounted) return;
      setState(() {
        _locationState = LocationState.error;
        _errorMessage = 'Location request timed out. Please try again.';
      });
      LocationDebugLogger.log('Fresh fetch: timeout');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _locationState = LocationState.error;
        _errorMessage = 'Unable to fetch location. Please try again.';
      });
      LocationDebugLogger.log('Fresh fetch error: $e');
    }
  }

  /// Show accuracy error snackbar - IMPROVED to prevent duplicates
  void _showAccuracyErrorSnackBar(double accuracy) {
    if (!mounted || _hasShownSnackbar) return;
    _hasShownSnackbar = true;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.gps_off_outlined,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Low GPS accuracy',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Please move to an open area and try again.',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.warningColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  /// Show success snackbar - IMPROVED to prevent duplicates
  void _showSuccessSnackBar(BuildContext context, String message) {
    if (!mounted || _hasShownSnackbar) return;
    _hasShownSnackbar = true;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppTheme.successColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _openSettings() {
    LocationService().openAppSettings();
  }

  void _navigateToManualEntry() {
    widget.onClose();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddressesScreen(isSelectionMode: false),
      ),
    );
  }

  void _retry() {
    _hasShownSnackbar = false;
    _fetchLocation();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              // Handle bar
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              // Header
              FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Text(
                    _locationState == LocationState.permissionFallback
                        ? 'Location Required'
                        : 'Select Location',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'Outfit',
                      color: AppTheme.textColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Content based on state
              _buildContent(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    switch (_locationState) {
      case LocationState.idle:
        return _buildIdleState();
      case LocationState.loading:
        return _buildLoadingState();
      case LocationState.success:
        return _buildSuccessState();
      case LocationState.error:
        return _buildErrorState();
      case LocationState.permissionFallback:
        return _buildPermissionFallbackState();
    }
  }

  Widget _buildIdleState() {
    return Column(
      children: [
        // Current Location Button with cache indicator
        _buildLocationButton(
          icon: _cachedLocation != null ? Icons.cached_rounded : Icons.my_location_rounded,
          iconColor: AppTheme.primaryColor,
          backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
          title: _cachedLocation != null ? 'Use Last Location' : 'Use Current Location',
          subtitle: _cachedLocation != null
              ? 'Tap to use cached location (${_cachedLocation!.address.split(',').first})'
              : 'Enable GPS to detect your location',
          onTap: _cachedLocation != null ? _applyCachedLocation : _fetchLocation,
        ),
        const SizedBox(height: 12),
        // Add New Address
        _buildLocationButton(
          icon: Icons.add_location_alt_outlined,
          iconColor: AppTheme.textColor,
          backgroundColor: Colors.grey[100]!,
          title: 'Add New Address',
          subtitle: 'Save a new address to your profile',
          onTap: () {
            widget.onClose();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AddressesScreen(isSelectionMode: false),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        // Saved Addresses
        _buildLocationButton(
          icon: Icons.location_on_outlined,
          iconColor: AppTheme.textColor,
          backgroundColor: Colors.grey[100]!,
          title: 'Select Saved Address',
          subtitle: 'Choose from your address book',
          onTap: () async {
            widget.onClose();
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AddressesScreen(isSelectionMode: true),
              ),
            );
            if (result != null && result is Address) {
              final authProvider = context.read<AuthProvider>();
              // FIX: Use updateDefaultLocation with coordinates
              await authProvider.updateDefaultLocation(
                result.fullAddress,
                result.latitude,
                result.longitude,
              );
              if (context.mounted) {
                _showSuccessSnackBar(context, 'Location updated');
              }
            }
          },
        ),
      ],
    );
  }

  Widget _buildLocationButton({
    required IconData icon,
    required Color iconColor,
    required Color backgroundColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: iconColor.withOpacity(0.1),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          color: AppTheme.subtitleColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.grey[400],
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppTheme.primaryColor.withOpacity(0.2),
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withOpacity(0.1),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          children: [
            // Animated location icon
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 500),
              builder: (context, value, child) {
                return Transform.scale(
                  scale: 0.8 + (value * 0.2),
                  child: child,
                );
              },
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryColor,
                      AppTheme.secondaryColor,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.my_location_rounded,
                  color: Colors.white,
                  size: 36,
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Pulsing text
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.5, end: 1.0),
              duration: const Duration(milliseconds: 800),
              builder: (context, value, child) {
                return Opacity(
                  opacity: 0.5 + (value * 0.5),
                  child: child,
                );
              },
              child: Text(
                'Fetching your location...',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textColor,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please allow location access',
              style: GoogleFonts.outfit(
                fontSize: 14,
                color: AppTheme.subtitleColor,
              ),
            ),
            const SizedBox(height: 24),
            // Loading indicator
            SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessState() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.successColor.withOpacity(0.1),
              AppTheme.successColor.withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppTheme.successColor.withOpacity(0.3),
          ),
        ),
        child: Column(
          children: [
            // Success icon with animation
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppTheme.successColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.successColor.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: 40,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Location fetched successfully!',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppTheme.textColor,
              ),
            ),
            const SizedBox(height: 12),
            // Address
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.8),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.location_on_rounded,
                    color: AppTheme.successColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _address,
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textColor,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Updating your location...',
              style: GoogleFonts.outfit(
                fontSize: 13,
                color: AppTheme.subtitleColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.errorColor.withOpacity(0.05),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppTheme.errorColor.withOpacity(0.2),
          ),
        ),
        child: Column(
          children: [
            // Error icon
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppTheme.errorColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.errorColor.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                color: Colors.white,
                size: 40,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Unable to fetch location',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppTheme.textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage,
              style: GoogleFonts.outfit(
                fontSize: 14,
                color: AppTheme.subtitleColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            // Retry button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _retry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.refresh_rounded, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Retry',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Cancel button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: TextButton(
                onPressed: widget.onClose,
                style: TextButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.subtitleColor,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Permission fallback state - manual location entry
  Widget _buildPermissionFallbackState() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppTheme.warningColor.withOpacity(0.3),
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.warningColor.withOpacity(0.1),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          children: [
            // Warning icon
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppTheme.warningColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.warningColor.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(
                Icons.location_off_outlined,
                color: Colors.white,
                size: 40,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Location Required',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppTheme.textColor,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Enable location to auto-detect your address or enter it manually.',
              style: GoogleFonts.outfit(
                fontSize: 14,
                color: AppTheme.subtitleColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            // Enable Location button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _openSettings,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.settings_rounded, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Enable Location',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Enter Manually button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton(
                onPressed: _navigateToManualEntry,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.textColor,
                  side: BorderSide(color: Colors.grey.shade300),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.edit_location_outlined, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Enter Manually',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Cancel button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: TextButton(
                onPressed: widget.onClose,
                style: TextButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.subtitleColor,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  bool _isLocationSheetOpen = false;

  void _showLocationSheet() {
    if (_isLocationSheetOpen) return;
    
    setState(() => _isLocationSheetOpen = true);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.3),
      builder: (context) => ModernLocationSheet(
        onClose: () {
          if (mounted) {
            setState(() => _isLocationSheetOpen = false);
          }
          Navigator.pop(context);
        },
      ),
    ).then((_) {
      if (mounted) {
        setState(() => _isLocationSheetOpen = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(context),
      body: _buildDashboardContent(context),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final customer = authProvider.customer;
    
    // Get default address or first from list or use default text
    String address = customer?.defaultAddress ?? 'Add your address';
    String city = 'Select City';

    if (customer?.addresses.isNotEmpty == true) {
      final firstAddress = customer!.addresses.first;
      if (customer.defaultAddress == null) {
        address = firstAddress['fullAddress'] ?? 'Add your address';
      }
      city = firstAddress['city'] ?? 'Select City';
    }

    return DashboardAppBar(
      city: city,
      address: address,
      onLocationTap: _showLocationSheet,
      onCartTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cart - Coming soon')),
        );
      },
    );
  }

  Widget _buildDashboardContent(BuildContext context) {
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Heading
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 20, 16, 8),
            child: Text(
              'Expert Care for All Your Devices',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
                letterSpacing: -0.5,
              ),
            ),
          ),
          
          // Search Bar
          Consumer<CategoryProvider>(
            builder: (context, categoryProvider, child) {
              return DashboardSearchBar(
                onChanged: (query) {
                  categoryProvider.setSearchQuery(query);
                  Provider.of<ServiceProvider>(context, listen: false).setSearchQuery(query);
                },
                onClear: () {
                  categoryProvider.clearSearch();
                  Provider.of<ServiceProvider>(context, listen: false).setSearchQuery('');
                },
                currentQuery: categoryProvider.searchQuery,
              );
            },
          ),

          // Banner Slider
          const SizedBox(height: 16),
          const BannerSlider(),
          
          // Professional Reels Section
          StreamBuilder<List<ProfessionalReel>>(
            stream: firestoreService.streamProfessionalReels(),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const SizedBox.shrink();
              }
              return ProfessionalReelsSection(reels: snapshot.data!);
            },
          ),
          
          // Cleaning Essentials Section
          StreamBuilder<List<CleaningEssential>>(
            stream: firestoreService.streamCleaningEssentials(),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const SizedBox.shrink();
              }
              return CleaningEssentialsSection(essentials: snapshot.data!);
            },
          ),
          
          // In the Spotlight Section
          const ServiceSpotlightSection(),
          
          // Professional Services Section
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 24, 16, 12),
            child: Text(
              'Professional Services',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          _buildServicesGrid(context),

          // Request Service CTA
          _buildRequestServiceCTA(context),

          // Categories Section
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 24, 16, 12),
            child: Text(
              'Browse Categories',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          _buildCategoriesGrid(context),
          
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildServicesGrid(BuildContext context) {
    return Consumer3<ServiceProvider, CartProvider, BookingProvider>(
      builder: (context, serviceProvider, cartProvider, bookingProvider, child) {
        if (serviceProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final services = serviceProvider.services.take(12).toList();

        if (services.isEmpty) {
          return const Center(child: Padding(
            padding: EdgeInsets.all(32.0),
            child: Text('No services available'),
          ));
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.75,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: services.length,
          itemBuilder: (context, index) {
            final service = services[index];
            return ServiceCard(
              service: service,
              onAddToCart: () {
                final cartItem = CartItem(
                  id: '',
                  serviceId: service.id,
                  serviceName: service.title,
                  serviceImage: service.imageUrl,
                  price: service.price,
                  quantity: 1,
                  totalPrice: service.price,
                );
                cartProvider.addItem(cartItem);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${service.title} added to cart')),
                );
              },
              onBookNow: () {
                _navigateToSlotSelection(context, service);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildRequestServiceCTA(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Can't find a service?",
                  style: TextStyle(
                    color: Colors.blue,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  "Request a custom service",
                  style: TextStyle(
                    color: Colors.black54,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => _showRequestServiceDialog(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Request'),
          ),
        ],
      ),
    );
  }

  void _showRequestServiceDialog(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RequestServiceScreen()),
    );
  }

  Widget _buildCategoriesGrid(BuildContext context) {
    return Consumer<CategoryProvider>(
      builder: (context, categoryProvider, child) {
        if (categoryProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final categories = categoryProvider.categories;

        if (categories.isEmpty) {
          return const Center(child: Text('No categories available'));
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.75,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final category = categories[index];
            return CategoryGridCard(
              category: category,
              onTap: () {
                _navigateToCategoryServices(context, category);
              },
            );
          },
        );
      },
    );
  }

  void _navigateToCategoryServices(BuildContext context, Category category) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CategoryServicesScreen(category: category),
      ),
    );
  }

  void _navigateToSlotSelection(BuildContext context, HomeService service) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SlotSelectionScreen(service: service),
      ),
    );
  }
}

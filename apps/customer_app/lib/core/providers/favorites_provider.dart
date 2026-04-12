import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../services/firestore_service.dart';

/// Provider for managing user favorites with optimistic UI updates,
/// real-time sync, and haptic feedback.
/// 
/// Uses Set<String> for O(1) lookups and Firestore for persistence.
/// Data model: customers/{customerId}/favorites/{serviceId}
class FavoritesProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  
  Map<String, String> _favoriteServices = {}; // serviceId -> categoryId
  String? _userId;
  StreamSubscription? _favoritesSubscription;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isStreamActive = true; // FIX 2: Track stream health
  bool _isRetrying = false; // FIX: Prevent retry spam
  
  /// Optimistic UI - immediately reflects changes
  Set<String> get favoriteIds => _favoriteServices.keys.toSet();
  
  /// Check if a service is favorited - O(1) lookup
  bool isFavorite(String serviceId) => _favoriteServices.containsKey(serviceId);
  
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;
  
  /// Initialize with userId and start listening to favorites stream
  void updateUserId(String? userId) {
    if (_userId == userId) return;
    _userId = userId;
    _favoritesSubscription?.cancel();
    
    if (userId != null) {
      // FIX 4: Single source state - only clear on initial load
      _isLoading = true;
      _errorMessage = null;
      // FIX 1: Only clear favorites on initial load (when empty)
      if (_favoriteServices.isEmpty) {
        _favoriteServices = {};
      }
      notifyListeners();
      
      _favoritesSubscription = _firestoreService.streamFavoriteIdsWithCategory(userId).listen(
        (items) {
          // FIX 2: Mark stream as active on success
          _isStreamActive = true;
          // FIX 4: Single source state - success state
          _favoriteServices = {
            for (var item in items) item['serviceId']!: item['categoryId']!
          };
          _isLoading = false;
          _errorMessage = null;
          notifyListeners();
        },
        onError: (error, stackTrace) {
          // FIX 2: Mark stream as dead on error
          _isStreamActive = false;
          if (kDebugMode) {
            debugPrint('❌ [FavoritesProvider] Stream error: $error');
            debugPrint('Stack trace: $stackTrace');
          }
          // FIX 4: Single source state - error state
          // FIX 1: DO NOT clear favorites on error - preserve existing data
          _isLoading = false;
          _errorMessage = 'Unable to load favorites. Please check your connection.';
          notifyListeners();
        },
      );
    } else {
      // FIX 4: Single source state - reset state
      _favoriteServices = {};
      _isLoading = false;
      _errorMessage = null;
      notifyListeners();
    }
  }
  
  /// Toggle favorite with optimistic UI update and haptic feedback
  Future<void> toggleFavorite(String serviceId, String categoryId) async {
    if (kDebugMode) debugPrint('❤️ [FavoritesProvider.toggleFavorite] serviceId=$serviceId, categoryId=$categoryId');
    if (_userId == null) {
      if (kDebugMode) debugPrint('❌ [FavoritesProvider.toggleFavorite] userId is null!');
      return;
    }
    if (serviceId.isEmpty) {
      if (kDebugMode) debugPrint('❌ [FavoritesProvider.toggleFavorite] serviceId is empty, aborting');
      return;
    }
    if (categoryId.isEmpty) {
      if (kDebugMode) debugPrint('❌ [FavoritesProvider.toggleFavorite] categoryId is empty, aborting');
      return;
    }
    
    final wasFavorite = _favoriteServices.containsKey(serviceId);
    
    // Optimistic update
    if (wasFavorite) {
      _favoriteServices.remove(serviceId);
    } else {
      _favoriteServices[serviceId] = categoryId;
    }
    notifyListeners();
    
    HapticFeedback.lightImpact();
    
    // FIX 1: Set error state directly instead of throwing
    try {
      await _firestoreService.toggleFavorite(_userId!, categoryId, serviceId, !wasFavorite);
      // FIX 2: Safe state reset on success
      _errorMessage = null;
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('❌ [FavoritesProvider.toggleFavorite] Error: $error');
        debugPrint('Stack trace: $stackTrace');
      }
      // Revert on failure
      if (wasFavorite) {
        _favoriteServices[serviceId] = categoryId;
      } else {
        _favoriteServices.remove(serviceId);
      }
      // FIX 1: Set error state instead of throwing
      _errorMessage = 'Unable to update favorites. Please try again.';
      notifyListeners();
    }
  }
  
  /// FIX 2: Clear error state
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
  
  /// FIX 1 & 3: Force refresh on retry - always recreate stream
  Future<void> retry() async {
    if (_userId == null) return;
    if (_isRetrying) return; // FIX: Prevent retry spam
    
    // FIX 1: Notify UI that retry started
    _isRetrying = true;
    notifyListeners();
    
    try {
      if (kDebugMode) debugPrint('[FavoritesProvider.retry] Starting retry...');
      
      // FIX 2: Sync loading state
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
      
      // FIX 1: Cancel existing stream safely
      if (_favoritesSubscription != null) {
        if (kDebugMode) debugPrint('[FavoritesProvider.retry] Cancelling existing stream');
        await _favoritesSubscription!.cancel();
        _favoritesSubscription = null;
      }
      
      // FIX 1: Force refresh by recreating stream
      if (kDebugMode) debugPrint('[FavoritesProvider.retry] Creating fresh stream');
      _isStreamActive = true; // Reset stream health
      
      _favoritesSubscription = _firestoreService.streamFavoriteIdsWithCategory(_userId!).listen(
        (items) {
          _isStreamActive = true;
          _favoriteServices = {
            for (var item in items) item['serviceId']!: item['categoryId']!
          };
          _isLoading = false;
          _errorMessage = null;
          if (kDebugMode) debugPrint('✅ [FavoritesProvider.retry] Success - loaded ${items.length} favorites');
          notifyListeners();
        },
        onError: (error, stackTrace) {
          _isStreamActive = false;
          if (kDebugMode) {
            debugPrint('❌ [FavoritesProvider.retry] Error: $error');
            debugPrint('Stack trace: $stackTrace');
          }
          _isLoading = false;
          _errorMessage = 'Unable to load favorites. Please check your connection.';
          notifyListeners();
        },
      );
    } finally {
      // FIX 3: Clean end state
      _isRetrying = false;
      _isLoading = false;
      notifyListeners();
    }
  }
  
  @override
  void dispose() {
    _favoritesSubscription?.cancel();
    super.dispose();
  }
}

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
  
  Set<String> _favoriteIds = {};
  String? _userId;
  StreamSubscription? _favoritesSubscription;
  bool _isLoading = false;
  
  /// Optimistic UI - immediately reflects changes
  Set<String> get favoriteIds => _favoriteIds;
  
  /// Check if a service is favorited - O(1) lookup
  bool isFavorite(String serviceId) => _favoriteIds.contains(serviceId);
  
  bool get isLoading => _isLoading;
  
  /// Initialize with userId and start listening to favorites stream
  void updateUserId(String? userId) {
    if (_userId == userId) return;
    _userId = userId;
    _favoritesSubscription?.cancel();
    
    if (userId != null) {
      _isLoading = true;
      notifyListeners();
      
      _favoritesSubscription = _firestoreService.streamFavoriteIds(userId).listen(
        (ids) {
          _favoriteIds = ids.toSet();
          _isLoading = false;
          notifyListeners();
        },
        onError: (error) {
          debugPrint('Favorites stream error: $error');
          _isLoading = false;
          notifyListeners();
        },
      );
    } else {
      _favoriteIds = {};
      _isLoading = false;
      notifyListeners();
    }
  }
  
  /// Toggle favorite with optimistic UI update and haptic feedback
  /// 
  /// Steps:
  /// 1. Immediately update local state (optimistic)
  /// 2. Trigger haptic feedback
  /// 3. Sync with Firestore
  /// 4. Revert on failure
  Future<void> toggleFavorite(String serviceId) async {
    if (_userId == null) return;
    
    final wasFavorite = _favoriteIds.contains(serviceId);
    
    // Optimistic update - immediate UI change
    if (wasFavorite) {
      _favoriteIds.remove(serviceId);
    } else {
      _favoriteIds.add(serviceId);
    }
    notifyListeners();
    
    // Haptic feedback
    HapticFeedback.lightImpact();
    
    try {
      // Sync with Firestore
      await _firestoreService.toggleFavorite(_userId!, serviceId, !wasFavorite);
      // Success - no need to notify as stream will update us
    } catch (error) {
      debugPrint('Error toggling favorite: $error');
      
      // Revert on failure
      if (wasFavorite) {
        _favoriteIds.add(serviceId);
      } else {
        _favoriteIds.remove(serviceId);
      }
      notifyListeners();
    }
  }
  
  /// Add to favorites (alias for toggleFavorite with known state)
  Future<void> addFavorite(String serviceId) async {
    if (_userId == null) return;
    if (_favoriteIds.contains(serviceId)) return; // Idempotent - already favorited
    
    // Optimistic update
    _favoriteIds.add(serviceId);
    notifyListeners();
    
    HapticFeedback.lightImpact();
    
    try {
      await _firestoreService.toggleFavorite(_userId!, serviceId, true);
    } catch (error) {
      debugPrint('Error adding favorite: $error');
      _favoriteIds.remove(serviceId);
      notifyListeners();
    }
  }
  
  /// Remove from favorites
  Future<void> removeFavorite(String serviceId) async {
    if (_userId == null) return;
    if (!_favoriteIds.contains(serviceId)) return; // Idempotent
    
    // Optimistic update
    _favoriteIds.remove(serviceId);
    notifyListeners();
    
    HapticFeedback.lightImpact();
    
    try {
      await _firestoreService.toggleFavorite(_userId!, serviceId, false);
    } catch (error) {
      debugPrint('Error removing favorite: $error');
      _favoriteIds.add(serviceId);
      notifyListeners();
    }
  }
  
  @override
  void dispose() {
    _favoritesSubscription?.cancel();
    super.dispose();
  }
}

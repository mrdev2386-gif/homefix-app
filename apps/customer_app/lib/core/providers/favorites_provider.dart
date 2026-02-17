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
  
  /// Optimistic UI - immediately reflects changes
  Set<String> get favoriteIds => _favoriteServices.keys.toSet();
  
  /// Check if a service is favorited - O(1) lookup
  bool isFavorite(String serviceId) => _favoriteServices.containsKey(serviceId);
  
  bool get isLoading => _isLoading;
  
  /// Initialize with userId and start listening to favorites stream
  void updateUserId(String? userId) {
    if (_userId == userId) return;
    _userId = userId;
    _favoritesSubscription?.cancel();
    
    if (userId != null) {
      _isLoading = true;
      notifyListeners();
      
      _favoritesSubscription = _firestoreService.streamFavoriteIdsWithCategory(userId).listen(
        (items) {
          _favoriteServices = {
            for (var item in items) item['serviceId']!: item['categoryId']!
          };
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
      _favoriteServices = {};
      _isLoading = false;
      notifyListeners();
    }
  }
  
  /// Toggle favorite with optimistic UI update and haptic feedback
  Future<void> toggleFavorite(String serviceId, String categoryId) async {
    if (_userId == null) return;
    
    final wasFavorite = _favoriteServices.containsKey(serviceId);
    
    // Optimistic update
    if (wasFavorite) {
      _favoriteServices.remove(serviceId);
    } else {
      _favoriteServices[serviceId] = categoryId;
    }
    notifyListeners();
    
    HapticFeedback.lightImpact();
    
    try {
      await _firestoreService.toggleFavorite(_userId!, categoryId, serviceId, !wasFavorite);
    } catch (error) {
      debugPrint('Error toggling favorite: $error');
      // Revert on failure
      if (wasFavorite) {
        _favoriteServices[serviceId] = categoryId;
      } else {
        _favoriteServices.remove(serviceId);
      }
      notifyListeners();
    }
  }
  
  @override
  void dispose() {
    _favoritesSubscription?.cancel();
    super.dispose();
  }
}

import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/cart_item.dart';
import '../services/firestore_service.dart';

class CartProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  List<CartItem> _items = [];
  String? _userId;
  StreamSubscription? _cartSubscription;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isStreamActive = true; // FIX 2: Track stream health
  bool _isRetrying = false; // FIX: Prevent retry spam
  Timer? _loadingTimeout;

  List<CartItem> get items => _items;
  int get itemCount => _items.length;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;

  double get totalAmount {
    return _items.fold(0.0, (sum, item) => sum + item.totalPrice);
  }

  void updateUserId(String? userId) async {
    if (_userId == userId) return;
    _userId = userId;
    if (_cartSubscription != null) {
      await _cartSubscription!.cancel();
      _cartSubscription = null;
    }
    // CRITICAL FIX: Always cancel old timeout before creating new one
    _loadingTimeout?.cancel();
    _loadingTimeout = null;
    
    if (userId != null) {
      // FIX 4: Single source state - only clear on initial load
      _isLoading = true;
      _errorMessage = null;
      // FIX 1: Only clear items on initial load (when empty)
      if (_items.isEmpty) {
        _items = [];
      }
      notifyListeners();

      _loadingTimeout = Timer(const Duration(seconds: 15), () {
        if (_isLoading) {
          if (kDebugMode) debugPrint('⚠️ [CartProvider] Loading timeout — forcing isLoading=false');
          // FIX 4: Single source state update
          _isLoading = false;
          // FIX 1: Preserve existing data on timeout error
          _errorMessage = 'Unable to load cart. Please try again.';
          notifyListeners();
        }
      });

      _cartSubscription = _firestoreService.streamCart(userId).listen(
        (cartItems) {
          _loadingTimeout?.cancel();
          _loadingTimeout = null;
          // FIX 2: Mark stream as active on success
          _isStreamActive = true;
          // FIX 4: Single source state - success state
          _items = cartItems;
          _isLoading = false;
          _errorMessage = null;
          notifyListeners();
        },
        onError: (error, stackTrace) {
          _loadingTimeout?.cancel();
          _loadingTimeout = null;
          // FIX 2: Mark stream as dead on error
          _isStreamActive = false;
          if (kDebugMode) {
            debugPrint('❌ [CartProvider] Stream error: $error');
            debugPrint('Stack trace: $stackTrace');
          }
          // FIX 4: Single source state - error state
          // FIX 1: DO NOT clear items on error - preserve existing data
          _isLoading = false;
          _errorMessage = 'Unable to load cart. Please check your connection.';
          notifyListeners();
        },
      );
    } else {
      // FIX 4: Single source state - reset state
      _items = [];
      _isLoading = false;
      _errorMessage = null;
      notifyListeners();
    }
  }

  Future<void> addItem(CartItem item) async {
    if (kDebugMode) debugPrint('🛒 [CartProvider.addItem] Called with item: ${item.serviceName}');
    if (_userId == null) {
      if (kDebugMode) debugPrint('❌ [CartProvider.addItem] userId is null!');
      return;
    }
    
    // FIX 1: Set error state directly instead of throwing
    try {
      if (kDebugMode) debugPrint('🛒 [CartProvider.addItem] Calling firestore_service.addToCart()');
      await _firestoreService.addToCart(_userId!, item);
      if (kDebugMode) debugPrint('✅ [CartProvider.addItem] Success');
      // FIX 2: Safe state reset on success
      _errorMessage = null;
      notifyListeners();
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('❌ [CartProvider.addItem] Error: $e');
        debugPrint('Stack trace: $stackTrace');
      }
      // FIX 1: Set error state instead of throwing
      _errorMessage = 'Unable to add item to cart. Please try again.';
      notifyListeners();
    }
  }

  /// FIX 2: Clear error state
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
  
  Future<void> retry() async {
    if (_userId == null) return;
    if (_isRetrying) return; // FIX: Prevent retry spam
    
    // FIX 1: Notify UI that retry started
    _isRetrying = true;
    notifyListeners();
    
    try {
      if (kDebugMode) debugPrint('[CartProvider.retry] Starting retry...');
      
      // FIX 2: Sync loading state
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
      
      // FIX 1: Cancel existing stream safely
      if (_cartSubscription != null) {
        if (kDebugMode) debugPrint('[CartProvider.retry] Cancelling existing stream');
        await _cartSubscription!.cancel();
        _cartSubscription = null;
      }
      
      // FIX 1: Force refresh by recreating stream
      if (kDebugMode) debugPrint('[CartProvider.retry] Creating fresh stream');
      _isStreamActive = true; // Reset stream health
      
      _loadingTimeout?.cancel();
      _loadingTimeout = Timer(const Duration(seconds: 15), () {
        if (_isLoading) {
          if (kDebugMode) debugPrint('⚠️ [CartProvider.retry] Timeout during retry');
          _isLoading = false;
          _isStreamActive = false;
          _errorMessage = 'Unable to load cart. Please try again.';
          notifyListeners();
        }
      });

      _cartSubscription = _firestoreService.streamCart(_userId!).listen(
        (cartItems) {
          _loadingTimeout?.cancel();
          _loadingTimeout = null;
          _isStreamActive = true;
          _items = cartItems;
          _isLoading = false;
          _errorMessage = null;
          if (kDebugMode) debugPrint('✅ [CartProvider.retry] Success - loaded ${cartItems.length} items');
          notifyListeners();
        },
        onError: (error, stackTrace) {
          _loadingTimeout?.cancel();
          _loadingTimeout = null;
          _isStreamActive = false;
          if (kDebugMode) {
            debugPrint('❌ [CartProvider.retry] Error: $error');
            debugPrint('Stack trace: $stackTrace');
          }
          _isLoading = false;
          _errorMessage = 'Unable to load cart. Please check your connection.';
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

  Future<void> updateQuantity(String itemId, int quantity) async {
    if (_userId == null) return;
    
    // FIX #2: Update local state instantly
    final itemIndex = _items.indexWhere((item) => item.id == itemId);
    if (itemIndex != -1) {
      if (quantity <= 0) {
        _items.removeAt(itemIndex);
      } else {
        final item = _items[itemIndex];
        final newTotalPrice = item.price * quantity;
        _items[itemIndex] = item.copyWith(
          quantity: quantity,
          totalPrice: newTotalPrice,
        );
      }
      notifyListeners();
    }
    
    // Then update Firestore in background
    if (quantity <= 0) {
      _firestoreService.removeFromCart(_userId!, itemId).catchError((e) {
        debugPrint('⚠️ [CART] Background remove failed: $e');
      });
    } else {
      _firestoreService.updateCartItemQuantity(_userId!, itemId, quantity).catchError((e) {
        debugPrint('⚠️ [CART] Background update failed: $e');
      });
    }
  }

  Future<void> removeItem(String itemId) async {
    if (_userId == null) return;
    
    // Update local state instantly
    _items.removeWhere((item) => item.id == itemId);
    notifyListeners();
    
    // Then remove from Firestore in background
    _firestoreService.removeFromCart(_userId!, itemId).catchError((e) {
      debugPrint('⚠️ [CART] Background remove failed: $e');
    });
  }

  Future<void> clearCart() async {
    if (_userId == null) return;
    
    // Update local state instantly
    _items.clear();
    notifyListeners();
    
    // Then clear Firestore in background
    _firestoreService.clearCart(_userId!).catchError((e) {
      debugPrint('⚠️ [CART] Background clear failed: $e');
    });
  }

  @override
  void dispose() {
    _cartSubscription?.cancel();
    _loadingTimeout?.cancel();
    super.dispose();
  }
}

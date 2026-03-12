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
  Timer? _loadingTimeout;

  List<CartItem> get items => _items;
  int get itemCount => _items.length;
  bool get isLoading => _isLoading;

  double get totalAmount {
    return _items.fold(0.0, (sum, item) => sum + item.totalPrice);
  }

  void updateUserId(String? userId) {
    if (_userId == userId) return;
    _userId = userId;
    _cartSubscription?.cancel();
    _loadingTimeout?.cancel();
    
    if (userId != null) {
      _isLoading = true;
      notifyListeners();

      _loadingTimeout = Timer(const Duration(seconds: 15), () {
        if (_isLoading) {
          if (kDebugMode) debugPrint('⚠️ [CartProvider] Loading timeout — forcing isLoading=false');
          _isLoading = false;
          notifyListeners();
        }
      });

      _cartSubscription = _firestoreService.streamCart(userId).listen(
        (cartItems) {
          _loadingTimeout?.cancel();
          _items = cartItems;
          _isLoading = false;
          notifyListeners();
        },
        onError: (error) {
          _loadingTimeout?.cancel();
          if (kDebugMode) debugPrint('❌ [CartProvider] Stream error: $error');
          _items = [];
          _isLoading = false;
          notifyListeners();
        },
      );
    } else {
      _items = [];
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addItem(CartItem item) async {
    print('🛒 [CartProvider.addItem] Called with item: ${item.serviceName}');
    if (_userId == null) {
      print('❌ [CartProvider.addItem] userId is null!');
      return;
    }
    try {
      print('🛒 [CartProvider.addItem] Calling firestore_service.addToCart()');
      await _firestoreService.addToCart(_userId!, item);
      print('✅ [CartProvider.addItem] Success');
    } catch (e) {
      print('❌ [CartProvider.addItem] Error: $e');
      if (kDebugMode) debugPrint('❌ [CartProvider] addItem failed: $e');
      rethrow;
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

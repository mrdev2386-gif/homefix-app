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
      notifyListeners(); // FIX: Notify UI immediately so it shows loading state

      // SAFETY TIMEOUT: Guarantee _isLoading becomes false even if stream never fires
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
          // FIX: CRITICAL — Without this, _isLoading stays true forever on Firestore errors
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
    if (_userId == null) return;
    try {
      await _firestoreService.addToCart(_userId!, item);
    } catch (e) {
      if (kDebugMode) debugPrint('❌ [CartProvider] addItem failed: $e');
      rethrow;
    }
  }

  Future<void> updateQuantity(String itemId, int quantity) async {
    if (_userId == null) return;
    if (quantity <= 0) {
      await removeItem(itemId);
    } else {
      await _firestoreService.updateCartItemQuantity(_userId!, itemId, quantity);
    }
  }

  Future<void> removeItem(String itemId) async {
    if (_userId == null) return;
    await _firestoreService.removeFromCart(_userId!, itemId);
  }

  Future<void> clearCart() async {
    if (_userId == null) return;
    await _firestoreService.clearCart(_userId!);
  }

  @override
  void dispose() {
    _cartSubscription?.cancel();
    _loadingTimeout?.cancel();
    super.dispose();
  }
}

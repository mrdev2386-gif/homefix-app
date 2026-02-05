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
    
    if (userId != null) {
      _isLoading = true;
      _cartSubscription = _firestoreService.streamCart(userId).listen((cartItems) {
        _items = cartItems;
        _isLoading = false;
        notifyListeners();
      });
    } else {
      _items = [];
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addItem(CartItem item) async {
    if (_userId == null) return;
    await _firestoreService.addToCart(_userId!, item);
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
    super.dispose();
  }
}

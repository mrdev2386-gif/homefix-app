import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/providers/cart_provider.dart';
import '../../../core/models/cart_item.dart';
import '../../../core/widgets/safe_network_image.dart';
import 'package:customer_app/core/theme/app_theme.dart';
import 'checkout_screen.dart';
import '../../../core/providers/checkout_provider.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  void _handleCheckout() {
    final cart = Provider.of<CartProvider>(context, listen: false);
    final checkout = Provider.of<CheckoutProvider>(context, listen: false);
    
    // Initialize checkout with cart items
    checkout.clear();
    checkout.setItems(cart.items);
    
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CheckoutScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        title: Text(
          'My Cart',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 24, color: AppTheme.textColor),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppTheme.textColor,
      ),
      body: Consumer<CartProvider>(
        builder: (context, cart, child) {
          if (cart.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          // FIX 3: Show error state with retry button
          if (cart.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Unable to load cart',
                    style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    cart.errorMessage ?? 'Please check your connection',
                    style: GoogleFonts.outfit(fontSize: 14, color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => cart.retry(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    ),
                  ),
                ],
              ),
            );
          }

          if (cart.items.isEmpty) {
            return _buildEmptyState();
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: cart.items.length,
                  itemBuilder: (context, index) {
                    final item = cart.items[index];
                    return _buildCartItem(item, cart);
                  },
                ),
              ),
              _buildCheckoutSection(cart),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.shopping_bag_outlined, size: 80, color: AppTheme.primaryColor.withOpacity(0.5)),
          ),
          const SizedBox(height: 24),
          Text(
            'Your cart is empty',
            style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w800, color: AppTheme.textColor),
          ),
          const SizedBox(height: 12),
          Text(
            'Add some services to get started!',
            style: GoogleFonts.outfit(fontSize: 16, color: AppTheme.subtitleColor),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('Browse Services'),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItem(CartItem item, CartProvider cart) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 4)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SafeNetworkImage(
                imageUrl: item.serviceImage,
                width: 90,
                height: 90,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.serviceName,
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 17, color: AppTheme.textColor),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₹${item.price.toStringAsFixed(0)} per unit',
                    style: GoogleFonts.outfit(color: AppTheme.subtitleColor, fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '₹${item.totalPrice.toStringAsFixed(0)}',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 18, color: AppTheme.primaryColor),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            _buildQtyBtn(Icons.remove, () => cart.updateQuantity(item.id, item.quantity - 1)),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                '${item.quantity}',
                                style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 16),
                              ),
                            ),
                            _buildQtyBtn(Icons.add, () => cart.updateQuantity(item.id, item.quantity + 1)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQtyBtn(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Icon(icon, size: 18, color: AppTheme.primaryColor),
      ),
    );
  }

  void _showCartError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.outfit(fontSize: 14),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red[600],
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Widget _buildCheckoutSection(CartProvider cart) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, -5)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Grand Total',
                style: GoogleFonts.outfit(fontSize: 16, color: AppTheme.subtitleColor, fontWeight: FontWeight.w600),
              ),
              Text(
                '₹${cart.totalAmount.toStringAsFixed(0)}',
                style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.w900, color: AppTheme.textColor),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _handleCheckout,
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                elevation: 0,
              ),
              child: Text(
                'Proceed to Checkout',
                style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

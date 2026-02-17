import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../core/models/sub_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/models/service.dart';
import '../../../../core/widgets/safe_network_image.dart';
import '../../../../core/providers/cart_provider.dart';
import '../../../../core/providers/favorites_provider.dart';
import '../../../../core/models/cart_item.dart';
import '../../../../core/theme/app_theme.dart';
import '../../cart/presentation/cart_screen.dart';

class ServiceDetailsScreen extends StatefulWidget {
  final String serviceId;
  final String? serviceName;
  final HomeService? serviceData;

  const ServiceDetailsScreen({
    super.key, 
    required this.serviceId, 
    this.serviceName,
    this.serviceData,
  });

  @override
  State<ServiceDetailsScreen> createState() => _ServiceDetailsScreenState();
}

class _ServiceDetailsScreenState extends State<ServiceDetailsScreen> {
  HomeService? _service;
  bool _isLoading = true;
  int _techCount = 0;
  bool _isAddingToCart = false;
  List<SubService> _subServices = [];
  bool _isSubServicesLoading = true;

  @override
  void initState() {
    super.initState();
    _service = widget.serviceData;
    _fetchService();
    _fetchTechnicianCount();
    _fetchSubServices();
  }

  Future<void> _fetchSubServices() async {
    if (_service == null) {
      // Wait for service to load first
      return;
    }
    
    // We need category ID to fetch subservices
    final categoryId = _service!.category;
    final serviceId = widget.serviceId;

    // Hard validation as requested
    if (categoryId.isEmpty || serviceId.isEmpty) {
      debugPrint('❌ SUBSERVICE FETCH BLOCKED — missing ids');
      setState(() => _isSubServicesLoading = false);
      return;
    }
    
    FirebaseFirestore.instance
        .collection('categories')
        .doc(categoryId)
        .collection('services')
        .doc(serviceId)
        .collection('subServices')
        .where('isActive', isEqualTo: true)
        .orderBy('order', descending: false)
        .snapshots()
        .listen((snapshot) {
      if (mounted) {
        setState(() {
          _subServices = snapshot.docs.map((doc) => SubService.fromFirestore(doc)).toList();
          _isSubServicesLoading = false;
        });
      }
    }, onError: (e) {
      debugPrint('Error fetching sub-services: $e');
      if (mounted) {
        setState(() => _isSubServicesLoading = false);
      }
    });
  }

  Future<void> _fetchService() async {
    if (_service != null && !mounted) return;
    try {
      // AUDIT: Use collectionGroup to support nested categories/{catId}/services source
      // We filter by 'id' field which should be present on most documents, or we'd need to know the categoryId
      final snapshot = await FirebaseFirestore.instance
          .collectionGroup('services')
          .where('id', isEqualTo: widget.serviceId)
          .get();
      
      if (mounted && snapshot.docs.isNotEmpty) {
        setState(() {
          _service = HomeService.fromFirestore(snapshot.docs.first);
          _fetchSubServices(); // Fetch sub-services now that we have categoryId
          _isLoading = false;
        });
      } else if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Error fetching service: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _fetchTechnicianCount() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('technicians')
          .where('status', isEqualTo: 'approved')
          .where('isAvailable', isEqualTo: true)
          .where('services', arrayContains: widget.serviceId)
          .get();
      
      if (mounted) {
        setState(() {
          _techCount = snapshot.docs.length;
        });
      }
    } catch (e) {
      debugPrint('Error fetching technician count: $e');
      // Fallback to count query if index missing
      _fetchTechnicianCountFallback();
    }
  }

  Future<void> _fetchTechnicianCountFallback() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('technicians')
          .where('isApproved', isEqualTo: true)
          .where('isAvailable', isEqualTo: true)
          .get();
      
      final filtered = snapshot.docs.where((doc) {
        final services = doc.data()['services'] as List<dynamic>?;
        return services?.contains(widget.serviceId) ?? false;
      }).length;
      
      if (mounted) {
        setState(() {
          _techCount = filtered;
        });
      }
    } catch (e) {
      debugPrint('Fallback technician count also failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    
    if (_service == null) {
      return const Scaffold(body: Center(child: Text('Service not found')));
    }

    final service = _service!;

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildSliverAppBar(context, service),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(service),
                  const SizedBox(height: 24),
                  _buildStats(service),
                  const SizedBox(height: 32),
                  Text(
                    'About Service',
                    style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.textColor),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Get premium ${service.title.toLowerCase()} service at your convenience. Our selected and background-checked professionals ensure top-quality results and a worry-free experience.',
                    style: GoogleFonts.outfit(color: AppTheme.subtitleColor, height: 1.6, fontSize: 15),
                  ),
                  const SizedBox(height: 32),
                  _buildSubServicesSection(),
                  const SizedBox(height: 32),
                  _buildGuaranteeCard(),
                  const SizedBox(height: 32),
                  _buildReviewsSection(service),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomAction(context, service),
    );
  }

  Widget _buildSliverAppBar(BuildContext context, HomeService service) {
    return SliverAppBar(
      expandedHeight: 320,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.white,
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: CircleAvatar(
          backgroundColor: Colors.white.withOpacity(0.9),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black, size: 18),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            SafeNetworkImage(
              imageUrl: service.imageUrl ?? '',
              width: double.infinity,
              height: 320,
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.black.withOpacity(0.35), Colors.transparent],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        _FavoriteActionButton(service: service), // AUDIT: Fixed parameter mismatch
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildHeader(HomeService service) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: AppTheme.primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
              child: Text(
                service.category.toUpperCase(),
                style: GoogleFonts.outfit(color: AppTheme.primaryColor, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1),
              ),
            ),
            Row(
              children: [
                const Icon(Icons.star_rounded, color: Colors.orange, size: 18),
                const SizedBox(width: 4),
                Text(
                  service.rating.toStringAsFixed(1),
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 16),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          service.title,
          style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.w900, height: 1.1, color: AppTheme.textColor),
        ),
      ],
    );
  }

  Widget _buildStats(HomeService service) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: AppTheme.accentColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(Icons.verified_rounded, 'Verified', 'Safe Experts', Colors.blue),
          _buildStatItem(Icons.groups_rounded, '$_techCount Available', 'Live Experts', Colors.purple),
          _buildStatItem(Icons.payments_rounded, 'Flexible', 'Pay Later', Colors.green),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String val, String sub, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 8),
        Text(val, style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 15, color: AppTheme.textColor)),
        Text(sub, style: GoogleFonts.outfit(color: AppTheme.subtitleColor, fontSize: 11)),
      ],
    );
  }

  Widget _buildInclusionItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(color: AppTheme.successColor, shape: BoxShape.circle),
            child: const Icon(Icons.check, color: Colors.white, size: 12),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              text, 
              style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w500, color: AppTheme.textColor)
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuaranteeCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryColor.withOpacity(0.05), AppTheme.secondaryColor.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppTheme.primaryColor.withOpacity(0.1), shape: BoxShape.circle),
            child: const Icon(Icons.shield_rounded, color: AppTheme.primaryColor, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Satisfaction Guaranteed', style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 16)),
                Text(
                  '100% money back if you are not satisfied with the work.',
                  style: GoogleFonts.outfit(color: AppTheme.subtitleColor, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsSection(HomeService service) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Reviews',
          style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.textColor),
        ),
        const SizedBox(height: 16),
        _buildReviewItem('Sarah J.', 'Excellent service, highly professional and punctual.'),
        _buildReviewItem('Michael R.', 'Very thorough cleaning. Worth every penny!'),
      ],
    );
  }

  Widget _buildSubServicesSection() {
    if (_isSubServicesLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_subServices.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Available Sub-Services',
          style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.textColor),
        ),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _subServices.length,
          itemBuilder: (context, index) {
            final sub = _subServices[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade100),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: SafeNetworkImage(
                      imageUrl: sub.imageUrl,
                      width: 60,
                      height: 60,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sub.name,
                          style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 15),
                        ),
                        Text(
                          '₹${sub.price.toStringAsFixed(0)}',
                          style: GoogleFonts.outfit(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => _handleSubServiceAddToCart(sub),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                      foregroundColor: AppTheme.primaryColor,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Add', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Future<void> _handleSubServiceAddToCart(SubService sub) async {
    HapticFeedback.mediumImpact();
    final cart = Provider.of<CartProvider>(context, listen: false);
    await cart.addItem(CartItem(
      id: '',
      serviceId: widget.serviceId,
      subServiceId: sub.id,
      serviceName: '${_service!.title} - ${sub.name}',
      serviceImage: sub.imageUrl ?? _service!.imageUrl ?? '',
      price: sub.price,
      quantity: 1,
      totalPrice: sub.price,
    ));
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${sub.name} added to cart'),
          backgroundColor: AppTheme.successColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _buildBottomAction(BuildContext context, HomeService service) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 40, offset: const Offset(0, -10))],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('STARTING AT', style: GoogleFonts.outfit(color: AppTheme.subtitleColor, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1)),
                Text(
                  '₹${service.basePrice.toStringAsFixed(0)}',
                  style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w900, color: AppTheme.textColor),
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _isAddingToCart ? null : () => _handleAddToCart(context, service),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                disabledBackgroundColor: const Color(0xFF6366F1).withOpacity(0.6),
              ),
              child: _isAddingToCart
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.shopping_cart_rounded, size: 18),
                        SizedBox(width: 8),
                        Text('Add to Cart', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  /// Handle add to cart with loading state, haptic feedback, and navigation
  Future<void> _handleAddToCart(BuildContext context, HomeService service) async {
    if (_isAddingToCart || !mounted) return;
    
    setState(() {
      _isAddingToCart = true;
    });

    try {
      final cart = Provider.of<CartProvider>(context, listen: false);
      await cart.addItem(CartItem(
        id: '',
        serviceId: service.id,
        serviceName: service.title,
        serviceImage: service.imageUrl ?? '',
        price: service.basePrice,
        quantity: 1,
        totalPrice: service.basePrice,
      ));
      
      // Haptic feedback on success
      HapticFeedback.mediumImpact();
      
      if (!mounted) return;
      
      // Show success snackbar with navigation
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '${service.title} added to cart',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          backgroundColor: AppTheme.successColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 2),
          action: SnackBarAction(
            label: 'VIEW CART',
            textColor: Colors.white,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CartScreen(),
                ),
              );
            },
          ),
        ),
      );
      
      // Navigate to cart after short delay
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (!mounted) return;
      
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const CartScreen(),
        ),
      );
      
    } catch (e) {
      debugPrint('Error adding to cart: $e');
      
      if (!mounted) return;
      
      // Show error snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Failed to add to cart. Please try again.',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isAddingToCart = false;
        });
      }
    }
  }
}

/// Animated favorite action button for the app bar
/// Uses InkWell for splash effect and scale animation on tap
class _FavoriteActionButton extends StatefulWidget {
  final HomeService service;

  const _FavoriteActionButton({required this.service});

  @override
  State<_FavoriteActionButton> createState() => _FavoriteActionButtonState();
}

class _FavoriteActionButtonState extends State<_FavoriteActionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleTap() {
    // Trigger scale animation
    _animationController.forward().then((_) {
      _animationController.reverse();
    });
    
    // Toggle favorite
    context.read<FavoritesProvider>().toggleFavorite(
      widget.service.id, 
      widget.service.category
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: CircleAvatar(
        backgroundColor: Colors.white.withOpacity(0.9),
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: child,
            );
          },
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _handleTap,
              borderRadius: BorderRadius.circular(20),
              splashColor: Colors.red.withOpacity(0.2),
              child: Consumer<FavoritesProvider>(
                builder: (context, favorites, _) {
                  final isFavorite = favorites.isFavorite(widget.service.id);
                  return AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    transitionBuilder: (child, animation) {
                      return FadeTransition(opacity: animation, child: child);
                    },
                    child: Icon(
                      isFavorite
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      key: ValueKey(isFavorite),
                      color: isFavorite ? Colors.red : Colors.black,
                      size: 20,
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

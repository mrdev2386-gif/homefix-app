import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:customer_app/core/models/sub_service.dart';
import 'package:customer_app/core/models/service.dart';
import 'package:customer_app/core/models/cart_item.dart';
import 'package:customer_app/core/widgets/safe_network_image.dart';
import 'package:customer_app/core/providers/cart_provider.dart';
import 'package:customer_app/core/providers/favorites_provider.dart';
import 'package:customer_app/core/theme/app_theme.dart';
import 'package:customer_app/core/services/category_service.dart';
import 'package:customer_app/features/cart/presentation/cart_screen.dart';

class ServiceDetailsScreen extends StatefulWidget {
  final String serviceId;
  /// The Firestore document ID of the parent category.
  /// MUST be the actual Firestore doc ID (e.g. "abc123"), NOT a display name.
  /// This is used to build the exact path:
  ///   categories/{categoryId}/services/{serviceId}/subServices
  final String categoryId;
  final String? serviceName;
  final HomeService? serviceData;

  const ServiceDetailsScreen({
    super.key,
    required this.serviceId,
    required this.categoryId,
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
  SubService? _selectedSubService; // Only subServices are bookable
  final CategoryService _categoryService = CategoryService();

  @override
  void initState() {
    super.initState();
    _service = widget.serviceData;
    _initialLoad();
  }

  Future<void> _initialLoad() async {
    await _fetchService();
    if (_service != null) {
      _fetchTechnicianCount();
      _fetchSubServices();
    }
  }

  Future<void> _fetchService() async {
    if (_service != null) {
      _isLoading = false;
      return;
    }
    
    final service = await _categoryService.getServiceById(widget.serviceId);
    if (mounted) {
      setState(() {
        _service = service;
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchSubServices() async {
    if (!mounted) return;

    // ✅ ALWAYS use widget.categoryId — the Firestore doc ID passed from the
    // parent screen. Never use service.category which may be a display name.
    final categoryId = widget.categoryId;
    final serviceId = widget.serviceId;

    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    debugPrint('🔍 [ServiceDetails] _fetchSubServices() STARTED');
    debugPrint('   serviceId   = "$serviceId"');
    debugPrint('   categoryId  = "$categoryId"  ← from widget.categoryId (Firestore doc ID)');
    debugPrint('   Firestore path: categories/$categoryId/services/$serviceId/subServices');

    if (categoryId.isEmpty || serviceId.isEmpty) {
      debugPrint('❌ [ServiceDetails] ABORT — categoryId or serviceId is EMPTY');
      debugPrint('   categoryId empty: ${categoryId.isEmpty}');
      debugPrint('   serviceId  empty: ${serviceId.isEmpty}');
      setState(() => _isSubServicesLoading = false);
      return;
    }
    debugPrint('✅ [ServiceDetails] IDs valid — starting stream');
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    _categoryService.getSubServices(categoryId, serviceId).listen((homeServices) {
      debugPrint('📦 [ServiceDetails] SubServices stream event received');
      debugPrint('   subServices.length = ${homeServices.length}');
      if (homeServices.isEmpty) {
        debugPrint('   ⚠️ EMPTY subServices — no docs at:');
        debugPrint('      categories/$categoryId/services/$serviceId/subServices');
        debugPrint('      Check: isActive=true exists, data is seeded');
      } else {
        for (var i = 0; i < homeServices.length && i < 5; i++) {
          debugPrint('   [${i+1}] id="${homeServices[i].id}" name="${homeServices[i].title}" price=${homeServices[i].basePrice}');
        }
      }
      if (!mounted) return;
      setState(() {
        _subServices = homeServices.map((hs) => SubService(
          id: hs.id,
          name: hs.title,
          imageUrl: hs.imageUrl,
          price: hs.basePrice,
          order: hs.order,
          isActive: hs.isActive,
        )).toList();
        _isSubServicesLoading = false;
      });
    }, onError: (e) {
      debugPrint('❌ [ServiceDetails] SubServices stream ERROR: $e');
      debugPrint('   type: ${e.runtimeType}');
      if (e.toString().contains('FAILED_PRECONDITION')) {
        debugPrint('   ROOT CAUSE: Missing Firestore composite index for isActive+order in subServices');
      } else if (e.toString().contains('PERMISSION_DENIED')) {
        debugPrint('   ROOT CAUSE: Firestore security rules blocking subServices read');
      }
      if (mounted) {
        setState(() => _isSubServicesLoading = false);
      }
    });
  }

  Future<void> _fetchTechnicianCount() async {
    if (!mounted) return;
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
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: AppTheme.primaryColor)));
    }
    
    if (_service == null) {
      return Scaffold(
        appBar: AppBar(elevation: 0, backgroundColor: Colors.white),
        body: Center(child: Text('Service not found', style: GoogleFonts.outfit())),
      );
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
                ],
              ),
            ),
          ),
          
          // Sub-services Header
          if (_subServices.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'Available Sub-Services',
                  style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.textColor),
                ),
              ),
            ),
            
          // Sub-services List (PERFORMANCE OPTIMIZED: Using SliverList instead of shrinkWrap ListView)
          if (_isSubServicesLoading)
            const SliverToBoxAdapter(child: Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator())))
          else if (_subServices.isNotEmpty)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final sub = _subServices[index];
                    return _buildSubServiceItem(sub);
                  },
                  childCount: _subServices.length,
                ),
              ),
            )
          else
            SliverToBoxAdapter(
              child: Container(
                // Fixed height container to prevent layout issues
                height: 180,
                padding: const EdgeInsets.all(40.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.pending_actions_rounded, color: Colors.grey[300], size: 48),
                    const SizedBox(height: 16),
                    Text(
                      'Options coming soon',
                      style: GoogleFonts.outfit(color: Colors.grey[600], fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Check back later for available choices',
                      style: GoogleFonts.outfit(color: Colors.grey[400], fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
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

  Widget _buildSubServiceItem(SubService sub) {
    final isSelected = _selectedSubService?.id == sub.id;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedSubService = sub;
        });
        HapticFeedback.selectionClick();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor.withOpacity(0.08) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : Colors.grey.shade100,
            width: isSelected ? 2 : 1,
          ),
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
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w700, 
                      fontSize: 15,
                      color: isSelected ? AppTheme.primaryColor : AppTheme.textColor,
                    ),
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
            if (isSelected)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 16),
              ),
          ],
        ),
      ),
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
          backgroundColor: Colors.white.withValues(alpha: 0.9),
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
              imageUrl: service.imageUrl,
              height: 320,
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.black.withValues(alpha: 0.35), Colors.transparent],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        _FavoriteActionButton(service: service),
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

  Widget _buildBottomAction(BuildContext context, HomeService service) {
    final hasSubServices = _subServices.isNotEmpty;
    final canBook = !hasSubServices || _selectedSubService != null;
    final displayPrice = _selectedSubService?.price ?? service.basePrice;
    final priceLabel = _selectedSubService != null 
        ? _selectedSubService!.name 
        : (hasSubServices ? 'Select an option below' : 'Starting at');
    
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
                Text(
                  hasSubServices ? (canBook ? priceLabel : 'SELECT AN OPTION') : 'STARTING AT',
                  style: GoogleFonts.outfit(
                    color: canBook ? AppTheme.subtitleColor : AppTheme.primaryColor,
                    fontSize: 10, 
                    fontWeight: FontWeight.w800, 
                    letterSpacing: 1,
                  ),
                ),
                Text(
                  '₹${displayPrice.toStringAsFixed(0)}',
                  style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w900, color: AppTheme.textColor),
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _isAddingToCart || !canBook 
                  ? null 
                  : () => _handleAddToCart(context, service),
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
                      children: [
                        Icon(hasSubServices && !canBook ? Icons.touch_app_rounded : Icons.shopping_cart_rounded, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          hasSubServices && !canBook ? 'Select Option' : 'Add to Cart',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleAddToCart(BuildContext context, HomeService service) async {
    if (_isAddingToCart || !mounted) return;
    
    // Enforce subService selection - only subServices are bookable
    if (_subServices.isNotEmpty && _selectedSubService == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select an option to proceed'),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    
    setState(() {
      _isAddingToCart = true;
    });

    try {
      final cart = Provider.of<CartProvider>(context, listen: false);
      
      // Use subService if selected, otherwise use service directly (fallback for services without subServices)
      final itemPrice = _selectedSubService?.price ?? service.basePrice;
      final itemName = _selectedSubService?.name ?? service.title;
      
      // FIX: Replace asserts with runtime guards — asserts crash before try/catch can handle
      if (service.category.isEmpty || service.categoryName.isEmpty || service.technicianId == null || service.technicianId!.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(service.technicianId == null || service.technicianId!.isEmpty
                  ? 'This service is not yet assigned to a technician'
                  : 'Missing service category information'),
              backgroundColor: AppTheme.errorColor,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }

      await cart.addItem(CartItem(
        id: '',
        categoryId: service.category,
        categoryName: service.categoryName,
        serviceId: service.id,
        subServiceId: _selectedSubService?.id,
        subServiceName: _selectedSubService?.name,
        serviceName: itemName,
        serviceImage: _selectedSubService?.imageUrl ?? service.imageUrl,
        price: itemPrice,
        quantity: 1,
        totalPrice: itemPrice,
        technicianId: service.technicianId,
        finalPriceSnapshot: itemPrice,
      ));
      
      HapticFeedback.mediumImpact();
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$itemName added to cart'),
          backgroundColor: AppTheme.successColor,
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'VIEW CART',
            textColor: Colors.white,
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const CartScreen()));
            },
          ),
        ),
      );
      
    } catch (e) {
      debugPrint('Error adding to cart: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isAddingToCart = false;
        });
      }
    }
  }

  Widget _buildReviewItem(String name, String review) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
        child: Text(name[0], style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
      ),
      title: Text(name, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14)),
      subtitle: Text(review, style: GoogleFonts.outfit(fontSize: 13, color: AppTheme.subtitleColor)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.star_rounded, color: Colors.orange, size: 14),
          Icon(Icons.star_rounded, color: Colors.orange, size: 14),
          Icon(Icons.star_rounded, color: Colors.orange, size: 14),
          Icon(Icons.star_rounded, color: Colors.orange, size: 14),
          Icon(Icons.star_rounded, color: Colors.orange, size: 14),
        ],
      ),
    );
  }
}

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
    _animationController.forward().then((_) => _animationController.reverse());
    context.read<FavoritesProvider>().toggleFavorite(widget.service.id, widget.service.category);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: CircleAvatar(
        backgroundColor: Colors.white.withValues(alpha: 0.9),
        child: InkWell(
          onTap: _handleTap,
          borderRadius: BorderRadius.circular(20),
          child: Consumer<FavoritesProvider>(
            builder: (context, favorites, _) {
              final isFavorite = favorites.isFavorite(widget.service.id);
              return ScaleTransition(
                scale: _scaleAnimation,
                child: Icon(
                  isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  color: isFavorite ? Colors.red : Colors.black,
                  size: 20,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:customer_app/core/models/sub_service.dart';
import 'package:customer_app/core/models/service.dart';
import 'package:customer_app/core/models/cart_item.dart';
import 'package:customer_app/core/widgets/safe_network_image.dart';
import 'package:customer_app/core/providers/cart_provider.dart';
import 'package:customer_app/core/providers/favorites_provider.dart';
import 'package:customer_app/core/theme/app_theme.dart';
import 'package:customer_app/core/services/category_service.dart';
import 'package:customer_app/core/services/firestore_service.dart';
import 'package:customer_app/features/cart/presentation/cart_screen.dart';

class ServiceDetailsScreen extends StatefulWidget {
  final String serviceId;
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
  SubService? _selectedSubService;
  bool _subServicesExpanded = true;
  late final CategoryService _categoryService;
  final ScrollController _scrollController = ScrollController();
  StreamSubscription<List<HomeService>>? _subServicesSubscription;

  @override
  void dispose() {
    _subServicesSubscription?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _categoryService = context.read<CategoryService>();
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
    try {
      final firestoreService = context.read<FirestoreService>();
      final service = await firestoreService.getServiceById(widget.serviceId);
      if (mounted) {
        setState(() {
          _service = service;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching service: $e');
      if (mounted) setState(() { _service = null; _isLoading = false; });
    }
  }

  Future<void> _fetchSubServices() async {
    if (!mounted) return;

    final categoryId = widget.categoryId;
    final serviceId = widget.serviceId;

    if (categoryId.isEmpty || serviceId.isEmpty) {
      setState(() => _isSubServicesLoading = false);
      return;
    }

    _subServicesSubscription?.cancel();
    _subServicesSubscription = _categoryService.getSubServices(categoryId, serviceId).asBroadcastStream().listen((homeServices) {
      if (!mounted) return;
      setState(() {
        _subServices = homeServices.map((hs) => SubService(
          id: hs.id,
          name: hs.title,
          imageUrl: hs.imageUrl,
          price: hs.price,
          order: hs.order,
          isActive: hs.isActive,
        )).toList();
        _isSubServicesLoading = false;
      });
    }, onError: (e) {
      if (mounted) {
        setState(() => _isSubServicesLoading = false);
      }
    });
  }

  Future<void> _fetchTechnicianCount() async {
    if (!mounted || _service == null) return;
    try {
      final userLocation = await _getUserLocation();
      if (userLocation == null) return;
      final firestoreService = context.read<FirestoreService>();
      final stream = firestoreService.streamOnlineTechnicians(
        state: userLocation['state'] ?? '',
        district: userLocation['district'] ?? '',
      );
      final technicians = await stream.first;
      if (mounted) setState(() => _techCount = technicians.length);
    } catch (e) {
      debugPrint('Error fetching technician count: $e');
    }
  }

  Future<Map<String, String>?> _getUserLocation() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return null;
      final firestoreService = context.read<FirestoreService>();
      final data = await firestoreService.getUserProfile(uid);
      if (data == null) return null;
      return {
        'state': (data['state'] ?? '').toString().toLowerCase(),
        'district': (data['district'] ?? '').toString().toLowerCase(),
      };
    } catch (e) {
      debugPrint('Error getting user location: $e');
      return null;
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
        controller: _scrollController,
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
                    service.description.isNotEmpty 
                        ? service.description
                        : 'Get premium ${service.title.toLowerCase()} service at your convenience. Our selected and background-checked professionals ensure top-quality results and a worry-free experience.',
                    style: GoogleFonts.outfit(color: AppTheme.subtitleColor, height: 1.6, fontSize: 15),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
          
          if (_subServices.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: GestureDetector(
                  onTap: () => setState(() => _subServicesExpanded = !_subServicesExpanded),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Available Sub-Services',
                          style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.textColor)),
                      Icon(_subServicesExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                          color: AppTheme.primaryColor),
                    ],
                  ),
                ),
              ),
            ),
            
          if (_isSubServicesLoading)
            const SliverToBoxAdapter(child: Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator())))
          else if (_subServices.isNotEmpty && _subServicesExpanded)
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
          _subServicesExpanded = false; // collapse after selection
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
                decoration: const BoxDecoration(
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
                  service.rating > 0 ? service.rating.toStringAsFixed(1) : 'New',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 16),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Text(
                service.title,
                style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.w900, height: 1.1, color: AppTheme.textColor),
              ),
            ),
            if (service.urgentBookingEnabled)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange, width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.flash_on, color: Colors.orange, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      'Urgent',
                      style: GoogleFonts.outfit(
                        color: Colors.orange,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
          ],
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
          _buildStatItem(Icons.verified_rounded, 'Verified', service.technicianName ?? 'Pro Expert', Colors.blue),
          _buildStatItem(Icons.location_on_rounded, 'Available in', service.technicianDistrict ?? 'Your Area', Colors.purple),
          _buildStatItem(Icons.star_rounded, service.rating > 0 ? service.rating.toStringAsFixed(1) : 'New', service.reviewCount > 0 ? '${service.reviewCount} Reviews' : 'No reviews yet', Colors.orange),
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
        if (service.reviewCount > 0) ...[
          // Show real review count and rating
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.star_rounded, color: Colors.orange, size: 24),
                const SizedBox(width: 8),
                Text(
                  '${service.rating.toStringAsFixed(1)} out of 5',
                  style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(width: 8),
                Text(
                  '(${service.reviewCount} reviews)',
                  style: GoogleFonts.outfit(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ] else ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.star_border_rounded, color: Colors.grey[400], size: 24),
                const SizedBox(width: 8),
                Text(
                  'No reviews yet',
                  style: GoogleFonts.outfit(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildBottomAction(BuildContext context, HomeService service) {
    final hasSubServices = _subServices.isNotEmpty;
    final canBook = !hasSubServices || _selectedSubService != null;
    final displayPrice = _selectedSubService?.price ?? (service.offerPrice ?? service.price);
    final originalPrice = service.price;
    final hasOffer = service.offerPrice != null && service.offerPrice! > 0 && service.offerPrice! < service.price;
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
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        '₹${displayPrice.toStringAsFixed(0)}',
                        overflow: TextOverflow.visible,
                        softWrap: true,
                        style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w900, color: AppTheme.textColor),
                      ),
                    ),
                    if (hasOffer && !hasSubServices)
                      Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${((originalPrice - service.offerPrice!) / originalPrice * 100).round()}% OFF',
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                  ],
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
    if (kDebugMode) debugPrint('🛒 [ADD TO CART] Button tapped for: ${service.title}');
    if (_isAddingToCart || !mounted) return;
    
    if (_subServices.isNotEmpty && _selectedSubService == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an option to proceed'),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    
    setState(() => _isAddingToCart = true);

    try {
      final cart = Provider.of<CartProvider>(context, listen: false);

      // Check if already in cart
      final alreadyInCart = cart.items.any((i) =>
          i.serviceId == service.id &&
          i.subServiceId == _selectedSubService?.id);

      if (alreadyInCart) {
        HapticFeedback.mediumImpact();
        setState(() => _isAddingToCart = false);
        if (!mounted) return;
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.white,
          isScrollControlled: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (ctx) => Padding(
            padding: EdgeInsets.fromLTRB(20, 24, 20, MediaQuery.of(ctx).padding.bottom + 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.green, size: 52),
                const SizedBox(height: 12),
                Text('Already in Cart', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Text('This service is already added to your cart.', textAlign: TextAlign.center, style: GoogleFonts.outfit(color: Colors.grey[600], fontSize: 14)),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        child: Text('Continue', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const CartScreen()));
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        child: Text('Go to Cart', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
        return;
      }
      
      final itemPrice = _selectedSubService?.price ?? (service.offerPrice ?? service.price);
      final itemName = _selectedSubService?.name ?? service.title;
      final finalPrice = itemPrice;
      if (kDebugMode) debugPrint('🛒 [ADD TO CART] Item: $itemName, Price: $itemPrice');
      
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

      if (kDebugMode) debugPrint('🛒 [ADD TO CART] Creating CartItem and calling addItem()');
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
        totalPrice: finalPrice,
        technicianId: service.technicianId,
        finalPriceSnapshot: finalPrice, // Store the final price that will be charged
      ));
      if (kDebugMode) debugPrint('✅ [ADD TO CART] Item added successfully');
      HapticFeedback.mediumImpact();
      setState(() => _isAddingToCart = false);
      if (!mounted) return;
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.white,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (ctx) => Padding(
          padding: EdgeInsets.fromLTRB(20, 24, 20, MediaQuery.of(ctx).padding.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.shopping_cart_checkout_rounded, color: AppTheme.primaryColor, size: 52),
              const SizedBox(height: 12),
              Text('Added to Cart!', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text('$itemName added successfully.', textAlign: TextAlign.center, style: GoogleFonts.outfit(color: Colors.grey[600], fontSize: 14)),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      child: Text('Continue', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const CartScreen()));
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      child: Text('Go to Cart', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
      
    } catch (e) {
      debugPrint('Error adding to cart: $e');
      if (mounted) setState(() => _isAddingToCart = false);
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
      trailing: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
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
    final isFav = context.read<FavoritesProvider>().isFavorite(widget.service.id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isFav ? 'Added to favorites' : 'Removed from favorites'),
        duration: const Duration(milliseconds: 1500),
        behavior: SnackBarBehavior.floating,
      ),
    );
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

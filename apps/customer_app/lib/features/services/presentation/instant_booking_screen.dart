import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/widgets/safe_network_image.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:customer_app/core/theme/app_theme.dart';
import '../../../core/providers/location_provider.dart';
import 'package:customer_app/core/models/category.dart';
import 'package:customer_app/core/services/category_service.dart';

import '../../custom_request/presentation/custom_request_screen.dart';

/// DTO for instant service from cloud function
class InstantService {
  final String serviceId;
  final String serviceName;
  final String technicianId;
  final String technicianName;
  final double rating;
  final int reviewCount;
  final double priceStarting;
  final String imageUrl;
  final int estimatedArrivalMinutes;
  final bool isVerified;
  final double? distanceKm;

  const InstantService({
    required this.serviceId,
    required this.serviceName,
    required this.technicianId,
    required this.technicianName,
    required this.rating,
    required this.reviewCount,
    required this.priceStarting,
    required this.imageUrl,
    required this.estimatedArrivalMinutes,
    required this.isVerified,
    this.distanceKm,
  });

  factory InstantService.fromMap(Map<String, dynamic> map) {
    // Ultra-safe parsing - prevents type cast crash
    final rawRating = map['rating'];
    final double rating = (rawRating is num) ? rawRating.toDouble() : 0.0;
    
    final rawReviewCount = map['reviewCount'];
    final int reviewCount = (rawReviewCount is num && rawReviewCount.isFinite) ? rawReviewCount.toInt() : 0;
    
    final rawPrice = map['priceStarting'];
    final double priceStarting = (rawPrice is num) ? rawPrice.toDouble() : 0.0;
    
    final rawArrival = map['estimatedArrivalMinutes'];
    final int estimatedArrivalMinutes = (rawArrival is num && rawArrival.isFinite) ? rawArrival.toInt() : 30;
    
    final rawIsVerified = map['isVerified'];
    final bool isVerified = (rawIsVerified is bool) ? rawIsVerified : false;
    
    final rawDistance = map['distanceKm'];
    final double? distanceKm = (rawDistance is num) ? rawDistance.toDouble() : null;
    
    return InstantService(
      serviceId: map['serviceId'] ?? '',
      serviceName: map['serviceName'] ?? '',
      technicianId: map['technicianId'] ?? '',
      technicianName: map['technicianName'] ?? '',
      rating: rating,
      reviewCount: reviewCount,
      priceStarting: priceStarting,
      imageUrl: map['imageUrl'] ?? '',
      estimatedArrivalMinutes: estimatedArrivalMinutes,
      isVerified: isVerified,
      distanceKm: distanceKm,
    );
  }
}

/// Sort options for instant booking
enum InstantSortOption { nearest, topRated, lowestPrice }

class InstantBookingScreen extends StatefulWidget {
  const InstantBookingScreen({super.key});

  @override
  State<InstantBookingScreen> createState() => _InstantBookingScreenState();
}

class _InstantBookingScreenState extends State<InstantBookingScreen> {
  final CategoryService _categoryService = CategoryService();

  List<Category> _categories = [];
  Category? _selectedCategory;
  InstantSortOption _sortOption = InstantSortOption.nearest;
  bool _availableNow = false;
  bool _isLoading = true;
  List<InstantService> _services = [];
  String? _errorMessage;
  final int _pageSize = 20;
  bool _isLoadingMore = false;
  String? _nextPageToken;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _fetchInstantServices();
  }

  void _loadCategories() {
    _categoryService.getCategories().listen((categories) {
      if (mounted) {
        setState(() {
          _categories = categories;
        });
      }
    });
  }

  Future<void> _fetchInstantServices({String? pageToken}) async {
    if (pageToken == null) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    } else {
      setState(() {
        _isLoadingMore = true;
      });
    }

    try {
      final addressProvider = context.read<LocationProvider>();
      final selectedAddress = addressProvider.selectedAddress;
      final latitude = selectedAddress?.latitude ?? 0.0;
      final longitude = selectedAddress?.longitude ?? 0.0;

      // Build request payload
      final Map<String, dynamic> request = {
        'city': addressProvider.selectedDistrict ?? '',
        'area': '',
        'latitude': latitude,
        'longitude': longitude,
        'categoryId': _selectedCategory?.id,
        'availableNow': _availableNow,
        'sortBy': _sortOption.toString().split('.').last,
        'limit': _pageSize,
        if (pageToken != null && pageToken.isNotEmpty) 'pageToken': pageToken,
      };

      // Call cloud function
      final response = await _callGetInstantServices(request);

      if (!mounted) return;

      final servicesList = (response['services'] as List<dynamic>?)
          ?.map((item) => InstantService.fromMap(item as Map<String, dynamic>))
          .toList() ?? <InstantService>[];

      setState(() {
        if (pageToken == null) {
          _services = servicesList;
        } else {
          _services = [..._services, ...servicesList];
        }
        _nextPageToken = response['nextPageToken'] as String?;
        _isLoading = false;
        _isLoadingMore = false;
      });
    } on FirebaseFunctionsException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message ?? 'Failed to load services';
        _isLoading = false;
        _isLoadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to load services';
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  Future<Map<String, dynamic>> _callGetInstantServices(Map<String, dynamic> request) async {
    final functions = FirebaseFunctions.instance;
    final callable = functions.httpsCallable('getInstantServices');
    final result = await callable.call(request);
    
    if (result.data == null) {
      throw Exception('No data returned from function');
    }
    
    return Map<String, dynamic>.from(result.data as Map<String, dynamic>);
  }

  String _extractCity(String address) {
    final parts = address.split(',');
    if (parts.length >= 2) {
      return parts[parts.length - 2].trim();
    }
    return '';
  }

  String _extractArea(String address) {
    final parts = address.split(',');
    if (parts.isNotEmpty) {
      return parts[0].trim();
    }
    return address;
  }

  Future<void> _loadMore() async {
    if (_nextPageToken != null && !_isLoadingMore) {
      await _fetchInstantServices(pageToken: _nextPageToken);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildLocationCard(),
            _buildFilterBar(),
            Expanded(
              child: _buildContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Instant Booking',
              style: GoogleFonts.outfit(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppTheme.textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationCard() {
    return Consumer<LocationProvider>(
      builder: (context, location, child) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.accentColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.location_on_rounded,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Delivering to',
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.subtitleColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      location.currentAddress.isNotEmpty
                          ? location.currentAddress
                          : 'Select location',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => _showLocationBottomSheet(context),
                child: Text(
                  'Change',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterBar() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          const SizedBox(width: 20),
          // Category chips
          SizedBox(
            height: 36,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              shrinkWrap: true,
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = _selectedCategory?.id == category.id;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = selected ? category : null;
                        _fetchInstantServices();
                      });
                    },
                    label: Text(
                      category.name,
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                    backgroundColor: Colors.white,
                    selectedColor: AppTheme.primaryColor,
                    labelStyle: GoogleFonts.outfit(
                      color: isSelected ? Colors.white : AppTheme.textColor,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 8),
          // Sort dropdown
          PopupMenuButton<InstantSortOption>(
            offset: const Offset(0, 40),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onSelected: (option) {
              setState(() {
                _sortOption = option;
                _fetchInstantServices();
              });
            },
            itemBuilder: (context) => [
              _buildSortMenuItem('Nearest', InstantSortOption.nearest, Icons.near_me_rounded),
              _buildSortMenuItem('Top Rated', InstantSortOption.topRated, Icons.star_rounded),
              _buildSortMenuItem('Lowest Price', InstantSortOption.lowestPrice, Icons.attach_money_rounded),
            ],
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_getSortIcon(), size: 16, color: AppTheme.primaryColor),
                  const SizedBox(width: 6),
                  Text(
                    _getSortLabel(),
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Available now toggle
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            decoration: BoxDecoration(
              color: _availableNow ? AppTheme.primaryColor : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _availableNow ? AppTheme.primaryColor : Colors.grey.shade300,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_availableNow)
                  Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: Text(
                      'Available Now',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                Switch(
                  value: _availableNow,
                  onChanged: (value) {
                    setState(() {
                      _availableNow = value;
                      _fetchInstantServices();
                    });
                  },
                  activeColor: Colors.white,
                  activeTrackColor: Colors.transparent,
                  inactiveThumbColor: AppTheme.primaryColor,
                  inactiveTrackColor: Colors.grey.shade300,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                if (!_availableNow)
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Text(
                      'Available Now',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textColor,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 20),
        ],
      ),
    );
  }

  PopupMenuItem<InstantSortOption> _buildSortMenuItem(
    String label,
    InstantSortOption value,
    IconData icon,
  ) {
    return PopupMenuItem<InstantSortOption>(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.primaryColor),
          const SizedBox(width: 10),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getSortIcon() {
    switch (_sortOption) {
      case InstantSortOption.nearest:
        return Icons.near_me_rounded;
      case InstantSortOption.topRated:
        return Icons.star_rounded;
      case InstantSortOption.lowestPrice:
        return Icons.attach_money_rounded;
    }
  }

  String _getSortLabel() {
    switch (_sortOption) {
      case InstantSortOption.nearest:
        return 'Nearest';
      case InstantSortOption.topRated:
        return 'Top Rated';
      case InstantSortOption.lowestPrice:
        return 'Lowest Price';
    }
  }

  Widget _buildContent() {
    if (_isLoading) {
      return _buildLoadingSkeleton();
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    if (_services.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      itemCount: _services.length + (_nextPageToken != null ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= _services.length) {
          return _buildLoadMoreButton();
        }
        return _buildServiceCard(_services[index]);
      },
    );
  }

  Widget _buildLoadingSkeleton() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      itemCount: 4,
      itemBuilder: (context, index) {
        return const ServiceCardSkeleton();
      },
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline_rounded, size: 64, color: AppTheme.errorColor),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              _errorMessage!,
              style: GoogleFonts.outfit(
                fontSize: 14,
                color: AppTheme.subtitleColor,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _fetchInstantServices(),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 40),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 24),
            Text(
              'No instant services nearby',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.textColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'You can still create a Custom Request',
              style: GoogleFonts.outfit(
                fontSize: 14,
                color: AppTheme.subtitleColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _navigateToCustomRequest(),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Create Custom Request'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToCustomRequest() {
    debugPrint('[InstantBooking] Navigating to CustomRequestScreen');
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CustomRequestScreen()),
    );
  }

  Widget _buildServiceCard(InstantService service) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Service image with performance optimization
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: SafeNetworkImage(
                  imageUrl: service.imageUrl ?? '',
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              // Available badge
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.access_time_rounded,
                        size: 12,
                        color: AppTheme.successColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${service.estimatedArrivalMinutes} mins',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Distance badge if available
              if (service.distanceKm != null)
                Positioned(
                  top: 12,
                  left: 12,
                  child: Text(
                    '${service.distanceKm!.toStringAsFixed(1)} km',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      backgroundColor: Colors.black54,
                    ),
                  ),
                ),
              // Verified badge
              if (service.isVerified)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.verified_rounded, size: 12, color: Colors.white),
                        const SizedBox(width: 4),
                        Text(
                          'Verified',
                          style: GoogleFonts.outfit(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              // Price badge
              Positioned(
                bottom: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'From ₹${service.priceStarting.toStringAsFixed(0)}',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          // Service details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  service.serviceName,
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryColor,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        service.serviceName,
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.person_rounded, size: 14, color: AppTheme.subtitleColor),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        service.technicianName,
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.subtitleColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Icon(Icons.star_rounded, size: 14, color: AppTheme.warningColor),
                    const SizedBox(width: 4),
                    Text(
                      service.rating.toStringAsFixed(1),
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textColor,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '(${service.reviewCount})',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.subtitleColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _handleBookNow(service),
                    icon: const Icon(Icons.bolt_rounded, size: 18),
                    label: const Text('Book Now'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadMoreButton() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: _isLoadingMore
          ? const Center(child: CircularProgressIndicator())
          : TextButton(
              onPressed: _loadMore,
              child: Text(
                'Load More',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
    );
  }

  void _showLocationBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Select Location',
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 24),

            _buildLocationOption(
              icon: Icons.map_outlined,
              title: 'Add New Address',
              subtitle: 'Search for your home or office',
              onTap: () => _handleAddNewAddress(context),
            ),
            const Divider(height: 1, indent: 80),
            _buildLocationOption(
              icon: Icons.home_work_outlined,
              title: 'Saved Addresses',
              subtitle: 'Select from frequently used locations',
              onTap: () => _handleSavedAddresses(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.accentColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: AppTheme.primaryColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.outfit(
                      color: AppTheme.subtitleColor,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.grey),
          ],
        ),
      ),
    );
  }



  Future<void> _handleAddNewAddress(BuildContext context) async {
    Navigator.pop(context);
    // Navigate to add address screen
  }

  Future<void> _handleSavedAddresses(BuildContext context) async {
    Navigator.pop(context);
    // Navigate to saved addresses screen
  }

  void _handleBookNow(InstantService service) {
    // Navigate to service details or booking flow
    // TODO: Implement booking flow
  }
}

/// Skeleton loader for service cards
class ServiceCardSkeleton extends StatelessWidget {
  const ServiceCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 160,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 12,
                  width: 80,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 20,
                  width: 180,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      height: 12,
                      width: 60,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      height: 12,
                      width: 40,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

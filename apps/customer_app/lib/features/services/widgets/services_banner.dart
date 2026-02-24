import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../core/widgets/safe_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/models/banner_model.dart';
import 'package:customer_app/core/theme/app_theme.dart';
import 'package:customer_app/core/services/category_service.dart';

/// Premium Top Banner Widget (Section 1)
/// Now correctly uses CategoryService as single source of truth.
class ServicesBanner extends StatefulWidget {
  final double height;
  final EdgeInsetsGeometry? margin;
  final Function(BannerModel banner)? onBannerTap;

  const ServicesBanner({
    super.key,
    this.height = 180,
    this.margin,
    this.onBannerTap,
  });

  @override
  State<ServicesBanner> createState() => _ServicesBannerState();
}

class _ServicesBannerState extends State<ServicesBanner> {
  final PageController _pageController = PageController();
  final CategoryService _categoryService = CategoryService();
  int _currentPage = 0;
  Timer? _timer;
  List<BannerModel> _banners = [];
  bool _isInitialized = false;

  late final Stream<List<BannerModel>> _bannerStream;

  @override
  void initState() {
    super.initState();
    _bannerStream = _categoryService.getBanners();
    _startAutoSlide();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoSlide() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!mounted || _banners.isEmpty) return;

      if (_currentPage < _banners.length - 1) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }

      if (_pageController.hasClients && mounted) {
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        height: widget.height,
        margin: widget.margin ?? const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<BannerModel>>(
      stream: _bannerStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !_isInitialized) {
          return _buildShimmer();
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildDefaultBanner();
        }

        _banners = snapshot.data!;
        _isInitialized = true;

        return _buildPremiumBanner();
      },
    );
  }

  Widget _buildDefaultBanner() {
    return Container(
      height: widget.height,
      margin: widget.margin ?? const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor,
            AppTheme.secondaryColor,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -30,
            top: -30,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Professional Home Services',
                  style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Book expert professionals for your home needs',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumBanner() {
    return Column(
      children: [
        Container(
          height: widget.height,
          margin: widget.margin ?? const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: PageView.builder(
              controller: _pageController,
              physics: const BouncingScrollPhysics(),
              onPageChanged: (index) {
                if (mounted) {
                  setState(() => _currentPage = index);
                }
              },
              itemCount: _banners.length,
              itemBuilder: (context, index) {
                final banner = _banners[index];
                return _buildBannerItem(banner);
              },
            ),
          ),
        ),
        if (_banners.length > 1) ...[
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_banners.length, (index) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                height: 6,
                width: _currentPage == index ? 24 : 6,
                decoration: BoxDecoration(
                  color: _currentPage == index
                      ? AppTheme.primaryColor
                      : Colors.grey[300],
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }),
          ),
        ],
      ],
    );
  }

  Widget _buildBannerItem(BannerModel banner) {
    return GestureDetector(
      onTap: () => widget.onBannerTap?.call(banner),
      child: Stack(
        fit: StackFit.expand,
        children: [
          SafeNetworkImage(
            imageUrl: banner.imageUrl,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.7),
                ],
                stops: const [0.3, 1.0],
              ),
            ),
          ),
          if (banner.title.isNotEmpty || banner.subtitle.isNotEmpty)
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (banner.title.isNotEmpty)
                    Text(
                      banner.title,
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  if (banner.subtitle.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      banner.subtitle,
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.85),
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

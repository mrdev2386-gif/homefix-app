import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';

/// SafeNetworkImage - Production-ready network image widget with:
/// - CachedNetworkImage for performance
/// - Shimmer loading placeholder
/// - Graceful fallback on error
/// - Support for assets and network URLs
class SafeNetworkImage extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final String fallbackUrl;
  final bool usePlaceholder;
  final Widget Function(BuildContext, String)? customPlaceholder;
  final Widget Function(BuildContext, String, dynamic)? customErrorWidget;

  const SafeNetworkImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.fallbackUrl = '',
    this.usePlaceholder = true,
    this.customPlaceholder,
    this.customErrorWidget,
  });

  @override
  Widget build(BuildContext context) {
    try {
      // Handle null or empty
      if (imageUrl == null || imageUrl!.trim().isEmpty) {
        return _buildFinalFallback();
      }

      final String url = imageUrl!.trim();

      // Handle Assets
      if (url.startsWith('assets/')) {
        return _clip(_buildAssetImage(url));
      }

      // Handle Network Images
      if (url.startsWith('http://') || url.startsWith('https://')) {
        return _clip(_buildNetworkImage(url));
      }

      // Invalid format - use fallback
      return _buildFinalFallback();
    } catch (e) {
      // NEVER CRASH - always show fallback
      return _buildFinalFallback();
    }
  }

  Widget _buildAssetImage(String path) {
    return Image.asset(
      path,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) => _buildFinalFallback(),
    );
  }

  Widget _buildNetworkImage(String url) {
    return CachedNetworkImage(
      imageUrl: url,
      width: width,
      height: height,
      fit: fit,
      placeholder: customPlaceholder ??
          (context, url) => usePlaceholder ? _buildShimmer() : const SizedBox(),
      errorWidget: customErrorWidget ??
          (context, url, error) {
            // Try fallback URL if main URL fails and fallback is provided
            if (url != fallbackUrl && fallbackUrl.isNotEmpty) {
              return CachedNetworkImage(
                imageUrl: fallbackUrl,
                width: width,
                height: height,
                fit: fit,
                placeholder: (context, url) =>
                    usePlaceholder ? _buildShimmer() : const SizedBox(),
                errorWidget: (context, url, error) =>
                    _buildFinalFallback(),
                fadeInDuration: const Duration(milliseconds: 200),
              );
            }
            return _buildFinalFallback();
          },
      fadeInDuration: const Duration(milliseconds: 300),
      memCacheWidth: 400,
      maxHeightDiskCache: 400,
    );
  }

  /// Safe icon size calculation - prevents NaN/Infinity crashes
  double _getSafeIconSize() {
    // Default fallback size
    const double defaultSize = 24.0;
    
    // Check width is valid finite number
    if (width == null || 
        !width!.isFinite || 
        width!.isNaN || 
        width! <= 0 || 
        width! == double.infinity) {
      return defaultSize;
    }
    
    // Calculate size but cap at reasonable max
    final calculated = width! * 0.3;
    if (calculated.isNaN || !calculated.isFinite || calculated <= 0) {
      return defaultSize;
    }
    
    return calculated.clamp(16.0, 80.0); // Clamp between 16-80px
  }

  Widget _clip(Widget child) {
    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: child,
      );
    }
    return child;
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[200]!,
      highlightColor: Colors.white,
      child: Container(
        width: width ?? double.infinity,
        height: height ?? double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: borderRadius,
        ),
      ),
    );
  }

  Widget _buildFinalFallback() {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.grey[100]!,
            Colors.grey[200]!,
          ],
        ),
        borderRadius: borderRadius,
      ),
      child: Center(
        child: Icon(
          Icons.home_repair_service_rounded,
          size: _getSafeIconSize(),
          color: Colors.grey[400],
        ),
      ),
    );
  }
}

/// Service-specific fallback with icon
class ServiceImageFallback extends StatelessWidget {
  final double? size;
  final String? serviceName;

  const ServiceImageFallback({
    super.key,
    this.size,
    this.serviceName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF6366F1).withOpacity(0.1),
            const Color(0xFF6366F1).withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getServiceIcon(),
              size: _getSafeServiceIconSize(),
              color: const Color(0xFF6366F1),
            ),
            if (serviceName != null && _isSizeValidForText((size ?? 60)))
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  serviceName!,
                  style: TextStyle(
                    fontSize: _getSafeTextSize((size ?? 60) * 0.12),
                    color: const Color(0xFF6366F1),
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
      ),
    );
  }

  IconData _getServiceIcon() {
    final name = serviceName?.toLowerCase() ?? '';
    if (name.contains('ac') || name.contains('air')) {
      return Icons.ac_unit;
    } else if (name.contains('plumb') || name.contains('pipe')) {
      return Icons.plumbing;
    } else if (name.contains('electric') || name.contains('wiring')) {
      return Icons.electrical_services;
    } else if (name.contains('clean') || name.contains('home')) {
      return Icons.cleaning_services;
    } else if (name.contains('repair') || name.contains('fix')) {
      return Icons.build;
    } else if (name.contains('appliance')) {
      return Icons.kitchen;
    }
    return Icons.home_repair_service_rounded;
  }

  /// Safe icon size for service images
  double _getSafeServiceIconSize() {
    const double defaultSize = 16.0;
    
    if (size == null || 
        !size!.isFinite || 
        size!.isNaN || 
        size! <= 0 || 
        size! == double.infinity) {
      return defaultSize;
    }
    
    final calculated = size! * 0.4;
    if (calculated.isNaN || !calculated.isFinite || calculated <= 0) {
      return defaultSize;
    }
    
    return calculated.clamp(12.0, 60.0);
  }

  /// Safe text size calculation
  double _getSafeTextSize(double requestedSize) {
    const double defaultTextSize = 8.0;
    
    if (requestedSize.isNaN || !requestedSize.isFinite || requestedSize <= 0) {
      return defaultTextSize;
    }
    
    return requestedSize.clamp(6.0, 24.0);
  }

  /// Check if size is valid for showing text
  bool _isSizeValidForText(double sizeValue) {
    return sizeValue.isFinite && 
           !sizeValue.isNaN && 
           sizeValue > 30;
  }
}

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Safe network image widget that handles all error cases gracefully
/// Prevents crashes from invalid URLs, network errors, and timeouts
class SafeNetworkImage extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final BorderRadius? borderRadius;
  final Color? backgroundColor;
  
  // Backward compatibility parameters (unused internally)
  final String? serviceName;
  final bool usePlaceholder;
  final String? fallbackUrl;
  
  const SafeNetworkImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.borderRadius,
    this.backgroundColor,
    // Backward compatibility (optional, unused)
    this.serviceName,
    this.usePlaceholder = true,
    this.fallbackUrl,
  });
  
  /// Safely converts dimension to valid value, never returns NaN/Infinity
  double _safeDimension(double? value, {double fallback = 100}) {
    if (value == null) return fallback;
    // Explicitly guard against infinity and NaN before any arithmetic
    if (value == double.infinity ||
        value == double.negativeInfinity ||
        value != value || // NaN check
        value <= 0) {
      debugPrint('[SAFE_IMAGE] ⚠️ Invalid dimension: $value → using fallback: $fallback');
      return fallback;
    }
    return value;
  }
  
  /// Validates if a URL is safe to load
  bool _isValidUrl(String? url) {
    if (url == null || url.isEmpty) {
      return false;
    }
    
    // Must be HTTP or HTTPS
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      debugPrint('[SAFE_IMAGE] Invalid protocol: $url');
      return false;
    }
    
    // Block known bad patterns
    if (url.contains('unsplash') && url.contains('404')) {
      debugPrint('[SAFE_IMAGE] Blocked known bad Unsplash URL');
      return false;
    }
    
    // Block obviously malformed URLs
    try {
      Uri.parse(url);
    } catch (e) {
      debugPrint('[SAFE_IMAGE] Malformed URL: $url');
      return false;
    }
    
    return true;
  }
  
  /// Sanitizes a dimension from LayoutBuilder constraints — never returns Infinity/NaN
  double _sanitizeDimension(double? value, {double fallback = 100}) {
    if (value == null) return fallback;
    if (value.isNaN || value.isInfinite) return fallback;
    if (value <= 0) return fallback;
    return value;
  }

  @override
  Widget build(BuildContext context) {
    // If URL is invalid, show fallback immediately
    if (!_isValidUrl(imageUrl)) {
      return _buildFallback();
    }

    // Use LayoutBuilder to safely resolve unconstrained dimensions
    return LayoutBuilder(
      builder: (context, constraints) {
        final safeWidth = _sanitizeDimension(
          (width != null)
              ? width
              : (constraints.maxWidth.isFinite ? constraints.maxWidth : null),
        );
        final safeHeight = _sanitizeDimension(
          (height != null)
              ? height
              : (constraints.maxHeight.isFinite ? constraints.maxHeight : null),
        );
        return _buildImage(safeWidth, safeHeight);
      },
    );
  }

  Widget _buildImage(double safeWidth, double safeHeight) {
    Widget imageWidget = CachedNetworkImage(
      imageUrl: imageUrl!,
      width: safeWidth,
      height: safeHeight,
      fit: fit,
      placeholder: (context, url) => placeholder ?? _buildPlaceholder(safeWidth, safeHeight),
      errorWidget: (context, url, error) {
        debugPrint('[SAFE_IMAGE] ❌ Failed to load: $url');
        debugPrint('[SAFE_IMAGE] Error: $error');
        return errorWidget ?? _buildFallback(safeWidth, safeHeight);
      },
      fadeInDuration: const Duration(milliseconds: 300),
      fadeOutDuration: const Duration(milliseconds: 100),
      // Disk cache limits
      maxWidthDiskCache: 1000,
      maxHeightDiskCache: 1000,
    );
    
    // Apply border radius if provided
    if (borderRadius != null) {
      imageWidget = ClipRRect(
        borderRadius: borderRadius!,
        child: imageWidget,
      );
    }

    // Apply background color if provided
    if (backgroundColor != null) {
      imageWidget = Container(
        width: safeWidth,
        height: safeHeight,
        color: backgroundColor,
        child: imageWidget,
      );
    }

    return imageWidget;
  }
  
  /// Builds a loading placeholder
  Widget _buildPlaceholder([double? safeWidth, double? safeHeight]) {
    final w = safeWidth ?? _safeDimension(width);
    final h = safeHeight ?? _safeDimension(height);
    
    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: borderRadius,
      ),
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[400]!),
          ),
        ),
      ),
    );
  }
  
  /// Builds an error fallback widget
  Widget _buildFallback([double? safeWidth, double? safeHeight]) {
    debugPrint('[SERVICE_IMAGE_FALLBACK] Image URL null/empty, showing placeholder');
    
    final w = safeWidth ?? _safeDimension(width);
    final h = safeHeight ?? _safeDimension(height);
    
    // Use reliable placeholder image
    const fallbackImage = 'https://via.placeholder.com/400x300.png?text=HomeFix';
    
    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.grey[200],
        borderRadius: borderRadius,
      ),
      child: Center(
        child: Image.network(
          fallbackImage,
          fit: BoxFit.cover,
          width: w,
          height: h,
          errorBuilder: (context, error, stackTrace) {
            // Ultimate fallback - show icon if even placeholder fails
            return Icon(
              Icons.image_not_supported,
              color: Colors.grey[400],
              size: (w < h ? w * 0.4 : h * 0.4).clamp(24, 48),
            );
          },
        ),
      ),
    );
  }
}

/// Circular variant of SafeNetworkImage
class SafeCircularNetworkImage extends StatelessWidget {
  final String? imageUrl;
  final double radius;
  final Widget? placeholder;
  final Widget? errorWidget;
  
  const SafeCircularNetworkImage({
    super.key,
    required this.imageUrl,
    required this.radius,
    this.placeholder,
    this.errorWidget,
  });
  
  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: SafeNetworkImage(
        imageUrl: imageUrl,
        width: radius * 2,
        height: radius * 2,
        fit: BoxFit.cover,
        placeholder: placeholder,
        errorWidget: errorWidget,
      ),
    );
  }
}

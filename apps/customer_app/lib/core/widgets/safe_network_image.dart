import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class SafeNetworkImage extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final BorderRadius? borderRadius;
  final Color? backgroundColor;
  
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
    this.serviceName,
    this.usePlaceholder = true,
    this.fallbackUrl,
  });
  
  double _safeDimension(double? value, {double fallback = 100}) {
    if (value == null) return fallback;
    if (value == double.infinity ||
        value == double.negativeInfinity ||
        value != value ||
        value <= 0) {
      return fallback;
    }
    return value;
  }
  
  bool _isValidUrl(String? url) {
    if (url == null || url.isEmpty) return false;
    if (!url.startsWith('http://') && !url.startsWith('https://')) return false;
    try {
      Uri.parse(url);
    } catch (e) {
      return false;
    }
    return true;
  }
  
  double _sanitizeDimension(double? value, {double fallback = 100}) {
    if (value == null) return fallback;
    if (value.isNaN || value.isInfinite) return fallback;
    if (value <= 0) return fallback;
    return value;
  }

  @override
  Widget build(BuildContext context) {
    if (!_isValidUrl(imageUrl)) {
      return _buildFallback();
    }

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
        return errorWidget ?? _buildFallback(safeWidth, safeHeight);
      },
      fadeInDuration: const Duration(milliseconds: 300),
      fadeOutDuration: const Duration(milliseconds: 100),
      maxWidthDiskCache: 1000,
      maxHeightDiskCache: 1000,
    );
    
    if (borderRadius != null) {
      imageWidget = ClipRRect(
        borderRadius: borderRadius!,
        child: imageWidget,
      );
    }

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
  
  Widget _buildFallback([double? safeWidth, double? safeHeight]) {
    final w = safeWidth ?? _safeDimension(width);
    final h = safeHeight ?? _safeDimension(height);
    
    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.grey[200],
        borderRadius: borderRadius,
      ),
      child: Center(
        child: Icon(
          Icons.image_not_supported,
          color: Colors.grey[400],
          size: (w < h ? w * 0.4 : h * 0.4).clamp(24, 48),
        ),
      ),
    );
  }
}

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

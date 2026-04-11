import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class SafeNetworkImage extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final double borderRadius;

  const SafeNetworkImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius = 0,
  });

  /// Sanitizes a dimension — never returns Infinity/NaN/zero
  double _sanitizeDimension(double? value, {double fallback = 100}) {
    if (value == null) return fallback;
    if (value.isNaN || value.isInfinite) return fallback;
    if (value <= 0) return fallback;
    return value;
  }

  /// Validates if a URL is safe to load
  bool _isValidUrl(String? url) {
    if (url == null || url.isEmpty) return false;
    if (!url.startsWith('http://') && !url.startsWith('https://')) return false;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final bool hasUrl = _isValidUrl(imageUrl);

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

        Widget imageWidget;
        if (!hasUrl) {
          imageWidget = _buildErrorWidget(safeWidth, safeHeight);
        } else {
          imageWidget = Image.network(
            imageUrl!,
            width: safeWidth,
            height: safeHeight,
            fit: fit,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return _buildShimmer(safeWidth, safeHeight);
            },
            errorBuilder: (context, error, stackTrace) =>
                _buildErrorWidget(safeWidth, safeHeight),
          );
        }

        if (borderRadius > 0) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(borderRadius),
            child: imageWidget,
          );
        }

        return imageWidget;
      },
    );
  }

  Widget _buildShimmer(double safeWidth, double safeHeight) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        width: safeWidth,
        height: safeHeight,
        color: Colors.white,
      ),
    );
  }

  Widget _buildErrorWidget(double safeWidth, double safeHeight) {
    return Container(
      width: safeWidth,
      height: safeHeight,
      color: Colors.grey[200],
      child: const Center(
        child: Icon(
          Icons.image_not_supported_outlined,
          color: Colors.grey,
          size: 48,
        ),
      ),
    );
  }
}

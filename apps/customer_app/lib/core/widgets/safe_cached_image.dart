import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class SafeCachedImage extends StatelessWidget {
  final String? imageUrl;
  final BoxFit fit;
  final double? width;
  final double? height;
  final double? cacheWidth;
  final BorderRadius? borderRadius;

  const SafeCachedImage({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.cacheWidth,
    this.borderRadius,
  });

  bool get _isValidUrl {
    if (imageUrl == null) return false;
    if (imageUrl!.isEmpty) return false;
    if (!imageUrl!.startsWith('http')) return false;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    Widget child;

    if (!_isValidUrl) {
      child = Container(
        width: width,
        height: height,
        color: const Color(0xFFF5F5F5),
        child: const Icon(Icons.broken_image, color: Colors.grey),
      );
    } else {
      child = CachedNetworkImage(
        imageUrl: imageUrl!,
        fit: fit,
        width: width,
        height: height,
        // Performance tuning
        memCacheWidth: cacheWidth?.toInt() ?? 600,
        memCacheHeight: 600,
        fadeInDuration: const Duration(milliseconds: 200),
        // Shimmer placeholder while loading
        placeholder: (context, url) => Container(
          width: width,
          height: height,
          color: const Color(0xFFF5F5F5),
          child: const Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
            ),
          ),
        ),
        // Error fallback icon
        errorWidget: (context, url, error) => Container(
          width: width,
          height: height,
          color: const Color(0xFFF5F5F5),
          child: const Icon(Icons.broken_image, color: Colors.grey),
        ),
      );
    }

    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: child,
      );
    }

    return child;
  }
}

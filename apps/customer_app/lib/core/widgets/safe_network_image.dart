import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';

class SafeNetworkImage extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final String fallbackUrl;
  final bool usePlaceholder;

  const SafeNetworkImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.fallbackUrl = 'https://images.unsplash.com/photo-1581578731548-c64695cc6952?w=800&q=80',
    this.usePlaceholder = true,
  });

  @override
  Widget build(BuildContext context) {
    // CRITICAL: Handle all null and invalid cases
    try {
      // 1. Handle null or empty
      if (imageUrl == null || imageUrl!.trim().isEmpty) {
        return _buildFinalFallback();
      }

      final String url = imageUrl!.trim();

      // 2. Handle Assets
      if (url.startsWith('assets/')) {
        return _clip(_buildAssetImage(url));
      }

      // 3. Handle Network Images
      if (url.startsWith('http://') || url.startsWith('https://')) {
        return _clip(_buildNetworkImage(url));
      }

      // 4. Invalid format - use fallback
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
      placeholder: usePlaceholder ? (context, url) => _buildShimmer() : null,
      errorWidget: (context, url, error) {
        // Try fallback URL if main URL fails
        if (url != fallbackUrl && fallbackUrl.isNotEmpty) {
          return CachedNetworkImage(
            imageUrl: fallbackUrl,
            width: width,
            height: height,
            fit: fit,
            placeholder: usePlaceholder ? (context, url) => _buildShimmer() : null,
            errorWidget: (context, url, error) => _buildFinalFallback(),
            fadeInDuration: const Duration(milliseconds: 200),
          );
        }
        return _buildFinalFallback();
      },
      fadeInDuration: const Duration(milliseconds: 300),
    );
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
        color: Colors.grey[100],
        borderRadius: borderRadius,
      ),
      child: Center(
        child: Icon(
          Icons.home_repair_service_rounded,
          size: width != null ? width! * 0.3 : 32,
          color: Colors.grey[400],
        ),
      ),
    );
  }
}

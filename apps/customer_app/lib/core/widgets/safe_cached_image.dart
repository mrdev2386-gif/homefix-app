import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class SafeCachedImage extends StatelessWidget {
  final String? imageUrl;
  final BoxFit fit;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  const SafeCachedImage({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
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
      child = const Icon(Icons.broken_image, color: Colors.grey);
    } else {
      child = CachedNetworkImage(
        imageUrl: imageUrl!,
        fit: fit,
        width: width,
        height: height,
        // Performance tuning
        memCacheWidth: 600,
        memCacheHeight: 600,
        fadeInDuration: const Duration(milliseconds: 200),
        placeholder: (context, url) =>
            const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        errorWidget: (context, url, error) =>
            const Icon(Icons.broken_image, color: Colors.grey),
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

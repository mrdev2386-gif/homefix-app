import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class SafeNetworkImage extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final double borderRadius;
  final String placeholderAsset;

  const SafeNetworkImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius = 0,
    this.placeholderAsset = 'assets/images/placeholder.png',
  });

  @override
  Widget build(BuildContext context) {
    bool hasUrl = imageUrl != null && imageUrl!.isNotEmpty;

    Widget imageWidget;
    if (!hasUrl) {
      imageWidget = Image.asset(
        placeholderAsset,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => _buildErrorWidget(),
      );
    } else {
      imageWidget = Image.network(
        imageUrl!,
        width: width,
        height: height,
        fit: fit,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return _buildShimmer();
        },
        errorBuilder: (context, error, stackTrace) => _buildErrorWidget(),
      );
    }

    if (borderRadius > 0) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: imageWidget,
      );
    }

    return imageWidget;
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        width: width ?? double.infinity,
        height: height ?? double.infinity,
        color: Colors.white,
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[200],
      child: const Icon(Icons.image_not_supported_outlined, color: Colors.grey),
    );
  }
}

import 'package:flutter/material.dart';
import '../core/widgets/safe_network_image.dart';

class AppImageAsset extends StatelessWidget {
  final String assetPath;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Color? color;

  const AppImageAsset({
    super.key,
    required this.assetPath,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SafeNetworkImage(
      imageUrl: assetPath,
      width: width,
      height: height,
      fit: fit,
    );
  }
}

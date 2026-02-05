import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class DashboardShimmer extends StatelessWidget {
  const DashboardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildShimmerBox(height: 190, margin: const EdgeInsets.symmetric(horizontal: 20)),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(child: _buildShimmerBox(height: 56, radius: 14)),
                const SizedBox(width: 14),
                Expanded(child: _buildShimmerBox(height: 56, radius: 14)),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _buildShimmerBox(width: 150, height: 24),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.75,
            ),
            itemCount: 6,
            itemBuilder: (context, index) => _buildShimmerBox(height: 120, radius: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerBox({double? width, double height = 100, double radius = 16, EdgeInsets? margin}) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[200]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        width: width ?? double.infinity,
        height: height,
        margin: margin,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }
}

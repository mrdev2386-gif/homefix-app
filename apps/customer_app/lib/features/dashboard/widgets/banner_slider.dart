import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/models/banner_model.dart';

class BannerSlider extends StatefulWidget {
  const BannerSlider({super.key});

  @override
  State<BannerSlider> createState() => _BannerSliderState();
}

class _BannerSliderState extends State<BannerSlider> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _timer;
  List<BannerModel> _banners = [];

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoSlide() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_banners.isEmpty) return;
      if (_currentPage < _banners.length - 1) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }
      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('banners')
          .where('active', isEqualTo: true)
          .orderBy('order')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
           return _buildShimmer();
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox.shrink(); // Hide if no banners
        }

        _banners = snapshot.data!.docs
            .map((doc) => BannerModel.fromFirestore(doc))
            .toList();

        // Only start timer once
        if (_timer == null) _startAutoSlide();

        return Column(
          children: [
            SizedBox(
              height: 180,
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _banners.length,
                itemBuilder: (context, index) {
                  final banner = _banners[index];
                  return GestureDetector(
                    onTap: () {
                      // Handle navigation based on banner.targetScreen
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Tapped: ${banner.targetId}')),
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        image: DecorationImage(
                          image: CachedNetworkImageProvider(banner.imageUrl),
                          fit: BoxFit.cover,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: CachedNetworkImage(
                          imageUrl: banner.imageUrl,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => _buildShimmer(height: 180),
                          errorWidget: (context, url, error) => Container(
                            color: Colors.grey[300],
                            child: const Icon(Icons.broken_image, size: 50, color: Colors.grey),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_banners.length, (index) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  height: 8,
                  width: _currentPage == index ? 24 : 8,
                  decoration: BoxDecoration(
                    color: _currentPage == index ? Colors.blue : Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
          ],
        );
      },
    );
  }

  Widget _buildShimmer({double height = 180}) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        height: height,
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}

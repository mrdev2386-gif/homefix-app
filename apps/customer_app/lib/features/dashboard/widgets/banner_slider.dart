import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/widgets/safe_cached_image.dart';
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
  bool _isUserInteracting = false;
  bool _isInitialized = false;
  
  late final Stream<QuerySnapshot> _bannerStream;

  @override
  void initState() {
    super.initState();
    // Stream created ONCE in initState, not in build
    _bannerStream = FirebaseFirestore.instance
        .collection('service_bottom_banners')
        .where('isActive', isEqualTo: true)
        .orderBy('order')
        .snapshots();
    _startAutoSlide();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoSlide() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!mounted || _banners.isEmpty || _isUserInteracting) return;
      
      if (_currentPage < _banners.length - 1) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }
      
      if (_pageController.hasClients && mounted) {
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _onUserInteractionStart() {
    if (!mounted) return;
    setState(() {
      _isUserInteracting = true;
    });
  }

  void _onUserInteractionEnd() {
    if (!mounted) return;
    setState(() {
      _isUserInteracting = false;
    });
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

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _bannerStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !_isInitialized) {
          return _buildShimmer();
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox.shrink();
        }

        // Map Firestore data to BannerModel
        try {
          final banners = snapshot.data!.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return BannerModel(
              id: doc.id,
              imageUrl: data['imageUrl'] ?? '',
              targetScreen: data['targetScreen'] ?? 'service',
              targetId: data['id'] ?? '',
              order: data['order'] ?? 0,
              active: data['isActive'] ?? true,
            );
          }).toList();
          
          if (mounted) {
            _banners = banners;
            _isInitialized = true;
          }
        } catch (e) {
          debugPrint("Error parsing banners: $e");
          return const SizedBox.shrink();
        }

        if (_banners.isEmpty) return const SizedBox.shrink();

        return Column(
          children: [
            SizedBox(
              height: 180,
              child: Listener(
                onPointerDown: (_) => _onUserInteractionStart(),
                onPointerUp: (_) => _onUserInteractionEnd(),
                onPointerCancel: (_) => _onUserInteractionEnd(),
                child: PageView.builder(
                  controller: _pageController,
                  physics: const BouncingScrollPhysics(),
                  pageSnapping: true,
                  onPageChanged: (index) {
                    if (!mounted) return;
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  itemCount: _banners.length,
                  itemBuilder: (context, index) {
                    final banner = _banners[index];
                    return GestureDetector(
                      onTap: () {
                        // Handle navigation
                        debugPrint('Banner tapped: ${banner.id}');
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: SafeCachedImage(
                            imageUrl: banner.imageUrl,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    );
                  },
                ),
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
}

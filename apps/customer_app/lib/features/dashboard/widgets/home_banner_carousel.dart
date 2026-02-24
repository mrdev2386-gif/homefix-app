import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../../core/widgets/safe_network_image.dart';

class HomeBannerCarousel extends StatefulWidget {
  const HomeBannerCarousel({super.key});

  @override
  State<HomeBannerCarousel> createState() => _HomeBannerCarouselState();
}

class _HomeBannerCarouselState extends State<HomeBannerCarousel> {
  int _activeIndex = 0;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('home_banners').where('isActive', isEqualTo: true).snapshots(),
      builder: (context, snapshot) {
        // Handle loading state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SizedBox(height: 200, child: Center(child: CircularProgressIndicator()));
        }
        
        // Handle error state - don't crash, show defaults
        if (snapshot.hasError) {
          debugPrint('⚠️ [BannerCarousel] Stream error: ${snapshot.error}');
          return _buildCarousel(_getDefaultBanners());
        }
        
        // Handle empty data
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildCarousel(_getDefaultBanners());
        }

        final banners = snapshot.data!.docs;
        return _buildCarousel(banners);
      },
    );
  }

  List<dynamic> _getDefaultBanners() {
    return [
      {
        'imageUrl': 'https://images.unsplash.com/photo-1556911220-e1502e3bf9b0?auto=format&fit=crop&q=80&w=1200',
        'title': 'Professional Cleaning',
        'subtitle': 'Flat 20% OFF on first booking',
      },
      {
        'imageUrl': 'https://images.unsplash.com/photo-1621905251189-08b45d6a269e?auto=format&fit=crop&q=80&w=1200',
        'title': 'Safe Electrician Services',
        'subtitle': 'Certified experts at your doorstep',
      },
      {
        'imageUrl': 'https://images.unsplash.com/photo-1581094288338-2314dddb7ecb?auto=format&fit=crop&q=80&w=1200',
        'title': 'AC Deep Clean',
        'subtitle': 'Improve efficiency & air quality',
      },
    ];
  }

  Widget _buildCarousel(List<dynamic> banners) {
    return Column(
      children: [
        CarouselSlider.builder(
          itemCount: banners.length,
          itemBuilder: (context, index, realIndex) {
            final banner = banners[index];
            final String imageUrl = banner is DocumentSnapshot ? banner['imageUrl'] : banner['imageUrl'];
            
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              child: GestureDetector(
                onTap: () {
                  // Handle banner tap
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Stack(
                    children: [
                      SafeNetworkImage(
                        imageUrl: imageUrl,
                        width: double.infinity,
                        height: 200,
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.black.withOpacity(0.6), Colors.transparent],
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 24,
                        left: 24,
                        right: 24,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (banner is Map && banner['subtitle'] != null)
                              Text(
                                banner['subtitle'],
                                style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            const SizedBox(height: 4),
                            Text(
                              banner is Map ? banner['title'] : (banner as DocumentSnapshot)['title'] ?? 'Special Offer',
                              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
          options: CarouselOptions(
            height: 200,
            viewportFraction: 1.0,
            autoPlay: true,
            autoPlayInterval: const Duration(seconds: 5),
            onPageChanged: (index, reason) {
              setState(() => _activeIndex = index);
            },
          ),
        ),
        const SizedBox(height: 16),
        AnimatedSmoothIndicator(
          activeIndex: _activeIndex,
          count: banners.length,
          effect: ExpandingDotsEffect(
            dotWidth: 8,
            dotHeight: 8,
            activeDotColor: const Color(0xFF6366F1),
            dotColor: Colors.grey.shade300,
          ),
        ),
      ],
    );
  }
}

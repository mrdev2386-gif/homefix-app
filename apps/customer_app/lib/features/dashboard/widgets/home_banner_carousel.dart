import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../../core/widgets/safe_network_image.dart';
import '../../../core/services/banner_service.dart';
import '../../../core/models/banner_model.dart';

class HomeBannerCarousel extends StatefulWidget {
  const HomeBannerCarousel({super.key});

  @override
  State<HomeBannerCarousel> createState() => _HomeBannerCarouselState();
}

class _HomeBannerCarouselState extends State<HomeBannerCarousel> {
  int _activeIndex = 0;
  final BannerService _bannerService = BannerService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<BannerModel>>(
      stream: _bannerService.streamHomeBanners(),
      builder: (context, snapshot) {
        // Handle loading state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()));
        }
        
        // Handle error state - don't crash, show defaults
        if (snapshot.hasError) {
          debugPrint('⚠️ [BannerCarousel] Stream error: ${snapshot.error}');
          return _buildCarousel(_getDefaultBanners());
        }
        
        // Handle empty data
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildCarousel(_getDefaultBanners());
        }

        final banners = snapshot.data!;
        return _buildCarousel(banners);
      },
    );
  }

  List<BannerModel> _getDefaultBanners() {
    return [
      BannerModel(
        id: 'default1',
        imageUrl: 'https://images.unsplash.com/photo-1556911220-e1502e3bf9b0?auto=format&fit=crop&q=80&w=1200',
        title: 'Professional Cleaning',
        subtitle: 'Flat 20% OFF on first booking',
        targetScreen: '',
        targetId: '',
        active: true,
        order: 0,
      ),
      BannerModel(
        id: 'default2',
        imageUrl: 'https://images.unsplash.com/photo-1621905251189-08b45d6a269e?auto=format&fit=crop&q=80&w=1200',
        title: 'Safe Electrician Services',
        subtitle: 'Certified experts at your doorstep',
        targetScreen: '',
        targetId: '',
        active: true,
        order: 1,
      ),
      BannerModel(
        id: 'default3',
        imageUrl: 'https://images.unsplash.com/photo-1581094288338-2314dddb7ecb?auto=format&fit=crop&q=80&w=1200',
        title: 'AC Deep Clean',
        subtitle: 'Improve efficiency & air quality',
        targetScreen: '',
        targetId: '',
        active: true,
        order: 2,
      ),
    ];
  }

  Widget _buildCarousel(List<BannerModel> banners) {
    return Column(
      children: [
        CarouselSlider.builder(
          itemCount: banners.length,
          itemBuilder: (context, index, realIndex) {
            final banner = banners[index];
            
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
                        imageUrl: banner.imageUrl,
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
                            if (banner.subtitle.isNotEmpty)
                              Text(
                                banner.subtitle,
                                style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            const SizedBox(height: 4),
                            Text(
                              banner.title.isNotEmpty ? banner.title : 'Special Offer',
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

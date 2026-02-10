
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../../core/models/dashboard_models.dart';
import '../../../core/widgets/safe_network_image.dart';

class ProfessionalReelsSection extends StatefulWidget {
  final List<ProfessionalReel> reels;

  const ProfessionalReelsSection({
    super.key,
    required this.reels,
  });

  @override
  State<ProfessionalReelsSection> createState() => _ProfessionalReelsSectionState();
}

class _ProfessionalReelsSectionState extends State<ProfessionalReelsSection> {
  final PageController _pageController = PageController(viewportFraction: 0.85);
  int _currentIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Exactly 5 videos enforced
    final displayReels = widget.reels.take(5).toList();
    
    if (displayReels.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Text(
            "Admin has not added content yet",
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
          child: Row(
            children: [
              const Icon(Icons.stars_rounded, color: Color(0xFF6366F1), size: 24),
              const SizedBox(width: 8),
              Text(
                'Celebrating Professionals',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: Colors.black,
                  fontSize: 22,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 480, 
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) => setState(() => _currentIndex = index),
            itemCount: displayReels.length,
            itemBuilder: (context, index) {
              return _ReelItem(
                reel: displayReels[index],
                isFocused: _currentIndex == index,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ReelItem extends StatefulWidget {
  final ProfessionalReel reel;
  final bool isFocused;

  const _ReelItem({required this.reel, required this.isFocused});

  @override
  State<_ReelItem> createState() => _ReelItemState();
}

class _ReelItemState extends State<_ReelItem> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeController();
  }

  void _initializeController() {
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.reel.videoUrl))
      ..setLooping(true)
      ..setVolume(0) // Auto-play muted
      ..initialize().then((_) {
        if (mounted) {
          setState(() => _isInitialized = true);
          if (widget.isFocused) _controller.play();
        }
      });
  }

  @override
  void didUpdateWidget(_ReelItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_isInitialized) {
      if (widget.isFocused) {
        _controller.play();
      } else {
        _controller.pause();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: widget.isFocused ? 1.0 : 0.92,
      duration: const Duration(milliseconds: 300),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, 10),
            )
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Thumbnail/Vibrant Fallback
              if (widget.reel.thumbnailUrl.isNotEmpty)
                SafeNetworkImage(
                  imageUrl: widget.reel.thumbnailUrl,
                  fit: BoxFit.cover,
                )
              else
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF4338CA)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
                
              // Video
              if (_isInitialized)
                FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: _controller.value.size.width,
                    height: _controller.value.size.height,
                    child: VideoPlayer(_controller),
                  ),
                ),
                
              // Non-clickable Overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.3),
                      Colors.black.withOpacity(0.8),
                    ],
                    stops: const [0.6, 0.8, 1.0],
                  ),
                ),
              ),
              
              // Content
              Positioned(
                bottom: 30,
                left: 20,
                right: 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.reel.title.isNotEmpty)
                      Text(
                        widget.reel.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withOpacity(0.3)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.verified_user_rounded, color: Color(0xFF10B981), size: 16),
                          SizedBox(width: 6),
                          Text(
                            'PRO VERIFIED',
                            style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Loading shimmer-like effect
              if (!_isInitialized)
                const Center(child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
            ],
          ),
        ),
      ),
    );
  }
}

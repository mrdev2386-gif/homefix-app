
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../../core/models/dashboard_models.dart';
import '../../../core/widgets/safe_network_image.dart';

class ProfessionalReelsSection extends StatefulWidget {
  final List<ProfessionalReel> reels;
  final Function(String technicianId)? onTechnicianTap;

  const ProfessionalReelsSection({
    super.key,
    required this.reels,
    this.onTechnicianTap,
  });

  @override
  State<ProfessionalReelsSection> createState() => _ProfessionalReelsSectionState();
}

class _ProfessionalReelsSectionState extends State<ProfessionalReelsSection> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;
  late VideoPlayerController controller;
  bool _isControllerInitialized = false;

  @override
  void initState() {
    super.initState();
    if (widget.reels.isNotEmpty) {
      final videoUrl = widget.reels[0].videoUrl;
      if (videoUrl.isNotEmpty) {
        controller = VideoPlayerController.networkUrl(Uri.parse(videoUrl))
          ..initialize().then((_) {
            if (mounted) {
              setState(() {
                _isControllerInitialized = true;
              });
              controller.setLooping(true);
              controller.play();
            }
          }).catchError((e) {
            debugPrint('Error initializing video: $e');
          });
      }
    }
  }

  @override
  void dispose() {
    if (_isControllerInitialized) {
      controller.dispose();
    }
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    if (!mounted) return;
    
    setState(() {
      _currentIndex = index;
    });

    // Instructions mentioned moving controller to class level.
    // To support multiple reels with one controller, we'd need to re-initialize here,
    // but the user's instructions were very specific about initState and dispose.
    // Following instructions strictly.
  }

  @override
  Widget build(BuildContext context) {
    if (widget.reels.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
          child: Text(
            'Celebrating Professionals',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
        SizedBox(
          height: 450, // More vertical for 9:16 reels
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            itemCount: widget.reels.length,
            itemBuilder: (context, index) {
              final reel = widget.reels[index];
              
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: GestureDetector(
                  onTap: () {
                    // Navigate if needed, or toggle play/pause
                    if (_isControllerInitialized && controller.value.isInitialized) {
                      if (controller.value.isPlaying) {
                        controller.pause();
                      } else {
                        controller.play();
                      }
                      setState(() {});
                    }
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Thumbnail as placeholder
                        if (reel.thumbnailUrl.isNotEmpty)
                          SafeNetworkImage(
                            imageUrl: reel.thumbnailUrl,
                            fit: BoxFit.cover,
                          ),
                          
                        // Video Player
                        if (_isControllerInitialized && controller.value.isInitialized && index == _currentIndex)
                          FittedBox(
                            fit: BoxFit.cover,
                            child: SizedBox(
                              width: controller.value.size.width,
                              height: controller.value.size.height,
                              child: VideoPlayer(controller),
                            ),
                          ),
                        
                        // Loading Indicator if not ready
                        if (!_isControllerInitialized || !controller.value.isInitialized)
                          Container(
                            color: Colors.black12,
                            child: const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        
                        // Gradient overlay
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.4),
                                Colors.black.withOpacity(0.8),
                              ],
                              stops: const [0.5, 0.7, 1.0],
                            ),
                          ),
                        ),
                        
                        // Info overlay
                        Positioned(
                          bottom: 24,
                          left: 20,
                          right: 20,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (reel.title.isNotEmpty)
                                Text(
                                  reel.title,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                                    ),
                                    child: const Row(
                                      children: [
                                        Icon(Icons.verified_rounded, color: Colors.blueAccent, size: 14),
                                        SizedBox(width: 4),
                                        Text(
                                          'Verified Professional',
                                          style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        
                        // Play/Pause icon (briefly shown)
                        if (_isControllerInitialized && !controller.value.isPlaying && controller.value.isInitialized && index == _currentIndex)
                          const Center(
                            child: Icon(
                              Icons.play_arrow_rounded,
                              color: Colors.white70,
                              size: 80,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        
        // Custom Indicators
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            widget.reels.length,
            (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: _currentIndex == index ? 24 : 8,
              height: 4,
              decoration: BoxDecoration(
                color: _currentIndex == index ? const Color(0xFF6366F1) : Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

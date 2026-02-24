import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'safe_network_image.dart';

/// Get proper public download URL from Firebase Storage
/// Handles gs:// paths, relative paths, and existing URLs
Future<String> getPublicVideoUrl(String storagePath) async {
  if (storagePath.isEmpty) {
    throw Exception('Empty video path');
  }
  
  // If already a valid https URL with token, return as-is
  if (storagePath.startsWith('https://') && 
      storagePath.contains('firebasestorage.googleapis.com') &&
      storagePath.contains('alt=media')) {
    return storagePath;
  }
  
  // Convert gs:// or relative path to download URL
  String path = storagePath;
  if (path.startsWith('gs://')) {
    path = path.replaceFirst(RegExp(r'gs://[^/]+/'), '');
  }
  
  final ref = FirebaseStorage.instance.ref(path);
  return await ref.getDownloadURL();
}

/// Safe video player widget that handles all error cases gracefully
/// Prevents crashes from invalid URLs, network errors, and playback failures
class SafeVideoPlayer extends StatefulWidget {
  final String videoUrl;
  final String? thumbnailUrl;
  final bool autoPlay;
  final bool looping;
  final bool showControls;
  final VoidCallback? onError;
  
  const SafeVideoPlayer({
    super.key,
    required this.videoUrl,
    this.thumbnailUrl,
    this.autoPlay = false,
    this.looping = false,
    this.showControls = true,
    this.onError,
  });
  
  @override
  State<SafeVideoPlayer> createState() => _SafeVideoPlayerState();
}

class _SafeVideoPlayerState extends State<SafeVideoPlayer> {
  VideoPlayerController? _controller;
  bool _hasError = false;
  bool _isInitializing = true;
  int _retryCount = 0;
  static const int _maxRetries = 1;
  String? _errorMessage;
  
  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }
  
  /// Validates if a video URL is safe to load
  bool _isValidVideoUrl(String url) {
    if (url.isEmpty) {
      debugPrint('[SAFE_VIDEO] Empty URL');
      return false;
    }
    
    // Must be HTTPS for security
    if (!url.startsWith('https://')) {
      debugPrint('[SAFE_VIDEO] Invalid protocol (must be HTTPS): $url');
      return false;
    }
    
    // Validate Firebase Storage URLs
    if (url.contains('firebasestorage.googleapis.com')) {
      if (!url.contains('token=')) {
        debugPrint('[SAFE_VIDEO] Firebase Storage URL missing auth token');
        return false;
      }
    }
    
    // Validate URL format
    try {
      final uri = Uri.parse(url);
      if (!uri.hasScheme || !uri.hasAuthority) {
        debugPrint('[SAFE_VIDEO] Malformed URL: $url');
        return false;
      }
    } catch (e) {
      debugPrint('[SAFE_VIDEO] Failed to parse URL: $url - $e');
      return false;
    }
    
    return true;
  }
  
  /// Quick URL validity check — must start with http
  bool _isValidUrl(String url) {
    return url.startsWith('http');
  }

  /// Initializes the video player with error handling
  Future<void> _initializePlayer() async {
    if (!mounted) return;

    // Validate URL before attempting to load
    if (widget.videoUrl.isEmpty) {
      setState(() {
        _hasError = true;
        _isInitializing = false;
        _errorMessage = 'Empty video URL';
      });
      widget.onError?.call();
      return;
    }

    try {
      debugPrint('[SAFE_VIDEO] Getting public URL for: ${widget.videoUrl}');

      // Get proper public URL from Firebase Storage
      final publicUrl = await getPublicVideoUrl(widget.videoUrl);

      // Guard: skip invalid URLs before creating controller
      if (!_isValidUrl(publicUrl)) {
        debugPrint('[SAFE_VIDEO] Invalid URL skipped: $publicUrl');
        _handleError('Invalid video URL');
        return;
      }

      debugPrint('[SAFE_VIDEO] Initializing player with URL: $publicUrl');

      _controller = VideoPlayerController.networkUrl(
        Uri.parse(publicUrl),
      );
      
      // Add error listener
      _controller!.addListener(_videoListener);
      
      // Initialize with timeout
      await _controller!.initialize().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Video initialization timeout');
        },
      );
      
      if (!mounted) return;
      
      // Set looping if requested
      if (widget.looping) {
        await _controller!.setLooping(true);
      }
      
      // Auto play if requested
      if (widget.autoPlay) {
        await _controller!.play();
      }
      
      setState(() {
        _isInitializing = false;
      });
      
      debugPrint('[SAFE_VIDEO] Player initialized successfully');
      
    } catch (e, stackTrace) {
      debugPrint('[SAFE_VIDEO] Initialization failed: $e');
      debugPrint('[SAFE_VIDEO] Stack trace: $stackTrace');
      _handleError(e.toString());
    }
  }
  
  /// Listens for video player errors during playback
  void _videoListener() {
    if (_controller == null || !mounted) return;
    
    if (_controller!.value.hasError) {
      final error = _controller!.value.errorDescription ?? 'Unknown playback error';
      debugPrint('[SAFE_VIDEO] Playback error: $error');
      _handleError(error);
    }
  }
  
  /// Handles errors with optional retry logic
  void _handleError(String error) {
    if (!mounted) return;
    
    // Check if we should retry
    if (_retryCount < _maxRetries && !error.contains('404') && !error.contains('403')) {
      _retryCount++;
      debugPrint('[SAFE_VIDEO] Retry attempt $_retryCount/$_maxRetries');
      
      // Dispose current controller
      _controller?.removeListener(_videoListener);
      _controller?.dispose();
      _controller = null;
      
      // Retry after a short delay
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          _initializePlayer();
        }
      });
    } else {
      // Max retries reached or unrecoverable error
      setState(() {
        _hasError = true;
        _isInitializing = false;
        _errorMessage = error;
      });
      
      widget.onError?.call();
      
      // Dispose controller
      _controller?.removeListener(_videoListener);
      _controller?.dispose();
      _controller = null;
    }
  }
  
  @override
  void dispose() {
    _controller?.removeListener(_videoListener);
    _controller?.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    // Show error fallback
    if (_hasError) {
      return _buildErrorFallback();
    }
    
    // Show loading placeholder
    if (_isInitializing || _controller == null || !_controller!.value.isInitialized) {
      return _buildLoadingPlaceholder();
    }
    
    // Show video player
    return _buildVideoPlayer();
  }
  
  /// Builds the video player widget
  Widget _buildVideoPlayer() {
    return AspectRatio(
      aspectRatio: _controller!.value.aspectRatio,
      child: Stack(
        alignment: Alignment.center,
        children: [
          VideoPlayer(_controller!),
          if (widget.showControls) _buildPlayPauseOverlay(),
        ],
      ),
    );
  }
  
  /// Builds play/pause overlay
  Widget _buildPlayPauseOverlay() {
    return GestureDetector(
      onTap: () {
        setState(() {
          if (_controller!.value.isPlaying) {
            _controller!.pause();
          } else {
            _controller!.play();
          }
        });
      },
      child: Container(
        color: Colors.transparent,
        child: Center(
          child: AnimatedOpacity(
            opacity: _controller!.value.isPlaying ? 0.0 : 1.0,
            duration: const Duration(milliseconds: 300),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(16),
              child: Icon(
                _controller!.value.isPlaying ? Icons.pause : Icons.play_arrow,
                color: Colors.white,
                size: 48,
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  /// Builds loading placeholder
  Widget _buildLoadingPlaceholder() {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
            if (_retryCount > 0) ...[
              const SizedBox(height: 16),
              Text(
                'Retry $_retryCount/$_maxRetries',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  /// Builds error fallback widget
  Widget _buildErrorFallback() {
    // If thumbnail is available, show it
    if (widget.thumbnailUrl != null && widget.thumbnailUrl!.isNotEmpty) {
      return Stack(
        alignment: Alignment.center,
        children: [
          SafeNetworkImage(
            imageUrl: widget.thumbnailUrl,
            fit: BoxFit.cover,
            width: double.infinity,
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.all(12),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.videocam_off, color: Colors.white, size: 32),
                SizedBox(height: 8),
                Text(
                  'Video unavailable',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      );
    }
    
    // No thumbnail, show error message
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.videocam_off, color: Colors.white54, size: 48),
            const SizedBox(height: 16),
            const Text(
              'Video unavailable',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

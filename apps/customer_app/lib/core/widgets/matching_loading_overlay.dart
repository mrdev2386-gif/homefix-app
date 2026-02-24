import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:customer_app/core/theme/app_theme.dart';

/// Full-screen modern loading overlay for matching process
/// 
/// Features:
/// - Animated pulse icon
/// - Progress message
/// - 12-second timeout with friendly retry
/// - Back button disabled during matching
class MatchingLoadingOverlay extends StatefulWidget {
  final VoidCallback onTimeout;
  final String message;
  final int timeoutSeconds;

  const MatchingLoadingOverlay({
    super.key,
    required this.onTimeout,
    this.message = 'Finding best professionals near you...',
    this.timeoutSeconds = 12,
  });

  @override
  State<MatchingLoadingOverlay> createState() => _MatchingLoadingOverlayState();
}

class _MatchingLoadingOverlayState extends State<MatchingLoadingOverlay> 
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _progressController;
  int _elapsedSeconds = 0;
  bool _hasTimedOut = false;

  @override
  void initState() {
    super.initState();
    
    // Pulse animation for icon
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    );

    // Progress animation
    _progressController = AnimationController(
      duration: Duration(seconds: widget.timeoutSeconds),
      vsync: this,
    )..addListener(() {
        setState(() {
          final totalSeconds = widget.timeoutSeconds;
          final currentValue = _progressController.value;
          _elapsedSeconds = totalSeconds - (currentValue * totalSeconds).round();
        });
        
        if (_progressController.isCompleted && !_hasTimedOut) {
          _handleTimeout();
        }
      });
    _progressController.forward();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  void _handleTimeout() {
    if (!mounted) return;
    setState(() => _hasTimedOut = true);
  }

  void _retry() {
    widget.onTimeout();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Material(
        color: Colors.white,
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated icon
              FadeTransition(
                opacity: _pulseAnimation,
                child: ScaleTransition(
                  scale: _pulseAnimation,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.person_search_rounded,
                      size: 48,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Message
              Text(
                _hasTimedOut ? 'Taking a bit longer...' : widget.message,
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textColor,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 16),
              
              // Progress indicator
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 48),
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: _progressController.value,
                        minHeight: 6,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _hasTimedOut 
                              ? Colors.orange.shade400 
                              : AppTheme.primaryColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _hasTimedOut 
                          ? 'Almost there...' 
                          : '$_elapsedSeconds / ${widget.timeoutSeconds}s',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Timeout retry button
              if (_hasTimedOut) ...[
                const SizedBox(height: 32),
                SizedBox(
                  width: 200,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _retry,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Try Again',
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close overlay
                  },
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

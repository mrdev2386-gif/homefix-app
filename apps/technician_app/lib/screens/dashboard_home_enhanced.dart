import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:technician_app/core/models/technician.dart';
import 'package:technician_app/core/providers/technician_provider.dart';
import 'package:technician_app/core/services/booking_service.dart';
import 'package:technician_app/core/services/functions_service.dart';
import 'package:technician_app/core/models/booking.dart';
import 'package:technician_app/screens/wallet_screen.dart';
import 'package:technician_app/features/notifications/presentation/notifications_screen.dart';
import 'package:technician_app/features/technician/services/add_service_screen.dart';
import 'package:technician_app/screens/job_details_screen.dart';

// ============================================================================
// REUSABLE WIDGET: Profile Completion Circle
// ============================================================================
/// A premium circular progress indicator with gradient stroke and centered percentage.
/// 
/// Specifications:
/// - Size: 72x72
/// - Stroke width: 6
/// - Background track: light grey (#F1F5F9)
/// - Foreground: gradient purple (#6366F1 to #8B5CF6)
/// - Center text: bold percentage (e.g., 100%)
/// - Smooth rounded caps
class ProfileCompletionCircle extends StatelessWidget {
  /// Value from 0.0 to 1.0
  final double value;
  
  /// Size of the circle (default 72)
  final double size;
  
  /// Stroke width (default 6)
  final double strokeWidth;
  
  /// Background track color
  final Color backgroundColor;
  
  /// Primary gradient start color
  final Color primaryColor;
  
  /// Secondary gradient end color  
  final Color secondaryColor;
  
  const ProfileCompletionCircle({
    super.key,
    required this.value,
    this.size = 72,
    this.strokeWidth = 6,
    this.backgroundColor = const Color(0xFFF1F5F9),
    this.primaryColor = const Color(0xFF6366F1),
    this.secondaryColor = const Color(0xFF8B5CF6),
  });

  @override
  Widget build(BuildContext context) {
    // Clamp value between 0 and 1
    final clampedValue = value.clamp(0.0, 1.0);
    final percentage = (clampedValue * 100).round();
    
    return SizedBox(
      width: size,
      height: size,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: clampedValue),
        duration: const Duration(milliseconds: 1500),
        curve: Curves.easeOutBack,
        builder: (context, animatedValue, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              // Background track
              CustomPaint(
                size: Size(size, size),
                painter: _GradientCirclePainter(
                  progress: animatedValue,
                  strokeWidth: strokeWidth,
                  backgroundColor: backgroundColor,
                  primaryColor: primaryColor,
                  secondaryColor: secondaryColor,
                ),
              ),
              // Center percentage text
              Text(
                '$percentage%',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: size * 0.25, // 18 for 72px
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1E293B),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Custom painter for gradient circle progress
class _GradientCirclePainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  final Color backgroundColor;
  final Color primaryColor;
  final Color secondaryColor;
  
  _GradientCirclePainter({
    required this.progress,
    required this.strokeWidth,
    required this.backgroundColor,
    required this.primaryColor,
    required this.secondaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    
    // Draw background track
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    
    canvas.drawCircle(center, radius, backgroundPaint);
    
    // Draw gradient progress arc
    if (progress > 0) {
      final rect = Rect.fromCircle(center: center, radius: radius);
      final gradient = SweepGradient(
        startAngle: -90 * (3.14159 / 180), // Start from top
        colors: [primaryColor, secondaryColor, primaryColor],
        stops: const [0.0, 0.5, 1.0],
        transform: const GradientRotation(-90 * (3.14159 / 180)),
      );
      
      final progressPaint = Paint()
        ..shader = gradient.createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;
      
      // Draw arc from top (-90 degrees) clockwise
      final sweepAngle = 2 * 3.14159 * progress;
      canvas.drawArc(
        rect,
        -90 * (3.14159 / 180), // Start angle
        sweepAngle, // Sweep angle
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _GradientCirclePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.primaryColor != primaryColor ||
        oldDelegate.secondaryColor != secondaryColor;
  }
}

// ============================================================================
// MAIN DASHBOARD HOME SCREEN
// ============================================================================

/// Dashboard Home Enhanced - ULTRA MODERN UI Redesign
/// 
/// Features:
/// - Premium gradient header with soft shadows
/// - Glass/soft card style for stats
/// - 2-column responsive grid layout
/// - Lightweight premium animations
/// - No hardcoded heights - uses flexible sizing
/// - Overflow-safe design for all screen sizes
class DashboardHomeEnhanced extends StatefulWidget {
  final Function(int)? onNavigate;
  
  const DashboardHomeEnhanced({super.key, this.onNavigate});

  @override
  State<DashboardHomeEnhanced> createState() => _DashboardHomeEnhancedState();
}

class _DashboardHomeEnhancedState extends State<DashboardHomeEnhanced> with WidgetsBindingObserver, TickerProviderStateMixin {
  final BookingService _bookingService = BookingService();
  final FunctionsService _functionsService = FunctionsService();
  Timer? _offlineTimer;
  bool _isSettingOnline = false;
  DateTime? _lastOnlineCall;
  
  // Animation controllers for lightweight premium feel
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  // PART 4: Stream Performance Fix - Cache streams to prevent rebuild storms
  late final Stream<List<Booking>> _activeBookingsStream;
  late final Stream<List<Booking>> _assignedBookingsStream;
  late final Stream<QuerySnapshot> _notificationsStream;
  late final Stream<DocumentSnapshot> _earningsStream;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // Initialize animations
    _fadeController = AnimationController(
        duration: const Duration(milliseconds: 600), vsync: this);
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    
    _scaleController = AnimationController(
        duration: const Duration(milliseconds: 400), vsync: this);
    _scaleAnimation = CurvedAnimation(parent: _scaleController, curve: Curves.easeOutBack);
    
    _fadeController.forward();
    _scaleController.forward();

    // PART 4: Initialize cached streams in initState
    final tech = context.read<TechnicianProvider>().technician;
    if (tech != null) {
      _activeBookingsStream = _bookingService.getActiveBookings(tech.uid);
      _assignedBookingsStream = _bookingService.getAssignedBookings(tech.uid);
      _notificationsStream = FirebaseFirestore.instance
          .collection('notifications')
          .where('userId', isEqualTo: tech.uid)
          .where('isRead', isEqualTo: false)
          .snapshots();
      _earningsStream = FirebaseFirestore.instance
          .collection('technicians')
          .doc(tech.uid)
          .collection('stats')
          .doc('earnings')
          .snapshots();
    }
    
    // PART 1: Auto online on app open
    Future.microtask(() async {
      if (mounted) {
        await _setOnline(true);
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _offlineTimer?.cancel();
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _offlineTimer?.cancel();
      _setOnline(true);
    } else if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _startOfflineTimer();
    }
  }

  Future<void> _setOnline(bool online) async {
    if (_isSettingOnline) return;
    final now = DateTime.now();
    // Only throttle if it's not a direct request (like on boot if it was already online)
    // but user says "Auto Online on App Open" so we should always call it if needed.
    if (_lastOnlineCall != null && now.difference(_lastOnlineCall!).inSeconds < 5) return;

    _isSettingOnline = true;
    _lastOnlineCall = now;

    try {
      if (mounted) {
        await _functionsService.updateTechnicianOnlineStatus(online);
      }
    } catch (e) {
      debugPrint('Failed to set online status: $e');
    } finally {
      if (mounted) {
        setState(() => _isSettingOnline = false);
      }
    }
  }

  void _startOfflineTimer() {
    _offlineTimer?.cancel();
    _offlineTimer = Timer(const Duration(minutes: 5), () async {
      try {
        await _functionsService.updateTechnicianOnlineStatus(false);
      } catch (e) {
        debugPrint('Failed to set offline: $e');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TechnicianProvider>(context);
    final tech = provider.technician;

    if (tech == null) {
      return const Scaffold(
        backgroundColor: Color(0xFFF5F6FA),
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return RefreshIndicator(
                onRefresh: () => provider.refreshTechnicianData(),
                color: const Color(0xFF6366F1),
                child: Listener(
                  behavior: HitTestBehavior.translucent,
                  onPointerDown: (event) {
                    debugPrint('🌍 Global tap at: ${event.position}');
                  },
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: constraints.maxHeight),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(height: 16),
                          _buildPremiumHeader(tech),
                          const SizedBox(height: 16),
                          _buildProfileCompletionCard(tech),
                          const SizedBox(height: 16),
                          _buildStatsRowSection(tech),
                          const SizedBox(height: 20),
                          _buildPrimaryActionCard(),
                          const SizedBox(height: 24),
                          _buildQuickActionsSection(),
                          const SizedBox(height: 24),
                          _buildActiveBookingsSection(tech),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  /// ULTRA MODERN Premium greeting header with glassmorphism + gradient
  /// IMPROVED: Better typography and spacing
  Widget _buildPremiumHeader(Technician tech) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontalPadding = constraints.maxWidth < 360 ? 16.0 : 20.0;
        
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4F46E5).withOpacity(0.25),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Solid/Gradient Background (wrapped with IgnorePointer to prevent gesture blocking)
                IgnorePointer(
                  ignoring: true,
                  child: Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(32),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top Row: Animated Greeting + Notification placeholder
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: TweenAnimationBuilder<double>(
                                tween: Tween(begin: 0.0, end: 1.0),
                                duration: const Duration(milliseconds: 1000),
                                curve: Curves.easeOutCubic,
                                builder: (context, value, child) {
                                  return Transform.translate(
                                    offset: Offset(0, 20 * (1 - value)),
                                    child: Opacity(
                                      opacity: value,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          // IMPROVED: "Good morning," → medium weight
                                          Text(
                                            'Good morning,',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 20,
                                              fontWeight: FontWeight.w500, // Medium weight
                                              color: Colors.white.withOpacity(0.9),
                                              letterSpacing: 0.2,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 2),
                                          // ADDED: Technician name dynamically below greeting
                                          Text(
                                            tech.name.split(' ').first,
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 26,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                              letterSpacing: 0.2,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 8),
                                          // IMPROVED: "Currently Offline" → smaller subtitle with status color
                                          Text(
                                            tech.isOnline 
                                                ? _getGreetingMessage() 
                                                : 'Currently Offline',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 14,
                                              color: tech.isOnline 
                                                  ? Colors.white.withOpacity(0.85)
                                                  : Colors.white.withOpacity(0.7),
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            // Notification button moved to Positioned at end of Stack
                          ],
                        ),
                        const SizedBox(height: 24),
                        // Status Section
                        _buildStatusPill(tech.isOnline),
                      ],
                    ),
                  ),
                ),
                
                // Subtle Glass Highlight Overlay (also ignore pointer events)
                Positioned(
                  top: -50,
                  right: -50,
                  child: IgnorePointer(
                    ignoring: true,
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                  ),
                ),
                
                // FIXED: Notification bell as LAST child - Positioned to be on top
                // Changed from right: 0 to right: 16 to fix edge tap bug
                Positioned(
                  top: 16,
                  right: 16,
                  child: _buildHardenedNotificationBell(tech),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// HARDENED: Notification bell with forced safe tap structure
  /// - Positioned as LAST child of Stack (on top)
  /// - Explicit 48x48 tap target
  /// - Debug print on tap
  /// - Listener with opaque hit test for edge cases
  Widget _buildHardenedNotificationBell(Technician tech) {
    return StreamBuilder<QuerySnapshot>(
      stream: _notificationsStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          debugPrint('❌ [Dashboard] Notifications stream error: ${snapshot.error}');
          return _buildHardenedBellContent(0);
        }
        
        final unreadCount = snapshot.data?.docs.length ?? 0;
        return _buildHardenedBellContent(unreadCount);
      },
    );
  }

  /// Hardened bell content with Positioned and explicit tap zone
  Widget _buildHardenedBellContent(int unreadCount) {
    return Semantics(
      label: 'Open notifications',
      button: true,
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: (_) {
          debugPrint('👆 Pointer detected on bell');
        },
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              debugPrint('🔔 Notification bell tapped — LEVEL 1');

              Future.microtask(() {
                debugPrint('🔔 Notification navigation firing — LEVEL 2');
                
                if (!context.mounted) {
                  debugPrint('❌ Context not mounted');
                  return;
                }
                
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                );
              });
            },
            borderRadius: BorderRadius.circular(14),
            child: Container(
              height: 48,
              width: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.3), // DEBUG: Visual hit test - remove after verification
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.white.withOpacity(0.25),
                ),
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(
                    Icons.notifications_outlined,
                    color: Colors.white,
                    size: 22,
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: -4,
                      top: -4,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Color(0xFFF43F5E),
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                        child: Text(
                          unreadCount > 9 ? '9+' : '$unreadCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// OLD: Notification button - kept for reference but not used anymore
  Widget _buildNotificationButton(Technician tech) {
    return StreamBuilder<QuerySnapshot>(
      stream: _notificationsStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          debugPrint('❌ [Dashboard] Notifications stream error: ${snapshot.error}');
          return _buildNotificationButtonContent(0);
        }
        
        final unreadCount = snapshot.data?.docs.length ?? 0;
        return _buildNotificationButtonContent(unreadCount);
      },
    );
  }

  /// Helper widget for notification button content
  Widget _buildNotificationButtonContent(int unreadCount) {
    // Use IconButton with minimum 48x48 tap target
    return Semantics(
      label: 'Notifications',
      hint: 'Tap to view notifications',
      button: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const NotificationsScreen()),
          ),
          borderRadius: BorderRadius.circular(16),
          splashColor: Colors.white.withOpacity(0.2),
          child: Container(
            constraints: const BoxConstraints(
              minWidth: 48,
              minHeight: 48,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Icon(
                  Icons.notifications_active_outlined,
                  color: Colors.white,
                  size: 22,
                ),
                if (unreadCount > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF43F5E),
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                      child: Text(
                        unreadCount > 9 ? '9+' : '$unreadCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Modern animated status pill with premium styling
  /// IMPROVED: More modern OFFLINE pill with rounded full pill, subtle border, small status dot
  Widget _buildStatusPill(bool isOnline) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOutBack,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: isOnline 
            ? const Color(0xFF10B981).withOpacity(0.2) 
            : Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(24), // Full pill rounded
        border: Border.all(
          color: isOnline 
              ? const Color(0xFF10B981).withOpacity(0.4) 
              : Colors.white.withOpacity(0.25),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Pulse animation for online indicator
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(seconds: 2),
            curve: Curves.easeInOut,
            builder: (context, value, child) {
              final scale = isOnline ? (1.0 + (value * 0.2)) : 1.0;
              final opacity = isOnline ? (0.8 - (value * 0.4)) : 1.0;
              
              return Stack(
                alignment: Alignment.center,
                children: [
                  if (isOnline)
                    Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withOpacity(opacity),
                        shape: BoxShape.circle,
                      ),
                      transform: Matrix4.identity()..scale(scale * 1.5),
                    ),
                  // Small status dot
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: isOnline ? const Color(0xFF10B981) : Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: isOnline ? [
                        BoxShadow(
                          color: const Color(0xFF10B981).withOpacity(0.5),
                          blurRadius: 8,
                          spreadRadius: 2,
                        )
                      ] : null,
                    ),
                  ),
                ],
              );
            },
            onEnd: () {
              // Pulse repeats
            },
          ),
          const SizedBox(width: 10),
          Text(
            isOnline ? 'ONLINE' : 'OFFLINE',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  /// Profile completion card with dynamic calculation & animated ring
  /// IMPROVED: Uses new ProfileCompletionCircle widget with proper gradient
  Widget _buildProfileCompletionCard(Technician tech) {
    // PART 3: Dynamic calculation from Firestore map
    final steps = tech.stepsCompleted ?? {};
    final completedCount = steps.values.where((v) => v == true).length;
    final totalSteps = 5;
    final progress = (completedCount / totalSteps).clamp(0.0, 1.0);
    final percentage = (progress * 100).round();
    final isComplete = percentage >= 100;
    
    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontalPadding = constraints.maxWidth < 360 ? 16.0 : 20.0;
        
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                // IMPROVED: Use new ProfileCompletionCircle widget
                ProfileCompletionCircle(
                  value: progress,
                  size: 72,
                  strokeWidth: 6,
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isComplete ? 'Profile Optimized' : 'Finish Setup',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isComplete 
                            ? 'Your profile is 100% ready for prime time!'
                            : 'Complete $completedCount of $totalSteps steps to unlock more jobs.',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: const Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                          height: 1.4,
                        ),
                      ),
                      if (!isComplete) ...[
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: () => widget.onNavigate?.call(3),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xFF6366F1).withOpacity(0.1),
                                  const Color(0xFF8B5CF6).withOpacity(0.1),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Complete Now',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF6366F1),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.arrow_forward_rounded, size: 14, color: Color(0xFF6366F1)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// MODERN 3-column responsive row for stats - Premium card style
  Widget _buildStatsRowSection(Technician tech) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontalPadding = constraints.maxWidth < 360 ? 12.0 : 16.0;
        
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: StreamBuilder<List<Booking>>(
            stream: _assignedBookingsStream,
            builder: (context, bookingsSnapshot) {
              if (bookingsSnapshot.hasError) {
                debugPrint('❌ [Dashboard] Assigned bookings stream error: ${bookingsSnapshot.error}');
              }
              final bookings = bookingsSnapshot.data ?? [];
              final todayJobs = bookings.where((b) => b.status != 'completed' && b.status != 'cancelled').length;

              return Row(
                children: [
                  Expanded(child: _buildCompactStatCard(
                    icon: Icons.work_outline_rounded,
                    value: '$todayJobs',
                    label: "Today Jobs",
                    color: const Color(0xFF6366F1),
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: _buildEarningsCompactCard(tech)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildCompactStatCard(
                    icon: Icons.star_rounded,
                    value: '0.0',
                    label: 'Rating',
                    color: const Color(0xFFFBBF24),
                  )),
                ],
              );
            },
          ),
        );
      },
    );
  }

  /// Compact stat card for 3-column row
  Widget _buildCompactStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.15),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0F172A),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              color: const Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  /// Compact earnings card for 3-column row
  Widget _buildEarningsCompactCard(Technician tech) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withOpacity(0.15),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: StreamBuilder<DocumentSnapshot>(
        stream: _earningsStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            debugPrint('❌ [Dashboard] Earnings stream error: ${snapshot.error}');
          }
          double monthEarnings = 0;
          if (snapshot.hasData && snapshot.data != null) {
            final data = snapshot.data!.data() as Map<String, dynamic>?;
            if (data != null) {
              monthEarnings = _safeDouble(
                data['monthEarnings'] ?? 
                data['thisMonthEarnings'] ?? 
                data['thisMonth'] ?? 
                data['month'] ?? 
                0
              );
            }
          }
          
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_rounded,
                  color: Color(0xFF10B981),
                  size: 18,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '₹${_formatCurrency(monthEarnings)}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F172A),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                'Earnings',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: const Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          );
        },
      ),
    );
  }

  /// PRIMARY ACTION CARD - Ready to receive jobs CTA
  /// IMPROVED: Fixed text overflow, consistent button height, better spacing
  Widget _buildPrimaryActionCard() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontalPadding = constraints.maxWidth < 360 ? 12.0 : 16.0;
        
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF6366F1).withOpacity(0.08),
                    const Color(0xFF8B5CF6).withOpacity(0.08),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFF6366F1).withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  // Status indicator
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6366F1).withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.flash_on_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Text content - IMPROVED: Better overflow handling
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Ready to receive jobs?',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0F172A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Check available job requests in your area',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            color: const Color(0xFF64748B),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // CTA Button - IMPROVED: Minimum height 44
                  GestureDetector(
                    onTap: () => widget.onNavigate?.call(1),
                    child: Container(
                      constraints: const BoxConstraints(
                        minWidth: 90,
                        minHeight: 44, // Minimum height 44
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF6366F1).withOpacity(0.35),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          'View Jobs',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Safe double conversion with fallback
  double _safeDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  /// Get time-based greeting message
  String _getGreetingMessage() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good morning! Ready for jobs';
    } else if (hour < 17) {
      return 'Good afternoon! Ready for jobs';
    } else {
      return 'Good evening! Ready for jobs';
    }
  }

  /// Proper currency formatting
  String _formatCurrency(double amount) {
    if (amount >= 10000000) {
      return '${(amount / 10000000).toStringAsFixed(1)}Cr';
    } else if (amount >= 100000) {
      return '${(amount / 100000).toStringAsFixed(1)}L';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K';
    }
    return amount.toStringAsFixed(0);
  }

  /// PREMIUM Quick Actions section with soft glass design
  Widget _buildQuickActionsSection() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontalPadding = constraints.maxWidth < 360 ? 16.0 : 20.0;
        
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Quick Actions',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 16),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.1,
                children: [
                   _buildNewActionCard(
                    'Add Service', 
                    Icons.add_task_rounded, 
                    const [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                    () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddServiceScreen())),
                  ),
                  _buildNewActionCard(
                    'Active Jobs', 
                    Icons.assignment_rounded, 
                    const [Color(0xFF10B981), Color(0xFF34D399)],
                    () => widget.onNavigate?.call(1),
                  ),
                  _buildNewActionCard(
                    'Wallet', 
                    Icons.account_balance_wallet_rounded, 
                    const [Color(0xFFF59E0B), Color(0xFFFBBF24)],
                    () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WalletScreen())),
                  ),
                  _buildNewActionCard(
                    'My Profile', 
                    Icons.person_pin_rounded, 
                    const [Color(0xFFEC4899), Color(0xFFF472B6)],
                    () => widget.onNavigate?.call(3),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNewActionCard(String label, IconData icon, List<Color> colors, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: colors[0].withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(28),
          splashColor: colors[0].withOpacity(0.1),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: colors,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: colors[0].withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white, size: 24),
                ),
                const SizedBox(height: 14),
                Text(
                  label,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1E293B),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// PREMIUM Active Bookings section with real-time stream
  Widget _buildActiveBookingsSection(Technician tech) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontalPadding = constraints.maxWidth < 360 ? 16.0 : 20.0;
        
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Active Bookings',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F172A),
                      letterSpacing: -0.5,
                    ),
                  ),
                  TextButton(
                    onPressed: () => widget.onNavigate?.call(1),
                    child: Text(
                      'View All',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF6366F1),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              StreamBuilder<List<Booking>>(
                stream: _activeBookingsStream,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    debugPrint('❌ [Dashboard] Active bookings stream error: ${snapshot.error}');
                    return _buildEmptyState();
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(40.0),
                        child: CircularProgressIndicator(strokeWidth: 3),
                      ),
                    );
                  }

                  final activeBookings = snapshot.data ?? [];

                  if (activeBookings.isEmpty) {
                    return _buildEmptyState();
                  }

                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: activeBookings.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      return _buildPremiumBookingCard(activeBookings[index]);
                    },
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPremiumBookingCard(Booking booking) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildModernStatusChip(booking.status),
              Text(
                '₹${booking.finalAmount.toStringAsFixed(0)}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF6366F1),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            booking.serviceTitle,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.person_outline_rounded, size: 16, color: Color(0xFF64748B)),
              ),
              const SizedBox(width: 12),
              Text(
                booking.customerName,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF475569),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.calendar_today_rounded, size: 16, color: Color(0xFF64748B)),
              ),
              const SizedBox(width: 12),
              Text(
                '${booking.scheduledTime} | ${booking.scheduledAt.toString().split(' ')[0]}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF475569),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: Colors.grey.withOpacity(0.1), height: 1),
          const SizedBox(height: 16),
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => JobDetailsScreen(booking: booking),
                ),
              );
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'View Details',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF6366F1),
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Color(0xFF6366F1)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernStatusChip(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'assigned':
        color = const Color(0xFF6366F1);
        break;
      case 'accepted':
        color = const Color(0xFF10B981);
        break;
      case 'in_progress':
        color = const Color(0xFFF59E0B);
        break;
      default:
        color = const Color(0xFF64748B);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Text(
        status.toUpperCase(),
        style: GoogleFonts.plusJakartaSans(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.assignment_late_outlined,
              size: 56,
              color: Colors.grey[300],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No active jobs yet',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'New active bookings will appear here in real-time.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: const Color(0xFF64748B),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Premium skeleton loading for profile screen
class ProfileSkeleton extends StatefulWidget {
  const ProfileSkeleton({super.key});

  @override
  State<ProfileSkeleton> createState() => _ProfileSkeletonState();
}

class _ProfileSkeletonState extends State<ProfileSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _animation = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return CustomScrollView(
          slivers: [
            // Header skeleton
            SliverAppBar(
              expandedHeight: 280,
              pinned: true,
              elevation: 0,
              backgroundColor: const Color(0xFF4A6CF7),
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF4A6CF7), Color(0xFF4338CA)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 60),
                      // Avatar
                      Container(
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                          color: Colors.white.withOpacity(0.2),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Name
                      Container(
                        width: 150,
                        height: 24,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: Colors.white.withOpacity(0.2),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Email/Phone
                      Container(
                        width: 120,
                        height: 16,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: Colors.white.withOpacity(0.15),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Content skeleton
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Info card skeleton
                    _buildCardSkeleton(),
                    const SizedBox(height: 32),

                    // Section title
                    _shimmerBox(width: 100, height: 14),
                    const SizedBox(height: 12),
                    // Settings group skeleton
                    _buildSettingsGroupSkeleton(),

                    const SizedBox(height: 32),
                    _shimmerBox(width: 80, height: 14),
                    const SizedBox(height: 12),
                    _buildSettingsGroupSkeleton(),

                    const SizedBox(height: 32),
                    _shimmerBox(width: 70, height: 14),
                    const SizedBox(height: 12),
                    _buildSettingsGroupSkeleton(),

                    const SizedBox(height: 40),
                    // Logout button
                    Container(
                      width: double.infinity,
                      height: 60,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: Colors.red.shade50,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _shimmerBox({
    required double width,
    required double height,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        gradient: LinearGradient(
          begin: Alignment(_animation.value, 0),
          end: Alignment(_animation.value + 1, 0),
          colors: [
            Colors.grey.shade200,
            Colors.grey.shade100,
            Colors.grey.shade200,
          ],
        ),
      ),
    );
  }

  Widget _buildCardSkeleton() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Row 1
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _shimmerBox(width: 80, height: 12),
                    const SizedBox(height: 4),
                    _shimmerBox(width: 140, height: 14),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(height: 1, color: Colors.grey.shade200),
          const SizedBox(height: 16),
          // Row 2
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _shimmerBox(width: 90, height: 12),
                    const SizedBox(height: 4),
                    _shimmerBox(width: 60, height: 16),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsGroupSkeleton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: List.generate(
          3,
          (index) => Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _shimmerBox(width: 100, height: 14),
                      const SizedBox(height: 4),
                      _shimmerBox(width: 150, height: 12),
                    ],
                  ),
                ),
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Error view for profile
class ProfileErrorView extends StatelessWidget {
  final String error;

  const ProfileErrorView({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.error_outline_rounded,
                  size: 64,
                  color: Colors.red[300],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Unable to load profile',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Please check your connection and try again',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () {
                  // Trigger rebuild
                  (context as Element).markNeedsBuild();
                },
                icon: const Icon(Icons.refresh_rounded),
                label: Text(
                  'Retry',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4A6CF7),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

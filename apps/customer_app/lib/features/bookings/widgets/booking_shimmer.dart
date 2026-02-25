import 'package:flutter/material.dart';
import 'package:customer_app/core/theme/app_theme.dart';

/// Premium shimmer loading widget for booking cards
class BookingCardShimmer extends StatefulWidget {
  const BookingCardShimmer({super.key});

  @override
  State<BookingCardShimmer> createState() => _BookingCardShimmerState();
}

class _BookingCardShimmerState extends State<BookingCardShimmer>
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
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  children: [
                    Expanded(
                      child: _shimmerBox(
                        width: 140,
                        height: 18,
                        borderRadius: 4,
                      ),
                    ),
                    _shimmerBox(
                      width: 70,
                      height: 26,
                      borderRadius: 13,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Booking ID
                _shimmerBox(
                  width: 100,
                  height: 14,
                  borderRadius: 4,
                ),
                const SizedBox(height: 8),
                // Date & Time
                _shimmerBox(
                  width: 160,
                  height: 14,
                  borderRadius: 4,
                ),
                const SizedBox(height: 8),
                // Address
                _shimmerBox(
                  width: double.infinity,
                  height: 14,
                  borderRadius: 4,
                ),
                const SizedBox(height: 24),
                // Divider
                Container(
                  height: 1,
                  color: Colors.grey.shade200,
                ),
                const SizedBox(height: 16),
                // Footer row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _shimmerBox(
                          width: 80,
                          height: 12,
                          borderRadius: 4,
                        ),
                        const SizedBox(height: 4),
                        _shimmerBox(
                          width: 60,
                          height: 20,
                          borderRadius: 4,
                        ),
                      ],
                    ),
                    _shimmerBox(
                      width: 100,
                      height: 36,
                      borderRadius: 8,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _shimmerBox({
    required double width,
    required double height,
    required double borderRadius,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
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
}

/// Shimmer loading list for bookings
class BookingListShimmer extends StatelessWidget {
  final int itemCount;

  const BookingListShimmer({
    super.key,
    this.itemCount = 5,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      itemCount: itemCount,
      itemBuilder: (context, index) => const BookingCardShimmer(),
    );
  }
}

/// Booking header shimmer
class BookingHeaderShimmer extends StatelessWidget {
  const BookingHeaderShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      child: Row(
        children: List.generate(5, (index) {
          final widths = [40.0, 70.0, 70.0, 80.0, 80.0];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Container(
              width: widths[index],
              height: 36,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                color: Colors.grey.shade200,
              ),
            ),
          );
        }),
      ),
    );
  }
}

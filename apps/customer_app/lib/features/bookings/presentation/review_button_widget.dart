import 'package:flutter/material.dart';
import 'package:customer_app/core/services/review_service.dart';
import 'rate_technician_screen.dart';

class ReviewButtonWidget extends StatefulWidget {
  final String bookingId;
  final String technicianId;
  final String technicianName;
  final String bookingStatus;
  final VoidCallback onReviewSubmitted;

  const ReviewButtonWidget({
    Key? key,
    required this.bookingId,
    required this.technicianId,
    required this.technicianName,
    required this.bookingStatus,
    required this.onReviewSubmitted,
  }) : super(key: key);

  @override
  State<ReviewButtonWidget> createState() => _ReviewButtonWidgetState();
}

class _ReviewButtonWidgetState extends State<ReviewButtonWidget> {
  late Future<bool> _hasReviewFuture;

  @override
  void initState() {
    super.initState();
    _hasReviewFuture = ReviewService.hasReview(widget.bookingId);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.bookingStatus != 'completed') {
      return const SizedBox.shrink();
    }

    return FutureBuilder<bool>(
      future: _hasReviewFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        if (snapshot.data == true) {
          return const SizedBox.shrink();
        }

        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => RateTechnicianScreen(
                    bookingId: widget.bookingId,
                    technicianId: widget.technicianId,
                    technicianName: widget.technicianName,
                  ),
                ),
              );

              if (result == true) {
                widget.onReviewSubmitted();
                setState(() {
                  _hasReviewFuture = ReviewService.hasReview(widget.bookingId);
                });
              }
            },
            icon: const Icon(Icons.star),
            label: const Text('Rate Technician'),
          ),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:customer_app/core/services/review_service.dart';

class ReviewDisplayWidget extends StatelessWidget {
  final String bookingId;

  const ReviewDisplayWidget({
    Key? key,
    required this.bookingId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: ReviewService.getReview(bookingId),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == null) {
          return const SizedBox.shrink();
        }

        final review = snapshot.data!;
        final rating = review['rating'] as int;
        final reviewText = review['reviewText'] as String? ?? '';

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Your Rating',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
              const SizedBox(height: 8),
              Row(
                children: List.generate(5, (index) {
                  return Icon(
                    Icons.star,
                    size: 16,
                    color: index < rating ? Colors.amber : Colors.grey[300],
                  );
                }),
              ),
              if (reviewText.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  reviewText,
                  style: const TextStyle(fontSize: 12),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:customer_app/core/services/review_service.dart';

class TechnicianRatingWidget extends StatelessWidget {
  final String technicianId;

  const TechnicianRatingWidget({
    Key? key,
    required this.technicianId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: ReviewService.getTechnicianRating(technicianId),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == null) {
          return const Text('No ratings yet');
        }

        final rating = snapshot.data!['averageRating'] as double;
        final totalReviews = snapshot.data!['totalReviews'] as int;

        return Row(
          children: [
            const Icon(Icons.star, color: Colors.amber, size: 18),
            const SizedBox(width: 4),
            Text(
              '$rating',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 4),
            Text(
              '($totalReviews reviews)',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        );
      },
    );
  }
}

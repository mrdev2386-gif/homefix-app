import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/app_theme.dart';
import '../core/models/review.dart';
import '../core/firestore/review_service.dart';

class ReviewScreen extends StatefulWidget {
  final String bookingId;
  final String customerId;
  final String technicianId;

  const ReviewScreen({
    super.key,
    required this.bookingId,
    required this.customerId,
    required this.technicianId,
  });

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  double _rating = 5.0;
  final _commentController = TextEditingController();
  final _reviewService = ReviewService();
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: Text("Rate Service", style: GoogleFonts.outfit(fontWeight: FontWeight.bold))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Icons.star_rounded, size: 80, color: Colors.amber),
            const SizedBox(height: 24),
            Text("How was your experience?", style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text("Your feedback helps us improve and rewards the technician.", textAlign: TextAlign.center, style: GoogleFonts.outfit(color: Colors.grey)),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return IconButton(
                  icon: Icon(index < _rating ? Icons.star_rounded : Icons.star_outline_rounded, color: Colors.amber, size: 40),
                  onPressed: () => setState(() => _rating = index + 1.0),
                );
              }),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _commentController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: "Write a comment (optional)",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitReview,
                child: _isSubmitting ? const CircularProgressIndicator(color: Colors.white) : const Text("Submit Review"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _submitReview() async {
    setState(() => _isSubmitting = true);
    final review = Review(
      reviewId: '',
      bookingId: widget.bookingId,
      customerId: widget.customerId,
      technicianId: widget.technicianId,
      rating: _rating,
      comment: _commentController.text.trim(),
      createdAt: DateTime.now(),
    );

    try {
      await _reviewService.submitReview(review);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Review submitted! Thank you.")));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}

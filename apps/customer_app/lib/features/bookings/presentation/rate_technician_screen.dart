import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/services/functions_helper.dart';

class RateTechnicianScreen extends StatefulWidget {
  final String bookingId;
  final String technicianId;
  final String technicianName;

  const RateTechnicianScreen({
    Key? key,
    required this.bookingId,
    required this.technicianId,
    required this.technicianName,
  }) : super(key: key);

  @override
  State<RateTechnicianScreen> createState() => _RateTechnicianScreenState();
}

class _RateTechnicianScreenState extends State<RateTechnicianScreen> {
  int _rating = 0;
  final _reviewController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a rating')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      if (kDebugMode) debugPrint('[RateTechnician] Calling submitServiceRating');
      final callable = await FunctionsHelper.getCallable('submitServiceRating');
      await callable.call({
        'bookingId': widget.bookingId,
        'technicianId': widget.technicianId,
        'rating': _rating,
        'reviewText': _reviewController.text.trim(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Review submitted successfully')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rate Technician')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Rate ${widget.technicianName}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return GestureDetector(
                    onTap: () => setState(() => _rating = index + 1),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Icon(
                        Icons.star,
                        size: 40,
                        color: index < _rating ? Colors.amber : Colors.grey[300],
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Write your experience',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _reviewController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Share your feedback...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitReview,
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Submit Review'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

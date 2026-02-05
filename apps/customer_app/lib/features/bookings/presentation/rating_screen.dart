
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../../../core/models/booking.dart';

class RatingScreen extends StatefulWidget {
  final Booking booking;

  const RatingScreen({super.key, required this.booking});

  @override
  State<RatingScreen> createState() => _RatingScreenState();
}

class _RatingScreenState extends State<RatingScreen> {
  int _rating = 0;
  final List<String> _selectedTags = [];
  final TextEditingController _reviewController = TextEditingController();
  bool _isSubmitting = false;

  final List<String> _lowRatingTags = [
    'Arrived Late',
    'Unprofessional',
    'Poor Quality',
    'High Price',
    'Bad Behavior',
  ];

  final List<String> _highRatingTags = [
    'On Time',
    'Polite',
    'Professional',
    'Skilled',
    'Great Quality',
  ];

  String get _sentimentEmoji {
    switch (_rating) {
      case 1: return '😡';
      case 2: return '😕';
      case 3: return '🙂';
      case 4: return '😃';
      case 5: return '🤩';
      default: return '❓';
    }
  }

  String get _sentimentText {
    switch (_rating) {
      case 1: return 'Terrible';
      case 2: return 'Poor';
      case 3: return 'Good';
      case 4: return 'Very Good';
      case 5: return 'Excellent';
      default: return 'Rate your experience';
    }
  }

  bool get _canSubmit {
    if (_rating == 0) return false;
    if (_reviewController.text.isNotEmpty && _reviewController.text.length < 10) return false;
    return true;
  }

  Future<void> _submitRating() async {
    if (!_canSubmit) return;

    setState(() => _isSubmitting = true);

    try {
      final HttpsCallable callable = FirebaseFunctions.instance.httpsCallable('submitServiceRating');
      await callable.call({
        'bookingId': widget.booking.id,
        'rating': _rating,
        'comment': _reviewController.text,
        'tags': _selectedTags,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Thank you for your feedback!')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit rating: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<String> currentTags = _rating < 4 ? _lowRatingTags : _highRatingTags;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Rate Service',
          style: GoogleFonts.outfit(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Technician Info
            CircleAvatar(
              radius: 40,
              backgroundColor: const Color(0xFF6366F1).withOpacity(0.1),
              child: const Icon(Icons.person, size: 40, color: Color(0xFF6366F1)),
            ),
            const SizedBox(height: 16),
            Text(
              widget.booking.technicianName ?? 'Technician',
              style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text(
              widget.booking.serviceTitle,
              style: GoogleFonts.outfit(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 32),

            // Sentiment Section
            if (_rating > 0) ...[
              Text(
                _sentimentEmoji,
                style: const TextStyle(fontSize: 48),
              ),
              const SizedBox(height: 8),
              Text(
                _sentimentText,
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _rating < 4 ? Colors.orange : Colors.indigo,
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Star Rating
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                final starValue = index + 1;
                final isSelected = _rating >= starValue;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _rating = starValue;
                      _selectedTags.clear();
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 1.0, end: isSelected ? 1.2 : 1.0),
                      duration: const Duration(milliseconds: 200),
                      builder: (context, scale, child) {
                        return Transform.scale(
                          scale: scale,
                          child: Icon(
                            isSelected ? Icons.star_rounded : Icons.star_outline_rounded,
                            color: isSelected ? Colors.amber[600] : Colors.grey[300],
                            size: 48,
                          ),
                        );
                      },
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 40),

            if (_rating > 0) ...[
              // Question
              Text(
                _rating < 4 ? 'What went wrong?' : 'What did you like?',
                style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // Tags
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: currentTags.map((tag) {
                  final isSelected = _selectedTags.contains(tag);
                  return FilterChip(
                    label: Text(tag),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedTags.add(tag);
                        } else {
                          _selectedTags.remove(tag);
                        }
                      });
                    },
                    selectedColor: const Color(0xFF6366F1).withOpacity(0.1),
                    checkmarkColor: const Color(0xFF6366F1),
                    labelStyle: GoogleFonts.outfit(
                      color: isSelected ? const Color(0xFF6366F1) : Colors.black87,
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(100),
                      side: BorderSide(
                        color: isSelected ? const Color(0xFF6366F1) : Colors.grey[300]!,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),

              // Review Text
              TextField(
                controller: _reviewController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Share more details (optional)',
                  hintStyle: GoogleFonts.outfit(color: Colors.grey[400]),
                  filled: true,
                  fillColor: Colors.grey[50],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFF6366F1), width: 1),
                  ),
                ),
                style: GoogleFonts.outfit(fontSize: 14),
                onChanged: (_) => setState(() {}),
              ),
              if (_reviewController.text.isNotEmpty && _reviewController.text.length < 10)
                Padding(
                  padding: const EdgeInsets.only(top: 8, left: 4),
                  child: Text(
                    'Please write at least 10 characters',
                    style: GoogleFonts.outfit(color: Colors.red[400], fontSize: 11),
                  ),
                ),
            ],

            const SizedBox(height: 48),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: (_canSubmit && !_isSubmitting) ? _submitRating : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  disabledBackgroundColor: Colors.grey[200],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: _isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        'Submit Feedback',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }
}

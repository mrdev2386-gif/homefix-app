
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../core/models/technician.dart';

class ReviewsScreen extends StatefulWidget {
  final Technician technician;

  const ReviewsScreen({super.key, required this.technician});

  @override
  State<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends State<ReviewsScreen> {
  late final Stream<QuerySnapshot> _reviewsStream;

  @override
  void initState() {
    super.initState();
    _reviewsStream = FirebaseFirestore.instance
        .collection('reviews')
        .where('technicianId', isEqualTo: widget.technician.uid)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text("Ratings & Reviews", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: CustomScrollView(
        slivers: [
          // Rating Summary Header
          SliverToBoxAdapter(
            child: _buildRatingSummary(),
          ),

          // Reviews List
          StreamBuilder<QuerySnapshot>(
            stream: _reviewsStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.rate_review_outlined, size: 64, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text(
                          "No reviews yet",
                          style: GoogleFonts.outfit(color: Colors.grey[600], fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final reviews = snapshot.data!.docs;

              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final review = reviews[index].data() as Map<String, dynamic>;
                    return _buildReviewTile(review);
                  },
                  childCount: reviews.length,
                ),
              );
            },
          ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 40)),
        ],
      ),
    );
  }

  Widget _buildRatingSummary() {
    final breakdown = widget.technician.ratingBreakdown;
    final total = widget.technician.totalRatings == 0 ? 1 : widget.technician.totalRatings;

    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(24),
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
          Row(
            children: [
              // Overall Rating
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    Text(
                      widget.technician.avgRating.toStringAsFixed(1),
                      style: GoogleFonts.outfit(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        return Icon(
                          index < widget.technician.avgRating.floor()
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          color: Colors.amber[600],
                          size: 16,
                        );
                      }),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "${widget.technician.totalRatings} Reviews",
                      style: GoogleFonts.outfit(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
              
              // Vertical Divider
              Container(width: 1, height: 100, color: Colors.grey[100]),
              
              const SizedBox(width: 24),
              
              // Breakdown Bars
              Expanded(
                flex: 3,
                child: Column(
                  children: [5, 4, 3, 2, 1].map((star) {
                    final count = breakdown[star.toString()] ?? 0;
                    final percent = count / total;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          Text(
                            "$star",
                            style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            fit: FlexFit.loose,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: percent,
                                backgroundColor: Colors.grey[100],
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  star >= 4 ? Colors.green : (star >= 3 ? Colors.orange : Colors.red),
                                ),
                                minHeight: 6,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReviewTile(Map<String, dynamic> review) {
    final rating = (review['rating'] ?? 0) as int;
    final createdAt = review['createdAt'] != null
        ? (review['createdAt'] as Timestamp).toDate()
        : DateTime.now();
    final tags = List<String>.from(review['tags'] ?? []);
    final comment = review['reviewText'] ?? '';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[100]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: List.generate(5, (index) {
                  return Icon(
                    index < rating ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: Colors.amber[600],
                    size: 18,
                  );
                }),
              ),
              Text(
                DateFormat('MMM dd, yyyy').format(createdAt),
                style: GoogleFonts.outfit(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (tags.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Wrap(
                spacing: 6,
                children: tags.map((tag) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.indigo.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    tag,
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      color: Colors.indigo[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )).toList(),
              ),
            ),
          if (comment.isNotEmpty)
            Text(
              comment,
              style: GoogleFonts.outfit(
                fontSize: 14,
                color: const Color(0xFF1E293B),
                height: 1.5,
              ),
            ),
        ],
      ),
    );
  }
}

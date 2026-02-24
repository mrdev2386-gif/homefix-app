import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:customer_app/core/models/category.dart';
import 'package:customer_app/core/theme/app_theme.dart';

/// Category Filter Chips Widget (Section 2)
/// Horizontal scrollable chips with selected state highlight
class CategoryChipBar extends StatelessWidget {
  final String? selectedCategoryId;
  final Function(String?) onCategorySelected;
  final double height;

  const CategoryChipBar({
    super.key,
    required this.selectedCategoryId,
    required this.onCategorySelected,
    this.height = 56,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('categories')
            .where('isActive', isEqualTo: true)
            .orderBy('order')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildShimmer();
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const SizedBox.shrink();
          }

          final categories = snapshot.data!.docs
              .map((doc) => Category.fromFirestore(doc))
              .toList();

          return ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            itemCount: categories.length + 1, // +1 for "All" chip
            itemBuilder: (context, index) {
              final isAll = index == 0;
              final category = isAll ? null : categories[index - 1];
              final isSelected = isAll
                  ? selectedCategoryId == null
                  : selectedCategoryId == category!.id;

              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _CategoryChip(
                  label: isAll ? 'All' : category!.name,
                  isSelected: isSelected,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onCategorySelected(category?.id);
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildShimmer() {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Shimmer.fromColors(
            baseColor: Colors.grey[200]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Individual Category Chip Widget
class _CategoryChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          splashColor: AppTheme.primaryColor.withValues(alpha: 0.1),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.primaryColor : Colors.grey[100],
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? AppTheme.primaryColor : Colors.transparent,
                width: 1.5,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppTheme.primaryColor.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected ? Colors.white : Colors.grey[600],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:customer_app/core/theme/app_theme.dart';
import 'package:customer_app/core/models/category.dart';
import '../../services/presentation/category_services_screen.dart';

class CategoryGrid extends StatelessWidget {
  const CategoryGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> categories = [
      {
        'id': 'cleaning',
        'name': 'Cleaning',
        'color': const Color(0xFF3B82F6),
        'gradient': [const Color(0xFF3B82F6), const Color(0xFF1D4ED8)],
      },
      {
        'id': 'repair',
        'name': 'Repair',
        'color': const Color(0xFFF97316),
        'gradient': [const Color(0xFFF97316), const Color(0xFFEA580C)],
      },
      {
        'id': 'appliance',
        'name': 'Appliance',
        'color': const Color(0xFF6366F1),
        'gradient': [const Color(0xFF6366F1), const Color(0xFF4F46E5)],
      },
      {
        'id': 'personal',
        'name': 'Personal',
        'color': const Color(0xFFEC4899),
        'gradient': [const Color(0xFFEC4899), const Color(0xFFDB2777)],
      },
      {
        'id': 'electrical',
        'name': 'Electrical',
        'color': const Color(0xFFF59E0B),
        'gradient': [const Color(0xFFF59E0B), const Color(0xFFD97706)],
      },
      {
        'id': 'plumbing',
        'name': 'Plumbing',
        'color': const Color(0xFF06B6D4),
        'gradient': [const Color(0xFF06B6D4), const Color(0xFF0891B2)],
      },
      {
        'id': 'painting',
        'name': 'Painting',
        'color': const Color(0xFF14B8A6),
        'gradient': [const Color(0xFF14B8A6), const Color(0xFF0D9488)],
      },
      {
        'id': 'more',
        'name': 'More',
        'color': const Color(0xFF6B7280),
        'gradient': [const Color(0xFF6B7280), const Color(0xFF4B5563)],
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        addSemanticIndexes: false,
        itemCount: categories.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          childAspectRatio: 0.85,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
        ),
        itemBuilder: (context, index) {
          final cat = categories[index];
          return RepaintBoundary(
            child: _CategoryItem(
              id: cat['id'],
              name: cat['name'],
              gradient: cat['gradient'] as List<Color>,
              color: cat['color'],
              onTap: () {
                print('CATEGORY CLICKED: ${cat['id']}');
                final category = Category(
                  id: cat['id'],
                  name: cat['name'],
                  title: cat['name'],
                  icon: _getIconForCategory(cat['name']),
                  isNew: false,
                );
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CategoryServicesScreen(
                      category: category,
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  IconData _getIconForCategory(String name) {
    switch (name) {
      case 'Cleaning':
        return Icons.cleaning_services_rounded;
      case 'Repair':
        return Icons.build_circle_rounded;
      case 'Appliance':
        return Icons.kitchen_rounded;
      case 'Personal':
        return Icons.face_rounded;
      case 'Electrical':
        return Icons.electrical_services_rounded;
      case 'Plumbing':
        return Icons.plumbing_rounded;
      case 'Painting':
        return Icons.format_paint_rounded;
      case 'More':
      default:
        return Icons.more_horiz_rounded;
    }
  }
}

class _CategoryItem extends StatelessWidget {
  final String id;
  final String name;
  final List<Color> gradient;
  final Color color;
  final VoidCallback onTap;

  const _CategoryItem({
    required this.id,
    required this.name,
    required this.gradient,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Premium gradient container with icon
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: gradient,
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: _buildIcon(),
            ),
            const SizedBox(height: 10),
            Text(
              name,
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppTheme.textColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIcon() {
    switch (name) {
      case 'Cleaning':
        return const Icon(Icons.cleaning_services_rounded, color: Colors.white, size: 28);
      case 'Repair':
        return const Icon(Icons.build_circle_rounded, color: Colors.white, size: 28);
      case 'Appliance':
        return const Icon(Icons.kitchen_rounded, color: Colors.white, size: 28);
      case 'Personal':
        return const Icon(Icons.face_rounded, color: Colors.white, size: 28);
      case 'Electrical':
        return const Icon(Icons.electrical_services_rounded, color: Colors.white, size: 28);
      case 'Plumbing':
        return const Icon(Icons.plumbing_rounded, color: Colors.white, size: 28);
      case 'Painting':
        return const Icon(Icons.format_paint_rounded, color: Colors.white, size: 28);
      case 'More':
      default:
        return const Icon(Icons.more_horiz_rounded, color: Colors.white, size: 28);
    }
  }
}

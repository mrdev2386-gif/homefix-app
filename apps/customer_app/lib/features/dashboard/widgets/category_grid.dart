import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:customer_app/core/theme/app_theme.dart';
import '../../services/presentation/services_categories_screen.dart';

class CategoryGrid extends StatelessWidget {
  const CategoryGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> categories = [
      {
        'name': 'Cleaning',
        'color': const Color(0xFF3B82F6),
        'gradient': [const Color(0xFF3B82F6), const Color(0xFF1D4ED8)],
      },
      {
        'name': 'Repair',
        'color': const Color(0xFFF97316),
        'gradient': [const Color(0xFFF97316), const Color(0xFFEA580C)],
      },
      {
        'name': 'Appliance',
        'color': const Color(0xFF6366F1),
        'gradient': [const Color(0xFF6366F1), const Color(0xFF4F46E5)],
      },
      {
        'name': 'Personal',
        'color': const Color(0xFFEC4899),
        'gradient': [const Color(0xFFEC4899), const Color(0xFFDB2777)],
      },
      {
        'name': 'Electrical',
        'color': const Color(0xFFF59E0B),
        'gradient': [const Color(0xFFF59E0B), const Color(0xFFD97706)],
      },
      {
        'name': 'Plumbing',
        'color': const Color(0xFF06B6D4),
        'gradient': [const Color(0xFF06B6D4), const Color(0xFF0891B2)],
      },
      {
        'name': 'Painting',
        'color': const Color(0xFF14B8A6),
        'gradient': [const Color(0xFF14B8A6), const Color(0xFF0D9488)],
      },
      {
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
              name: cat['name'],
              gradient: cat['gradient'] as List<Color>,
              color: cat['color'],
              onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ServicesCategoriesScreen(),
                    ),
                  );
              },
            ),
          );
        },
      ),
    );
  }
}

class _CategoryItem extends StatelessWidget {
  final String name;
  final List<Color> gradient;
  final Color color;
  final VoidCallback onTap;

  const _CategoryItem({
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

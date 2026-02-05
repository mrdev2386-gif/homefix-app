import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../services/presentation/service_list_screen.dart';

class CategoryGrid extends StatelessWidget {
  const CategoryGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> categories = [
      {'name': 'Cleaning', 'icon': Icons.cleaning_services_rounded, 'color': Colors.blue},
      {'name': 'Repair', 'icon': Icons.build_circle_rounded, 'color': Colors.orange},
      {'name': 'Appliance', 'icon': Icons.kitchen_rounded, 'color': Colors.indigo},
      {'name': 'Personal', 'icon': Icons.face_rounded, 'color': Colors.pink},
      {'name': 'Electrical', 'icon': Icons.electrical_services_rounded, 'color': Colors.amber},
      {'name': 'Plumbing', 'icon': Icons.plumbing_rounded, 'color': Colors.cyan},
      {'name': 'Painting', 'icon': Icons.format_paint_rounded, 'color': Colors.teal},
      {'name': 'More', 'icon': Icons.more_horiz_rounded, 'color': Colors.grey},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: categories.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          childAspectRatio: 0.85,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
        ),
        itemBuilder: (context, index) {
          final cat = categories[index];
          return _CategoryItem(
            name: cat['name'],
            icon: cat['icon'],
            color: cat['color'],
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ServiceListScreen(category: cat['name'] == 'More' ? null : cat['name'].toLowerCase()),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _CategoryItem extends StatelessWidget {
  final String name;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _CategoryItem({
    required this.name,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withOpacity(0.1)),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            name,
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppTheme.textColor,
            ),
          ),
        ],
      ),
    );
  }
}

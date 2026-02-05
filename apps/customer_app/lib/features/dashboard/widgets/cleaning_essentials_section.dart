
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/models/dashboard_models.dart';
import '../../../core/widgets/safe_network_image.dart';
import '../../../core/theme/app_theme.dart';
import '../../technicians/presentation/technician_list_screen.dart';

class CleaningEssentialsSection extends StatelessWidget {
  final List<CleaningCategory> essentials;

  const CleaningEssentialsSection({
    super.key,
    required this.essentials,
  });

  @override
  Widget build(BuildContext context) {
    if (essentials.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
          child: Text(
            'Cleaning Essentials',
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppTheme.textColor,
            ),
          ),
        ),
        SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            itemCount: essentials.length,
            physics: const BouncingScrollPhysics(),
            itemBuilder: (context, index) {
              final essential = essentials[index];
              return _buildEssentialCard(context, essential);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEssentialCard(BuildContext context, CleaningCategory category) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TechnicianListScreen(
              categoryId: category.id,
              categoryName: category.name,
            ),
          ),
        );
      },
      child: Container(
        width: 140,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Icon/Image
            Container(
              height: 120,
              width: 140,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: SafeNetworkImage(
                  imageUrl: category.iconUrl,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Title
            Text(
              category.name,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 14,
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
}

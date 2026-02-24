import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:customer_app/core/theme/app_theme.dart';
import 'package:customer_app/core/widgets/safe_network_image.dart';
import '../../providers/partner_onboarding_provider.dart';

/// Profile Photo Step - Step 4 of 8
/// 
/// FEATURES:
/// - Camera and gallery options
/// - Image preview with remove option
/// - Modern card-based UI
/// - Photo guidelines
class OnboardingStepPhoto extends StatelessWidget {
  final Animation<double> fadeAnimation;
  final Animation<Offset> slideAnimation;

  const OnboardingStepPhoto({
    super.key,
    required this.fadeAnimation,
    required this.slideAnimation,
  });

  Future<void> _pickImage(BuildContext context, PartnerOnboardingProvider provider, ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1024,
        maxHeight: 1024,
      );
      
      if (pickedFile != null) {
        provider.setProfilePhoto(pickedFile);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.check, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Text('Photo selected successfully', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                ],
              ),
              backgroundColor: const Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.all(16),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  void _showImageSourceDialog(BuildContext context, PartnerOnboardingProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Choose Photo Source',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppTheme.textColor,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildSourceOption(
                    context: context,
                    icon: Icons.camera_alt_rounded,
                    label: 'Camera',
                    color: const Color(0xFF3B82F6),
                    onTap: () {
                      Navigator.pop(ctx);
                      _pickImage(context, provider, ImageSource.camera);
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildSourceOption(
                    context: context,
                    icon: Icons.photo_library_rounded,
                    label: 'Gallery',
                    color: const Color(0xFF8B5CF6),
                    onTap: () {
                      Navigator.pop(ctx);
                      _pickImage(context, provider, ImageSource.gallery);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceOption({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 32),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PartnerOnboardingProvider>(
      builder: (context, provider, child) {
        final hasPhoto = provider.profilePhoto != null;
        
        return FadeTransition(
          opacity: fadeAnimation,
          child: SlideTransition(
            position: slideAnimation,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.primaryColor.withOpacity(0.1),
                            AppTheme.primaryColor.withOpacity(0.05),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.camera_alt_outlined,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Profile Photo',
                                  style: GoogleFonts.outfit(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    color: AppTheme.textColor,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Upload a clear photo of yourself',
                                  style: GoogleFonts.outfit(
                                    fontSize: 14,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Photo Upload Card
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Photo Preview/Upload Area
                          GestureDetector(
                            onTap: () => _showImageSourceDialog(context, provider),
                            child: Container(
                              width: 180,
                              height: 180,
                              decoration: BoxDecoration(
                                color: hasPhoto ? null : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: hasPhoto
                                      ? AppTheme.primaryColor
                                      : Colors.grey.shade300,
                                  width: hasPhoto ? 3 : 2,
                                  strokeAlign: BorderSide.strokeAlignOutside,
                                ),
                                boxShadow: hasPhoto
                                    ? [
                                        BoxShadow(
                                          color: AppTheme.primaryColor.withOpacity(0.2),
                                          blurRadius: 20,
                                          offset: const Offset(0, 8),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: hasPhoto
                                  ? Stack(
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(22),
                                          child: kIsWeb
                                              ? (() {
                                                  // Cleaned: Removed noisy print
                                                  return SafeNetworkImage(
                                                    imageUrl: provider.profilePhoto!.path,
                                                    fit: BoxFit.cover,
                                                    width: 180,
                                                    height: 180,
                                                  );
                                                }())
                                              : Image.file(
                                                  File(provider.profilePhoto!.path),
                                                  fit: BoxFit.cover,
                                                  width: 180,
                                                  height: 180,
                                                ),
                                        ),
                                        // Edit overlay
                                        Positioned(
                                          bottom: 8,
                                          right: 8,
                                          child: Container(
                                            padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              color: AppTheme.primaryColor,
                                              shape: BoxShape.circle,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black.withOpacity(0.2),
                                                  blurRadius: 8,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                            child: const Icon(
                                              Icons.edit,
                                              color: Colors.white,
                                              size: 18,
                                            ),
                                          ),
                                        ),
                                      ],
                                    )
                                  : Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            color: AppTheme.primaryColor.withOpacity(0.1),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            Icons.add_a_photo_outlined,
                                            size: 40,
                                            color: AppTheme.primaryColor,
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          'Tap to upload',
                                          style: GoogleFonts.outfit(
                                            color: AppTheme.primaryColor,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 15,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                          
                          // Remove button
                          if (hasPhoto) ...[
                            const SizedBox(height: 16),
                            TextButton.icon(
                              onPressed: () => provider.setProfilePhoto(null),
                              icon: const Icon(Icons.delete_outline, size: 20),
                              label: Text(
                                'Remove Photo',
                                style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                              ),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.red,
                              ),
                            ),
                          ],
                          
                          // Status indicator
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: hasPhoto
                                  ? const Color(0xFF10B981).withOpacity(0.1)
                                  : Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  hasPhoto ? Icons.check_circle : Icons.info_outline,
                                  size: 18,
                                  color: hasPhoto
                                      ? const Color(0xFF10B981)
                                      : Colors.orange.shade700,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  hasPhoto ? 'Photo uploaded' : 'Photo required',
                                  style: GoogleFonts.outfit(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: hasPhoto
                                        ? const Color(0xFF059669)
                                        : Colors.orange.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Guidelines Card
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFFCD34D)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.tips_and_updates_outlined,
                                color: Color(0xFFD97706),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Photo Guidelines',
                                style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF92400E),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            '• Use a clear, recent photo of yourself\n'
                            '• Face should be clearly visible\n'
                            '• Good lighting, no filters\n'
                            '• Professional appearance preferred',
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              color: const Color(0xFF92400E),
                              height: 1.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

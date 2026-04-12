import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/providers/technician_provider.dart';
import '../../../core/app_theme.dart';
import '../../../core/models/technician.dart';
import '../../../core/services/functions_service.dart';
import '../../support/faqs_screen.dart';
import '../../../core/widgets/safe_network_image.dart';
import '../../../../main.dart';
import 'edit_personal_details_screen.dart';
import 'edit_bank_details_screen.dart';

/// Technician Profile Screen - Premium UI
/// 
/// SECURE: All updates go through callable Cloud Functions
/// KYC status is read-only from Firestore
/// Bank details are masked
class TechnicianProfileScreen extends StatefulWidget {
  const TechnicianProfileScreen({super.key});

  @override
  State<TechnicianProfileScreen> createState() => _TechnicianProfileScreenState();
}

class _TechnicianProfileScreenState extends State<TechnicianProfileScreen> with TickerProviderStateMixin {
  late final FunctionsService _functionsService;
  bool _notificationsEnabled = true;
  bool _isLoggingOut = false;
  
  late AnimationController _fadeController;
  late AnimationController _avatarScaleController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _avatarScaleAnimation;

  @override
  void initState() {
    super.initState();
    _functionsService = context.read<FunctionsService>();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _avatarScaleController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _avatarScaleAnimation = CurvedAnimation(parent: _avatarScaleController, curve: Curves.easeOut);
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _avatarScaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      floatingActionButton: _buildEditProfileFAB(context),
      body: SafeArea(
        child: Consumer<TechnicianProvider>(
          builder: (context, techProvider, child) {
            if (techProvider.isLoading || techProvider.technician == null) {
              return const _PremiumProfileShimmer();
            }

            final technician = techProvider.technician!;
            
            return FadeTransition(
              opacity: _fadeAnimation,
              child: RefreshIndicator(
                onRefresh: () => techProvider.refreshTechnicianData(),
                color: AppTheme.primaryColor,
                child: CustomScrollView(
                  slivers: [
                    // PART 1: Premium Glass Profile Header
                    SliverToBoxAdapter(
                      child: _PremiumProfileHeader(
                        technician: technician,
                        onAvatarTap: () => _openFullImage(context, technician.profilePhotoUrl),
                        avatarScaleAnimation: _avatarScaleAnimation,
                      ),
                    ),
                    
                    // PART 2: Circular Profile Completion Ring & Verification Chips
                    SliverToBoxAdapter(
                      child: _VerificationAndCompletionCard(technician: technician),
                    ),
                    
                    // PART 3: Personal Details
                    SliverToBoxAdapter(
                      child: _PersonalDetailsCard(
                        technician: technician,
                        onEditTap: () => _navigateToEditProfile(context),
                      ),
                    ),
                    
                    // PART 7: Bank & Payout Details
                    SliverToBoxAdapter(
                      child: _BankDetailsCard(
                        technician: technician,
                        onUpdateTap: () => _navigateToUpdateBank(context),
                      ),
                    ),

                    
                    // PART 8: Performance Summary
                    SliverToBoxAdapter(
                      child: _PerformanceCard(technician: technician),
                    ),
                    
                    // PART 9: Availability / Working Hours
                    SliverToBoxAdapter(
                      child: _AvailabilityCard(
                        technician: technician,
                        onEditTap: () => _navigateToEditAvailability(context),
                      ),
                    ),
                    
                    // PART 9: Support & Help
                    SliverToBoxAdapter(
                      child: _SupportSection(
                        onRaiseDisputeTap: () => _navigateToRaiseDispute(context),
                        onContactSupportTap: () => _navigateToContactSupport(context),
                        onFaqsTap: () => _navigateToFaqs(context),
                      ),
                    ),
                    
                    // PART 10: App Settings
                    SliverToBoxAdapter(
                      child: _SettingsSection(
                        notificationsEnabled: _notificationsEnabled,
                        onNotificationsChanged: (value) {
                          setState(() => _notificationsEnabled = value);
                        },
                        onLogoutTap: () => _showLogoutSheet(context),
                        isLoggingOut: _isLoggingOut,
                      ),
                    ),
                    
                    const SliverToBoxAdapter(
                      child: SizedBox(height: 100),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEditProfileFAB(BuildContext context) {
    return FloatingActionButton.extended(
      heroTag: 'fab_profile_edit',
      onPressed: () {
        HapticFeedback.lightImpact();
        _navigateToEditProfile(context);
      },
      backgroundColor: const Color(0xFF6A5AE0),
      foregroundColor: Colors.white,
      elevation: 4,
      label: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [Icon(Icons.edit, size: 18), SizedBox(width: 8), Text('Edit Profile', style: TextStyle(fontWeight: FontWeight.w600))],
      ),
    );
  }

  void _navigateToEditProfile(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const EditPersonalDetailsScreen()),
    );
  }


  void _navigateToEditSkills(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const EditSkillsScreen()),
    );
  }

  void _navigateToEditAvailability(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const EditAvailabilityScreen()),
    );
  }

  void _navigateToUpdateBank(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const EditBankDetailsScreen()),
    );
  }

  void _openFullImage(BuildContext context, String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FullImageViewScreen(imageUrl: imageUrl),
      ),
    );
  }

  void _navigateToFaqs(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const FaqsScreen()),
    );
  }

  void _navigateToRaiseDispute(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RaiseDisputeScreen()),
    );
  }

  void _navigateToContactSupport(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ContactSupportScreen()),
    );
  }

  Future<void> _showLogoutSheet(BuildContext context) async {
    HapticFeedback.lightImpact();
    
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const _LogoutBottomSheet(),
    );

    if (confirmed == true && mounted) {
      setState(() => _isLoggingOut = true);
      try {
        await FirebaseAuth.instance.signOut();
        if (mounted) {
          rootNavigatorKey.currentState?.pushNamedAndRemoveUntil('/login', (route) => false);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Logout failed: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoggingOut = false);
        }
      }
    }
  }
}

// ============================================
// PART 1: Premium Glass Profile Header
// ============================================
class _PremiumProfileHeader extends StatelessWidget {
  final Technician technician;
  final VoidCallback onAvatarTap;
  final Animation<double> avatarScaleAnimation;

  const _PremiumProfileHeader({
    required this.technician,
    required this.onAvatarTap,
    required this.avatarScaleAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF6A5AE0), Color(0xFF9F44D3), Color(0xFFEC4899)],
              ),
              boxShadow: [BoxShadow(color: const Color(0xFF6A5AE0).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  color: Colors.transparent,
                  padding: const EdgeInsets.fromLTRB(24, 50, 24, 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              technician.name.isNotEmpty ? technician.name : 'Technician',
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.phone, size: 14, color: Colors.white70),
                                const SizedBox(width: 4),
                                Text(technician.phone, style: const TextStyle(fontSize: 14, color: Colors.white70)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star, size: 16, color: Color(0xFFFCD34D)),
                            const SizedBox(width: 4),
                            Text(technician.avgRating.toStringAsFixed(1), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                            const SizedBox(width: 4),
                            Text('(${technician.totalRatings})', style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.8))),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 24,
            bottom: -50,
            child: GestureDetector(
              onTap: onAvatarTap,
              child: ScaleTransition(
                scale: avatarScaleAnimation,
                child: Hero(
                  tag: 'profile_avatar_${technician.uid ?? 'self'}',
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                      boxShadow: [BoxShadow(color: const Color(0xFF6A5AE0).withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 5))],
                    ),
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: const Color(0xFFF3F0FF),
                      backgroundImage: technician.profilePhotoUrl != null ? NetworkImage(technician.profilePhotoUrl!) : null,
                      child: technician.profilePhotoUrl == null ? const Icon(Icons.person, size: 50, color: Color(0xFF6A5AE0)) : null,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================
// PART 2: Circular Profile Completion Ring & Verification Chips
// ============================================
class _VerificationAndCompletionCard extends StatefulWidget {
  final Technician technician;

  const _VerificationAndCompletionCard({required this.technician});

  @override
  State<_VerificationAndCompletionCard> createState() => _VerificationAndCompletionCardState();
}

class _VerificationAndCompletionCardState extends State<_VerificationAndCompletionCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(milliseconds: 600), vsync: this);
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int _getProfileCompletion(Technician tech) {
    return tech.getProfileCompletion();
  }

  @override
  Widget build(BuildContext context) {
    final completion = _getProfileCompletion(widget.technician);
    final isComplete = completion == 100;

    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isComplete ? [const Color(0xFF00C853), const Color(0xFF00E676)] : [Colors.grey[300]!, Colors.grey[200]!],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: (isComplete ? const Color(0xFF00C853) : Colors.grey).withOpacity(0.2), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            if (isComplete)
              Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white.withOpacity(0.3), shape: BoxShape.circle), child: const Icon(Icons.check_circle, size: 32, color: Colors.white))
            else
              Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white.withOpacity(0.3), shape: BoxShape.circle), child: const Icon(Icons.pending, size: 32, color: Colors.white)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isComplete ? '🎉 Profile Completed!' : 'Complete Your Profile',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isComplete ? "You're fully verified & ready to accept jobs." : 'Complete your profile to get more job requests.',
                    style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.9)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getAadhaarStatus(Technician tech) {
    if (tech.aadhaarFrontUrl != null && tech.aadhaarFrontUrl!.isNotEmpty) {
      return 'verified';
    }
    return 'pending';
  }

  String _getBankStatus(Technician tech) {
    final hasDetails = (tech.bankName?.isNotEmpty ?? false) &&
        (tech.accountNumber?.isNotEmpty ?? false) &&
        (tech.ifscCode?.isNotEmpty ?? false) &&
        (tech.accountHolderName?.isNotEmpty ?? false);

    if (hasDetails) {
      return 'verified';
    }
    return 'pending';
  }
}

class _AnimatedVerificationChip extends StatefulWidget {
  final String label;
  final String status;
  final int index;

  const _AnimatedVerificationChip({
    required this.label,
    required this.status,
    required this.index,
  });

  @override
  State<_AnimatedVerificationChip> createState() => _AnimatedVerificationChipState();
}

class _AnimatedVerificationChipState extends State<_AnimatedVerificationChip>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    Future.delayed(Duration(milliseconds: 100 * widget.index), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Color color;
    IconData icon;
    String text;

    switch (widget.status) {
      case 'verified':
        color = AppTheme.success;
        icon = Icons.verified;
        text = 'Verified';
        break;
      case 'pending':
        color = AppTheme.warning;
        icon = Icons.pending;
        text = 'Pending';
        break;
      case 'rejected':
        color = AppTheme.error;
        icon = Icons.cancel;
        text = 'Rejected';
        break;
      default:
        color = AppTheme.warning;
        icon = Icons.pending;
        text = 'Unknown';
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 16, color: color),
              ),
              const SizedBox(width: 10),
              Flexible(
                fit: FlexFit.loose,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        widget.label,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Flexible(
                      child: Text(
                        text,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================
// PART 3: Personal Details
// ============================================
class _PersonalDetailsCard extends StatelessWidget {
  final Technician technician;
  final VoidCallback onEditTap;

  const _PersonalDetailsCard({required this.technician, required this.onEditTap});

  Widget _docTile(String title, String? url, BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: url != null ? () => _viewDocument(context, url) : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 84,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: url == null ? Colors.red.shade50 : Colors.grey.shade100,
                border: Border.all(
                  color: url == null ? Colors.red.shade200 : Colors.grey.shade300,
                ),
              ),
              child: url != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(url, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.error_outline, color: Colors.red)),
                    )
                  : const Center(child: Icon(Icons.image_not_supported, color: Colors.red)),
            ),
            const SizedBox(height: 6),
            Text(title, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)), maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            if (url != null)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle, size: 12, color: AppTheme.success),
                  const SizedBox(width: 4),
                  Text('Verified', style: TextStyle(fontSize: 10, color: AppTheme.success, fontWeight: FontWeight.w600)),
                ],
              )
            else
              Text('Missing', style: TextStyle(fontSize: 10, color: Colors.red, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  void _viewDocument(BuildContext context, String url) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => FullImageViewScreen(imageUrl: url)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _PremiumCard(
      title: 'Personal Details',
      titleAction: TextButton.icon(
        onPressed: onEditTap,
        icon: const Icon(Icons.edit, size: 16),
        label: const Text('Edit'),
        style: TextButton.styleFrom(foregroundColor: const Color(0xFF6A5AE0)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DetailRow(icon: Icons.person_outline, label: 'Full Name', value: technician.name.isNotEmpty ? technician.name : '-', isMissing: technician.name.isEmpty),
          _DetailRow(icon: Icons.phone_outlined, label: 'Phone', value: technician.phone, isMissing: technician.phone.isEmpty),
          _DetailRow(icon: Icons.email_outlined, label: 'Email', value: technician.email.isNotEmpty ? technician.email : 'Not set', isMissing: technician.email.isEmpty),
          _DetailRow(icon: Icons.location_on_outlined, label: 'City/Area', value: technician.district ?? 'Not set', isMissing: technician.district == null),
          _DetailRow(icon: Icons.work_outline, label: 'Experience', value: technician.experienceYears != null ? '${technician.experienceYears} years' : 'Not set', isMissing: technician.experienceYears == null),
          const SizedBox(height: 20),
          const Divider(height: 1),
          const SizedBox(height: 16),
          const Text('Verification Documents', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
          const SizedBox(height: 12),
          Row(
            children: [
              _docTile('Aadhaar Front', technician.aadhaarFrontUrl, context),
              const SizedBox(width: 12),
              _docTile('Aadhaar Back', technician.aadhaarBackUrl, context),
              const SizedBox(width: 12),
              _docTile('Profile Photo', technician.profilePhotoUrl, context),
            ],
          ),
        ],
      ),
    );
  }
}

class _DocumentPreview extends StatelessWidget {
  final String label;
  final String? imageUrl;

  const _DocumentPreview({required this.label, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    final isVerified = imageUrl != null && imageUrl!.isNotEmpty;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isVerified ? AppTheme.success.withOpacity(0.2) : Colors.red.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          if (isVerified)
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(imageUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported)),
              ),
            )
          else
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.image_not_supported, color: Colors.red),
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
                const SizedBox(height: 4),
                Text(isVerified ? 'Verified' : 'Not uploaded', style: TextStyle(fontSize: 12, color: isVerified ? AppTheme.success : Colors.red, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          if (isVerified)
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: AppTheme.success.withOpacity(0.1), shape: BoxShape.circle),
              child: const Icon(Icons.check, size: 16, color: AppTheme.success),
            ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isMissing;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.isMissing = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color color = isMissing ? Colors.red : Colors.grey.shade800;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


// ============================================
// PART 5: Earnings Section
// ============================================
class _EarningsCard extends StatelessWidget {
  final VoidCallback onTap;

  const _EarningsCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF6366F1),
                        const Color(0xFF8B5CF6),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Flexible(
                  fit: FlexFit.loose,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'My Earnings',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'View your earnings and transactions',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.chevron_right,
                    color: Color(0xFF64748B),
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================
// PART 6: Documents Section
// ============================================
class _DocumentsCard extends StatelessWidget {
  final Technician technician;

  const _DocumentsCard({required this.technician});

  @override
  Widget build(BuildContext context) {
    final hasDocuments = (technician.aadhaarFrontUrl != null && technician.aadhaarFrontUrl!.isNotEmpty) ||
        (technician.profilePhotoUrl != null && technician.profilePhotoUrl!.isNotEmpty);

    return _PremiumCard(
      title: 'Documents',
      child: hasDocuments
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (technician.aadhaarFrontUrl != null && technician.aadhaarFrontUrl!.isNotEmpty)
                  _DocumentItem(
                    icon: Icons.badge_outlined,
                    label: 'Aadhaar Card',
                    status: 'verified',
                    onViewTap: () => _viewDocument(context, technician.aadhaarFrontUrl),
                  ),
                if (technician.panNumber != null && technician.panNumber!.isNotEmpty)
                  _DocumentItem(
                    icon: Icons.article_outlined,
                    label: 'PAN Card',
                    status: 'verified',
                    onViewTap: () {},
                  ),
                _DocumentItem(
                  icon: Icons.person_outline,
                  label: 'Profile Photo',
                  status: technician.profilePhotoUrl != null && technician.profilePhotoUrl!.isNotEmpty 
                      ? 'verified' 
                      : 'missing',
                  onViewTap: () => _viewDocument(context, technician.profilePhotoUrl),
                ),
              ],
            )
          : const _EmptyState(
              icon: Icons.folder_open_outlined,
              message: 'No documents uploaded',
              subMessage: 'Upload your documents to verify your profile',
            ),
    );
  }

  void _viewDocument(BuildContext context, String? url) {
    if (url == null || url.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FullImageViewScreen(imageUrl: url),
      ),
    );
  }
}

class _DocumentItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String status;
  final VoidCallback onViewTap;

  const _DocumentItem({
    required this.icon,
    required this.label,
    required this.status,
    required this.onViewTap,
  });

  @override
  Widget build(BuildContext context) {
    final isVerified = status == 'verified';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isVerified 
              ? AppTheme.success.withOpacity(0.2) 
              : AppTheme.warning.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isVerified 
                  ? AppTheme.success.withOpacity(0.1) 
                  : AppTheme.warning.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 22,
              color: isVerified ? AppTheme.success : AppTheme.warning,
            ),
          ),
          const SizedBox(width: 14),
          Flexible(
            fit: FlexFit.loose,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  fit: FlexFit.loose,
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Flexible(
                  fit: FlexFit.loose,
                  child: Text(
                    isVerified ? 'Verified' : 'Not uploaded',
                    style: TextStyle(
                      fontSize: 13,
                      color: isVerified ? AppTheme.success : AppTheme.warning,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          if (isVerified)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'View',
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.success,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ============================================
// PART 6: Bank & Payout Details (MASKED)
// ============================================
class _BankDetailsCard extends StatelessWidget {
  final Technician technician;
  final VoidCallback onUpdateTap;

  const _BankDetailsCard({
    required this.technician,
    required this.onUpdateTap,
  });

  @override
  Widget build(BuildContext context) {
    final techData = technician.toMap();
    final hasBankDetails = (techData['bankName'] != null && techData['bankName'].toString().isNotEmpty) ||
                          (techData['accountNumber'] != null && techData['accountNumber'].toString().isNotEmpty);

    return _PremiumCard(
      title: 'Bank & Payout',
      titleAction: TextButton.icon(
        onPressed: onUpdateTap,
        icon: const Icon(Icons.edit, size: 16),
        label: Text(hasBankDetails ? 'Edit' : 'Add'),
        style: TextButton.styleFrom(foregroundColor: AppTheme.primaryColor),
      ),
      child: hasBankDetails
          ? _buildBankDetailsView(techData)
          : const _EmptyState(
              icon: Icons.account_balance_outlined,
              message: 'No payout method added',
              subMessage: 'Add your bank details to receive payments',
            ),
    );
  }

  Widget _buildBankDetailsView(Map<String, dynamic> techData) {
    final bankName = techData['bankName'] as String?;
    final accountNumber = techData['accountNumber'] as String?;
    final ifscCode = techData['ifscCode'] as String?;
    final bankStatus = techData['bankStatus'] as String? ?? 'not_submitted';
    
    final maskedAccount = accountNumber != null && accountNumber.length > 4
        ? '****${accountNumber.substring(accountNumber.length - 4)}'
        : accountNumber ?? '****';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF6366F1), const Color(0xFF8B5CF6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.account_balance, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bankName ?? 'Bank Account',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Account: $maskedAccount',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              _buildStatusBadge(bankStatus),
            ],
          ),
          if (ifscCode != null) ...[
            const SizedBox(height: 16),
            const Divider(color: Colors.white24, height: 1),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.code, color: Colors.white70, size: 16),
                const SizedBox(width: 8),
                Text(
                  'IFSC: $ifscCode',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bgColor;
    Color textColor;
    IconData icon;
    String label;

    switch (status) {
      case 'approved':
        bgColor = Colors.green;
        textColor = Colors.white;
        icon = Icons.verified;
        label = 'Verified';
        break;
      case 'pending':
        bgColor = Colors.orange;
        textColor = Colors.white;
        icon = Icons.pending;
        label = 'Pending';
        break;
      case 'rejected':
        bgColor = Colors.red;
        textColor = Colors.white;
        icon = Icons.error;
        label = 'Rejected';
        break;
      default:
        bgColor = Colors.white.withOpacity(0.2);
        textColor = Colors.white;
        icon = Icons.info;
        label = 'Not Verified';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================
// PART 7: Performance Summary
// ============================================
class _PerformanceCard extends StatefulWidget {
  final Technician technician;

  const _PerformanceCard({required this.technician});

  @override
  State<_PerformanceCard> createState() => _PerformanceCardState();
}

class _PerformanceCardState extends State<_PerformanceCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int _calculateCompletionRate(Technician tech) {
    if (tech.jobsDone > 0) {
      return 95;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return _PremiumCard(
      title: 'Performance',
      child: Row(
        children: [
          Expanded(
            child: _AnimatedStatItem(
              animation: _animation,
              icon: Icons.check_circle_outline,
              label: 'Jobs Done',
              value: widget.technician.jobsDone,
              color: AppTheme.primaryColor,
              index: 0,
            ),
          ),
          Expanded(
            child: _AnimatedStatItem(
              animation: _animation,
              icon: Icons.star_outline,
              label: 'Avg Rating',
              value: widget.technician.avgRating,
              isDecimal: true,
              color: const Color(0xFFF59E0B),
              index: 1,
            ),
          ),
          Expanded(
            child: _AnimatedStatItem(
              animation: _animation,
              icon: Icons.thumb_up_outlined,
              label: 'Completion',
              value: _calculateCompletionRate(widget.technician),
              suffix: '%',
              color: AppTheme.success,
              index: 2,
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedStatItem extends StatelessWidget {
  final Animation<double> animation;
  final IconData icon;
  final String label;
  final dynamic value;
  final String? suffix;
  final Color color;
  final int index;
  final bool isDecimal;

  const _AnimatedStatItem({
    required this.animation,
    required this.icon,
    required this.label,
    required this.value,
    this.suffix,
    required this.color,
    required this.index,
    this.isDecimal = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final animatedValue = isDecimal
            ? (animation.value * (value as double)).toStringAsFixed(1)
            : '${(animation.value * (value as int)).round()}${suffix ?? ''}';
        
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 24, color: color),
            ),
            const SizedBox(height: 12),
            Flexible(
              fit: FlexFit.loose,
              child: Text(
                animatedValue,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 4),
            Flexible(
              fit: FlexFit.loose,
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF94A3B8),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        );
      },
    );
  }
}

// ============================================
// PART 8: Availability / Working Hours
// ============================================
class _AvailabilityCard extends StatelessWidget {
  final Technician technician;
  final VoidCallback onEditTap;

  const _AvailabilityCard({
    required this.technician,
    required this.onEditTap,
  });

  @override
  Widget build(BuildContext context) {
    // Check both new and old formats for availability data
    final techData = technician.toMap();
    final availabilityData = techData['availability'] as Map<String, dynamic>?;
    
    bool hasWorkHours = false;
    String workHoursText = '';
    bool isEmergencyAvailable = false;
    
    if (availabilityData != null) {
      final startTimeStr = availabilityData['startTime'] as String?;
      final endTimeStr = availabilityData['endTime'] as String?;
      isEmergencyAvailable = availabilityData['isEmergencyOn'] as bool? ?? false;
      
      if (startTimeStr != null && endTimeStr != null) {
        hasWorkHours = true;
        workHoursText = '$startTimeStr - $endTimeStr';
      }
    } else {
      // Fallback to old format
      hasWorkHours = technician.workStartTime != null && technician.workEndTime != null;
      if (hasWorkHours) {
        workHoursText = '${_formatTime(technician.workStartTime!)} - ${_formatTime(technician.workEndTime!)}';
      }
      isEmergencyAvailable = technician.emergencyServiceAvailable;
    }
    
    return _PremiumCard(
      title: 'Availability',
      titleAction: TextButton.icon(
        onPressed: onEditTap,
        icon: const Icon(Icons.edit, size: 16),
        label: const Text('Edit'),
        style: TextButton.styleFrom(
          foregroundColor: AppTheme.primaryColor,
        ),
      ),
      child: hasWorkHours
          ? Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.success.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.success.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.access_time, size: 22, color: AppTheme.success),
                      ),
                      const SizedBox(width: 14),
                      Flexible(
                        fit: FlexFit.loose,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              workHoursText,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                            const Text(
                              'Working Hours',
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.success,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Available',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (isEmergencyAvailable) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.flash_on, size: 20, color: Color(0xFFF59E0B)),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Emergency Service Available',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF92400E),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            )
          : const _EmptyState(
              icon: Icons.schedule_outlined,
              message: 'No working hours set',
              subMessage: 'Set your availability to start receiving jobs',
            ),
    );
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

// ============================================
// PART 9: Support & Help
// ============================================
class _SupportSection extends StatelessWidget {
  final VoidCallback onRaiseDisputeTap;
  final VoidCallback onContactSupportTap;
  final VoidCallback onFaqsTap;

  const _SupportSection({
    required this.onRaiseDisputeTap,
    required this.onContactSupportTap,
    required this.onFaqsTap,
  });

  @override
  Widget build(BuildContext context) {
    return _PremiumCard(
      title: 'Support & Help',
      child: Column(
        children: [
          _SupportItem(
            icon: Icons.gavel_outlined,
            label: 'Raise Dispute',
            onTap: onRaiseDisputeTap,
          ),
          _SupportItem(
            icon: Icons.support_agent_outlined,
            label: 'Contact Support',
            onTap: onContactSupportTap,
          ),
          _SupportItem(
            icon: Icons.quiz_outlined,
            label: 'FAQs',
            onTap: onFaqsTap,
            showDivider: false,
          ),
        ],
      ),
    );
  }
}

class _SupportItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool showDivider;

  const _SupportItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, size: 20, color: const Color(0xFF64748B)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      label,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Color(0xFF1E293B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right,
                    size: 22,
                    color: Color(0xFF94A3B8),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (showDivider)
          const Divider(height: 1, indent: 56),
      ],
    );
  }
}

// ============================================
// PART 10: App Settings
// ============================================
class _SettingsSection extends StatelessWidget {
  final bool notificationsEnabled;
  final ValueChanged<bool> onNotificationsChanged;
  final VoidCallback onLogoutTap;
  final bool isLoggingOut;

  const _SettingsSection({
    required this.notificationsEnabled,
    required this.onNotificationsChanged,
    required this.onLogoutTap,
    required this.isLoggingOut,
  });

  @override
  Widget build(BuildContext context) {
    return _PremiumCard(
      title: 'Settings',
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.notifications_outlined, size: 20, color: Color(0xFF64748B)),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Text(
                    'Notifications',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ),
                Switch(
                  value: notificationsEnabled,
                  onChanged: onNotificationsChanged,
                  activeColor: AppTheme.primaryColor,
                ),
              ],
            ),
          ),
          const Divider(height: 20),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: isLoggingOut ? null : onLogoutTap,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.logout, size: 20, color: AppTheme.error),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        isLoggingOut ? 'Logging out...' : 'Logout',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.error,
                        ),
                      ),
                    ),
                    if (isLoggingOut)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================
// Premium Card Widget
// ============================================
class _PremiumCard extends StatelessWidget {
  final String title;
  final Widget? titleAction;
  final Widget child;

  const _PremiumCard({required this.title, this.titleAction, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
              if (titleAction != null) titleAction!,
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

// ============================================
// Premium Empty State
// ============================================
class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String subMessage;

  const _EmptyState({
    required this.icon,
    required this.message,
    required this.subMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0).withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 32,
              color: const Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subMessage,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF94A3B8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ============================================
// PART 9: Premium Logout Bottom Sheet
// ============================================
class _LogoutBottomSheet extends StatelessWidget {
  const _LogoutBottomSheet();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            // Warning icon
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.error.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.logout,
                size: 32,
                color: AppTheme.error,
              ),
            ),
            const SizedBox(height: 20),
            // Title
            const Text(
              'Confirm Logout',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            // Message
            const Text(
              'Are you sure you want to logout? You will need to login again to access your account.',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF64748B),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            // Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.error,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Logout',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================
// PART 6: Premium Shimmer Loading
// ============================================
class _PremiumProfileShimmer extends StatelessWidget {
  const _PremiumProfileShimmer();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header shimmer
          Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              height: 180,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
          const SizedBox(height: 70),
          // Verification shimmer
          Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              height: 180,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Details shimmer
          Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              height: 220,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Services shimmer
          Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              height: 140,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Documents shimmer
          Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              height: 180,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Bank shimmer
          Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================
// Placeholder screens for navigation
// ============================================

class FullImageViewScreen extends StatelessWidget {
  final String imageUrl;
  
  const FullImageViewScreen({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: InteractiveViewer(
          child: SafeNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _cityController = TextEditingController();
  final _experienceController = TextEditingController();
  final _bioController = TextEditingController();
  
  bool _isSaving = false;
  bool _isUploadingPhoto = false;
  String? _profilePhotoUrl;
  String? _selectedGender;
  DateTime? _selectedDOB;
  
  final List<String> _genderOptions = ['Male', 'Female', 'Other'];
  Technician? _technician;

  @override
  void initState() {
    super.initState();
    print("[EDIT PROFILE] Loading initial data");
    _loadCurrentData();
  }

  void _loadCurrentData() {
    final provider = context.read<TechnicianProvider>();
    _technician = provider.technician;
    if (_technician != null) {
      _nameController.text = _technician!.name;
      _cityController.text = _technician!.district ?? '';
      _experienceController.text = _technician!.experienceYears?.toString() ?? '';
      _bioController.text = _technician!.bio ?? '';
      _profilePhotoUrl = _technician!.profilePhotoUrl;
      _selectedGender = _technician!.gender;
      _selectedDOB = _technician!.dateOfBirth;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _cityController.dispose();
    _experienceController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  String _capitalizeWords(String text) {
    if (text.isEmpty) return text;
    return text.split(' ').map((word) => 
      word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1).toLowerCase()
    ).join(' ').replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  Future<void> _pickImage() async {
    if (_isSaving || _isUploadingPhoto) return;
    
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () {
                Navigator.pop(ctx);
                _getImage(useCamera: true);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () {
                Navigator.pop(ctx);
                _getImage(useCamera: false);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _getImage({required bool useCamera}) async {
    if (_isUploadingPhoto) return;
    
    setState(() => _isUploadingPhoto = true);
    
    try {
      final provider = context.read<TechnicianProvider>();
      final picker = ImagePicker();
      final source = useCamera ? ImageSource.camera : ImageSource.gallery;
      
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 1280,
        maxHeight: 1280,
        imageQuality: 70,
      );
      
      if (pickedFile != null && mounted) {
        final file = File(pickedFile.path);
        final url = await provider.uploadDocumentImage(file, 'profile_photo');
        
        if (mounted) {
          setState(() {
            _profilePhotoUrl = url;
            _isUploadingPhoto = false;
          });
        }
      } else if (mounted) {
        setState(() => _isUploadingPhoto = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploadingPhoto = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload image: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _saveProfile() async {
    print("[EDIT PROFILE] Save pressed");
    
    if (_isSaving) return;
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isSaving = true);
    
    try {
      final provider = context.read<TechnicianProvider>();
      
      final payload = {
        'fullName': _capitalizeWords(_nameController.text.trim()),
        'email': _technician?.email ?? '',
        'phone': _technician?.phone ?? '',
        'district': _capitalizeWords(_cityController.text.trim()),
        'experienceYears': int.tryParse(_experienceController.text) ?? 0,
        'bio': _bioController.text.trim(),
        'gender': _selectedGender,
        'dateOfBirth': _selectedDOB?.toIso8601String(),
        'profilePhotoUrl': _profilePhotoUrl,
      };
      
      debugPrint('[PROFILE_SAVE] payload=$payload');
      
      await provider.saveStepData(step: 1, data: payload);
      
      debugPrint('[PROVIDER_REFRESH] started');
      await provider.refreshTechnicianData();
      debugPrint('[PROVIDER_REFRESH] done, tech=${provider.technician?.toMap()}');
      
      print("[EDIT PROFILE] SUCCESS");
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      print("[EDIT PROFILE] ERROR: $e");
      debugPrint('[PROFILE_SAVE] error=$e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _technician == null
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Profile Photo
                    Center(
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 60,
                            backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                            backgroundImage: _profilePhotoUrl != null
                                ? NetworkImage(_profilePhotoUrl!)
                                : null,
                            child: _profilePhotoUrl == null
                                ? const Icon(Icons.person, size: 60, color: AppTheme.primaryColor)
                                : null,
                          ),
                          if (_isUploadingPhoto)
                            const Positioned.fill(
                              child: CircleAvatar(
                                backgroundColor: Colors.black38,
                                child: CircularProgressIndicator(color: Colors.white),
                              ),
                            ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: CircleAvatar(
                              radius: 20,
                              backgroundColor: AppTheme.primaryColor,
                              child: IconButton(
                                icon: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                                onPressed: _pickImage,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Name Field
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                      textCapitalization: TextCapitalization.words,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Name is required';
                        }
                        if (value.trim().length < 2) {
                          return 'Name must be at least 2 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // City Field
                    TextFormField(
                      controller: _cityController,
                      decoration: const InputDecoration(
                        labelText: 'City/District',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.location_city),
                      ),
                      textCapitalization: TextCapitalization.words,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'City is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Experience Field
                    TextFormField(
                      controller: _experienceController,
                      decoration: const InputDecoration(
                        labelText: 'Years of Experience',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.work),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                    const SizedBox(height: 16),
                    
                    // Gender Selection
                    DropdownButtonFormField<String>(
                      value: _selectedGender,
                      decoration: const InputDecoration(
                        labelText: 'Gender',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.wc),
                      ),
                      items: _genderOptions.map((gender) => DropdownMenuItem(
                        value: gender,
                        child: Text(gender),
                      )).toList(),
                      onChanged: (value) {
                        setState(() => _selectedGender = value);
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Bio Field
                    TextFormField(
                      controller: _bioController,
                      decoration: const InputDecoration(
                        labelText: 'Bio (Optional)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.description),
                        alignLabelWithHint: true,
                      ),
                      maxLines: 3,
                      maxLength: 500,
                    ),
                    const SizedBox(height: 24),
                    
                    // Save Button
                    ElevatedButton(
                      onPressed: _isSaving ? null : _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Save Profile',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
    );
  }
}

class EditAvailabilityScreen extends StatefulWidget {
  const EditAvailabilityScreen({super.key});

  @override
  State<EditAvailabilityScreen> createState() => _EditAvailabilityScreenState();
}

class _EditAvailabilityScreenState extends State<EditAvailabilityScreen> {
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 18, minute: 0);
  bool _isSaving = false;
  final List<int> _selectedDays = [1, 2, 3, 4, 5]; // Mon-Fri
  bool _emergencyAvailable = false;

  final List<String> _dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  void initState() {
    super.initState();
    _loadCurrentData();
  }

  void _loadCurrentData() {
    final provider = context.read<TechnicianProvider>();
    final tech = provider.technician;
    if (tech != null) {
      // Try to load from new availability format first
      final availabilityData = tech.toMap()['availability'] as Map<String, dynamic>?;
      if (availabilityData != null) {
        final startTimeStr = availabilityData['startTime'] as String?;
        final endTimeStr = availabilityData['endTime'] as String?;
        
        if (startTimeStr != null) {
          final parts = startTimeStr.split(':');
          if (parts.length == 2) {
            _startTime = TimeOfDay(
              hour: int.tryParse(parts[0]) ?? 9,
              minute: int.tryParse(parts[1]) ?? 0,
            );
          }
        }
        
        if (endTimeStr != null) {
          final parts = endTimeStr.split(':');
          if (parts.length == 2) {
            _endTime = TimeOfDay(
              hour: int.tryParse(parts[0]) ?? 18,
              minute: int.tryParse(parts[1]) ?? 0,
            );
          }
        }
        
        _emergencyAvailable = availabilityData['isEmergencyOn'] as bool? ?? false;
      } else {
        // Fallback to old format
        if (tech.workStartTime != null) {
          _startTime = tech.workStartTime!;
        }
        if (tech.workEndTime != null) {
          _endTime = tech.workEndTime!;
        }
        _emergencyAvailable = tech.emergencyServiceAvailable;
      }
    }
  }

  Future<void> _selectTime(BuildContext context, bool isStartTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStartTime ? _startTime : _endTime,
    );
    if (picked != null) {
      setState(() {
        if (isStartTime) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  Future<void> _saveAvailability() async {
    if (_isSaving) return;

    // Validation
    if (_startTime.hour > _endTime.hour || 
        (_startTime.hour == _endTime.hour && _startTime.minute >= _endTime.minute)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('End time must be after start time'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    // Show "Coming Soon" message - backend function not yet implemented
    if (mounted) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Availability editing is coming soon. Contact support for assistance.'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Edit Availability',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF0F172A),
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Working Hours
            Text(
              'Working Hours',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Flexible(
                  fit: FlexFit.loose,
                  child: _buildTimeCard(
                    'Start Time',
                    _startTime,
                    () => _selectTime(context, true),
                  ),
                ),
                const SizedBox(width: 16),
                Flexible(
                  fit: FlexFit.loose,
                  child: _buildTimeCard(
                    'End Time',
                    _endTime,
                    () => _selectTime(context, false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Emergency Service
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Emergency Service',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Accept urgent jobs outside working hours',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  Switch(
                    value: _emergencyAvailable,
                    onChanged: (value) => setState(() => _emergencyAvailable = value),
                    activeColor: const Color(0xFF6366F1),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Save Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveAvailability,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        'Save Availability',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeCard(String label, TimeOfDay time, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              time.format(context),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0F172A),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class EditSkillsScreen extends StatefulWidget {
  const EditSkillsScreen({super.key});

  @override
  State<EditSkillsScreen> createState() => _EditSkillsScreenState();
}

class _EditSkillsScreenState extends State<EditSkillsScreen> {
  final Set<String> _selectedSkills = {};
  bool _isLoading = true;
  bool _isSaving = false;
  List<String> _availableSkills = [];

  // Common skills for technicians
  final List<String> _commonSkills = [
    'AC Repair',
    'Plumbing',
    'Electrical',
    'Carpentry',
    'Painting',
    'Appliance Repair',
    'Cleaning',
    'Pest Control',
    'Home Security',
    'Smart Home Installation',
    'Water Heater Repair',
    'Kitchen Equipment',
    'Bathroom Fixtures',
    'Window Repair',
    'Furniture Assembly',
    'TV Mounting',
    'Locksmith',
    'Masonry',
    'Tile Work',
    'Glass Work',
  ];

  @override
  void initState() {
    super.initState();
    _loadSkills();
  }

  void _loadSkills() {
    final provider = context.read<TechnicianProvider>();
    final tech = provider.technician;
    
    if (tech != null && tech.skills.isNotEmpty) {
      _selectedSkills.addAll(tech.skills);
    }
    
    // Use common skills as available options
    setState(() {
      _availableSkills = _commonSkills;
      _isLoading = false;
    });
  }

  Future<void> _saveSkills() async {
    if (_isSaving) return;

    setState(() => _isSaving = true);

    try {
      await context.read<TechnicianProvider>().updateSkills(_selectedSkills.toList());
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Skills updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update skills: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Edit Skills',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF0F172A),
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Info
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Color(0xFF6366F1)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Select the skills you are proficient in. This helps customers find you.',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            color: const Color(0xFF6366F1),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Skills Grid
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 3,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: _availableSkills.length,
                    itemBuilder: (context, index) {
                      final skill = _availableSkills[index];
                      final isSelected = _selectedSkills.contains(skill);
                      return InkWell(
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _selectedSkills.remove(skill);
                            } else {
                              _selectedSkills.add(skill);
                            }
                          });
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF6366F1)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF6366F1)
                                  : const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              skill,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: isSelected
                                    ? Colors.white
                                    : const Color(0xFF0F172A),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Save Button
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveSkills,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6366F1),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              'Save Skills (${_selectedSkills.length} selected)',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}



class RaiseDisputeScreen extends StatefulWidget {
  const RaiseDisputeScreen({super.key});

  @override
  State<RaiseDisputeScreen> createState() => _RaiseDisputeScreenState();
}

class _RaiseDisputeScreenState extends State<RaiseDisputeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _jobIdController = TextEditingController();
  bool _isSubmitting = false;
  String? _selectedReason;

  final List<String> _reasons = [
    'Payment Not Received',
    'Incorrect Payment Amount',
    'Customer Not Satisfied',
    'Job Cancellation Issue',
    'Service Quality Issue',
    'Other',
  ];

  @override
  void dispose() {
    _descriptionController.dispose();
    _jobIdController.dispose();
    super.dispose();
  }

  Future<void> _submitDispute() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isSubmitting) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please login to submit a dispute')),
        );
      }
      return;
    }

    setState(() => _isSubmitting = true);

    // Show "Coming Soon" message - backend function not yet implemented
    if (mounted) {
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Dispute submission is coming soon. Please contact support directly.'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Raise Dispute',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF0F172A),
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: Color(0xFFF59E0B),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Please provide detailed information about your dispute. Our team will review it within 48 hours.',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Job ID Field (Optional)
              Text(
                'Job ID (Optional)',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: TextFormField(
                  controller: _jobIdController,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.all(16),
                    border: InputBorder.none,
                    hintText: 'Enter Job ID if related to a specific job',
                    hintStyle: GoogleFonts.plusJakartaSans(
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Reason Dropdown
              Text(
                'Reason *',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: DropdownButtonFormField<String>(
                  value: _selectedReason,
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: InputBorder.none,
                  ),
                  hint: Text(
                    'Select a reason',
                    style: GoogleFonts.plusJakartaSans(
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                  items: _reasons.map((reason) {
                    return DropdownMenuItem(
                      value: reason,
                      child: Text(
                        reason,
                        style: GoogleFonts.plusJakartaSans(
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _selectedReason = value);
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select a reason';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 24),

              // Description Field
              Text(
                'Description *',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: TextFormField(
                  controller: _descriptionController,
                  maxLines: 6,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.all(16),
                    border: InputBorder.none,
                    hintText: 'Describe your dispute in detail...',
                    hintStyle: GoogleFonts.plusJakartaSans(
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a description';
                    }
                    if (value.trim().length < 20) {
                      return 'Description must be at least 20 characters';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitDispute,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEF4444),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          'Submit Dispute',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ContactSupportScreen extends StatefulWidget {
  const ContactSupportScreen({super.key});

  @override
  State<ContactSupportScreen> createState() => _ContactSupportScreenState();
}

class _ContactSupportScreenState extends State<ContactSupportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _messageController = TextEditingController();
  bool _isSubmitting = false;
  String? _selectedCategory;

  final List<String> _categories = [
    'Payment Issue',
    'Booking Problem',
    'Account Issue',
    'Technical Problem',
    'Other',
  ];

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submitTicket() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isSubmitting) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please login to submit a ticket')),
        );
      }
      return;
    }

    setState(() => _isSubmitting = true);

    // Show "Coming Soon" message - backend function not yet implemented
    if (mounted) {
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Support ticket submission is coming soon. Please contact support directly.'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Contact Support',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF0F172A),
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: AppTheme.primaryColor,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Submit a support ticket and our team will get back to you within 24 hours.',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Category Dropdown
              Text(
                'Category (Optional)',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: InputBorder.none,
                  ),
                  hint: Text(
                    'Select a category',
                    style: GoogleFonts.plusJakartaSans(
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                  items: _categories.map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text(
                        category,
                        style: GoogleFonts.plusJakartaSans(
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _selectedCategory = value);
                  },
                ),
              ),
              const SizedBox(height: 24),

              // Message Field
              Text(
                'Message *',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: TextFormField(
                  controller: _messageController,
                  maxLines: 6,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.all(16),
                    border: InputBorder.none,
                    hintText: 'Describe your issue in detail...',
                    hintStyle: GoogleFonts.plusJakartaSans(
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your message';
                    }
                    if (value.trim().length < 10) {
                      return 'Message must be at least 10 characters';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitTicket,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          'Submit Ticket',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


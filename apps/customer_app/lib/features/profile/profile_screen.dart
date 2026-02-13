import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:io';
import 'package:customer_app/core/services/storage_service.dart';

import '../../core/services/auth_service.dart';
import '../../core/services/firestore_service.dart';
import '../../core/models/user_model.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/safe_network_image.dart';
import '../../core/utils/app_localizations.dart';
import '../../shared/widgets/app_widgets.dart';
import '../bookings/presentation/booking_history_screen.dart';
import '../support/presentation/support_screen.dart';
import '../settings/settings_screen.dart';
import 'presentation/edit_profile_screen.dart';
import 'presentation/favorite_services_screen.dart';
import 'package:customer_app/features/profile/presentation/partner_onboarding_screen_v2.dart';
import 'presentation/about_screen.dart';
import 'presentation/policy_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    final currentUser = authService.currentUser;

    if (currentUser == null) {
      return const _ProfileGuestView();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        top: false, // SliverAppBar handles top if needed, but let's be safe
        child: StreamBuilder<UserModel>(
          stream: firestoreService.streamUserModel(currentUser.uid),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const _ProfileSkeleton();
            }

            if (snapshot.hasError) {
              return _ProfileErrorView(error: snapshot.error.toString());
            }

            final user = snapshot.data;
            debugPrint("[Profile] User role logic: ${(user?.role ?? 'customer').toString().toLowerCase()}");
            return _ProfileContent(user: user ?? UserModel(uid: currentUser.uid));
          },
        ),
      ),
    );
  }
}

class _ProfileContent extends StatefulWidget {
  final UserModel user;

  const _ProfileContent({required this.user});

  @override
  State<_ProfileContent> createState() => _ProfileContentState();
}

class _ProfileContentState extends State<_ProfileContent> {
  bool _isUploading = false;

  Future<void> _changeProfileImage() async {
    if (_isUploading) return; // Prevent multiple taps during upload

    try {
      final picker = ImagePicker();
      final l10n = AppLocalizations.of(context);
      
      // Show source selection dialog
      final ImageSource? source = await showDialog<ImageSource>(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(l10n.translate('chooseImageSource'), style: GoogleFonts.outfit(fontWeight: FontWeight.w800)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_rounded, color: AppTheme.primaryColor),
                title: Text(l10n.translate('gallery'), style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded, color: AppTheme.primaryColor),
                title: Text(l10n.translate('camera'), style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
            ],
          ),
        ),
      );

      if (source == null) return; // User cancelled

      // Pick image with quality compression
      final XFile? image = await picker.pickImage(
        source: source,
        imageQuality: 70, // Compress to reduce file size
        maxWidth: 1024,
        maxHeight: 1024,
      );
      
      if (image == null) return; // User cancelled picker

      // Validate file size before upload
      final file = File(image.path);
      final fileSize = await file.length();
      if (fileSize > StorageService.maxFileSizeBytes) {
        if (mounted) {
          final sizeMB = (fileSize / (1024 * 1024)).toStringAsFixed(1);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.translate('imageSizeExceeds', params: {'size': sizeMB})),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Start upload
      setState(() => _isUploading = true);

      final storage = Provider.of<StorageService>(context, listen: false);
      final firestore = Provider.of<FirestoreService>(context, listen: false);
      
      // Upload to Firebase Storage
      final String downloadURL = await storage.uploadProfilePhoto(
        userId: widget.user.uid,
        file: image,
      );
      
      // Update Firestore with download URL
      await firestore.updateProfileImageUrl(widget.user.uid, downloadURL);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Text(l10n.translate('profileImageUpdated'), style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      debugPrint('[ProfileScreen] Error uploading profile image: $e');
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    e.toString(),
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final l10n = AppLocalizations.of(context);
    final initials = (widget.user.name?.isNotEmpty ?? false) ? widget.user.name!.substring(0, 1).toUpperCase() : 'U';

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverAppBar(
          expandedHeight: 280,
          pinned: true,
          elevation: 0,
          backgroundColor: AppTheme.primaryColor,
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primaryColor, Color(0xFF4338CA)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned(
                    top: -50, right: -50,
                    child: CircleAvatar(radius: 120, backgroundColor: Colors.white.withOpacity(0.05)),
                  ),
                  Positioned(
                    bottom: -30, left: -30,
                    child: CircleAvatar(radius: 80, backgroundColor: Colors.white.withOpacity(0.05)),
                  ),
                  
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 50),
                      // Avatar with Upload
                      GestureDetector(
                        onTap: _isUploading ? null : _changeProfileImage,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: 110, height: 110,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 4),
                                boxShadow: [
                                  BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 10)),
                                ],
                              ),
                              child: ClipOval(
                                child: widget.user.photoUrl != null && widget.user.photoUrl!.isNotEmpty
                                    ? (() {
                                        print("IMAGE URL => ${widget.user.photoUrl}");
                                        return CachedNetworkImage(
                                          imageUrl: widget.user.photoUrl ?? '',
                                          fit: BoxFit.cover,
                                          placeholder: (context, url) => Container(
                                            color: AppTheme.accentColor,
                                            child: Center(
                                              child: CircularProgressIndicator(
                                                color: AppTheme.primaryColor,
                                              ),
                                            ),
                                          ),
                                          errorWidget: (context, url, error) {
                                            debugPrint('[ProfileScreen] Error loading profile image: $error');
                                            return Container(
                                              color: AppTheme.primaryColor,
                                              child: Center(
                                                child: Text(
                                                  initials,
                                                  style: GoogleFonts.outfit(
                                                    fontSize: 40,
                                                    fontWeight: FontWeight.w900,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                        );
                                      }())
                                    : Container(
                                        color: AppTheme.primaryColor,
                                        child: Center(
                                          child: Text(
                                            initials,
                                            style: GoogleFonts.outfit(
                                              fontSize: 40,
                                              fontWeight: FontWeight.w900,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                              ),
                            ),
                            if (_isUploading)
                              Container(
                                width: 110,
                                height: 110,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.black.withOpacity(0.5),
                                ),
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 3,
                                  ),
                                ),
                              )
                            else
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(Icons.camera_alt, size: 16, color: AppTheme.primaryColor),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        widget.user.name?.isNotEmpty ?? false ? widget.user.name! : l10n.translate('welcomeUser'),
                        style: GoogleFonts.outfit(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900),
                      ),
                      Text(
                        (widget.user.email?.isNotEmpty ?? false) ? widget.user.email! : ((widget.user.phone?.isNotEmpty ?? false) ? widget.user.phone! : l10n.translate('homeFixMember')),
                        style: GoogleFonts.outfit(color: Colors.white.withOpacity(0.8), fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Info Card: Address & Wallet
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 10))],
                  ),
                  child: Column(
                    children: [
                      _buildInfoRow(
                        icon: Icons.location_on_rounded,
                        color: Colors.redAccent,
                        title: l10n.translate('primaryAddress'),
                        value: (widget.user.defaultAddress?.isNotEmpty ?? false) ? widget.user.defaultAddress! : l10n.translate('noAddressSet'),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Divider(height: 1),
                      ),
                      _buildInfoRow(
                        icon: Icons.account_balance_wallet_rounded,
                        color: Colors.green,
                        title: l10n.translate('walletBalance'),
                        value: '₹${widget.user.walletBalance.toStringAsFixed(2)}',
                        trailing: TextButton(
                          onPressed: () {},
                          child: Text(l10n.translate('addMoney'), style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),
                _sectionTitle(l10n.translate('accountSettings')),
                _settingsGroup([
                  _settingsTile(Icons.person_outline_rounded, l10n.translate('personalDetails'), l10n.translate('nameEmailPhone'), 
                    () => Navigator.push(context, MaterialPageRoute(builder: (_) => EditProfileScreen(user: widget.user)))),
                  _settingsTile(Icons.history_rounded, l10n.translate('bookingHistory'), l10n.translate('viewAllPastServices'), 
                    () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BookingHistoryScreen()))),
                  _settingsTile(Icons.favorite_border_rounded, l10n.translate('favorites'), l10n.translate('servicesYouLoved'), 
                    () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FavoriteServicesScreen()))),
                ]),

                const SizedBox(height: 32),
                _sectionTitle(l10n.translate('preferences')),
                _settingsGroup([
                  _settingsTile(
                    Icons.settings_rounded,
                    l10n.settings,
                    l10n.translate('appPreferencesPrivacy'),
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SettingsScreen(user: widget.user),
                      ),
                    ),
                  ),
                  _settingsTile(Icons.notifications_none_rounded, l10n.notifications, l10n.translate('manageAlertsUpdates'), () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SettingsScreen(user: widget.user),
                      ),
                    );
                  }),
                  _settingsTile(Icons.language_rounded, l10n.language, l10n.translate('languageSubtitle'), () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SettingsScreen(user: widget.user),
                      ),
                    );
                  }),
                ]),

                if ((widget.user.role ?? 'customer').toString().toLowerCase() == 'customer') ...[
                  const SizedBox(height: 32),
                  _buildBecomeTechnicianCTA(context, l10n),
                ],

                const SizedBox(height: 32),
                _sectionTitle(l10n.translate('support')),
                _settingsGroup([
                  _settingsTile(Icons.help_outline_rounded, l10n.translate('helpCenter'), l10n.translate('faqsCustomerSupport'), 
                    () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SupportScreen()))),
                  _settingsTile(Icons.policy_outlined, l10n.translate('privacyPolicy'), l10n.translate('howWeProtectData'), 
                    () => Navigator.push(context, MaterialPageRoute(builder: (_) => PolicyScreen(title: l10n.translate('privacyPolicy'))))),
                  _settingsTile(Icons.info_outline_rounded, l10n.translate('aboutHomeFix'), '${l10n.translate('version')} 2.0.1', 
                    () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutScreen()))),
                ]),

                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: () => _confirmLogout(context, authService, l10n),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade50,
                      foregroundColor: Colors.red,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: Colors.red.shade100)),
                    ),
                    child: Text(l10n.logout.toUpperCase(), style: GoogleFonts.outfit(fontWeight: FontWeight.w900, letterSpacing: 1)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title,
        style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w800, color: AppTheme.subtitleColor, letterSpacing: 1),
      ),
    );
  }

  Widget _settingsGroup(List<Widget> children) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildBecomeTechnicianCTA(BuildContext context, AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF10B981), Color(0xFF059669)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PartnerOnboardingScreenV2())),
        borderRadius: BorderRadius.circular(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.handyman_rounded, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  l10n.translate('earnMoreWithHomeFix'),
                  style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              l10n.translate('joinCommunity'),
              style: GoogleFonts.outfit(color: Colors.white.withOpacity(0.9), fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PartnerOnboardingScreenV2())),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF059669),
                elevation: 0,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(
                l10n.translate('registerAsPartner'),
                style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _settingsTile(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: AppTheme.accentColor.withOpacity(0.5), borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: AppTheme.primaryColor, size: 20),
      ),
      title: Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 15)),
      subtitle: Text(subtitle, style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.subtitleColor)),
      trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
    );
  }

  Widget _buildInfoRow({required IconData icon, required Color color, required String title, required String value, Widget? trailing}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.subtitleColor)),
              Text(value, style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w800), maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
        if (trailing != null) trailing,
      ],
    );
  }

  void _confirmLogout(BuildContext context, AuthService auth, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(l10n.translate('logoutQuestion'), style: GoogleFonts.outfit(fontWeight: FontWeight.w900)),
        content: Text(l10n.translate('logoutConfirm')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel.toUpperCase())),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              auth.signOut();
            },
            child: Text(l10n.logout.toUpperCase(), style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class _ProfileSkeleton extends StatelessWidget {
  const _ProfileSkeleton();

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      child: Column(
        children: [
          SkeletonLoader(height: 280, borderRadius: 0),
          Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              children: [
                SkeletonLoader(height: 150, borderRadius: 24),
                SizedBox(height: 32),
                SkeletonLoader(height: 200, borderRadius: 24),
                SizedBox(height: 32),
                SkeletonLoader(height: 200, borderRadius: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileErrorView extends StatelessWidget {
  final String error;
  const _ProfileErrorView({required this.error});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, size: 80, color: Colors.redAccent),
            const SizedBox(height: 24),
            Text(l10n.translate('oopsSomethingWrong'), style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w900)),
            const SizedBox(height: 12),
            Text(error, textAlign: TextAlign.center, style: GoogleFonts.outfit(color: AppTheme.subtitleColor)),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.translate('goBack')),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileGuestView extends StatelessWidget {
  const _ProfileGuestView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.person_outline_rounded, size: 100, color: AppTheme.primaryColor),
          const SizedBox(height: 24),
          Text(l10n.translate('loginToViewProfile'), style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, '/login'),
            child: Text(l10n.login.toUpperCase()),
          ),
        ],
      ),
    );
  }
}

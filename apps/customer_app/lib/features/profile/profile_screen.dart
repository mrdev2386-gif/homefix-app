import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';

import '../../core/services/auth_service.dart';
import '../../core/services/firestore_service.dart';
import '../../core/models/user_model.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/safe_network_image.dart';
import '../../shared/widgets/app_widgets.dart';
import '../bookings/presentation/booking_history_screen.dart';
import '../support/presentation/support_screen.dart';
import 'presentation/edit_profile_screen.dart';
import 'presentation/favorite_services_screen.dart';
import 'presentation/technician_onboarding_screen.dart';
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

class _ProfileContent extends StatelessWidget {
  final UserModel user;

  const _ProfileContent({required this.user});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final initials = (user.name?.isNotEmpty ?? false) ? user.name!.substring(0, 1).toUpperCase() : 'U';

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // Modern Header
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
                  Positioned.fill(
                    child: Container(color: Colors.transparent),
                  ),
                   // Decorative Circles
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
                      const SizedBox(height: 40),
                      // Avatar
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
                          child: SafeNetworkImage(
                            imageUrl: user.photoUrl,
                            fallbackUrl: 'https://ui-avatars.com/api/?name=$initials&background=6366F1&color=fff&bold=true&size=256',
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        user.name?.isNotEmpty ?? false ? user.name! : 'Welcome User',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        (user.email?.isNotEmpty ?? false) ? user.email! : ((user.phone?.isNotEmpty ?? false) ? user.phone! : 'HomeFix Member'),
                        style: GoogleFonts.outfit(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),

        // Settings Sections
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
                        title: 'Primary Address',
                        value: (user.defaultAddress?.isNotEmpty ?? false) ? user.defaultAddress! : 'No address set',
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Divider(height: 1),
                      ),
                      _buildInfoRow(
                        icon: Icons.account_balance_wallet_rounded,
                        color: Colors.green,
                        title: 'Wallet Balance',
                        value: '₹${user.walletBalance.toStringAsFixed(2)}',
                        trailing: TextButton(
                          onPressed: () {},
                          child: Text('ADD MONEY', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),
                _sectionTitle('ACCOUNT SETTINGS'),
                _settingsGroup([
                  _settingsTile(Icons.person_outline_rounded, 'Personal Details', 'Name, Email, Phone', 
                    () => Navigator.push(context, MaterialPageRoute(builder: (_) => EditProfileScreen(user: user)))),
                  _settingsTile(Icons.history_rounded, 'Booking History', 'View all your past services', 
                    () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BookingHistoryScreen()))),
                  _settingsTile(Icons.favorite_border_rounded, 'Favorites', 'Services you loved', 
                    () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FavoriteServicesScreen()))),
                ]),

                if ((user.role ?? 'customer').toString().toLowerCase() == 'customer') ...[
                  const SizedBox(height: 32),
                  _buildBecomeTechnicianCTA(context),
                ],

                const SizedBox(height: 24),
                _sectionTitle('SUPPORT'),
                _settingsGroup([
                  _settingsTile(Icons.help_outline_rounded, 'Help Center', 'FAQs and Customer Support', 
                    () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SupportScreen()))),
                  _settingsTile(Icons.policy_outlined, 'Privacy Policy', 'How we protect your data', 
                    () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PolicyScreen(title: 'Privacy Policy')))),
                  _settingsTile(Icons.info_outline_rounded, 'About HomeFix', 'Version 2.0.1', 
                    () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutScreen()))),
                ]),

                const SizedBox(height: 40),
                // Logout Button
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: () => _confirmLogout(context, authService),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade50,
                      foregroundColor: Colors.red,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: Colors.red.shade100)),
                    ),
                    child: Text(
                      'LOGOUT',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.w900, letterSpacing: 1),
                    ),
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
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildBecomeTechnicianCTA(BuildContext context) {
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
                'Earn more with HomeFix',
                style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Join our community of 50,000+ service professionals and grow your business today.',
            style: GoogleFonts.outfit(color: Colors.white.withOpacity(0.9), fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TechnicianOnboardingScreen())),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF059669),
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            child: Text(
              'REGISTER AS A PARTNER',
              style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _settingsTile(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return ListTile(
      onTap: () {
        debugPrint("[Profile] Clicked: $title");
        onTap();
      },
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

  void _confirmLogout(BuildContext context, AuthService auth) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Logout?', style: GoogleFonts.outfit(fontWeight: FontWeight.w900)),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              auth.signOut();
            },
            child: const Text('LOGOUT', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, size: 80, color: Colors.redAccent),
            const SizedBox(height: 24),
            Text('Oops! Something went wrong', style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w900)),
            const SizedBox(height: 12),
            Text(error, textAlign: TextAlign.center, style: GoogleFonts.outfit(color: AppTheme.subtitleColor)),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Go Back'),
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.person_outline_rounded, size: 100, color: AppTheme.primaryColor),
          const SizedBox(height: 24),
          Text('Login to view Profile', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, '/login'),
            child: const Text('LOGIN'),
          ),
        ],
      ),
    );
  }
}

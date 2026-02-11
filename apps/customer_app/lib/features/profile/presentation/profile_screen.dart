import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/models/user_model.dart';
import '../../../core/theme/app_theme.dart';
import 'referral_screen.dart';
import 'package:customer_app/features/profile/presentation/technician_onboarding_screen.dart';
import 'saved_addresses_screen.dart';
import '../../notifications/presentation/notification_screen.dart';
import '../../bookings/presentation/booking_history_screen.dart';
import '../../support/presentation/support_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    final currentUser = authService.currentUser;

    if (currentUser == null) {
      return const Scaffold(body: Center(child: Text('Please login to continue')));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        title: Text(
          'Account',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 24, color: AppTheme.textColor),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: AppTheme.textColor),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<UserModel?>(
        stream: firestoreService.streamUserModel(currentUser.uid),
        builder: (context, snapshot) {
          // Use Firestore data if available, otherwise fallback to Firebase Auth
          final firestoreUser = snapshot.data;
          
          // Create a fallback user from Firebase Auth data
          final user = firestoreUser ?? UserModel(
            uid: currentUser.uid,
            email: currentUser.email,
            phone: currentUser.phoneNumber,
            name: currentUser.displayName ?? 'Valued Customer',
            photoUrl: currentUser.photoURL,
            walletBalance: 0.0,
          );

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                _buildHeader(context, user),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  child: Column(
                    children: [
                      _buildWalletShortcut(context, user),
                      const SizedBox(height: 24),
                      _buildMenuSection(context, 'Activity', [
                        _buildMenuTile(
                          context,
                          icon: Icons.calendar_month_rounded,
                          title: 'My Bookings',
                          subtitle: 'View and track your scheduled services',
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BookingHistoryScreen())),
                        ),
                        _buildMenuTile(
                          context,
                          icon: Icons.location_on_rounded,
                          title: 'My Addresses',
                          subtitle: 'Manage your primary and saved locations',
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SavedAddressesScreen())),
                        ),
                      ]),
                      const SizedBox(height: 24),
                      _buildMenuSection(context, 'Partner with Us', [
                        _buildMenuTile(
                          context,
                          icon: Icons.construction_rounded,
                          title: 'Become a Technician',
                          subtitle: 'Join as a service expert and start earning',
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TechnicianOnboardingScreen())),
                          isHighlighted: user.role != 'technician',
                        ),
                      ]),
                      const SizedBox(height: 24),
                      _buildMenuSection(context, 'More', [
                        _buildMenuTile(
                          context,
                          icon: Icons.help_outline_rounded,
                          title: 'Help & Support',
                          subtitle: '24/7 assistance for all your queries',
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SupportScreen())),
                        ),
                        _buildMenuTile(
                          context,
                          icon: Icons.card_giftcard_rounded,
                          title: 'Referral Rewards',
                          subtitle: 'Invite friends and earn wallet credits',
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReferralScreen())),
                        ),
                      ]),
                      const SizedBox(height: 32),
                      _buildLogoutButton(context, authService),
                      const SizedBox(height: 16),
                      Text(
                        'HomeFix v2.4.1 Premium Edition',
                        style: GoogleFonts.outfit(color: Colors.grey.shade400, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 48),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, UserModel user) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.primaryColor.withOpacity(0.1), width: 4),
              image: DecorationImage(
                image: NetworkImage(user.photoUrl ?? 'https://ui-avatars.com/api/?name=${user.name ?? "U"}&background=6366F1&color=fff'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name ?? 'Valued Customer',
                  style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w900, color: AppTheme.textColor),
                ),
                const SizedBox(height: 4),
                Text(
                  user.email ?? user.phone ?? 'No contact info',
                  style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: AppTheme.accentColor, borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.edit_outlined, size: 20, color: AppTheme.primaryColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWalletShortcut(BuildContext context, UserModel user) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryColor, AppTheme.primaryColor.withBlue(255)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: AppTheme.primaryColor.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Available Balance',
                    style: GoogleFonts.outfit(color: Colors.white.withOpacity(0.8), fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₹${user.walletBalance.toStringAsFixed(0)}',
                    style: GoogleFonts.outfit(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                  ),
                ],
              ),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppTheme.primaryColor,
                  minimumSize: const Size(100, 44),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: Text('Add Money', style: GoogleFonts.outfit(fontWeight: FontWeight.w800)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMenuSection(BuildContext context, String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            title.toUpperCase(),
            style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 11, color: Colors.grey.shade400, letterSpacing: 1.5),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: Column(children: items),
        ),
      ],
    );
  }

  Widget _buildMenuTile(BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isHighlighted = false,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isHighlighted ? AppTheme.primaryColor.withOpacity(0.1) : const Color(0xFFF8F9FE),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(icon, color: isHighlighted ? AppTheme.primaryColor : AppTheme.textColor, size: 22),
      ),
      title: Text(
        title,
        style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 16, color: AppTheme.textColor),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.grey.shade400),
      ),
      trailing: Icon(Icons.chevron_right_rounded, color: Colors.grey.shade300, size: 24),
    );
  }

  Widget _buildLogoutButton(BuildContext context, AuthService auth) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: TextButton(
        onPressed: () => _showLogoutDialog(context, auth),
        style: TextButton.styleFrom(
          foregroundColor: Colors.red.shade600,
          backgroundColor: Colors.red.shade50,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.logout_rounded, size: 20),
            const SizedBox(width: 12),
            Text(
              'Sign Out Account',
              style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, AuthService auth) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to log out of your account?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              auth.signOut();
            },
            child: const Text('Sign Out', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

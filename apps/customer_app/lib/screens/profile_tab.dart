import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../core/app_theme.dart';
import '../core/providers/auth_provider.dart';
import '../core/widgets/safe_network_image.dart';
import 'addresses_screen.dart';
import 'payments_screen.dart';
import 'referral_screen.dart';
import 'wallet_screen.dart';
import 'edit_profile_screen.dart';
import 'settings_screen.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.customer;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          "My Profile",
          style: GoogleFonts.outfit(
            color: const Color(0xFF1F2937),
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
      ),
      body: user == null 
        ? _buildGuestView(context)
        : SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
            child: Column(
              children: [
                _buildProfileHeader(context, user),
                const SizedBox(height: 24),
                _buildWalletQuickCard(context, user.walletBalance),
                const SizedBox(height: 32),
                _buildMenuItem(
                  context: context,
                  icon: Icons.history_rounded,
                  title: "Booking History",
                  subtitle: "View your past and current bookings",
                  onTap: () => Navigator.pushNamed(context, '/booking_history'),
                ),
                _buildMenuItem(
                  context: context,
                  icon: Icons.location_on_outlined,
                  title: "My Addresses",
                  subtitle: "Save your home and office address",
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddressesScreen())),
                ),
                _buildMenuItem(
                  context: context,
                  icon: Icons.payment_outlined,
                  title: "Payment Methods",
                  subtitle: "Saved cards and UPI IDs",
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PaymentsScreen())),
                ),
                _buildMenuItem(
                  context: context,
                  icon: Icons.card_giftcard_outlined,
                  title: "Refer & Earn",
                  subtitle: "Invite friends and get credits",
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReferralScreen())),
                ),
                _buildMenuItem(
                  context: context,
                  icon: Icons.work_outline_rounded,
                  title: "Become a Technician",
                  subtitle: "Join our professional network",
                  onTap: () => Navigator.pushNamed(context, '/become_technician'),
                ),
                _buildMenuItem(
                  context: context,
                  icon: Icons.help_outline_rounded,
                  title: "Help & Support",
                  subtitle: "Contact us for help",
                  onTap: () => Navigator.pushNamed(context, '/support'),
                ),
                _buildMenuItem(
                  context: context,
                  icon: Icons.settings_outlined,
                  title: "Settings",
                  subtitle: "Account, Privacy, Notifications",
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await authProvider.signOut();
                    },
                    icon: const Icon(Icons.logout_rounded, color: Colors.red),
                    label: Text(
                      "Logout",
                      style: GoogleFonts.outfit(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.withOpacity(0.05),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
    );
  }

  Widget _buildGuestView(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_outline, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'Join HomeFix Today!',
            style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Log in to see your profile and bookings',
            style: GoogleFonts.outfit(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Log In', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, dynamic user) {
    return Column(
      children: [
        Stack(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.2), width: 2),
              ),
              child: ClipOval(
                child: SafeNetworkImage(
                  imageUrl: user.photoUrl,
                  width: 90,
                  height: 90,
                  fit: BoxFit.cover,
                  fallbackUrl: 'https://ui-avatars.com/api/?name=${user.name}&background=random&size=128',
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen())),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Color(0xFF6366F1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.edit, color: Colors.white, size: 14),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              user.name,
              style: GoogleFonts.outfit(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF1F2937),
              ),
            ),
            if (user.isVerified) ...[
              const SizedBox(width: 8),
              const Icon(Icons.verified, color: Colors.blue, size: 20),
            ],
          ],
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
             Icon(Icons.mail_outline, size: 14, color: user.email.isNotEmpty ? Colors.blue : Colors.grey),
             const SizedBox(width: 4),
             Text(
                user.email.isNotEmpty ? user.email : "Email not provided",
                style: GoogleFonts.outfit(fontSize: 13, color: Colors.grey[600]),
             ),
             const SizedBox(width: 12),
             Icon(Icons.phone_android_outlined, size: 14, color: user.phone.isNotEmpty ? Colors.green : Colors.grey),
             const SizedBox(width: 4),
             Text(
                user.phone.isNotEmpty ? user.phone : "Phone not provided",
                style: GoogleFonts.outfit(fontSize: 13, color: Colors.grey[600]),
             ),
          ],
        ),
      ],
    );
  }


  Widget _buildWalletQuickCard(BuildContext context, double balance) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WalletScreen())),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withOpacity(0.2),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.account_balance_wallet, color: Colors.white, size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Wallet Balance", style: GoogleFonts.outfit(color: Colors.white70, fontSize: 12)),
                  Text("₹${balance.toStringAsFixed(0)}", style: GoogleFonts.outfit(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppTheme.textColor, size: 22),
        ),
        title: Text(
          title,
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey),
        ),
        trailing: const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}

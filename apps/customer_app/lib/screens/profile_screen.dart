import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/app_theme.dart';
import '../core/auth/auth_service.dart';
import '../core/widgets/safe_network_image.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final authService = AuthService();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Profile',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            color: AppTheme.textColor,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Header Section
            Center(
              child: Stack(
                children: [
                  user?.photoURL != null
                      ? ClipOval(
                          child: SafeNetworkImage(
                            imageUrl: user!.photoURL!,
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                            fallbackUrl: 'https://ui-avatars.com/api/?name=User&background=random&size=128',
                          ),
                        )
                      : CircleAvatar(
                          radius: 50,
                          backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                          child: const Icon(Icons.person, size: 50, color: AppTheme.primaryColor),
                        ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppTheme.primaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.camera_alt_rounded, size: 16, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              user?.displayName ?? 'HomeFix User',
              style: GoogleFonts.outfit(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppTheme.textColor,
              ),
            ),
            Text(
              user?.email ?? user?.phoneNumber ?? '',
              style: GoogleFonts.outfit(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 32),
            
            // Menu Items
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  _buildMenuItem(Icons.person_outline_rounded, 'Account Information'),
                  _buildMenuItem(Icons.location_on_outlined, 'My Addresses'),
                  _buildMenuItem(Icons.payment_rounded, 'Payment Methods'),
                  _buildMenuItem(Icons.local_offer_outlined, 'My Coupons'),
                  _buildMenuItem(Icons.help_outline_rounded, 'Support & FAQ'),
                  _buildMenuItem(Icons.description_outlined, 'About HomeFix'),
                  const SizedBox(height: 24),
                  
                  // Logout Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: TextButton.icon(
                      onPressed: () async {
                        debugPrint("User logging out...");
                        await authService.signOut();
                      },
                      icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
                      label: Text(
                        'Logout',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.redAccent,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.redAccent.withOpacity(0.05),
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
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[100]!),
      ),
      child: ListTile(
        leading: Icon(icon, color: AppTheme.textColor, size: 22),
        title: Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: AppTheme.textColor,
          ),
        ),
        trailing: const Icon(Icons.chevron_right_rounded, size: 20, color: Colors.grey),
        onTap: () {},
      ),
    );
  }
}

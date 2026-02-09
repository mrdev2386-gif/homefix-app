import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../../core/services/auth_service.dart';
import '../../core/services/firestore_service.dart';
import '../../core/models/user_model.dart';
import '../../core/widgets/safe_network_image.dart';
import '../../core/theme/app_theme.dart';

import '../settings/settings_screen.dart';
import '../history/history_screen.dart';
import 'presentation/saved_addresses_screen.dart';
import 'presentation/favorite_services_screen.dart';
import 'presentation/referral_screen.dart';
import '../../screens/become_technician_screen.dart';
import '../../screens/wallet_screen.dart';
import '../support/presentation/support_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isUploading = false;

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    final currentUser = authService.currentUser;

    if (currentUser == null) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        body: _buildGuestView(),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: StreamBuilder<UserModel?>(
        stream: firestoreService.streamUserModel(currentUser.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error loading profile', style: GoogleFonts.outfit(fontSize: 18)),
                  const SizedBox(height: 8),
                  Text('${snapshot.error}', style: GoogleFonts.outfit(fontSize: 14, color: Colors.grey)),
                ],
              ),
            );
          }
          
          // Fallback data from Firebase Auth if Firestore is loading or missing
          final userModel = snapshot.data;
          
          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildHeader(userModel),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  child: Column(
                    children: [
                      _buildBalanceCard(userModel),
                      const SizedBox(height: 32),
                      
                      _buildSectionTitle('ACTIVITY'),
                      _buildActionCard([
                        _buildMenuTile(
                          icon: Icons.calendar_today_rounded,
                          title: 'My Bookings',
                          subtitle: 'View and manage your service history',
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryScreen())),
                        ),
                        _buildMenuTile(
                          icon: Icons.location_on_rounded,
                          title: 'Saved Addresses',
                          subtitle: 'Manage your delivery locations',
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SavedAddressesScreen())),
                        ),
                        _buildMenuTile(
                          icon: Icons.favorite_rounded,
                          title: 'Favorites',
                          subtitle: 'Your most loved services',
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FavoriteServicesScreen())),
                        ),
                      ]),
                      
                      const SizedBox(height: 24),
                      _buildSectionTitle('EARNINGS & REWARDS'),
                      _buildActionCard([
                        _buildMenuTile(
                          icon: Icons.card_giftcard_rounded,
                          title: 'Refer & Earn',
                          subtitle: 'Invite friends and get rewards',
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReferralScreen())),
                        ),
                        _buildMenuTile(
                          icon: Icons.account_balance_wallet_rounded,
                          title: 'Wallet & Payments',
                          subtitle: 'Manage balance and transactions',
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WalletScreen())),
                        ),
                      ]),

                      const SizedBox(height: 24),
                      _buildSectionTitle('PARTNER PROGRAM'),
                      _buildActionCard([
                        _buildMenuTile(
                          icon: Icons.engineering_rounded,
                          title: 'Become a Partner',
                          subtitle: 'Register as a HomeFix expert',
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BecomeTechnicianScreen())),
                        ),
                      ]),

                      const SizedBox(height: 24),
                      _buildSectionTitle('ACCOUNT SETTINGS'),
                      _buildActionCard([
                        _buildMenuTile(
                          icon: Icons.settings_rounded,
                          title: 'Settings',
                          subtitle: 'Preferences and notifications',
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
                        ),
                        _buildMenuTile(
                          icon: Icons.help_center_rounded,
                          title: 'Help & Support',
                          subtitle: 'Get help with your orders',
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_ ) => const SupportScreen())),
                        ),
                      ]),

                      const SizedBox(height: 48),
                      _buildLogoutButton(authService),
                      const SizedBox(height: 24),
                      Text(
                        'HomeFix Premium v1.2.5',
                        style: GoogleFonts.outfit(
                          color: AppTheme.subtitleColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(UserModel? user) {
    final authUser = Provider.of<AuthService>(context, listen: false).currentUser;
    
    // SAFE FALLBACKS
    final String name = user?.name ?? authUser?.displayName ?? 'HomeFix User';
    final String contact = user?.phone ?? user?.email ?? authUser?.phoneNumber ?? authUser?.email ?? 'Member';
    final String photo = user?.photoUrl ?? authUser?.photoURL ?? '';
    
    // Safe initials for fallback avatar
    final String initials = name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'H';

    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      elevation: 0,
      stretch: true,
      backgroundColor: AppTheme.primaryColor,
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground],
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primaryColor, Color(0xFF4338CA)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            // Decorative shapes
            Positioned(
              top: -30, right: -30,
              child: CircleAvatar(radius: 100, backgroundColor: Colors.white.withOpacity(0.05)),
            ),
            Positioned(
              bottom: 40, left: 24, right: 24,
              child: Row(
                children: [
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Container(
                        width: 90, height: 90,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            )
                          ],
                        ),
                        child: ClipOval(
                          child: SafeNetworkImage(
                            imageUrl: photo,
                            fallbackUrl: 'https://ui-avatars.com/api/?name=$initials&background=6366F1&color=fff&bold=true&size=256',
                          ),
                        ),
                      ),
                      if (_isUploading)
                        Container(
                          width: 90, height: 90,
                          decoration: BoxDecoration(color: Colors.black.withOpacity(0.3), shape: BoxShape.circle),
                          child: const Center(child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                        ),
                    ],
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          name,
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            contact,
                            style: GoogleFonts.outfit(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildEditButton(user),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditButton(UserModel? user) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: const Icon(Icons.edit_note_rounded, color: Colors.white, size: 24),
        onPressed: () => _showEditProfileDialog(user),
      ),
    );
  }

  Widget _buildBalanceCard(UserModel? user) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 24,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.accentColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.account_balance_wallet_rounded, color: AppTheme.primaryColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TOTAL WALLET BALANCE',
                  style: GoogleFonts.outfit(
                    color: AppTheme.subtitleColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '₹${user?.walletBalance ?? 0.0}',
                  style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.textColor,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WalletScreen())),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            child: Text(
              'TOP UP',
              style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            color: AppTheme.subtitleColor,
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildActionCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppTheme.accentColor,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: AppTheme.primaryColor, size: 20),
      ),
      title: Text(
        title,
        style: GoogleFonts.outfit(
          fontWeight: FontWeight.w800,
          fontSize: 15,
          color: AppTheme.textColor,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.outfit(
          fontSize: 12,
          color: AppTheme.subtitleColor,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey, size: 20),
    );
  }

  Widget _buildLogoutButton(AuthService auth) {
    return SizedBox(
      width: double.infinity,
      child: TextButton(
        onPressed: () => _showLogoutConfirmDialog(auth),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 20),
          backgroundColor: Colors.red.withOpacity(0.05),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: Colors.red.withOpacity(0.1)),
          ),
        ),
        child: Text(
          'LOGOUT ACCOUNT',
          style: GoogleFonts.outfit(
            color: Colors.red,
            fontWeight: FontWeight.w900,
            fontSize: 15,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }

  Widget _buildGuestView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(color: AppTheme.accentColor, shape: BoxShape.circle),
              child: const Icon(Icons.person_pin_rounded, size: 80, color: AppTheme.primaryColor),
            ),
            const SizedBox(height: 32),
            Text(
              'Your Safe Profile',
              style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.w900, color: AppTheme.textColor),
            ),
            const SizedBox(height: 12),
            Text(
              'Login to access your bookings, saved addresses and personalized rewards.',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(color: AppTheme.subtitleColor, fontSize: 15, height: 1.5),
            ),
            const SizedBox(height: 48),
            ElevatedButton(
              onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 60),
                backgroundColor: AppTheme.primaryColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: Text(
                'LOGIN / SIGN UP',
                style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditProfileDialog(UserModel? user) {
    final nameController = TextEditingController(text: user?.name ?? '');
    File? localImage;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 32,
              left: 24, right: 24, top: 24,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(5))),
                const SizedBox(height: 32),
                Text('Edit Profile', style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w900)),
                const SizedBox(height: 32),
                
                GestureDetector(
                  onTap: () async {
                    final picker = ImagePicker();
                    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 60);
                    if (pickedFile != null) {
                      setModalState(() => localImage = File(pickedFile.path));
                    }
                  },
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Container(
                        width: 120, height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.accentColor,
                          border: Border.all(color: Colors.white, width: 4),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 15)],
                        ),
                        child: ClipOval(
                          child: localImage != null 
                            ? Image.file(localImage!, fit: BoxFit.cover)
                            : SafeNetworkImage(
                                imageUrl: user?.photoUrl,
                                fallbackUrl: 'https://ui-avatars.com/api/?name=${(user?.name ?? "H").substring(0, 1)}&background=6366F1&color=fff&bold=true&size=256',
                              ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: const BoxDecoration(color: AppTheme.primaryColor, shape: BoxShape.circle),
                        child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 20),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 40),
                TextField(
                  controller: nameController,
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
                  decoration: InputDecoration(
                    labelText: 'Full Name',
                    hintText: 'e.g. Yash Saini',
                    prefixIcon: const Icon(Icons.person_pin_rounded, color: AppTheme.primaryColor),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: Colors.grey.shade100)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: AppTheme.primaryColor)),
                  ),
                ),
                
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: _isUploading ? null : () async {
                    if (nameController.text.trim().isEmpty) return;
                    
                    Navigator.pop(context);
                    setState(() => _isUploading = true);
                    
                    try {
                      String? finalPhotoUrl = user?.photoUrl;
                      
                      if (localImage != null && user != null) {
                        final storageRef = FirebaseStorage.instance.ref().child('profiles').child('${user.uid}.jpg');
                        await storageRef.putFile(localImage!);
                        finalPhotoUrl = await storageRef.getDownloadURL();
                      }
                      
                      await Provider.of<AuthService>(context, listen: false).updateProfile(
                        name: nameController.text.trim(),
                        photoUrl: finalPhotoUrl,
                      );
                      
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Profile updated successfully!'), backgroundColor: Colors.green),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                        );
                      }
                    } finally {
                      if (mounted) setState(() => _isUploading = false);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 60),
                    backgroundColor: AppTheme.primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  child: Text('SAVE CHANGES', style: GoogleFonts.outfit(fontWeight: FontWeight.w900, color: Colors.white)),
                ),
              ],
            ),
          );
        }
      ),
    );
  }

  void _showLogoutConfirmDialog(AuthService auth) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: Text('Logout?', style: GoogleFonts.outfit(fontWeight: FontWeight.w900)),
        content: Text('Are you sure you want to exit your session?', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('CANCEL', style: GoogleFonts.outfit(color: Colors.grey, fontWeight: FontWeight.w800))),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              auth.signOut();
            }, 
            child: Text('LOGOUT', style: GoogleFonts.outfit(color: Colors.red, fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }
}

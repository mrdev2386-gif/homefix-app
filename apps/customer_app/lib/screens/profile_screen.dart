import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../core/app_theme.dart';
import '../core/auth/auth_service.dart';
import 'wallet_screen.dart';
import 'addresses_screen.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  User? _user;
  bool _uploading = false;
  double _walletBalance = 0.0;

  @override
  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser;
    _fetchWalletBalance();
  }

  Future<void> _fetchWalletBalance() async {
    if (_user == null) return;
    try {
      final doc = await FirebaseFirestore.instance.collection('wallets').doc(_user!.uid).get();
      if (doc.exists && mounted) {
        setState(() {
          _walletBalance = (doc.data()?['balance'] ?? 0.0).toDouble();
        });
      }
    } catch (e) {
      debugPrint("Error fetching wallet: $e");
    }
  }

  Future<void> _updateProfilePhoto() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);

    if (pickedFile == null || _user == null) return;

    setState(() => _uploading = true);

    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child('user_profiles/${_user!.uid}/profile.jpg');
      
      await ref.putData(await pickedFile.readAsBytes());
      final url = await ref.getDownloadURL();

      await _user!.updatePhotoURL(url);
      await FirebaseFunctions.instance.httpsCallable('updateUserProfile').call({'photoUrl': url});

      setState(() {
        _user = FirebaseAuth.instance.currentUser;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile photo updated!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update photo: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _logout() async {
    try {
      await _authService.signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      debugPrint("Logout error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_user == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: Text('Profile', style: GoogleFonts.outfit(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 40),
        child: Column(
          children: [
            const SizedBox(height: 20),
            _buildProfileHeader(),
            const SizedBox(height: 24),
            _buildWalletCard(),
            const SizedBox(height: 24),
            _buildSectionHeader('Account'),
            _buildMenuItem(
              icon: Icons.location_on_outlined, 
              title: 'My Addresses', 
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddressesScreen()))
            ),
            _buildMenuItem(
              icon: Icons.person_outline, 
              title: 'Personal Information', 
              subtitle: 'Name, Email, Phone',
              onTap: () {} // TODO: Edit Profile Screen
            ),
            _buildMenuItem(
              icon: Icons.credit_card, 
              title: 'Payment Methods', 
              subtitle: 'Manage cards & UPI',
              onTap: () {} // TODO: Payment Methods Screen
            ),
            
            const SizedBox(height: 24),
            _buildSectionHeader('Settings'),
            _buildMenuItem(
              icon: Icons.notifications_outlined, 
              title: 'Notifications',
              onTap: () {} // TODO: Notifications Screen
            ),
            _buildMenuItem(
              icon: Icons.lock_outline, 
              title: 'Privacy & Security',
              onTap: () {} // TODO: Privacy Screen
            ),
             _buildMenuItem(
              icon: Icons.language, 
              title: 'App Language',
              subtitle: 'English (US)',
              onTap: () {} 
            ),

            const SizedBox(height: 24),
            _buildSectionHeader('Support'),
            _buildMenuItem(
              icon: Icons.help_outline, 
              title: 'Help Center',
              onTap: () {}
            ),
            _buildMenuItem(
              icon: Icons.info_outline, 
              title: 'About HomeFix',
              subtitle: 'v1.0.0',
              onTap: () {}
            ),

            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: _logout,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.red.withOpacity(0.1),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.logout, color: Colors.red),
                  label: Text('Logout', style: GoogleFonts.outfit(color: Colors.red, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Column(
      children: [
        Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 4),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5)),
                ],
              ),
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Colors.grey[200],
                backgroundImage: _user?.photoURL != null ? CachedNetworkImageProvider(_user!.photoURL!) : null,
                child: _user?.photoURL == null 
                    ? const Icon(Icons.person, size: 50, color: Colors.grey) 
                    : null,
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: GestureDetector(
                onTap: _uploading ? null : _updateProfilePhoto,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Color(0xFF6366F1),
                    shape: BoxShape.circle,
                  ),
                  child: _uploading 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          _user?.displayName ?? 'HomeFix User',
          style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        const SizedBox(height: 4),
        Text(
          _user?.email ?? _user?.phoneNumber ?? '',
          style: GoogleFonts.outfit(color: Colors.grey[600], fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildWalletCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: const Color(0xFF6366F1).withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('My Wallet', style: GoogleFonts.outfit(color: Colors.white.withOpacity(0.9), fontSize: 16)),
              Container( // Icon wrapper
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.account_balance_wallet, color: Colors.white, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            '₹${_walletBalance.toStringAsFixed(2)}',
            style: GoogleFonts.outfit(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WalletScreen())),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF6366F1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('View Details', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        children: [
          Text(
            title.toUpperCase(),
            style: GoogleFonts.outfit(color: Colors.grey[600], fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1.2),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({required IconData icon, required String title, String? subtitle, required VoidCallback onTap}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 5, offset: const Offset(0, 2)),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: Colors.black87, size: 22),
        ),
        title: Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 15)),
        subtitle: subtitle != null ? Text(subtitle, style: GoogleFonts.outfit(color: Colors.grey, fontSize: 13)) : null,
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}

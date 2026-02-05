import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'otp_screen.dart';


class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
      _isGoogleLoading = true;
    });
    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return;
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      await FirebaseAuth.instance.signInWithCredential(credential);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Login failed: $e")),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isGoogleLoading = false;
        });
      }
    }
  }

  Future<void> _signInWithPhone() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    final phoneNumber = '+91${_phoneController.text.trim()}';
    
    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        codeSent: (verificationId, resendToken) {
          if (mounted) {
            setState(() => _isLoading = false);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => OtpScreen(
                  verificationId: verificationId,
                  phoneNumber: phoneNumber,
                ),
              ),
            );
          }
        },
        verificationFailed: (e) {
          if (mounted) {
            setState(() => _isLoading = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Verification failed: ${e.message}")),
            );
          }
        },
        verificationCompleted: (credential) async {
          await FirebaseAuth.instance.signInWithCredential(credential);
        },
        codeAutoRetrievalTimeout: (id) {},
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              height: 350,
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.handyman_rounded, size: 64, color: Colors.white),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'HomeFix Partner',
                    style: GoogleFonts.outfit(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Professional Network for Experts',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Partner Login',
                    style: GoogleFonts.outfit(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Connect with customers and grow your service business with HomeFix.',
                    style: GoogleFonts.outfit(color: Colors.grey[600], fontSize: 15, height: 1.5),
                  ),
                  const SizedBox(height: 40),
                  
                  // Phone Input
                  Form(
                    key: _formKey,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                        decoration: InputDecoration(
                          prefixIcon: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('+91', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                                const SizedBox(width: 8),
                                Container(width: 1, height: 20, color: Colors.grey[300]),
                              ],
                            ),
                          ),
                          hintText: 'Phone Number',
                          border: InputBorder.none,
                        ),
                        validator: (v) => (v?.length ?? 0) != 10 ? 'Enter 10 digits' : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _signInWithPhone,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F172A), 
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: _isLoading && !_isGoogleLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text('Continue', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      const Expanded(child: Divider()),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text('OR', style: GoogleFonts.outfit(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                      const Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: 32),

                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton.icon(
                      onPressed: _isLoading ? null : _signInWithGoogle,
                      icon: _isGoogleLoading 
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : Image.network(
                              'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/1200px-Google_%22G%22_logo.svg.png',
                              width: 20,
                            ),
                      label: Text('Continue with Google', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black)),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        side: BorderSide(color: Colors.grey[300]!),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: Text(
                      'By joining, you agree to our Service Terms',
                      style: GoogleFonts.outfit(color: Colors.grey, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

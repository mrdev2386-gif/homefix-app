import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/app_theme.dart';
import '../core/auth/auth_service.dart';
import '../widgets/app_image_asset.dart';
import 'otp_screen.dart';

class LoginScreen extends StatefulWidget {
  final String? referralCode;
  const LoginScreen({super.key, this.referralCode});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();
  bool _isLoading = false;

  void _handleGoogleLogin() async {
    setState(() => _isLoading = true);
    try {
      debugPrint("LoginScreen: [Google] Starting process...");
      final user = await _authService.signInWithGoogle(referredBy: widget.referralCode);
      if (user != null) {
        debugPrint("LoginScreen: [Google] Login successful for ${user.user?.email}");
        // AuthGate will rebuild and navigate to Dashboard
      } else {
        debugPrint("LoginScreen: [Google] Login canceled or returned null");
      }
    } catch (e) {
      debugPrint("LoginScreen: [Google] Fatal Error: $e");
      String message = 'Google Login failed';
      if (e.toString().contains('network_error')) message = 'Network error. Check connection.';
      if (e.toString().contains('developer_error')) message = 'Configuration error (check SHA-1).';
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _handlePhoneLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      final phoneNumber = '+91${_phoneController.text.trim()}';
      
      try {
        debugPrint("LoginScreen: [Phone] Checking $phoneNumber...");
        await _authService.verifyPhoneNumber(
          phoneNumber: phoneNumber,
          onCodeSent: (verificationId, resendToken) {
            debugPrint("LoginScreen: [Phone] Code sent! ID: $verificationId");
            if (mounted) {
              setState(() => _isLoading = false);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => OtpScreen(
                    verificationId: verificationId,
                    phoneNumber: phoneNumber,
                    referralCode: widget.referralCode,
                  ),
                ),
              );
            }
          },
          onVerificationFailed: (e) {
            debugPrint("LoginScreen: [Phone] Verification failed: ${e.code} - ${e.message}");
            if (mounted) {
              setState(() => _isLoading = false);
              String message = e.message ?? 'Verification failed';
              if (e.code == 'invalid-phone-number') message = 'Invalid phone number format.';
              if (e.code == 'too-many-requests') message = 'Too many attempts. Try again later.';
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(message),
                  backgroundColor: Colors.redAccent,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
          onVerificationCompleted: (credential) async {
            debugPrint("LoginScreen: [Phone] Auto-verification completed. Signing in...");
            try {
              await _authService.signInWithCredential(credential);
              debugPrint("LoginScreen: [Phone] Auto-sign-in success!");
              // AuthGate will handle navigation
            } catch (e) {
              debugPrint("LoginScreen: [Phone] Auto-sign-in error: $e");
            }
          },
        );
      } catch (e) {
        debugPrint("LoginScreen: [Phone] Unexpected Error: $e");
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('An unexpected error occurred.')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // Background decoration
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 60),
                      // Logo/Header
                      Center(
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: const Icon(
                                Icons.home_repair_service_rounded,
                                size: 56,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'HomeFix',
                              style: GoogleFonts.outfit(
                                fontSize: 40,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textColor,
                                letterSpacing: -1.0,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Expert services, doorstep comfort',
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                color: Colors.grey[500],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 60),
                      
                      Text(
                        'Login or Sign up',
                        style: GoogleFonts.outfit(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textColor,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Phone Input
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.grey[100]!),
                        ),
                        child: TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                          decoration: InputDecoration(
                            prefixIcon: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '+91',
                                    style: GoogleFonts.outfit(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.textColor,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(width: 1, height: 24, color: Colors.grey[300]),
                                ],
                              ),
                            ),
                            hintText: 'Enter phone number',
                            hintStyle: GoogleFonts.outfit(color: Colors.grey[400]),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Required';
                            if (value.length != 10) return 'Enter 10 digits';
                            return null;
                          },
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Continue Button
                      SizedBox(
                        width: double.infinity,
                        height: 60,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handlePhoneLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            elevation: 0,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : Text(
                                  'Continue',
                                  style: GoogleFonts.outfit(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                      
                      const SizedBox(height: 32),
                      Row(
                        children: [
                          const Expanded(child: Divider()),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            child: Text(
                              'OR',
                              style: GoogleFonts.outfit(
                                color: Colors.grey[400],
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const Expanded(child: Divider()),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // Google Sign-In Button
                      SizedBox(
                        width: double.infinity,
                        height: 60,
                        child: OutlinedButton.icon(
                          onPressed: _isLoading ? null : _handleGoogleLogin,
                          icon: const AppImageAsset(
                            assetPath: 'assets/icons/google_logo.png',
                            height: 24,
                          ),
                          label: Text(
                            'Continue with Google',
                            style: GoogleFonts.outfit(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.grey[200]!),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 48),
                      // Footer
                      Center(
                        child: Column(
                          children: [
                            Text(
                              'By continuing, you agree to our',
                              style: GoogleFonts.outfit(fontSize: 13, color: Colors.grey[500]),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('Terms of Service', 
                                  style: GoogleFonts.outfit(fontSize: 13, color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
                                Text('  &  ', style: GoogleFonts.outfit(fontSize: 13, color: Colors.grey[400])),
                                Text('Privacy Policy', 
                                  style: GoogleFonts.outfit(fontSize: 13, color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
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

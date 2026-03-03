import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  String? _phoneError;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _validatePhone() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _phoneError = null;
      });

      final phone = _phoneController.text.trim();
      if (phone.isEmpty) {
        setState(() {
          _phoneError = 'Please enter your phone number';
        });
        return;
      }

      if (phone.length < 10) {
        setState(() {
          _phoneError = 'Phone number must be 10 digits';
        });
        return;
      }

      if (!RegExp(r'^\d{10}$').hasMatch(phone)) {
        setState(() {
          _phoneError = 'Please enter a valid phone number';
        });
        return;
      }
    });
  }

  // Google Sign-In disabled for technicians - Phone OTP is mandatory first step
  // See technical specification: Phone → OTP Verify → Basic Details → Documents → Services → Review → Submit

  Future<void> _verifyPhone() async {
    _validatePhone();
    if (_phoneError != null) return;

    final phone = _phoneController.text.trim();

    setState(() => _isLoading = true);

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: "+91$phone",
        verificationCompleted: (PhoneAuthCredential credential) async {
          try {
            await FirebaseAuth.instance.signInWithCredential(credential);
          } catch (e) {
            debugPrint('Auto verification error: $e');
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          if (mounted) {
            setState(() => _isLoading = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(_getPhoneErrorMessage(e)),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        codeSent: (String verificationId, int? resendToken) {
          if (mounted) {
            setState(() => _isLoading = false);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => OtpScreen(
                  verificationId: verificationId,
                  phoneNumber: "+91$phone",
                ),
              ),
            );
          }
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          // Handle timeout - could show resend option
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _getPhoneErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-phone-number':
        return 'Invalid phone number format.';
      case 'quota-exceeded':
        return 'Too many requests. Please wait 30-60 seconds before trying again.';
      case 'too-many-requests':
        return 'Too many requests. Please wait a moment and try again.';
      case 'device-blocked':
        return 'This device has been temporarily blocked. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';
      case 'user-disabled':
        return 'This phone number has been disabled. Please contact support.';
      case 'session-expired':
        return 'Session expired. Please request a new OTP.';
      default:
        return e.message ?? 'Verification failed. Please try again.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 60),
              // Logo or App Name
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.build_circle_rounded,
                  color: Color(0xFF6366F1),
                  size: 32,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                "Welcome Technician 👋",
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F172A),
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Login to manage your services and jobs.",
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  color: const Color(0xFF64748B),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 48),
              
              Text(
                "Phone Number",
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                decoration: InputDecoration(
                  hintText: "Enter your phone number",
                  prefixIcon: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Text(
                      "+91",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                  ),
                  errorText: _phoneError,
                  errorStyle: const TextStyle(
                    color: Colors.red,
                    fontSize: 12,
                  ),
                ),
                onChanged: (_) {
                  if (_phoneError != null) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        setState(() => _phoneError = null);
                      }
                    });
                  }
                },
              ),
              const SizedBox(height: 32),
              // Phone OTP is MANDATORY for technicians
              // This is the entry gate to the onboarding flow
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _verifyPhone,
                  icon: _isLoading && !_isGoogleLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.phone),
                  label: Text(
                    'Continue with Phone',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(height: 60),
              Center(
                child: RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: const Color(0xFF64748B),
                      height: 1.5,
                    ),
                    children: const [
                      TextSpan(text: "By continuing, you agree to our "),
                      TextSpan(
                        text: "Terms of Service",
                        style: TextStyle(
                          color: Color(0xFF6366F1),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

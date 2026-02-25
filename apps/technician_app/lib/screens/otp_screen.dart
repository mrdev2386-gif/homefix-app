import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../core/providers/technician_provider.dart';

class OtpScreen extends StatefulWidget {
  final String verificationId;
  final String phoneNumber;

  const OtpScreen({
    super.key,
    required this.verificationId,
    required this.phoneNumber,
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final List<TextEditingController> _controllers = List.generate(6, (index) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());
  bool _isLoading = false;
  bool _isResending = false; // Rate guard to prevent OTP spam
  int _timerSeconds = 30;
  Timer? _timer;
  late String _currentVerificationId;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _currentVerificationId = widget.verificationId;
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var node in _focusNodes) node.dispose();
    for (var controller in _controllers) controller.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timerSeconds = 30;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_timerSeconds == 0) {
        timer.cancel();
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() => _timerSeconds--);
          }
        });
      }
    });
  }

  bool get _isOtpComplete => _controllers.every((c) => c.text.isNotEmpty);

  void _clearError() {
    if (_errorMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() => _errorMessage = null);
        }
      });
    }
  }

  Future<void> _handleVerify() async {
    String otp = _controllers.map((c) => c.text).join();
    if (otp.length < 6) {
      setState(() => _errorMessage = 'Please enter the complete 6-digit code');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _currentVerificationId,
        smsCode: otp,
      );
      
      // Sign in with credential
      await FirebaseAuth.instance.signInWithCredential(credential);
      
      // ✅ CRITICAL: After successful OTP, create technician draft profile
      // This ensures resume-on-reopen works properly
      if (mounted) {
        try {
          final provider = context.read<TechnicianProvider>();
          await provider.createOnboardingDraft(
            phone: widget.phoneNumber.replaceAll('+91', ''),
          );
          debugPrint('[OtpScreen] Draft profile created successfully');
        } catch (e) {
          debugPrint('[OtpScreen] Error creating draft: $e');
          // Continue anyway - the onboarding screen will handle creating draft if needed
        }
        
        // Navigate back to root - AuthGate will handle routing
        Navigator.popUntil(context, (route) => route.isFirst);
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = _getOtpErrorMessage(e);
        });
        // Clear the OTP fields on error
        for (var controller in _controllers) {
          controller.clear();
        }
        _focusNodes[0].requestFocus();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'An unexpected error occurred. Please try again.';
        });
      }
    }
  }

  String _getOtpErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-verification-code':
        return 'Invalid OTP. Please enter the correct code.';
      case 'session-expired':
        return 'Session expired. Please request a new OTP.';
      case 'quota-exceeded':
        return 'Too many attempts. Please wait 30-60 seconds before trying again.';
      case 'too-many-requests':
        return 'Too many requests. Please wait a moment and try again.';
      case 'device-blocked':
        return 'This device has been temporarily blocked. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';
      case 'invalid-phone-number':
        return 'Invalid phone number. Please try again.';
      case 'user-disabled':
        return 'This account has been disabled. Please contact support.';
      default:
        return e.message ?? 'Verification failed. Please try again.';
    }
  }

  String _getResendErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'quota-exceeded':
        return 'Too many OTP requests. Please wait 30 seconds before requesting again.';
      case 'too-many-requests':
        return 'Too many requests. Please wait a moment and try again.';
      case 'device-blocked':
        return 'This device is temporarily blocked. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Please check your internet and try again.';
      case 'session-expired':
        return 'Session expired. Please request a new OTP.';
      default:
        return e.message ?? 'Failed to resend OTP. Please try again.';
    }
  }

  Future<void> _resendCode() async {
    // Additional rate limiting check - minimum 30 seconds between requests
    if (_timerSeconds > 0 || _isLoading || _isResending) {
      if (_timerSeconds > 0) {
        setState(() {
          _errorMessage = 'Please wait ${_timerSeconds} seconds before requesting a new code.';
        });
      }
      return;
    }
    
    setState(() {
      _isResending = true;
      _errorMessage = null;
    });
    
    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: widget.phoneNumber,
        codeSent: (verificationId, resendToken) {
          if (mounted) {
            setState(() {
              _currentVerificationId = verificationId;
              _isResending = false;
              _startTimer();
            });
            // Show success message
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('New OTP sent successfully'),
                backgroundColor: Colors.green,
              ),
            );
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          if (mounted) {
            setState(() {
              _isResending = false;
              _errorMessage = _getResendErrorMessage(e);
            });
          }
        },
        verificationCompleted: (credential) async {
          await FirebaseAuth.instance.signInWithCredential(credential);
          if (mounted) Navigator.popUntil(context, (route) => route.isFirst);
        },
        codeAutoRetrievalTimeout: (id) {
          // Handle timeout - user can try resend after timer
          if (mounted) {
            setState(() {
              _isResending = false;
            });
          }
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isResending = false;
          _errorMessage = 'Failed to resend OTP. Please try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Text(
                'Verify Account',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F172A),
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 12),
              RichText(
                text: TextSpan(
                  style: GoogleFonts.plusJakartaSans(
                    color: const Color(0xFF64748B),
                    fontSize: 16,
                    height: 1.5,
                  ),
                  children: [
                    const TextSpan(text: 'Enter the verification code we just sent to '),
                    TextSpan(
                      text: widget.phoneNumber,
                      style: const TextStyle(
                        color: Color(0xFF0F172A),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),
              
              // Error message display
              if (_errorMessage != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: _clearError,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(6, (index) {
                  return SizedBox(
                    width: 48,
                    height: 60,
                    child: TextFormField(
                      controller: _controllers[index],
                      focusNode: _focusNodes[index],
                      autofocus: index == 0,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      maxLength: 1,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F172A),
                      ),
                      decoration: InputDecoration(
                        counterText: '',
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
                        ),
                      ),
                      onChanged: (value) {
                        _clearError();
                        if (value.isNotEmpty) {
                          if (index < 5) {
                            _focusNodes[index + 1].requestFocus();
                          } else {
                            _focusNodes[index].unfocus();
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              _handleVerify();
                            });
                          }
                        } else if (index > 0) {
                          _focusNodes[index - 1].requestFocus();
                        }
                      },
                    ),
                  );
                }),
              ),
              
              const SizedBox(height: 48),
              
              SizedBox(
                width: double.infinity,
                height: 58,
                child: ElevatedButton(
                  onPressed: (_isLoading || !_isOtpComplete) ? null : _handleVerify,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F172A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          'Verify & Continue',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),
              
              const SizedBox(height: 32),
              
              Center(
                child: _timerSeconds > 0
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Resend code in ',
                            style: GoogleFonts.plusJakartaSans(color: const Color(0xFF64748B)),
                          ),
                          Text(
                            '0:${_timerSeconds.toString().padLeft(2, '0')}',
                            style: GoogleFonts.plusJakartaSans(
                              color: const Color(0xFF0F172A),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      )
                    : TextButton(
                        onPressed: _resendCode,
                        child: Text(
                          'Resend Code',
                          style: GoogleFonts.plusJakartaSans(
                            color: const Color(0xFF6366F1),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

}

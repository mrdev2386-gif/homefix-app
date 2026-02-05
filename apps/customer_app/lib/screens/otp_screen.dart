import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/app_theme.dart';
import '../core/auth/auth_service.dart';

class OtpScreen extends StatefulWidget {
  final String verificationId;
  final String phoneNumber;
  final String? referralCode;

  const OtpScreen({
    super.key,
    required this.verificationId,
    required this.phoneNumber,
    this.referralCode,
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final List<TextEditingController> _controllers = List.generate(6, (index) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());
  final _authService = AuthService();
  bool _isLoading = false;
  int _timerSeconds = 30;
  Timer? _timer;


  @override
  void dispose() {
    _timer?.cancel();
    for (var node in _focusNodes) {
      node.dispose();
    }
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timerSeconds == 0) {
        timer.cancel();
      } else {
        setState(() {
          _timerSeconds--;
        });
      }
    });
  }

  bool get _isOtpComplete => _controllers.every((c) => c.text.isNotEmpty);

  void _handleVerify() async {
    String otp = _controllers.map((c) => c.text).join();
    if (otp.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter all 6 digits'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.black87,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      debugPrint("OtpScreen: Verifying OTP $otp...");
      await _authService.signInWithOTP(_currentVerificationId, otp, referredBy: widget.referralCode);
      debugPrint("OtpScreen: Success!");
      if (mounted) {
        // Pop back to root - AuthGate will handle splash/dashboard
        Navigator.popUntil(context, (route) => route.isFirst);
      }
    } catch (e) {
      debugPrint("OtpScreen: Error $e");
      if (mounted) {
        setState(() => _isLoading = false);
        // Clear OTP fields on error? Or just show error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Invalid code. Please check and try again.'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  late String _currentVerificationId;

  @override
  void initState() {
    super.initState();
    _currentVerificationId = widget.verificationId;
    _startTimer();
  }

  void _resendCode() async {
    if (_timerSeconds > 0 || _isLoading) return;
    
    setState(() => _isLoading = true);
    try {
      await _authService.verifyPhoneNumber(
        phoneNumber: widget.phoneNumber,
        onCodeSent: (verificationId, resendToken) {
          if (mounted) {
            setState(() {
              _currentVerificationId = verificationId;
              _timerSeconds = 30;
              _isLoading = false;
              _startTimer();
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('OTP Resent!'), behavior: SnackBarBehavior.floating),
            );
          }
        },
        onVerificationFailed: (e) {
          if (mounted) {
            setState(() => _isLoading = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(e.message ?? 'Resend failed'), behavior: SnackBarBehavior.floating),
            );
          }
        },
        onVerificationCompleted: (credential) async {
          // Auto-verify if possible
          await _authService.signInWithCredential(credential);
          if (mounted) Navigator.popUntil(context, (route) => route.isFirst);
        },
      );
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.mark_email_read_outlined, color: AppTheme.primaryColor, size: 32),
              ),
              const SizedBox(height: 24),
              Text(
                'Verification Code',
                style: GoogleFonts.outfit(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textColor,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 12),
              RichText(
                text: TextSpan(
                  style: GoogleFonts.outfit(fontSize: 16, color: Colors.grey[600], height: 1.5),
                  children: [
                    const TextSpan(text: 'We have sent a 6-digit code to\n'),
                    TextSpan(
                      text: widget.phoneNumber,
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textColor),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),
              
              // OTP Input Grid
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(6, (index) {
                  return SizedBox(
                    width: 48,
                    height: 56,
                    child: TextFormField(
                      controller: _controllers[index],
                      focusNode: _focusNodes[index],
                      autofocus: index == 0,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      maxLength: 1,
                      style: GoogleFonts.outfit(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                      decoration: InputDecoration(
                        counterText: '',
                        filled: true,
                        fillColor: Colors.grey[50],
                        contentPadding: EdgeInsets.zero,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: Colors.grey[200]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
                        ),
                      ),
                      onChanged: (value) {
                        if (value.isNotEmpty) {
                          if (index < 5) {
                            _focusNodes[index + 1].requestFocus();
                          } else {
                            _focusNodes[index].unfocus();
                            _handleVerify();
                          }
                        } else {
                          if (index > 0) {
                            _focusNodes[index - 1].requestFocus();
                          }
                        }
                        setState(() {}); // Refresh for button state
                      },
                    ),
                  );
                }),
              ),
              
              const SizedBox(height: 48),
              
              // Verify Button
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: (_isLoading || !_isOtpComplete) ? null : _handleVerify,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    disabledBackgroundColor: AppTheme.primaryColor.withOpacity(0.5),
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
                          'Verify & Continue',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Resend Timer
              Center(
                child: Column(
                  children: [
                    _timerSeconds > 0
                        ? RichText(
                            text: TextSpan(
                              style: GoogleFonts.outfit(color: Colors.grey[600], fontSize: 15),
                              children: [
                                const TextSpan(text: "Didn't receive code? "),
                                TextSpan(
                                  text: '00:$_timerSeconds',
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textColor),
                                ),
                              ],
                            ),
                          )
                        : TextButton.icon(
                            onPressed: _resendCode,
                            icon: const Icon(Icons.refresh_rounded, size: 20),
                            label: Text(
                              'Resend Code',
                              style: GoogleFonts.outfit(
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

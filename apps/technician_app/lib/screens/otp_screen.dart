import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
  int _timerSeconds = 30;
  Timer? _timer;
  late String _currentVerificationId;

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
      if (_timerSeconds == 0) {
        timer.cancel();
      } else {
        setState(() => _timerSeconds--);
      }
    });
  }

  bool get _isOtpComplete => _controllers.every((c) => c.text.isNotEmpty);

  Future<void> _handleVerify() async {
    String otp = _controllers.map((c) => c.text).join();
    if (otp.length < 6) return;

    setState(() => _isLoading = true);
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _currentVerificationId,
        smsCode: otp,
      );
      await FirebaseAuth.instance.signInWithCredential(credential);
      if (mounted) {
        Navigator.popUntil(context, (route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid code pill. Please try again.')),
        );
      }
    }
  }

  Future<void> _resendCode() async {
    if (_timerSeconds > 0 || _isLoading) return;
    
    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: widget.phoneNumber,
        codeSent: (verificationId, resendToken) {
          if (mounted) {
            setState(() {
              _currentVerificationId = verificationId;
              _isLoading = false;
              _startTimer();
            });
          }
        },
        verificationFailed: (e) {
          if (mounted) {
            setState(() => _isLoading = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Failed: ${e.message}")),
            );
          }
        },
        verificationCompleted: (credential) async {
          await FirebaseAuth.instance.signInWithCredential(credential);
          if (mounted) Navigator.popUntil(context, (route) => route.isFirst);
        },
        codeAutoRetrievalTimeout: (id) {},
      );
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
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
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black),
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
                'Verify Phone',
                style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                'Enter the 6-digit code sent to ${widget.phoneNumber}',
                style: GoogleFonts.outfit(color: Colors.grey[600], fontSize: 16),
              ),
              const SizedBox(height: 48),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(6, (index) {
                  return SizedBox(
                    width: 45,
                    height: 55,
                    child: TextFormField(
                      controller: _controllers[index],
                      focusNode: _focusNodes[index],
                      autofocus: index == 0,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      maxLength: 1,
                      style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        counterText: '',
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[200]!)),
                      ),
                      onChanged: (value) {
                        if (value.isNotEmpty) {
                          if (index < 5) {
                            _focusNodes[index + 1].requestFocus();
                          } else {
                            _focusNodes[index].unfocus();
                            _handleVerify();
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
                height: 56,
                child: ElevatedButton(
                  onPressed: (_isLoading || !_isOtpComplete) ? null : _handleVerify,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F172A),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Verify & Continue', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
              
              const SizedBox(height: 32),
              
              Center(
                child: _timerSeconds > 0
                    ? Text('Resend code in 0:$_timerSeconds', style: GoogleFonts.outfit(color: Colors.grey))
                    : TextButton(
                        onPressed: _resendCode,
                        child: Text('Resend Code', style: GoogleFonts.outfit(color: const Color(0xFF6366F1), fontWeight: FontWeight.bold)),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

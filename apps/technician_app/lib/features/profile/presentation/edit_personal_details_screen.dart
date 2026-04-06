import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/providers/technician_provider.dart';
import '../../../core/app_theme.dart';
import '../../../core/services/functions_service.dart';
import '../../../core/widgets/location_selector.dart';

class EditPersonalDetailsScreen extends StatefulWidget {
  const EditPersonalDetailsScreen({super.key});

  @override
  State<EditPersonalDetailsScreen> createState() => _EditPersonalDetailsScreenState();
}

class _EditPersonalDetailsScreenState extends State<EditPersonalDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _cityController = TextEditingController();
  final _experienceController = TextEditingController();
  final _bioController = TextEditingController();
  final _alternatePhoneController = TextEditingController();
  final _functionsService = FunctionsService();
  
  bool _isSaving = false;
  bool _isVerifyingEmail = false;
  bool _isCheckingVerification = false;
  String? _selectedGender;
  String? _phoneNumber;
  String? _alternatePhone;
  String? _originalEmail;
  bool _emailVerified = false;
  Timer? _autoCheckTimer;
  String? _selectedState;
  String? _selectedDistrict;
  
  final List<String> _genderOptions = ['Male', 'Female', 'Other'];

  @override
  void initState() {
    super.initState();
    _loadCurrentData();
  }

  void _loadCurrentData() async {
    final provider = context.read<TechnicianProvider>();
    final technician = provider.technician;
    final user = FirebaseAuth.instance.currentUser;
    
    if (technician != null) {
      _nameController.text = technician.name;
      _emailController.text = technician.email ?? user?.email ?? '';
      _originalEmail = technician.email ?? user?.email;
      _selectedState = technician.state;
      _selectedDistrict = technician.district;
      _experienceController.text = technician.experienceYears?.toString() ?? '';
      _bioController.text = technician.bio ?? '';
      _selectedGender = technician.gender;
      _phoneNumber = technician.phone;
      _alternatePhone = technician.alternatePhone;
      _emailVerified = user?.emailVerified ?? false;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _cityController.dispose();
    _experienceController.dispose();
    _bioController.dispose();
    _alternatePhoneController.dispose();
    _autoCheckTimer?.cancel();
    super.dispose();
  }

  bool _hasEmailChanged() {
    return _emailController.text.trim() != (_originalEmail ?? '');
  }

  Future<void> _sendVerificationEmail() async {
    if (_isVerifyingEmail) return;
    
    final email = _emailController.text.trim();
    if (email.isEmpty || !_isValidEmail(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid email address'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isVerifyingEmail = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (!mounted) return;
        _showErrorSnackbar('User not authenticated');
        return;
      }

      // Step 1: Attach email to Firebase user (for phone-auth users)
        await user.verifyBeforeUpdateEmail(email);

      // Step 2: Send verification email
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
      }

      if (!mounted) return;
      
      // Start auto-check timer every 5 seconds
      _startAutoCheckTimer();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Verification link sent to $email. Please check your inbox.'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 5),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      // Don't block app - just show warning
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Verification email failed: ${e.toString()}'),
          backgroundColor: Colors.orange,
        ),
      );
    } finally {
      if (mounted) setState(() => _isVerifyingEmail = false);
    }
  }

  // ISSUE 4 FIX: Auto-check verification status every 5 seconds
  void _startAutoCheckTimer() {
    if (_autoCheckTimer != null && _autoCheckTimer!.isActive) return;
    _autoCheckTimer?.cancel();
    _autoCheckTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      if (!mounted || _emailVerified) {
        timer.cancel();
        return;
      }
      await _checkVerificationStatus(silent: true);
    });
  }


  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<void> _checkVerificationStatus({bool silent = false}) async {
    if (_isCheckingVerification && !silent) return;

    if (!silent && mounted) setState(() => _isCheckingVerification = true);

    try {
      await FirebaseAuth.instance.currentUser?.reload();
      final refreshedUser = FirebaseAuth.instance.currentUser;
      
      if (refreshedUser == null) {
        if (!mounted || silent) return;
        _showErrorSnackbar('User not authenticated');
        return;
      }

      final isVerified = refreshedUser.emailVerified;
      print("Email verified: ${refreshedUser.emailVerified}");

      if (mounted) {
        setState(() {
          _emailVerified = isVerified;
        });
      }

        // UPDATE: Request profile refresh from backend to sync verification status
        try {
          await context.read<TechnicianProvider>().refreshTechnician();
        } catch (e) {
          debugPrint('Failed to refresh profile after email verify: $e');
        }

      if (!mounted) return;
      
      if (_emailVerified) {
        _autoCheckTimer?.cancel();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Email verified successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      } else if (!silent) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Email not verified yet. Please check your inbox.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (!mounted || silent) return;
      // Don't block app - just show warning
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Verification check failed: ${e.toString()}'),
          backgroundColor: Colors.orange,
        ),
      );
    } finally {
      if (mounted && !silent) setState(() => _isCheckingVerification = false);
    }
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isSaving) return;

    // Validate name is required
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Name is required'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final email = _emailController.text.trim();
      
      debugPrint('[ProfileEdit] Saving profile data...');
      debugPrint('[ProfileEdit] fullName: ${_nameController.text.trim()}');
      debugPrint('[ProfileEdit] state: $_selectedState');
      debugPrint('[ProfileEdit] district: $_selectedDistrict');
      debugPrint('[ProfileEdit] experienceYears: ${int.tryParse(_experienceController.text)}');
      debugPrint('[ProfileEdit] alternatePhone: ${_alternatePhone?.trim()}');
      
      // Call Cloud Function and await completion
      final result = await _functionsService.updateTechnicianPersonalDetails(
        fullName: _nameController.text.trim(),
        email: email.isEmpty ? null : email,
        city: _cityController.text.trim().isEmpty ? null : _cityController.text.trim(),
        state: _selectedState,
        district: _selectedDistrict,
        experienceYears: int.tryParse(_experienceController.text),
        gender: _selectedGender,
        bio: _bioController.text.trim().isEmpty ? null : _bioController.text.trim(),
        alternatePhone: _alternatePhone?.trim(),
      );

      debugPrint('[ProfileEdit] Cloud Function result: $result');

      if (!mounted) return;

      debugPrint('[ProfileEdit] Forcing provider refresh...');
      // Force refresh technician data from server
      await context.read<TechnicianProvider>().refreshTechnician();
      debugPrint('[ProfileEdit] Provider refresh complete');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Personal details updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      debugPrint('[ProfileEdit] Error saving profile: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text('Edit Personal Details'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Name is required';
                  }
                  if (value.trim().length < 2) {
                    return 'Name must be at least 2 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                initialValue: _phoneNumber,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
                readOnly: true,
                enabled: false,
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.email),
                  suffixIcon: _hasEmailChanged()
                      ? Icon(
                          _emailVerified ? Icons.verified : Icons.warning,
                          color: _emailVerified ? Colors.green : Colors.red,
                        )
                      : null,
                ),
                keyboardType: TextInputType.emailAddress,
                onChanged: (_) => setState(() {}),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Email is required';
                  }
                  if (!_isValidEmail(value.trim())) {
                    return 'Enter a valid email address';
                  }
                  return null;
                },
              ),
              if (_hasEmailChanged())
                const SizedBox(height: 8),
              if (_hasEmailChanged() && !_emailVerified)
                OutlinedButton.icon(
                  onPressed: _isVerifyingEmail ? null : _sendVerificationEmail,
                  icon: _isVerifyingEmail
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send),
                  label: Text(
                    _isVerifyingEmail
                        ? 'Sending...'
                        : 'Verify Email',
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primaryColor,
                    side: const BorderSide(color: AppTheme.primaryColor),
                  ),
                ),
              if (_hasEmailChanged() && !_emailVerified)
                const SizedBox(height: 8),
              if (_hasEmailChanged() && !_emailVerified)
                ElevatedButton.icon(
                  onPressed: () => _checkVerificationStatus(silent: false),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Check Verification'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              if (_hasEmailChanged())
                const SizedBox(height: 8),
              if (_hasEmailChanged())
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _emailVerified ? Colors.green.shade50 : Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _emailVerified ? Colors.green : Colors.orange,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _emailVerified ? Icons.check_circle : Icons.schedule,
                        color: _emailVerified ? Colors.green : Colors.orange,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _emailVerified
                              ? '✓ Email Verified'
                              : 'Verification email sent. Checking automatically...',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: _emailVerified ? FontWeight.bold : FontWeight.normal,
                            color: _emailVerified ? Colors.green.shade900 : Colors.orange.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
              LocationSelector(
                initialState: _selectedState,
                initialDistrict: _selectedDistrict,
                onLocationChanged: (state, district) {
                  setState(() {
                    _selectedState = state;
                    _selectedDistrict = district;
                  });
                },
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _experienceController,
                decoration: const InputDecoration(
                  labelText: 'Years of Experience',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.work),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              const SizedBox(height: 16),
              
              DropdownButtonFormField<String>(
                value: _selectedGender,
                decoration: const InputDecoration(
                  labelText: 'Gender',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.wc),
                ),
                items: _genderOptions.map((gender) => DropdownMenuItem(
                  value: gender,
                  child: Text(gender),
                )).toList(),
                onChanged: (value) {
                  setState(() => _selectedGender = value);
                },
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                initialValue: _alternatePhone,
                decoration: const InputDecoration(
                  labelText: 'Alternative Phone Number (Optional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone_forwarded),
                  hintText: '+91 XXXXXXXXXX',
                ),
                keyboardType: TextInputType.phone,
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9+\-\s]'))],
                onChanged: (value) => _alternatePhone = value,
                validator: (value) {
                  if (value != null && value.trim().isNotEmpty) {
                    final cleaned = value.replaceAll(RegExp(r'[\s\-]'), '');
                    if (!RegExp(r'^[+]?[0-9]{10,15}$').hasMatch(cleaned)) {
                      return 'Enter a valid phone number';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _bioController,
                decoration: const InputDecoration(
                  labelText: 'Bio (Optional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
                maxLength: 500,
              ),
              const SizedBox(height: 24),
              
              ElevatedButton(
                onPressed: _isSaving ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Save Changes',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

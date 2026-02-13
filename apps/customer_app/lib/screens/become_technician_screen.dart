import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

class BecomeTechnicianScreen extends StatefulWidget {
  const BecomeTechnicianScreen({super.key});

  @override
  State<BecomeTechnicianScreen> createState() => _BecomeTechnicianScreenState();
}

class _BecomeTechnicianScreenState extends State<BecomeTechnicianScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  bool _isLoading = false;
  String? _applicationStatus;

  // Form controllers
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _experienceController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _pincodeController = TextEditingController();
  final TextEditingController _bankNameController = TextEditingController();
  final TextEditingController _accountNumberController = TextEditingController();
  final TextEditingController _ifscController = TextEditingController();
  final TextEditingController _accountHolderController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();

  // Data
  List<Map<String, dynamic>> _categories = [];
  Map<String, List<Map<String, dynamic>>> _subcategories = {};
  
  // Selection
  final Map<String, List<String>> _selectedSubcategories = {}; // categoryId -> [subIds]
  
  XFile? _idProof;
  XFile? _profilePhoto;
  bool _agreedToTerms = false;
  
  // Verification
  bool _isEmailVerified = false;
  bool _isPhoneVerified = false;
  String? _verificationId;
  bool _otpSent = false;

  @override
  void initState() {
    super.initState();
    _checkApplicationStatus();
    _fetchMasterData();
    _prefillUserData();
    _checkVerificationStatus();
  }

  Future<void> _checkApplicationStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('technician_applications')
        .doc(user.uid)
        .get();

    if (doc.exists && mounted) {
      setState(() {
        _applicationStatus = doc.data()?['status'];
      });
    }
  }

  Future<void> _fetchMasterData() async {
    try {
      final catSnapshot = await FirebaseFirestore.instance
          .collection('technician_categories')
          .where('isActive', isEqualTo: true)
          .orderBy('order')
          .get();

      final subSnapshot = await FirebaseFirestore.instance
          .collection('technician_subcategories')
          .where('isActive', isEqualTo: true)
          .orderBy('order')
          .get();

      if (!mounted) return;

      final categories = catSnapshot.docs.map((doc) => doc.data()).toList();
      final Map<String, List<Map<String, dynamic>>> subs = {};

      for (var doc in subSnapshot.docs) {
        final data = doc.data();
        final catId = data['categoryId'] as String;
        if (!subs.containsKey(catId)) subs[catId] = [];
        subs[catId]!.add(data);
      }

      setState(() {
        _categories = categories;
        _subcategories = subs;
      });
    } catch (e) {
      debugPrint('Error fetching master data: $e');
      if (mounted) _showError('Failed to load services. Please check your connection.');
    }
  }

  void _prefillUserData() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _nameController.text = user.displayName ?? '';
      _emailController.text = user.email ?? '';
      _phoneController.text = user.phoneNumber ?? '';
    }
  }

  Future<void> _checkVerificationStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await user.reload();
      setState(() {
        _isEmailVerified = user.emailVerified;
        _isPhoneVerified = user.phoneNumber != null && user.phoneNumber!.isNotEmpty;
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _experienceController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _pincodeController.dispose();
    _bankNameController.dispose();
    _accountNumberController.dispose();
    _ifscController.dispose();
    _accountHolderController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  // ... [Image picking and Upload logic remains similar] ...
  Future<void> _pickImage(bool isIdProof) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);

    if (pickedFile != null) {
      setState(() {
        if (isIdProof) {
          _idProof = pickedFile;
        } else {
          _profilePhoto = pickedFile;
        }
      });
    }
  }

  Future<String?> _uploadFile(XFile file, String path, {String? userId}) async {
    try {
      final ref = FirebaseStorage.instance.ref().child(path);
      // FIX: Add required metadata for storage.rules validation
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {
          'uploadedAt': DateTime.now().toIso8601String(),
          if (userId != null) 'userId': userId,
        },
      );
      final uploadTask = await ref.putData(await file.readAsBytes(), metadata);
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      debugPrint('Upload error: $e');
      return null;
    }
  }

  // ... [Verification Logic] ...
  Future<void> _sendEmailVerification() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.sendEmailVerification();
        _showMessage('Verification email sent to ${user.email}', Colors.blue);
      }
    } catch (e) {
      _showError(e.toString());
    }
  }

  Future<void> _verifyPhone() async {
    if (_phoneController.text.isEmpty) {
      _showError('Enter phone number');
      return;
    }
    
    setState(() => _isLoading = true);
    
    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: _phoneController.text.startsWith('+') ? _phoneController.text : '+91${_phoneController.text}',
        verificationCompleted: (PhoneAuthCredential credential) async {
          await FirebaseAuth.instance.currentUser!.linkWithCredential(credential);
          _showMessage('Phone verified automatically!', Colors.green);
          setState(() {
            _isPhoneVerified = true;
            _isLoading = false;
          });
        },
        verificationFailed: (FirebaseAuthException e) {
          _showError(e.message ?? 'Verification failed');
          setState(() => _isLoading = false);
        },
        codeSent: (String verificationId, int? resendToken) {
          setState(() {
            _verificationId = verificationId;
            _otpSent = true;
            _isLoading = false;
          });
          _showMessage('OTP sent!', Colors.blue);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
           _verificationId = verificationId;
        },
      );
    } catch (e) {
      _showError(e.toString());
      setState(() => _isLoading = false);
    }
  }

  Future<void> _submitOTP() async {
    if (_verificationId == null || _otpController.text.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: _otpController.text,
      );
      
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
         // Link/Update phone
         if (user.phoneNumber == null) {
           await user.linkWithCredential(credential);
         } else {
           await user.updatePhoneNumber(credential);
         }
      }
      
      setState(() {
        _isPhoneVerified = true;
        _otpSent = false;
        _isLoading = false;
      });
      _showMessage('Phone verified successfully!', Colors.green);
    } catch (e) {
      _showError('Invalid OTP');
      setState(() => _isLoading = false);
    }
  }

  // ... [Submission Logic] ...
  Future<void> _submitApplication() async {
    if (!_formKey.currentState!.validate()) return;
    
    // Check if any subcategory is selected
    bool hasSelection = _selectedSubcategories.values.any((list) => list.isNotEmpty);
    if (!hasSelection) {
      _showError('Please select at least one service category and subcategory');
      return;
    }
    
    if (_idProof == null) {
      _showError('Please upload ID proof');
      return;
    }
    if (!_agreedToTerms) {
      _showError('Please agree to terms and conditions');
      return;
    }
    if (!_isEmailVerified && !_isPhoneVerified) {
       _showError('Please complete contact verification');
       return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw 'User not logged in';

      // Upload documents with userId metadata for storage.rules validation
      final idProofUrl = await _uploadFile(_idProof!, 'technician_docs/${user.uid}/id_proof.jpg', userId: user.uid);
      String? profilePhotoUrl;
      if (_profilePhoto != null) {
        profilePhotoUrl = await _uploadFile(_profilePhoto!, 'technician_docs/${user.uid}/profile_photo.jpg', userId: user.uid);
      }

      // Flatten selected services for easy querying
      List<String> selectedCatIds = _selectedSubcategories.keys.where((k) => _selectedSubcategories[k]!.isNotEmpty).toList();
      List<String> selectedSubIds = [];
      _selectedSubcategories.forEach((_, subs) => selectedSubIds.addAll(subs));

      // Call Cloud Function
      final HttpsCallable callable = FirebaseFunctions.instance.httpsCallable('submitFullApplication');
      
      final Map<String, dynamic> payload = {
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'address': _addressController.text.trim(),
        'city': _cityController.text.trim(),
        'pinCode': _pincodeController.text.trim(),
        'experience': _experienceController.text.trim(),
        
        'bankName': _bankNameController.text.trim(),
        'accountNumber': _accountNumberController.text.trim(),
        'ifsc': _ifscController.text.trim(),
        'accountHolder': _accountHolderController.text.trim(),
        
        'categories': selectedCatIds,
        'subcategories': selectedSubIds,
        
        'idProofUrl': idProofUrl,
        'photoUrl': profilePhotoUrl,
      };

      await callable.call(payload);

      setState(() => _applicationStatus = 'submitted');
      
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Application Submitted'),
            content: const Text(
                'Your application has been received and is under review. You will be notified once approved.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close dialog
                  Navigator.of(context).pop(); // Go back to profile/home
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
      
    } catch (e) {
      _showError('Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showMessage(String msg, Color color) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
    }
  }

  void _showError(String message) => _showMessage(message, Colors.red);

  void _nextStep() {
    if (_currentStep == 0) {
      if (!_isPhoneVerified && !_isEmailVerified) {
        _showError('Please verify at least one contact method');
        return;
      }
    }
    
    if (_currentStep < 7) {
      setState(() => _currentStep++);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_applicationStatus == 'pending') return _buildStatusScreen(Icons.access_time, Colors.orange, 'Under Review', 'Your application is being reviewed.');
    if (_applicationStatus == 'approved') return _buildStatusScreen(Icons.check_circle, Colors.green, 'Approved!', 'Welcome to the team!');
    if (_applicationStatus == 'rejected') return _buildStatusScreen(Icons.cancel, Colors.red, 'Rejected', 'Application was not approved.');

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Join as Partner', style: GoogleFonts.outfit(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: _isLoading && !_otpSent
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildProgressIndicator(),
                Expanded(
                  child: Form(
                    key: _formKey,
                    child: PageView(
                      controller: _pageController,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                         _buildVerificationStep(),
                        _buildPersonalDetailsStep(),
                        _buildServiceSelectionStep(),
                        _buildExperienceStep(),
                        _buildDocumentsStep(),
                        _buildAddressStep(),
                        _buildBankDetailsStep(),
                        _buildAgreementStep(),
                      ],
                    ),
                  ),
                ),
                _buildNavigationButtons(),
              ],
            ),
    );
  }

  Widget _buildStatusScreen(IconData icon, Color color, String title, String msg) {
    return Scaffold(
      appBar: AppBar(title: const Text('Status')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 80, color: color),
              const SizedBox(height: 24),
              Text(title, style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Text(msg, textAlign: TextAlign.center, style: GoogleFonts.outfit(color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVerificationStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           Text('Verification', style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold)),
           const SizedBox(height: 8),
           Text('Verify your contact details to proceed', style: GoogleFonts.outfit(color: Colors.grey)),
           const SizedBox(height: 32),
           
           // Email
           Container(
             padding: const EdgeInsets.all(16),
             decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(12)),
             child: Column(
               children: [
                 Row(
                   children: [
                     const Icon(Icons.email_outlined),
                     const SizedBox(width: 12),
                     Expanded(child: Text(_emailController.text.isEmpty ? 'Email Verification' : _emailController.text)),
                     if (_isEmailVerified) const Icon(Icons.check_circle, color: Colors.green)
                   ],
                 ),
                 if (!_isEmailVerified)
                   Padding(
                     padding: const EdgeInsets.only(top: 12),
                     child: ElevatedButton(
                       onPressed: _sendEmailVerification,
                       child: const Text('Send Verification Email'),
                     ),
                   )
               ],
             ),
           ),
           const SizedBox(height: 20),
           
           // Phone
           Container(
             padding: const EdgeInsets.all(16),
             decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(12)),
             child: Column(
               children: [
                 Row(
                   children: [
                     const Icon(Icons.phone_outlined),
                     const SizedBox(width: 12),
                     Expanded(child: TextFormField(
                       controller: _phoneController,
                       decoration: const InputDecoration(hintText: 'Phone Number', border: InputBorder.none),
                       keyboardType: TextInputType.phone,
                       enabled: !_isPhoneVerified,
                     )),
                     if (_isPhoneVerified) const Icon(Icons.check_circle, color: Colors.green)
                   ],
                 ),
                 if (!_isPhoneVerified && !_otpSent)
                   Padding(
                     padding: const EdgeInsets.only(top: 12),
                     child: ElevatedButton(
                       onPressed: _verifyPhone,
                       child: const Text('Verify Phone'),
                     ),
                   ),
                 if (_otpSent && !_isPhoneVerified)
                    Padding(
                     padding: const EdgeInsets.only(top: 12),
                     child: Row(
                       children: [
                         Expanded(child: TextField(controller: _otpController, decoration: const InputDecoration(hintText: 'Enter OTP'))),
                         const SizedBox(width: 8),
                         ElevatedButton(onPressed: _submitOTP, child: const Text('Submit')),
                       ],
                     ),
                   )
               ],
             ),
           ),
        ],
      ),
    );
  }

  Widget _buildPersonalDetailsStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Personal Details', style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 32),
          TextFormField(controller: _nameController, decoration: _inputDecoration('Full Name', Icons.person_outline), validator: (v) => v!.isEmpty ? 'Required' : null),
          const SizedBox(height: 16),
          TextFormField(controller: _emailController, decoration: _inputDecoration('Email', Icons.email_outlined), readOnly: _isEmailVerified),
          const SizedBox(height: 16),
          TextFormField(controller: _phoneController, decoration: _inputDecoration('Phone', Icons.phone_outlined), readOnly: _isPhoneVerified),
        ],
      ),
    );
  }

  Widget _buildServiceSelectionStep() {
    if (_categories.isEmpty) {
      return const Center(child: Text('Loading services...'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Your Skills', style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold)),
          Text('Select categories and specific skills', style: GoogleFonts.outfit(color: Colors.grey)),
          const SizedBox(height: 24),
          
          ..._categories.map((cat) {
             final isCatExpanded = _selectedSubcategories.containsKey(cat['id']);
             final subs = _subcategories[cat['id']] ?? [];
             
             return Container(
               margin: const EdgeInsets.only(bottom: 16),
               decoration: BoxDecoration(
                 border: Border.all(color: Colors.grey[200]!),
                 borderRadius: BorderRadius.circular(12),
               ),
               child: Column(
                 children: [
                   ListTile(
                     title: Text(cat['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                     trailing: Icon(isCatExpanded || _selectedSubcategories[cat['id']]?.isNotEmpty == true ? Icons.expand_less : Icons.expand_more),
                     onTap: () {
                         // Just expansion logic if needed, or select all?
                         // Let's just expand/collapse via UI state if we want better UX
                     },
                   ),
                   Padding(
                     padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                     child: Wrap(
                       spacing: 8,
                       runSpacing: 8,
                       children: subs.map((sub) {
                         final isSelected = _selectedSubcategories[cat['id']]?.contains(sub['id']) ?? false;
                         return FilterChip(
                           label: Text(sub['name']),
                           selected: isSelected,
                           onSelected: (selected) {
                             setState(() {
                               if (!_selectedSubcategories.containsKey(cat['id'])) {
                                 _selectedSubcategories[cat['id']] = [];
                               }
                               if (selected) {
                                 _selectedSubcategories[cat['id']]!.add(sub['id']);
                               } else {
                                 _selectedSubcategories[cat['id']]!.remove(sub['id']);
                               }
                             });
                           },
                           selectedColor: const Color(0xFF6366F1).withOpacity(0.2),
                           checkmarkColor: const Color(0xFF6366F1),
                         );
                       }).toList(),
                     ),
                   )
                 ],
               ),
             );
          }).toList(),
        ],
      ),
    );
  }
  
  // ... [Other Steps - Keeping similar implementation but ensuring concise code] ...
  
  Widget _buildExperienceStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Experience', style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 32),
          TextFormField(
            controller: _experienceController,
            decoration: _inputDecoration('Years of Experience', Icons.work_outline),
            keyboardType: TextInputType.number,
            validator: (v) => v!.isEmpty ? 'Required' : null,
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentsStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Documents', style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 32),
          _buildUploadButton('ID Proof *', _idProof, () => _pickImage(true), Icons.badge_outlined),
          const SizedBox(height: 16),
          _buildUploadButton('Profile Photo', _profilePhoto, () => _pickImage(false), Icons.photo_camera_outlined),
        ],
      ),
    );
  }

  Widget _buildAddressStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Address', style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 32),
          TextFormField(controller: _addressController, decoration: _inputDecoration('Full Address', Icons.location_on_outlined), maxLines: 2, validator: (v) => v!.isEmpty ? 'Required' : null),
          const SizedBox(height: 16),
          TextFormField(controller: _cityController, decoration: _inputDecoration('City', Icons.location_city_outlined), validator: (v) => v!.isEmpty ? 'Required' : null),
          const SizedBox(height: 16),
          TextFormField(controller: _pincodeController, decoration: _inputDecoration('Pincode', Icons.pin_drop_outlined), keyboardType: TextInputType.number, validator: (v) => v!.isEmpty ? 'Required' : null),
        ],
      ),
    );
  }

  Widget _buildBankDetailsStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Bank Details', style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 32),
          TextFormField(controller: _accountHolderController, decoration: _inputDecoration('Holder Name', Icons.person_outline), validator: (v) => v!.isEmpty ? 'Required' : null),
          const SizedBox(height: 16),
          TextFormField(controller: _bankNameController, decoration: _inputDecoration('Bank Name', Icons.account_balance_outlined), validator: (v) => v!.isEmpty ? 'Required' : null),
          const SizedBox(height: 16),
          TextFormField(controller: _accountNumberController, decoration: _inputDecoration('Account Number', Icons.credit_card_outlined), keyboardType: TextInputType.number, validator: (v) => v!.isEmpty ? 'Required' : null),
          const SizedBox(height: 16),
          TextFormField(controller: _ifscController, decoration: _inputDecoration('IFSC', Icons.code_outlined), validator: (v) => v!.isEmpty ? 'Required' : null),
        ],
      ),
    );
  }

  Widget _buildAgreementStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Agreement', style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 32),
          CheckboxListTile(
            value: _agreedToTerms,
            onChanged: (v) => setState(() => _agreedToTerms = v!),
            title: const Text('I agree to the terms and conditions'),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  Widget _buildUploadButton(String label, XFile? file, VoidCallback onTap, IconData icon) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          border: Border.all(color: file != null ? Colors.green : Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
          color: file != null ? Colors.green.withOpacity(0.05) : Colors.white,
        ),
        child: Row(
          children: [
            Icon(icon, color: file != null ? Colors.green : Colors.grey),
            const SizedBox(width: 16),
            Expanded(child: Text(file != null ? file.name : label, maxLines: 1, overflow: TextOverflow.ellipsis)),
            if (file != null) const Icon(Icons.check_circle, color: Colors.green) else const Icon(Icons.upload_outlined, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
     // Simple indicator
     return Container(
       height: 4, 
       margin: const EdgeInsets.all(20),
       child: LinearProgressIndicator(value: (_currentStep + 1) / 8, backgroundColor: Colors.grey[200], valueColor: const AlwaysStoppedAnimation(Color(0xFF6366F1))),
     );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: const Offset(0, -5))]),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(child: OutlinedButton(onPressed: _previousStep, child: const Text('Back'))),
          if (_currentStep > 0) const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _currentStep == 7 ? _submitApplication : _nextStep,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366F1), padding: const EdgeInsets.symmetric(vertical: 16)),
              child: Text(_currentStep == 7 ? 'Submit' : 'Next', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}

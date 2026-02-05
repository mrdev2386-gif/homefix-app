import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/foundation.dart';

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

  List<String> _selectedServices = [];
  XFile? _idProof;
  XFile? _profilePhoto;
  bool _agreedToTerms = false;

  final List<String> _availableServices = [
    'Plumbing',
    'Electrical',
    'Carpentry',
    'Painting',
    'AC Repair',
    'Appliance Repair',
    'Cleaning',
    'Pest Control',
  ];

  @override
  void initState() {
    super.initState();
    _checkApplicationStatus();
    _prefillUserData();
  }

  Future<void> _checkApplicationStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('technician_applications')
        .doc(user.uid)
        .get();

    if (doc.exists) {
      setState(() {
        _applicationStatus = doc.data()?['status'];
      });
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
    super.dispose();
  }

  Future<void> _pickImage(bool isIdProof) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

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

  Future<String?> _uploadFile(XFile file, String path) async {
    try {
      final ref = FirebaseStorage.instance.ref().child(path);
      final uploadTask = await ref.putData(await file.readAsBytes());
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      debugPrint('Upload error: $e');
      return null;
    }
  }

  Future<void> _submitApplication() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedServices.isEmpty) {
      _showError('Please select at least one service');
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

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw 'User not logged in';

      // Upload documents
      final idProofUrl = await _uploadFile(
        _idProof!,
        'technician_docs/${user.uid}/id_proof.jpg',
      );

      String? profilePhotoUrl;
      if (_profilePhoto != null) {
        profilePhotoUrl = await _uploadFile(
          _profilePhoto!,
          'technician_docs/${user.uid}/profile_photo.jpg',
        );
      }

      // Save application
      await FirebaseFirestore.instance
          .collection('technician_applications')
          .doc(user.uid)
          .set({
        'uid': user.uid,
        'name': _nameController.text,
        'email': _emailController.text,
        'phone': _phoneController.text,
        'serviceTypes': _selectedServices,
        'experience': _experienceController.text,
        'address': _addressController.text,
        'city': _cityController.text,
        'pincode': _pincodeController.text,
        'bankName': _bankNameController.text,
        'accountNumber': _accountNumberController.text,
        'ifsc': _ifscController.text,
        'accountHolder': _accountHolderController.text,
        'idProofUrl': idProofUrl,
        'profilePhotoUrl': profilePhotoUrl,
        'status': 'pending',
        'appliedAt': FieldValue.serverTimestamp(),
      });

      setState(() {
        _applicationStatus = 'pending';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Application submitted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      _showError('Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _nextStep() {
    if (_currentStep < 6) {
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
    if (_applicationStatus == 'pending') {
      return _buildPendingScreen();
    }

    if (_applicationStatus == 'approved') {
      return _buildApprovedScreen();
    }

    if (_applicationStatus == 'rejected') {
      return _buildRejectedScreen();
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Become a Technician',
          style: GoogleFonts.outfit(
            color: const Color(0xFF1F2937),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
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
                      onPageChanged: (index) => setState(() => _currentStep = index),
                      children: [
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

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: List.generate(7, (index) {
          final isActive = index <= _currentStep;
          return Expanded(
            child: Container(
              height: 4,
              margin: EdgeInsets.only(right: index < 6 ? 8 : 0),
              decoration: BoxDecoration(
                color: isActive ? const Color(0xFF6366F1) : Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
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
            Expanded(
              child: Text(
                file != null ? file.name : label,
                style: GoogleFonts.outfit(
                  fontWeight: file != null ? FontWeight.w600 : FontWeight.normal,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (file != null)
              const Icon(Icons.check_circle, color: Colors.green)
            else
              const Icon(Icons.upload_outlined, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalDetailsStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Personal Details',
            style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Tell us about yourself',
            style: GoogleFonts.outfit(color: Colors.grey),
          ),
          const SizedBox(height: 32),
          TextFormField(
            controller: _nameController,
            decoration: _inputDecoration('Full Name', Icons.person_outline),
            validator: (v) => v!.isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _emailController,
            decoration: _inputDecoration('Email', Icons.email_outlined),
            keyboardType: TextInputType.emailAddress,
            validator: (v) => v!.isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _phoneController,
            decoration: _inputDecoration('Phone Number', Icons.phone_outlined),
            keyboardType: TextInputType.phone,
            validator: (v) => v!.isEmpty ? 'Required' : null,
          ),
        ],
      ),
    );
  }

  Widget _buildServiceSelectionStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Service Categories',
            style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Select services you can provide (multiple selection allowed)',
            style: GoogleFonts.outfit(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _availableServices.map((service) {
              final isSelected = _selectedServices.contains(service);
              return FilterChip(
                label: Text(service),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedServices.add(service);
                    } else {
                      _selectedServices.remove(service);
                    }
                  });
                },
                selectedColor: const Color(0xFF6366F1).withOpacity(0.2),
                checkmarkColor: const Color(0xFF6366F1),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildExperienceStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Experience',
            style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Tell us about your work experience',
            style: GoogleFonts.outfit(color: Colors.grey),
          ),
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
          Text(
            'Documents',
            style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Upload required documents',
            style: GoogleFonts.outfit(color: Colors.grey),
          ),
          const SizedBox(height: 32),
          _buildUploadButton(
            'ID Proof (Aadhaar/PAN) *',
            _idProof,
            () => _pickImage(true),
            Icons.badge_outlined,
          ),
          const SizedBox(height: 16),
          _buildUploadButton(
            'Profile Photo',
            _profilePhoto,
            () => _pickImage(false),
            Icons.photo_camera_outlined,
          ),
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
          Text(
            'Address & Service Area',
            style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Where will you provide services?',
            style: GoogleFonts.outfit(color: Colors.grey),
          ),
          const SizedBox(height: 32),
          TextFormField(
            controller: _addressController,
            decoration: _inputDecoration('Full Address', Icons.location_on_outlined),
            maxLines: 2,
            validator: (v) => v!.isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _cityController,
            decoration: _inputDecoration('City', Icons.location_city_outlined),
            validator: (v) => v!.isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _pincodeController,
            decoration: _inputDecoration('Pincode', Icons.pin_drop_outlined),
            keyboardType: TextInputType.number,
            validator: (v) => v!.isEmpty ? 'Required' : null,
          ),
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
          Text(
            'Bank Details',
            style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'For receiving payments',
            style: GoogleFonts.outfit(color: Colors.grey),
          ),
          const SizedBox(height: 32),
          TextFormField(
            controller: _accountHolderController,
            decoration: _inputDecoration('Account Holder Name', Icons.person_outline),
            validator: (v) => v!.isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _bankNameController,
            decoration: _inputDecoration('Bank Name', Icons.account_balance_outlined),
            validator: (v) => v!.isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _accountNumberController,
            decoration: _inputDecoration('Account Number', Icons.credit_card_outlined),
            keyboardType: TextInputType.number,
            validator: (v) => v!.isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _ifscController,
            decoration: _inputDecoration('IFSC Code', Icons.code_outlined),
            validator: (v) => v!.isEmpty ? 'Required' : null,
          ),
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
          Text(
            'Agreement & Consent',
            style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Please review and accept',
            style: GoogleFonts.outfit(color: Colors.grey),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Terms & Conditions',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Text(
                  '• I agree to provide quality services\n'
                  '• I will maintain professional conduct\n'
                  '• I understand the payment terms\n'
                  '• I agree to background verification\n'
                  '• All information provided is accurate',
                  style: GoogleFonts.outfit(fontSize: 13, height: 1.8),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          CheckboxListTile(
            value: _agreedToTerms,
            onChanged: (v) => setState(() => _agreedToTerms = v!),
            title: Text(
              'I agree to all terms and conditions',
              style: GoogleFonts.outfit(),
            ),
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _previousStep,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Back'),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _currentStep == 6 ? _submitApplication : _nextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                _currentStep == 6 ? 'Submit Application' : 'Next',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingScreen() {
    return Scaffold(
      appBar: AppBar(title: const Text('Application Status')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.access_time, size: 80, color: Colors.orange),
              const SizedBox(height: 24),
              Text(
                'Application Under Review',
                style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'We are reviewing your application. You will be notified once approved.',
                style: GoogleFonts.outfit(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Back to Home'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildApprovedScreen() {
    return Scaffold(
      appBar: AppBar(title: const Text('Application Status')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle, size: 80, color: Colors.green),
              const SizedBox(height: 24),
              Text(
                'Congratulations!',
                style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'You are now a HomeFix Technician. Download the Technician App to start working.',
                style: GoogleFonts.outfit(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Back to Home'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRejectedScreen() {
    return Scaffold(
      appBar: AppBar(title: const Text('Application Status')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cancel, size: 80, color: Colors.red),
              const SizedBox(height: 24),
              Text(
                'Application Not Approved',
                style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Unfortunately, your application was not approved. Please contact support for more details.',
                style: GoogleFonts.outfit(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Back to Home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

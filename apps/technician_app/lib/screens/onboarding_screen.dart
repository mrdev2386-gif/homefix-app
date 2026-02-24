import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../core/providers/technician_provider.dart';
import '../core/utils/service_image_utils.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  final int _totalSteps = 4;
  bool _isSubmitting = false;

  // Form Data
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _experienceController = TextEditingController();
  String? _selectedCategoryId;
  String? _selectedCategoryName;
  String? _documentType = 'Aadhar Card';
  
  XFile? _frontImage;
  XFile? _backImage;
  String? _frontImageUrl;
  String? _backImageUrl;
  bool _isUploadingFront = false;
  bool _isUploadingBack = false;

  List<dynamic> _categories = [];
  bool _isLoadingCategories = true;

  @override
  void initState() {
    super.initState();
    _prefillUserData();
    _fetchCategories();
  }

  void _prefillUserData() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _fullNameController.text = user.displayName ?? '';
      _emailController.text = user.email ?? '';
    }
  }

  Future<void> _fetchCategories() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('categories')
          .where('isActive', isEqualTo: true)
          .get();
      setState(() {
        _categories = snapshot.docs.map((doc) => {
          'id': doc.id,
          'name': doc.data()['name'],
        }).toList();
        _isLoadingCategories = false;
      });
    } catch (e) {
      debugPrint("Error fetching categories: $e");
      setState(() => _isLoadingCategories = false);
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _experienceController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_validateStep()) {
      if (_currentStep < _totalSteps - 1) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
        setState(() => _currentStep++);
      } else {
        _submitApplication();
      }
    }
  }

  bool _validateStep() {
    switch (_currentStep) {
      case 0: // Personal Info
        if (_fullNameController.text.trim().isEmpty) {
          _showError("Please enter your full name");
          return false;
        }
        if (_emailController.text.trim().isEmpty || !_emailController.text.contains('@')) {
          _showError("Please enter a valid email");
          return false;
        }
        if (_experienceController.text.isEmpty || int.tryParse(_experienceController.text) == null) {
          _showError("Please enter valid years of experience");
          return false;
        }
        return true;
      case 1: // Category
        if (_selectedCategoryId == null) {
          _showError("Please select your primary skill category");
          return false;
        }
        return true;
      case 2: // Documents
        if (_frontImageUrl == null || _backImageUrl == null) {
          _showError("Please upload both front and back images of your document");
          return false;
        }
        return true;
      default:
        return true;
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Future<void> _pickAndUploadImage(bool isFront) async {
    final image = await ServiceImageUtils.pickImage();
    if (image == null) return;

    final error = await ServiceImageUtils.validateImage(image);
    if (error != null) {
      _showError(error);
      return;
    }

    setState(() {
      if (isFront) {
        _isUploadingFront = true;
      } else {
        _isUploadingBack = true;
      }
    });

    try {
      final url = await ServiceImageUtils.uploadKycImage(image, isFront ? 'kyc_front' : 'kyc_back');
      setState(() {
        if (isFront) {
          _frontImageUrl = url;
          _frontImage = image;
        } else {
          _backImageUrl = url;
          _backImage = image;
        }
      });
    } catch (e) {
      _showError("Upload failed: $e");
    } finally {
      setState(() {
        if (isFront) {
          _isUploadingFront = false;
        } else {
          _isUploadingBack = false;
        }
      });
    }
  }

  Future<void> _submitApplication() async {
    setState(() => _isSubmitting = true);
    try {
      await context.read<TechnicianProvider>().submitApplication(
        fullName: _fullNameController.text.trim(),
        email: _emailController.text.trim(),
        experienceYears: int.parse(_experienceController.text),
        primaryCategoryId: _selectedCategoryId!,
        documentType: _documentType ?? 'Aadhar Card',
        frontImage: _frontImageUrl!,
        backImage: _backImageUrl!,
      );
      // AuthGate will automatically switch to ApplicationStatusScreen
    } catch (e) {
      _showError("Submission failed: $e");
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Professional Application", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Column(
        children: [
          _buildProgressBar(),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildPersonalInfoStep(),
                _buildCategoryStep(),
                _buildDocumentsStep(),
                _buildReviewStep(),
              ],
            ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: List.generate(_totalSteps, (index) {
          final isActive = index <= _currentStep;
          return Expanded(
            child: Container(
              height: 4,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: isActive ? const Color(0xFF6366F1) : const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildPersonalInfoStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Tell us about yourself", style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text("We need your basic details to start your professional profile.", 
               style: GoogleFonts.outfit(color: Colors.grey[600])),
          const SizedBox(height: 32),
          _buildTextField("Full Name", _fullNameController, Icons.person_outline),
          const SizedBox(height: 20),
          _buildTextField("Email Address", _emailController, Icons.email_outlined, keyboardType: TextInputType.emailAddress),
          const SizedBox(height: 20),
          _buildTextField("Years of Experience", _experienceController, Icons.work_outline, keyboardType: TextInputType.number),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, {TextInputType? keyboardType}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: GoogleFonts.outfit(),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 20),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryStep() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Your Primary Skill", style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text("Choose the main category you provide services in.", 
               style: GoogleFonts.outfit(color: Colors.grey[600])),
          const SizedBox(height: 32),
          if (_isLoadingCategories)
            const Center(child: CircularProgressIndicator())
          else
            Expanded(
              child: ListView.builder(
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final cat = _categories[index];
                  final isSelected = _selectedCategoryId == cat['id'];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: InkWell(
                      onTap: () => setState(() {
                        _selectedCategoryId = cat['id'];
                        _selectedCategoryName = cat['name'];
                      }),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFF6366F1).withOpacity(0.05) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isSelected ? const Color(0xFF6366F1) : Colors.transparent),
                        ),
                        child: Row(
                          children: [
                            Text(cat['name'], style: GoogleFonts.outfit(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                            const Spacer(),
                            if (isSelected) const Icon(Icons.check_circle, color: Color(0xFF6366F1), size: 20),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
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
          Text("KYC Verification", style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text("Upload your identity proof for background check.", style: GoogleFonts.outfit(color: Colors.grey[600])),
          const SizedBox(height: 32),
          Text("Select Document Type", style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _documentType,
            items: ['Aadhar Card', 'PAN Card', 'Driving License'].map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
            onChanged: (v) => setState(() => _documentType = v),
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 32),
          _buildImageUpload("Front Side", _frontImageUrl, _isUploadingFront, () => _pickAndUploadImage(true)),
          const SizedBox(height: 24),
          _buildImageUpload("Back Side", _backImageUrl, _isUploadingBack, () => _pickAndUploadImage(false)),
        ],
      ),
    );
  }

  Widget _buildImageUpload(String label, String? url, bool isUploading, VoidCallback onTap) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        InkWell(
          onTap: isUploading ? null : onTap,
          child: Container(
            height: 160,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: isUploading
                ? const Center(child: CircularProgressIndicator())
                : url != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(url, fit: BoxFit.cover, width: double.infinity),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo_outlined, size: 32, color: Colors.grey[400]),
                          const SizedBox(height: 8),
                          Text("Click to upload", style: GoogleFonts.outfit(color: Colors.grey[500])),
                        ],
                      ),
          ),
        ),
      ],
    );
  }

  Widget _buildReviewStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Review Application", style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text("Final check before submitting your application.", style: GoogleFonts.outfit(color: Colors.grey[600])),
          const SizedBox(height: 32),
          _buildReviewItem("Name", _fullNameController.text),
          _buildReviewItem("Email", _emailController.text),
          _buildReviewItem("Experience", "${_experienceController.text} Years"),
          _buildReviewItem("Primary Skill", _selectedCategoryName ?? ""),
          _buildReviewItem("Document", _documentType ?? ""),
          const SizedBox(height: 20),
          const Text("Identification Images", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            children: [
               if (_frontImageUrl != null) Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(_frontImageUrl!, height: 100, fit: BoxFit.cover))),
               const SizedBox(width: 12),
               if (_backImageUrl != null) Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(_backImageUrl!, height: 100, fit: BoxFit.cover))),
            ],
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.blue.withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.blue),
                const SizedBox(width: 12),
                Expanded(
                  child: Text("Our team will review your application within 24-48 hours.", 
                       style: GoogleFonts.outfit(fontSize: 13, color: Colors.blue[800])),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildReviewItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.outfit(color: Colors.grey[500], fontSize: 13)),
          const SizedBox(height: 4),
          Text(value, style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _isSubmitting ? null : () {
                  _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                  setState(() => _currentStep--);
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text("Back", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _nextPage,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isSubmitting 
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text(_currentStep == _totalSteps - 1 ? "Submit Application" : "Continue", 
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/theme/app_theme.dart';

class TechnicianOnboardingScreen extends StatefulWidget {
  const TechnicianOnboardingScreen({super.key});

  @override
  State<TechnicianOnboardingScreen> createState() => _TechnicianOnboardingScreenState();
}

class _TechnicianOnboardingScreenState extends State<TechnicianOnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  bool _isLoading = false;

  // Data
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _experienceYearsController = TextEditingController();
  final _experienceDescController = TextEditingController();
  final _bankAccountController = TextEditingController();
  final _bankIfscController = TextEditingController();
  final _bankHolderController = TextEditingController();
  final _addressController = TextEditingController();
  
  List<String> _selectedCategories = [];
  XFile? _profilePhoto;
  XFile? _idProof;
  bool _agreedToTerms = false;

  final List<String> _categories = [
    'Cleaning', 'Plumbing', 'Electrical', 'Painting', 'AC Repair', 'Appliance Repair', 'Carpentry', 'Pest Control'
  ];

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _experienceYearsController.dispose();
    _experienceDescController.dispose();
    _bankAccountController.dispose();
    _bankIfscController.dispose();
    _bankHolderController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0:
        if (_nameController.text.isEmpty || _phoneController.text.isEmpty || _emailController.text.isEmpty) {
          _showError('Please fill all personal details');
          return false;
        }
        return true;
      case 1:
        if (_selectedCategories.isEmpty) {
          _showError('Please select at least one category');
          return false;
        }
        return true;
      case 2:
        if (_experienceYearsController.text.isEmpty) {
          _showError('Please enter your years of experience');
          return false;
        }
        return true;
      case 3:
        if (_profilePhoto == null) {
          _showError('Please upload a profile photo');
          return false;
        }
        return true;
      case 4:
        if (_idProof == null) {
          _showError('Please upload an ID proof');
          return false;
        }
        return true;
      case 5:
        if (_addressController.text.isEmpty) {
          _showError('Please enter your service area address');
          return false;
        }
        return true;
      case 6:
        if (_bankHolderController.text.isEmpty || _bankAccountController.text.isEmpty || _bankIfscController.text.isEmpty) {
          _showError('Please fill all bank details');
          return false;
        }
        return true;
      case 7:
        if (!_agreedToTerms) {
          _showError('Please agree to the terms and conditions');
          return false;
        }
        return true;
      default:
        return true;
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.redAccent));
  }

  void _nextPage() {
    if (!_validateCurrentStep()) return;
    
    if (_currentStep < 7) {
      _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    } else {
      _submitApplication();
    }
  }

  void _prevPage() {
    if (_currentStep > 0) {
      _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    } else {
      Navigator.pop(context);
    }
  }

  Future<void> _pickImage(bool isProfile) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (pickedFile != null) {
      setState(() {
        if (isProfile) _profilePhoto = pickedFile;
        else _idProof = pickedFile;
      });
    }
  }

  Future<void> _submitApplication() async {
    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please agree to the terms')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final firestore = Provider.of<FirestoreService>(context, listen: false);
      final storage = Provider.of<StorageService>(context, listen: false);
      final userId = auth.currentUser!.uid;

      // 1. Upload Files
      String? profileUrl;
      String? idProofUrl;

      if (_profilePhoto != null) {
        profileUrl = await storage.uploadProfilePhoto(userId: userId, file: _profilePhoto!);
      }
      if (_idProof != null) {
        idProofUrl = await storage.uploadTechnicianDoc(userId: userId, file: _idProof!, docType: 'id_proof');
      }

      // 2. Submit Data
      await firestore.becomeTechnician(userId, {
        'fullName': _nameController.text,
        'phone': _phoneController.text,
        'email': _emailController.text,
        'categories': _selectedCategories,
        'experienceYears': _experienceYearsController.text,
        'experienceDescription': _experienceDescController.text,
        'profilePhotoUrl': profileUrl,
        'idProofUrl': idProofUrl,
        'address': _addressController.text,
        'bankDetails': {
          'accountNumber': _bankAccountController.text,
          'ifscCode': _bankIfscController.text,
          'holderName': _bankHolderController.text,
        },
        'status': 'pending',
      });

      if (mounted) _showSuccessDialog();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_outline_rounded, color: Colors.emerald, size: 80),
            const SizedBox(height: 24),
            Text('Application Received!', style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            Text(
              'We are reviewing your application. You will be notified typically within 24-48 hours.',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(color: Colors.grey, height: 1.5),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Text('Back to Profile', style: GoogleFonts.outfit(fontWeight: FontWeight.w800, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Join as Partner', style: GoogleFonts.outfit(fontWeight: FontWeight.w800)),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textColor,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded), onPressed: _prevPage),
      ),
      body: Column(
        children: [
          _buildProgressBar(),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (idx) => setState(() => _currentStep = idx),
              children: [
                _buildStepPersonal(),
                _buildStepCategories(),
                _buildStepExperience(),
                _buildStepPhoto(),
                _buildStepIdProof(),
                _buildStepAddress(),
                _buildStepBank(),
                _buildStepAgreement(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildProgressBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        children: [
          LinearProgressIndicator(
            value: (_currentStep + 1) / 8,
            backgroundColor: AppTheme.accentColor,
            color: AppTheme.primaryColor,
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Step ${_currentStep + 1} of 8', style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.grey)),
              Text(_getStepTitle(), style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 13, color: AppTheme.primaryColor)),
            ],
          ),
        ],
      ),
    );
  }

  String _getStepTitle() {
    switch (_currentStep) {
      case 0: return 'Personal Info';
      case 1: return 'Your Skills';
      case 2: return 'Experience';
      case 3: return 'Profile Picture';
      case 4: return 'ID Verification';
      case 5: return 'Service Area';
      case 6: return 'Bank Details';
      case 7: return 'Terms';
      default: return '';
    }
  }

  Widget _buildStepPersonal() {
    return _buildStepPadding([
      _buildStepHeader('Let\'s start with basics', 'Your name and contact details help us reach you.'),
      _buildTextField('Full Name', _nameController, Icons.person_outline),
      _buildTextField('Phone Number', _phoneController, Icons.phone_android_outlined, keyboardType: TextInputType.phone),
      _buildTextField('Email Address', _emailController, Icons.email_outlined, keyboardType: TextInputType.emailAddress),
    ]);
  }

  Widget _buildStepCategories() {
    return _buildStepPadding([
      _buildStepHeader('What are you good at?', 'Select the categories you want to provide services in.'),
      Wrap(
        spacing: 12,
        runSpacing: 12,
        children: _categories.map((cat) {
          final isSelected = _selectedCategories.contains(cat);
          return FilterChip(
            label: Text(cat, style: GoogleFonts.outfit(fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600, color: isSelected ? Colors.white : AppTheme.textColor)),
            selected: isSelected,
            onSelected: (val) {
              setState(() {
                if (val) _selectedCategories.add(cat);
                else _selectedCategories.remove(cat);
              });
            },
            selectedColor: AppTheme.primaryColor,
            checkmarkColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            backgroundColor: const Color(0xFFF8F9FE),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          );
        }).toList(),
      ),
    ]);
  }

  Widget _buildStepExperience() {
    return _buildStepPadding([
      _buildStepHeader('Your Track Record', 'Tell us about your professional background.'),
      _buildTextField('Years of Experience', _experienceYearsController, Icons.timer_outlined, keyboardType: TextInputType.number),
      _buildTextField('Service Expertise (Optional)', _experienceDescController, Icons.description_outlined, maxLines: 4),
    ]);
  }

  Widget _buildStepPhoto() {
    return _buildUploadStep('Profile Photo', 'A clear face photo helps build customer trust.', _profilePhoto, true);
  }

  Widget _buildStepIdProof() {
    return _buildUploadStep('ID Proof (Aadhar/PAN)', 'We need this for identity verification.', _idProof, false);
  }

  Widget _buildStepAddress() {
    return _buildStepPadding([
      _buildStepHeader('Service Base', 'Your primary address for calculating service range.'),
      _buildTextField('Full Address', _addressController, Icons.map_outlined, maxLines: 3),
    ]);
  }

  Widget _buildStepBank() {
    return _buildStepPadding([
      _buildStepHeader('Payment Details', 'Where should we send your earnings?'),
      _buildTextField('Account Holder Name', _bankHolderController, Icons.account_circle_outlined),
      _buildTextField('Account Number', _bankAccountController, Icons.account_balance_rounded),
      _buildTextField('IFSC Code', _bankIfscController, Icons.password_rounded),
    ]);
  }

  Widget _buildStepAgreement() {
    return _buildStepPadding([
      _buildStepHeader('One Last Thing', 'By clicking below, you agree to our Service Partner Agreement.'),
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: const Color(0xFFF8F9FE), borderRadius: BorderRadius.circular(20)),
        child: Text(
          '1. You will provide high-quality services.\n2. You will maintain valid ID proofs.\n3. Platform fees will be deducted from earnings.\n4. You agree to follow safety protocols.',
          style: GoogleFonts.outfit(height: 1.8, fontWeight: FontWeight.w600, color: Colors.grey.shade600),
        ),
      ),
      const SizedBox(height: 24),
      CheckboxListTile(
        title: Text('I agree to the Terms & Conditions', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
        value: _agreedToTerms,
        onChanged: (v) => setState(() => _agreedToTerms = v!),
        activeColor: AppTheme.primaryColor,
        contentPadding: EdgeInsets.zero,
        controlAffinity: ListTileControlAffinity.leading,
      ),
    ]);
  }

  Widget _buildStepPadding(List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }

  Widget _buildStepHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        Text(subtitle, style: GoogleFonts.outfit(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w600)),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, {TextInputType? keyboardType, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 13, color: AppTheme.textColor)),
          const SizedBox(height: 10),
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: Colors.grey.shade400, size: 20),
              filled: true,
              fillColor: const Color(0xFFF8F9FE),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadStep(String title, String subtitle, XFile? file, bool isProfile) {
    return _buildStepPadding([
      _buildStepHeader(title, subtitle),
      Center(
        child: GestureDetector(
          onTap: () => _pickImage(isProfile),
          child: Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FE),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppTheme.primaryColor.withOpacity(0.1), width: 2),
            ),
            child: file != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(22), 
                    child: kIsWeb 
                      ? Image.network(file.path, fit: BoxFit.cover)
                      : Image.network(file.path, fit: BoxFit.cover)
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.cloud_upload_outlined, size: 48, color: AppTheme.primaryColor),
                      const SizedBox(height: 16),
                      Text('Tap to Upload', style: GoogleFonts.outfit(fontWeight: FontWeight.w800, color: AppTheme.primaryColor)),
                    ],
                  ),
          ),
        ),
      ),
    ]);
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _nextPage,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: _isLoading 
              ? const CircularProgressIndicator(color: Colors.white)
              : Text(
                  _currentStep == 7 ? 'SUBMIT APPLICATION' : 'CONTINUE',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.white, letterSpacing: 1),
                ),
          ),
        ),
      ),
    );
  }
}

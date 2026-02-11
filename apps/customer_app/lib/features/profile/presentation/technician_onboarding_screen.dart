
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/dashboard_models.dart';

class TechnicianOnboardingScreen extends StatefulWidget {
  const TechnicianOnboardingScreen({super.key});

  @override
  State<TechnicianOnboardingScreen> createState() => _TechnicianOnboardingScreenState();
}

class _TechnicianOnboardingScreenState extends State<TechnicianOnboardingScreen> {
  final PageController _pageController = PageController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  int _currentStep = 0;
  bool _isLoading = false;

  // Data - Non-nullable controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _experienceYearsController = TextEditingController();
  final TextEditingController _experienceDescController = TextEditingController();
  final TextEditingController _bankAccountController = TextEditingController();
  final TextEditingController _bankIfscController = TextEditingController();
  final TextEditingController _bankHolderController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  
  // Category Selection
  List<TechnicianCategory> _allCategories = [];
  List<TechnicianSubcategory> _allSubcategories = [];
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _selectedCategoryIds = {};
  final Set<String> _selectedSubCategoryIds = {};
  
  XFile? _profilePhoto;
  XFile? _idProof;
  bool _agreedToTerms = false;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_validateStep1);
    _phoneController.addListener(_validateStep1);
    _emailController.addListener(_validateStep1);
  }

  void _validateStep1() {
    setState(() {}); // Trigger rebuild to update button state
  }

  void _filterCategories(String query) {
    setState(() {}); // Trigger rebuild for search
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.removeListener(_validateStep1);
    _phoneController.removeListener(_validateStep1);
    _emailController.removeListener(_validateStep1);
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _experienceYearsController.dispose();
    _experienceDescController.dispose();
    _bankAccountController.dispose();
    _bankIfscController.dispose();
    _bankHolderController.dispose();
    _addressController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  bool _isStepValid() {
    switch (_currentStep) {
      case 0:
        // Step 1: Strict validation
        final name = _nameController.text.trim();
        final phone = _phoneController.text.trim();
        final email = _emailController.text.trim();
        
        if (name.length < 3) return false;
        if (phone.length != 10) return false;
        
        // Email regex validation
        final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
        if (!emailRegex.hasMatch(email)) return false;
        
        return true;
      case 1:
        return _selectedCategoryIds.isNotEmpty && _selectedSubCategoryIds.isNotEmpty;
      case 2:
        return _experienceYearsController.text.trim().isNotEmpty;
      case 3:
        return _profilePhoto != null;
      case 4:
        return _idProof != null;
      case 5:
        return _addressController.text.trim().isNotEmpty;
      case 6:
        return _bankHolderController.text.trim().isNotEmpty && 
               _bankAccountController.text.trim().isNotEmpty && 
               _bankIfscController.text.trim().isNotEmpty;
      case 7:
        return _agreedToTerms;
      default:
        return true;
    }
  }

  bool _validateCurrentStep() {
    if (!_isStepValid()) {
      switch (_currentStep) {
        case 0: 
          _showError('Please enter valid details:\n• Name (min 3 characters)\n• Phone (10 digits)\n• Valid email address'); 
          break;
        case 1: _showError('Please select at least 1 category and 1 subcategory'); break;
        case 2: _showError('Please enter your years of experience'); break;
        case 3: _showError('Please upload a profile photo'); break;
        case 4: _showError('Please upload an ID proof'); break;
        case 5: _showError('Please enter your service area address'); break;
        case 6: _showError('Please fill all bank details'); break;
        case 7: _showError('Please agree to the terms and conditions'); break;
      }
      return false;
    }
    return true;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _nextPage() {
    if (!_validateCurrentStep()) return;
    
    if (_currentStep < 7) {
      // Save data locally and navigate to next step
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300), 
        curve: Curves.easeInOut,
      );
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
        'categories': _selectedCategoryIds.toList(),
        'subCategories': _selectedSubCategoryIds.toList(),
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
            const Icon(Icons.check_circle_outline_rounded, color: Color(0xFF10B981), size: 80),
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStepHeader('Let\'s start with basics', 'Your name and contact details help us reach you.'),
            _buildTextField(
              'Full Name',
              _nameController,
              Icons.person_outline,
              validator: (value) {
                if (value == null || value.trim().length < 3) {
                  return 'Name must be at least 3 characters';
                }
                return null;
              },
            ),
            _buildTextField(
              'Phone Number',
              _phoneController,
              Icons.phone_android_outlined,
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.trim().length != 10) {
                  return 'Phone must be exactly 10 digits';
                }
                return null;
              },
            ),
            _buildTextField(
              'Email Address',
              _emailController,
              Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Email is required';
                }
                final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
                if (!emailRegex.hasMatch(value.trim())) {
                  return 'Enter a valid email address';
                }
                return null;
              },
            ),
            const SizedBox(height: 100), // Space for keyboard
          ],
        ),
      ),
    );
  }

  Widget _buildStepCategories() {
    final firestore = Provider.of<FirestoreService>(context, listen: false);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStepHeader('What are you good at?', 'Select the categories & subcategories you excel in.'),
              TextField(
                controller: _searchController,
                onChanged: _filterCategories,
                decoration: InputDecoration(
                  hintText: 'Search categories or services...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  filled: true,
                  fillColor: const Color(0xFFF8F9FE),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<List<TechnicianCategory>>(
            stream: firestore.streamTechnicianCategories(),
            builder: (context, catSnapshot) {
              if (catSnapshot.connectionState == ConnectionState.waiting) {
                return _buildCategorySkeleton();
              }
              
              if (catSnapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline, size: 64, color: Colors.redAccent),
                        const SizedBox(height: 16),
                        Text(
                          'Error loading categories',
                          style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${catSnapshot.error}',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(color: Colors.grey, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                );
              }
              
              if (!catSnapshot.hasData || catSnapshot.data!.isEmpty) {
                return _buildEmptyCategories();
              }

              final categories = catSnapshot.data!;

              return StreamBuilder<List<TechnicianSubcategory>>(
                stream: firestore.streamTechnicianSubcategories(),
                builder: (context, subSnapshot) {
                  if (subSnapshot.connectionState == ConnectionState.waiting) {
                    return _buildCategorySkeleton();
                  }
                  
                  final allSubCats = subSnapshot.data ?? [];
                  final query = _searchController.text.toLowerCase();

                  // Filter logic
                  final filteredCats = categories.where((cat) {
                    if (query.isEmpty) return true;
                    final catMatch = cat.name.toLowerCase().contains(query);
                    final subCatMatch = allSubCats.any((sub) => 
                      sub.categoryId == cat.id && sub.name.toLowerCase().contains(query)
                    );
                    return catMatch || subCatMatch;
                  }).toList();

                  if (filteredCats.isEmpty && query.isNotEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(40.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.search_off, size: 64, color: Colors.grey.shade300),
                            const SizedBox(height: 16),
                            Text(
                              'No results for "$query"',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.outfit(color: Colors.grey, fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: filteredCats.length,
                    itemBuilder: (context, index) {
                      final cat = filteredCats[index];
                      final subCats = allSubCats.where((s) => s.categoryId == cat.id).toList();
                      final isCatSelected = _selectedCategoryIds.contains(cat.id);
                      final subMatch = query.isNotEmpty && subCats.any((s) => s.name.toLowerCase().contains(query));

                      return Card(
                        elevation: 0,
                        clipBehavior: Clip.antiAlias,
                        color: isCatSelected ? AppTheme.primaryColor.withOpacity(0.04) : Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16), 
                          side: BorderSide(
                            color: isCatSelected 
                              ? AppTheme.primaryColor.withOpacity(0.2) 
                              : Colors.grey.shade200,
                          ),
                        ),
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ExpansionTile(
                          initiallyExpanded: subMatch || isCatSelected,
                          title: Text(
                            cat.name,
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              color: isCatSelected ? AppTheme.primaryColor : AppTheme.textColor,
                            ),
                          ),
                          leading: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isCatSelected ? AppTheme.primaryColor : Colors.transparent,
                              border: Border.all(
                                color: isCatSelected ? AppTheme.primaryColor : Colors.grey.shade300,
                                width: 2,
                              ),
                            ),
                            child: isCatSelected 
                              ? const Icon(Icons.check, size: 14, color: Colors.white) 
                              : null,
                          ),
                          children: subCats.map((sub) {
                            final isSubSelected = _selectedSubCategoryIds.contains(sub.id);
                            final subQueryMatch = query.isEmpty || sub.name.toLowerCase().contains(query);
                            
                            if (!subQueryMatch) return const SizedBox.shrink();

                            return ListTile(
                              contentPadding: const EdgeInsets.only(left: 48, right: 16),
                              title: Text(sub.name, style: GoogleFonts.outfit(fontSize: 14)),
                              trailing: isSubSelected 
                                ? const Icon(Icons.check_circle, color: AppTheme.primaryColor, size: 20)
                                : Icon(Icons.add_circle_outline, color: Colors.grey.shade300, size: 20),
                              onTap: () {
                                setState(() {
                                  if (isSubSelected) {
                                    _selectedSubCategoryIds.remove(sub.id);
                                    // If no more subcategories selected for this category, deselect category
                                    final hasOtherSubs = allSubCats
                                      .where((s) => s.categoryId == cat.id)
                                      .any((s) => _selectedSubCategoryIds.contains(s.id));
                                    if (!hasOtherSubs) _selectedCategoryIds.remove(cat.id);
                                  } else {
                                    _selectedSubCategoryIds.add(sub.id);
                                    _selectedCategoryIds.add(cat.id);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyCategories() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.category_outlined, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              "Services will be available soon",
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                color: Colors.grey,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Categories are being configured by admin",
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                color: Colors.grey.shade400,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySkeleton() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: 5,
      itemBuilder: (context, index) => Container(
        height: 72,
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
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

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    IconData icon, {
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.w800,
              fontSize: 13,
              color: AppTheme.textColor,
            ),
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            validator: validator,
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: Colors.grey.shade400, size: 20),
              filled: true,
              fillColor: const Color(0xFFF8F9FE),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Colors.redAccent, width: 1),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Colors.redAccent, width: 2),
              ),
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
    final isValid = _isStepValid();
    
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: (_isLoading || !isValid) ? null : _nextPage,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              disabledBackgroundColor: Colors.grey.shade300,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: isValid ? 2 : 0,
            ),
            child: _isLoading 
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : Text(
                  _currentStep == 7 ? 'SUBMIT APPLICATION' : 'CONTINUE',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    color: isValid ? Colors.white : Colors.grey.shade500,
                    letterSpacing: 1,
                  ),
                ),
          ),
        ),
      ),
    );
  }
}

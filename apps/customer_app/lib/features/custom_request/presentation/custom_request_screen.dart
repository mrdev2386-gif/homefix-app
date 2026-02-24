import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:customer_app/core/services/user_service.dart'; // Added UserService import
import 'package:customer_app/core/theme/app_theme.dart';
import 'package:customer_app/core/services/category_service.dart';
import 'package:customer_app/core/services/functions_service.dart';
import 'package:customer_app/core/services/auth_service.dart';
import 'package:customer_app/core/services/storage_service.dart';
import 'package:customer_app/core/models/category.dart';
import 'package:customer_app/core/models/service.dart';
import 'package:customer_app/core/models/address.dart';

class CustomRequestScreen extends StatefulWidget {
  const CustomRequestScreen({super.key});

  @override
  State<CustomRequestScreen> createState() => _CustomRequestScreenState();
}

class _CustomRequestScreenState extends State<CustomRequestScreen> with SingleTickerProviderStateMixin {
  int _currentStep = 1; // 1: Category, 2: Subcategory, 3: Form
  Category? _selectedCategory;
  HomeService? _selectedSubCategory;
  
  // Step 3 Form Data
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  DateTime? _preferredDate;
  TimeOfDay? _preferredTime;
  Address? _selectedAddress;
  final List<File> _images = [];
  bool _isSubmitting = false;
  double _uploadProgress = 0.0;

  final CategoryService _categoryService = CategoryService();
  final StorageService _storageService = StorageService();
  final ImagePicker _picker = ImagePicker();
  
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < 3) {
      setState(() {
        _currentStep++;
        _animationController.reset();
        _animationController.forward();
      });
    }
  }

  void _prevStep() {
    if (_currentStep > 1) {
      setState(() {
        _currentStep--;
        _animationController.reset();
        _animationController.forward();
      });
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    if (_images.length >= 3) return;
    final XFile? image = await _picker.pickImage(
      source: source,
      imageQuality: 70,
      maxWidth: 1200,
    );
    if (image != null) {
      setState(() => _images.add(File(image.path)));
    }
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an address')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
      _uploadProgress = 0.1; // Start progress
    });

    try {
      final functionsService = Provider.of<FunctionsService>(context, listen: false);
      final userId = Provider.of<AuthService>(context, listen: false).currentUser?.uid;
      
      if (userId == null) throw Exception('User not authenticated');

      // 1. Upload Images to Firebase Storage (Production Hardened)
      List<String> imageUrls = [];
      if (_images.isNotEmpty) {
        setState(() => _uploadProgress = 0.3);
        imageUrls = await _storageService.uploadMultipleFiles(
          files: _images,
          path: 'custom_requests/$userId/${DateTime.now().millisecondsSinceEpoch}',
        );
        setState(() => _uploadProgress = 0.7);
      }

      final String? dateStr = _preferredDate != null 
          ? DateFormat('yyyy-MM-dd').format(_preferredDate!)
          : null;
      final String? timeStr = _preferredTime != null
          ? '${_preferredTime!.hour.toString().padLeft(2, '0')}:${_preferredTime!.minute.toString().padLeft(2, '0')}'
          : null;

      final requestData = {
        'categoryId': _selectedCategory!.id,
        'subCategoryId': _selectedSubCategory!.id,
        'description': _descriptionController.text,
        'preferredDate': dateStr != null ? '$dateStr $timeStr' : null,
        'addressId': _selectedAddress!.id,
        'images': imageUrls, // Now using Storage URLs
        'idempotencyKey': DateTime.now().millisecondsSinceEpoch.toString(),
      };

      setState(() => _uploadProgress = 0.9);
      final result = await functionsService.createCustomServiceRequest(requestData);

      if (mounted) {
        if (result['success'] == true) {
          _showSuccessDialog();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['message'] ?? 'Failed to submit request')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Submission failed: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => FadeTransition(
        opacity: _animationController,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.successColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded, color: AppTheme.successColor, size: 48),
              ),
              const SizedBox(height: 24),
              Text('Request Sent!', 
                style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 24, color: AppTheme.textColor)),
              const SizedBox(height: 12),
              Text(
                'Our team will review your requirement and assign the best technician shortly.',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(color: AppTheme.subtitleColor, fontSize: 15),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    setState(() {
                      _currentStep = 1;
                      _selectedCategory = null;
                      _selectedSubCategory = null;
                      _descriptionController.clear();
                      _images.clear();
                      _preferredDate = null;
                      _preferredTime = null;
                    });
                  },
                  child: const Text('Back to Dashboard'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          Column(
            children: [
              _buildStepper(),
              Expanded(
                child: _buildCurrentStep(),
              ),
            ],
          ),
          if (_isSubmitting) _buildLoadingOverlay(),
        ],
      ),
      bottomNavigationBar: _buildBottomCTA(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text('Custom Request', 
        style: GoogleFonts.outfit(fontWeight: FontWeight.w800, color: AppTheme.textColor)),
      centerTitle: true,
      backgroundColor: AppTheme.backgroundColor,
      elevation: 0,
      leading: _currentStep > 1 
        ? IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            onPressed: _prevStep,
          )
        : null,
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.white.withOpacity(0.9),
      width: double.infinity,
      height: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(strokeWidth: 3),
          const SizedBox(height: 24),
          Text('Processing Securely...', 
            style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 18)),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: _uploadProgress,
            backgroundColor: Colors.grey[200],
            borderRadius: BorderRadius.circular(10),
          ),
          const SizedBox(height: 8),
          Text('${(_uploadProgress * 100).toInt()}%', 
            style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 12, color: AppTheme.primaryColor)),
        ],
      ),
    );
  }

  Widget _buildStepper() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
      child: Row(
        children: [
          _stepNode(1, _currentStep >= 1),
          _stepLine(_currentStep >= 2),
          _stepNode(2, _currentStep >= 2),
          _stepLine(_currentStep >= 3),
          _stepNode(3, _currentStep >= 3),
        ],
      ),
    );
  }

  Widget _stepNode(int step, bool active) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: active ? AppTheme.primaryColor : Colors.white,
        shape: BoxShape.circle,
        border: active ? null : Border.all(color: Colors.grey.shade300, width: 2),
        boxShadow: active ? [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ] : null,
      ),
      child: Center(
        child: Text('$step', 
          style: TextStyle(
            color: active ? Colors.white : Colors.grey.shade400,
            fontWeight: FontWeight.w900,
            fontSize: 14,
          )),
      ),
    );
  }

  Widget _stepLine(bool active) {
    return Expanded(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: 2,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: active ? AppTheme.primaryColor : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 1: return _buildCategoryStep();
      case 2: return _buildSubCategoryStep();
      case 3: return _buildFormStep();
      default: return const SizedBox.shrink();
    }
  }

  Widget _buildCategoryStep() {
    return StreamBuilder<List<Category>>(
      stream: _categoryService.getActiveCategories(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildCategorySkeleton();
        }
        final categories = snapshot.data ?? [];
        
        return GridView.builder(
          padding: const EdgeInsets.all(24),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.0,
          ),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final cat = categories[index];
            final bool isSelected = _selectedCategory?.id == cat.id;
            
            return _buildCategoryCard(cat, isSelected);
          },
        );
      },
    );
  }

  Widget _buildCategoryCard(Category cat, bool isSelected) {
    return InkWell(
      onTap: () {
        setState(() => _selectedCategory = cat);
        _nextStep();
      },
      borderRadius: BorderRadius.circular(24),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor.withOpacity(0.05) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : Colors.grey.shade100,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.accentColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Image.network(
                cat.imageUrl,
                width: 48,
                height: 48,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(Icons.category, size: 40, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 12),
            Text(cat.name, 
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w800,
                fontSize: 15,
                color: isSelected ? AppTheme.primaryColor : AppTheme.textColor,
              )),
          ],
        ),
      ),
    );
  }

  Widget _buildSubCategoryStep() {
    if (_selectedCategory == null) return const SizedBox.shrink();

    return StreamBuilder<List<HomeService>>(
      stream: _categoryService.getServicesByCategoryResult(_selectedCategory!.id).map((r) => r.data ?? []),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildListSkeleton();
        }
        
        List<HomeService> services = snapshot.data ?? [];
        // Unique ID for "Other"
        if (!services.any((s) => s.id == 'custom_sub_service')) {
          services.add(HomeService(
            id: 'custom_sub_service',
            key: 'custom_sub_service',
            title: 'Other / Not Listed',
            imageAssetPath: '',
            imageUrl: '',
            basePrice: 0,
            isActive: true,
            category: _selectedCategory!.id,
            categoryName: _selectedCategory!.name,
            isTopService: false,
            order: 9999,
            createdAt: DateTime.now(),
          ));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(24),
          itemCount: services.length,
          itemBuilder: (context, index) {
            final service = services[index];
            final bool isSelected = _selectedSubCategory?.id == service.id;
            final bool isOther = service.id == 'custom_sub_service';
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                onTap: () {
                  setState(() => _selectedSubCategory = service);
                  if (!isOther) {
                    _nextStep();
                  } else {
                    _nextStep(); // Still next step for "Other"
                  }
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.primaryColor.withOpacity(0.05) : (isOther ? Colors.orange.withOpacity(0.03) : Colors.white),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? AppTheme.primaryColor : (isOther ? Colors.orange.withOpacity(0.2) : Colors.grey.shade100),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(isOther ? Icons.auto_awesome : Icons.check_circle_outline, 
                        color: isSelected ? AppTheme.primaryColor : (isOther ? Colors.orange : Colors.grey[400]),
                        size: 20),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(service.title, 
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                            color: isSelected ? AppTheme.primaryColor : (isOther ? Colors.orange[800] : AppTheme.textColor),
                          )),
                      ),
                      Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey[300]),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFormStep() {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _buildSummaryCard(),
          const SizedBox(height: 32),
          
          _fieldLabel('What needs to be fixed?'),
          const SizedBox(height: 12),
          TextFormField(
            controller: _descriptionController,
            maxLines: 4,
            decoration: AppTheme.inputDecoration(
              hintText: 'Detail your problem (e.g. leaking tap, short circuit...)',
              prefixIcon: const Icon(Icons.edit_note_rounded),
            ),
            validator: (val) => (val == null || val.length < 10) ? 'Provide more details (min 10 chars)' : null,
          ),
          const SizedBox(height: 32),

          _fieldLabel('Execution Preference'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _datePickerTile()),
              const SizedBox(width: 12),
              Expanded(child: _timePickerTile()),
            ],
          ),
          const SizedBox(height: 32),

          _fieldLabel('Service Location'),
          const SizedBox(height: 12),
          _addressSelectorTile(),
          const SizedBox(height: 32),

          _fieldLabel('Evidence / Photos (Recommended)'),
          const SizedBox(height: 12),
          _imageGrid(),
          
          const SizedBox(height: 120), // Space for sticky bottom
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryColor.withOpacity(0.1), AppTheme.accentColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.bolt_rounded, color: AppTheme.primaryColor),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${_selectedCategory?.name ?? "Custom"}', style: GoogleFonts.outfit(fontWeight: FontWeight.w900, color: AppTheme.textColor)),
              Text('${_selectedSubCategory?.title ?? "Service"}', style: GoogleFonts.outfit(color: AppTheme.subtitleColor, fontSize: 13, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _fieldLabel(String text) {
    return Text(text, style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 16, color: AppTheme.textColor));
  }

  Widget _datePickerTile() {
    return _pickerBase(
      label: _preferredDate == null ? 'Today / Select Date' : DateFormat('MMM dd').format(_preferredDate!),
      icon: Icons.calendar_today_rounded,
      onTap: () async {
        final d = await showDatePicker(
          context: context,
          initialDate: DateTime.now().add(const Duration(minutes: 5)),
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 90)),
          builder: (context, child) => Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(primary: AppTheme.primaryColor),
            ),
            child: child!,
          ),
        );
        if (d != null) setState(() => _preferredDate = d);
      },
    );
  }

  Widget _timePickerTile() {
    return _pickerBase(
      label: _preferredTime == null ? 'ASAP / Select Time' : _preferredTime!.format(context),
      icon: Icons.access_time_rounded,
      onTap: () async {
        final t = await showTimePicker(context: context, initialTime: TimeOfDay.now());
        if (t != null) setState(() => _preferredTime = t);
      },
    );
  }

  Widget _addressSelectorTile() {
    return _pickerBase(
      label: _selectedAddress?.fullAddress ?? 'Pick a Saved Address',
      icon: Icons.location_on_rounded,
      isLarge: true,
      onTap: _showAddressBottomSheet,
    );
  }

  Widget _pickerBase({required String label, required IconData icon, required VoidCallback onTap, bool isLarge = false}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppTheme.primaryColor),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 14), overflow: TextOverflow.ellipsis)),
            const Icon(Icons.expand_more_rounded, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  void _showAddressBottomSheet() {
    final userId = context.read<AuthService>().currentUser?.uid;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Select Address', style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 20)),
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded)),
              ],
            ),
            const SizedBox(height: 20),
            StreamBuilder<List<Address>>(
              stream: UserService().getAddresses(userId!),
              builder: (context, snap) {
                if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                final addresses = snap.data!;
                if (addresses.isEmpty) return const Center(child: Text('No addresses found in your profile.'));
                
                return Column(
                  children: addresses.map((addr) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    onTap: () {
                      setState(() => _selectedAddress = addr);
                      Navigator.pop(context);
                    },
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: AppTheme.accentColor, borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.place_rounded, color: AppTheme.primaryColor, size: 20),
                    ),
                    title: Text(addr.name, style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
                    subtitle: Text(addr.fullAddress, style: GoogleFonts.outfit(fontSize: 12)),
                    trailing: _selectedAddress?.id == addr.id ? const Icon(Icons.check_circle_rounded, color: AppTheme.successColor) : null,
                  )).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _imageGrid() {
    return Row(
      children: [
        if (_images.isEmpty) 
          Expanded(child: _imagePlaceholder())
        else
          ..._images.asMap().entries.map((e) => _imageTile(e.key, e.value)),
        if (_images.isNotEmpty && _images.length < 3)
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: _smallImageAdd(),
          ),
      ],
    );
  }

  Widget _imagePlaceholder() {
    return InkWell(
      onTap: _showImgSheet,
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.primaryColor.withOpacity(0.2), style: BorderStyle.solid),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add_a_photo_rounded, color: AppTheme.primaryColor),
            const SizedBox(height: 8),
            Text('Tap to add photos', style: GoogleFonts.outfit(color: AppTheme.primaryColor, fontWeight: FontWeight.w700, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _imageTile(int index, File file) {
    return Stack(
      children: [
        Container(
          width: 80,
          height: 80,
          margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            image: DecorationImage(image: FileImage(file), fit: BoxFit.cover),
            border: Border.all(color: Colors.grey.shade200),
          ),
        ),
        Positioned(
          top: 4,
          right: 16,
          child: InkWell(
            onTap: () => setState(() => _images.removeAt(index)),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              child: const Icon(Icons.close_rounded, size: 12, color: Colors.red),
            ),
          ),
        ),
      ],
    );
  }

  Widget _smallImageAdd() {
    return InkWell(
      onTap: _showImgSheet,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: AppTheme.accentColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.primaryColor.withOpacity(0.1)),
        ),
        child: const Icon(Icons.add_rounded, color: AppTheme.primaryColor),
      ),
    );
  }

  void _showImgSheet() {
    showModalBottomSheet(context: context, builder: (c) => SafeArea(
      child: Wrap(children: [
        ListTile(leading: const Icon(Icons.camera_alt_rounded), title: const Text('Camera'), onTap: () { Navigator.pop(c); _pickImage(ImageSource.camera); }),
        ListTile(leading: const Icon(Icons.photo_library_rounded), title: const Text('Gallery'), onTap: () { Navigator.pop(c); _pickImage(ImageSource.gallery); }),
      ]),
    ));
  }

  Widget _buildBottomCTA() {
    bool canGoNext = (_currentStep == 1 && _selectedCategory != null) || 
                    (_currentStep == 2 && _selectedSubCategory != null);
    
    if (_currentStep == 3) {
      return Container(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, -5))],
        ),
        child: ElevatedButton(
          onPressed: _isSubmitting ? null : _submitRequest,
          child: Text(_isSubmitting ? 'SECURE SUBMITTING...' : 'CONFIRM & SUBMIT'),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      decoration: BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Colors.grey.shade100))),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: canGoNext ? AppTheme.primaryColor : Colors.grey.shade300,
        ),
        onPressed: canGoNext ? _nextStep : null,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('CONTINUE'),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_rounded, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySkeleton() {
    return GridView.builder(
      padding: const EdgeInsets.all(24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 16, mainAxisSpacing: 16),
      itemCount: 6,
      itemBuilder: (_, __) => Shimmer.fromColors(
        baseColor: Colors.grey[200]!,
        highlightColor: Colors.white,
        child: Container(decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24))),
      ),
    );
  }

  Widget _buildListSkeleton() {
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: 8,
      itemBuilder: (_, __) => Shimmer.fromColors(
        baseColor: Colors.grey[200]!,
        highlightColor: Colors.white,
        child: Container(margin: const EdgeInsets.only(bottom: 12), height: 60, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16))),
      ),
    );
  }
}

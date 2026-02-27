import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../../core/app_theme.dart';
import '../../../core/services/functions_service.dart';
import '../../../core/services/category_data_service.dart';
import '../../../core/utils/image_upload_service.dart';
import '../../../core/widgets/searchable_dropdown.dart';
import '../../../core/providers/technician_provider.dart';

/// Add Service Screen - Production-Grade Form
/// 
/// Features:
/// - Firestore-driven Category dropdown (searchable)
/// - Subcategory selection (350+ items, searchable, virtualized)
/// - Image picker with compression and progress
/// - Proper form validation with try/catch
/// - Loading state handling
/// - Duplicate submission prevention
/// - Modern UI with BorderRadius 16-20
/// - Zero RenderFlex overflow
class AddServiceScreen extends StatefulWidget {
  const AddServiceScreen({super.key});

  @override
  State<AddServiceScreen> createState() => _AddServiceScreenState();
}

class _AddServiceScreenState extends State<AddServiceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _imageUploadService = ImageUploadService();
  final _functionsService = FunctionsService();
  final _categoryDataService = CategoryDataService();
  
  // Form state
  String? _selectedCategoryId;
  String? _selectedCategoryName;
  String? _selectedSubCategoryId;
  String? _selectedSubCategoryName;
  File? _selectedImage;
  String? _uploadedImageUrl;
  
  // Loading states
  bool _isUploading = false;
  bool _isSaving = false;
  double _uploadProgress = 0.0;
  
  // Data
  List<CategoryData> _categories = [];
  List<SubCategoryData> _subCategories = [];
  bool _isLoadingCategories = true;
  bool _isLoadingSubCategories = false;
  String? _categoryError;
  String? _subCategoryError;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  /// Load categories from Firestore
  Future<void> _loadCategories() async {
    setState(() {
      _isLoadingCategories = true;
      _categoryError = null;
    });
    
    try {
      final categories = await _categoryDataService.getCategories();
      setState(() {
        _categories = categories;
        _isLoadingCategories = false;
      });
    } catch (e) {
      setState(() {
        _categoryError = 'Failed to load categories';
        _isLoadingCategories = false;
      });
    }
  }

  /// Load subcategories from Firestore (filtered by category)
  Future<void> _loadSubCategories(String categoryId) async {
    setState(() {
      _isLoadingSubCategories = true;
      _subCategoryError = null;
      // Clear selected subcategory when category changes
      _selectedSubCategoryId = null;
      _selectedSubCategoryName = null;
    });
    
    try {
      final subCategories = await _categoryDataService.getSubCategories(categoryId: categoryId);
      setState(() {
        _subCategories = subCategories;
        _isLoadingSubCategories = false;
      });
    } catch (e) {
      setState(() {
        _subCategoryError = 'Failed to load subcategories';
        _isLoadingSubCategories = false;
      });
    }
  }

  /// Pick image from gallery or camera
  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                'Select Image',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              _buildImageSourceOption(
                icon: Icons.photo_library,
                title: 'Choose from Gallery',
                onTap: () async {
                  Navigator.pop(context);
                  final file = await _imageUploadService.pickImageFromGallery();
                  if (file != null && mounted) {
                    setState(() => _selectedImage = file);
                  }
                },
              ),
              const SizedBox(height: 12),
              _buildImageSourceOption(
                icon: Icons.camera_alt,
                title: 'Take a Photo',
                onTap: () async {
                  Navigator.pop(context);
                  final file = await _imageUploadService.pickImageFromCamera();
                  if (file != null && mounted) {
                    setState(() => _selectedImage = file);
                  }
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageSourceOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.primaryColor),
            const SizedBox(width: 16),
            Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Upload image with progress
  Future<void> _uploadImage() async {
    if (_selectedImage == null) return;
    
    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
    });
    
    try {
      final url = await _imageUploadService.uploadServiceImage(
        _selectedImage!,
        onProgress: (progress) {
          if (mounted) {
            setState(() => _uploadProgress = progress);
          }
        },
      );
      
      if (mounted) {
        setState(() {
          _uploadedImageUrl = url;
          _isUploading = false;
          _uploadProgress = 1.0;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image uploaded successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _uploadProgress = 0.0;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Save service with proper error handling
  Future<void> _saveService() async {
    // Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    // Validate category
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a category'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    // Validate image
    if (_selectedImage == null && _uploadedImageUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an image'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Prevent duplicate submissions
    if (_isSaving) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      // Upload image if not already uploaded
      String imageUrl = _uploadedImageUrl ?? '';
      if (_selectedImage != null && _uploadedImageUrl == null) {
        final uploadedUrl = await _imageUploadService.uploadServiceImage(
          _selectedImage!,
          onProgress: (progress) {
            if (mounted) {
              setState(() => _uploadProgress = progress);
            }
          },
        );
        if (uploadedUrl != null) {
          imageUrl = uploadedUrl;
        }
      }

      // Get technician ID
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        throw Exception('User not authenticated');
      }

      // Save service via Functions Service
      await _functionsService.addService(
        name: _nameController.text.trim(),
        price: double.parse(_priceController.text.trim()),
        imageUrl: imageUrl,
        category: _selectedCategoryId!,
        subCategory: _selectedSubCategoryId,
        description: _descriptionController.text.trim().isEmpty 
            ? null 
            : _descriptionController.text.trim(),
      );

      if (mounted) {
        // Refresh the technician's services
        context.read<TechnicianProvider>().refreshTechnicianData();
        
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Service added successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add service: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Add New Service',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF0F172A),
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image Picker Section
                _buildImagePickerSection(),
                const SizedBox(height: 24),
                
                // Service Name
                _buildSectionTitle('Service Details'),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: _nameController,
                  label: 'Service Name',
                  hint: 'e.g., AC Repair, Plumbing Service',
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter service name';
                    }
                    if (value.trim().length < 3) {
                      return 'Name must be at least 3 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Category Dropdown (Firestore-driven, Searchable)
                _buildSectionTitle('Category'),
                const SizedBox(height: 12),
                _buildCategoryDropdown(),
                const SizedBox(height: 16),
                
                // Subcategory Dropdown (350+ items, Searchable)
                _buildSectionTitle('Subcategory (Optional)'),
                const SizedBox(height: 12),
                _buildSubCategoryDropdown(),
                const SizedBox(height: 16),
                
                // Price
                _buildSectionTitle('Pricing'),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: _priceController,
                  label: 'Price (₹)',
                  hint: 'e.g., 500',
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter price';
                    }
                    final price = double.tryParse(value.trim());
                    if (price == null || price <= 0) {
                      return 'Please enter a valid price';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Description
                _buildSectionTitle('Description (Optional)'),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: _descriptionController,
                  label: 'Description',
                  hint: 'Describe your service...',
                  maxLines: 4,
                ),
                const SizedBox(height: 32),
                
                // Submit Button
                _buildSubmitButton(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF64748B),
      ),
    );
  }

  Widget _buildImagePickerSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _selectedImage != null 
              ? AppTheme.primaryColor 
              : const Color(0xFFE2E8F0),
          width: _selectedImage != null ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          if (_selectedImage != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                _selectedImage!,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 12),
            
            // Upload progress or status
            if (_isUploading)
              Column(
                children: [
                  LinearProgressIndicator(
                    value: _uploadProgress,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Uploading... ${(_uploadProgress * 100).toInt()}%',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              )
            else if (_uploadedImageUrl != null)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Image uploaded',
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.green,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              )
            else
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _uploadImage,
                  icon: const Icon(Icons.cloud_upload),
                  label: const Text('Upload Image'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () => setState(() {
                _selectedImage = null;
                _uploadedImageUrl = null;
                _uploadProgress = 0.0;
              }),
              icon: const Icon(Icons.refresh),
              label: const Text('Change Image'),
            ),
          ] else ...[
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 160,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFE2E8F0),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.add_photo_alternate_outlined,
                        size: 32,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Tap to add service image',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Square image recommended (1:1)',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 15,
        color: const Color(0xFF0F172A),
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.plusJakartaSans(
          color: const Color(0xFF94A3B8),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
      ),
    );
  }

  /// Build Firestore-driven Category dropdown with search
  Widget _buildCategoryDropdown() {
    // Convert CategoryData to DropdownItem
    final dropdownItems = _categories.map((cat) => DropdownItem(
      id: cat.id,
      label: cat.name,
      icon: _getIconForCategory(cat.iconName),
    )).toList();
    
    // Add "Custom" option at the end
    dropdownItems.add(const DropdownItem(
      id: 'custom',
      label: 'Custom',
      icon: Icons.add_circle_outline,
    ));

    // Find selected item
    DropdownItem? selectedItem;
    if (_selectedCategoryId != null) {
      final index = _categories.indexWhere((c) => c.id == _selectedCategoryId);
      if (index >= 0) {
        selectedItem = DropdownItem(
          id: _categories[index].id,
          label: _categories[index].name,
          icon: _getIconForCategory(_categories[index].iconName),
        );
      } else if (_selectedCategoryId == 'custom') {
        selectedItem = const DropdownItem(
          id: 'custom',
          label: 'Custom',
          icon: Icons.add_circle_outline,
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SearchableDropdown<DropdownItem>(
          items: dropdownItems,
          selectedItem: selectedItem,
          hint: 'Select category',
          searchHint: 'Search categories...',
          isLoading: _isLoadingCategories,
          enabled: !_isLoadingCategories,
          onChanged: (item) {
            if (item != null) {
              setState(() {
                _selectedCategoryId = item.id;
                _selectedCategoryName = item.label;
              });
              
              // Load subcategories for selected category
              if (item.id != 'custom') {
                _loadSubCategories(item.id);
              } else {
                setState(() => _subCategories = []);
              }
            }
          },
          selectedColor: AppTheme.primaryColor,
        ),
        if (_categoryError != null) ...[
          const SizedBox(height: 8),
          Text(
            _categoryError!,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: Colors.red,
            ),
          ),
        ],
      ],
    );
  }

  /// Build Subcategory dropdown (350+ items, searchable, virtualized)
  Widget _buildSubCategoryDropdown() {
    // Don't show subcategory if no category selected or custom category
    if (_selectedCategoryId == null || _selectedCategoryId == 'custom') {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.grey.shade500, size: 20),
            const SizedBox(width: 12),
            Text(
              'Select a category first',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    // Convert SubCategoryData to DropdownItem
    final dropdownItems = _subCategories.map((sub) => DropdownItem(
      id: sub.id,
      label: sub.name,
      subtitle: sub.categoryId,
    )).toList();
    
    // Add "Custom" option at the end
    dropdownItems.add(const DropdownItem(
      id: 'custom',
      label: 'Custom',
      subtitle: 'Add custom subcategory',
    ));

    // Find selected item
    DropdownItem? selectedItem;
    if (_selectedSubCategoryId != null) {
      final index = _subCategories.indexWhere((s) => s.id == _selectedSubCategoryId);
      if (index >= 0) {
        selectedItem = DropdownItem(
          id: _subCategories[index].id,
          label: _subCategories[index].name,
          subtitle: _subCategories[index].categoryId,
        );
      } else if (_selectedSubCategoryId == 'custom') {
        selectedItem = const DropdownItem(
          id: 'custom',
          label: 'Custom',
          subtitle: 'Add custom subcategory',
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SearchableDropdown<DropdownItem>(
          items: dropdownItems,
          selectedItem: selectedItem,
          hint: 'Select subcategory',
          searchHint: 'Search subcategories...',
          isLoading: _isLoadingSubCategories,
          enabled: !_isLoadingSubCategories && _selectedCategoryId != null && _selectedCategoryId != 'custom',
          onChanged: (item) {
            if (item != null) {
              setState(() {
                _selectedSubCategoryId = item.id;
                _selectedSubCategoryName = item.label;
              });
            }
          },
          selectedColor: AppTheme.primaryColor,
        ),
        if (_subCategoryError != null) ...[
          const SizedBox(height: 8),
          Text(
            _subCategoryError!,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: Colors.red,
            ),
          ),
        ],
        if (_isLoadingSubCategories)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 8),
                Text(
                  'Loading subcategories...',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _saveService,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
          disabledBackgroundColor: AppTheme.primaryColor.withOpacity(0.6),
        ),
        child: _isSaving
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                'Add Service',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  /// Get icon for category
  IconData _getIconForCategory(String? iconName) {
    switch (iconName?.toLowerCase()) {
      case 'ac':
        return Icons.ac_unit;
      case 'electrical':
        return Icons.electrical_services;
      case 'plumbing':
        return Icons.plumbing;
      case 'cleaning':
        return Icons.cleaning_services;
      case 'appliance':
        return Icons.kitchen;
      case 'carpentry':
        return Icons.carpenter;
      case 'painting':
        return Icons.format_paint;
      case 'spa':
        return Icons.spa;
      case 'salon':
        return Icons.content_cut;
      case 'pest_control':
        return Icons.pest_control;
      case 'water_purifier':
        return Icons.water_drop;
      default:
        return Icons.category;
    }
  }
}

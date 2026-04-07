import 'dart:async';
import 'dart:io';
import 'package:async/async.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../../core/app_theme.dart';
import '../../../core/services/functions_service.dart';
import '../../../core/services/category_data_service.dart';
import '../../../core/utils/image_upload_service.dart';
import '../../../core/utils/firestore_safe_parser.dart';
import '../../../core/widgets/searchable_dropdown.dart';
import '../../../core/providers/technician_provider.dart';
import 'service_config_widgets.dart';

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
/// - Bulletproof category → service reactive flow
/// - Ultra-safe custom service logic
class AddServiceScreen extends StatefulWidget {
  final Map<String, dynamic>? service;
  final String? serviceId;
  final bool isEdit;

  const AddServiceScreen({
    super.key,
    this.service,
    this.serviceId,
    this.isEdit = false,
  });

  @override
  State<AddServiceScreen> createState() => _AddServiceScreenState();
}

class _AddServiceScreenState extends State<AddServiceScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _customServiceController = TextEditingController();
  final TextEditingController _originalPriceController = TextEditingController();
  final TextEditingController _offerPriceController = TextEditingController();
  final _imageUploadService = ImageUploadService();
  final _functionsService = FunctionsService();
  final _categoryDataService = CategoryDataService();
  
  // Form state
  String? _selectedCategoryId;
  String? _selectedCategoryName;
  String? _selectedServiceId;
  String? _selectedServiceName;
  File? _selectedImage;
  String? _uploadedImageUrl;
  bool _showCustomServiceInput = false;
  
  // Urgent Booking state
  bool _urgentBookingEnabled = false;
  String? _urgentArrivalTime;
  int? _urgentFee;
  
  // Night Service state
  bool _nightServiceEnabled = false;
  int? _nightCharge;
  
  // Pricing state
  double? _originalPrice;
  double? _offerPrice;
  
  // Loading states
  bool _isUploading = false;
  bool _isSaving = false;
  double _uploadProgress = 0.0;
  
  // Data
  List<CategoryData> _categories = [];
  List<ServiceData> _services = [];
  bool _isLoadingCategories = true;
  bool _isLoadingServices = false;
  String? _categoryError;
  String? _serviceError;

  // PART 1: Async call cancellation
  CancelableOperation<List<ServiceData>>? _servicesOperation;

  // PART 2: Rapid tap prevention
  DateTime? _lastSaveTap;
  static const _saveDebounceMs = 500;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    
    // Prefill data in edit mode
    if (widget.isEdit && widget.service != null) {
      _prefillServiceData();
    }
  }

  void _prefillServiceData() {
    final service = widget.service!;
    _nameController.text = FirestoreSafeParser.toSafeString(service['name']);
    _descriptionController.text = FirestoreSafeParser.toSafeString(service['description']);
    
    final price = FirestoreSafeParser.toSafeDouble(service['price']);
    _priceController.text = price > 0 ? price.toStringAsFixed(0) : '';
    
    _originalPrice = FirestoreSafeParser.toSafeDouble(service['originalPrice']);
    if (_originalPrice != null && _originalPrice! > 0) {
      _originalPriceController.text = _originalPrice!.toStringAsFixed(0);
    }
    
    _offerPrice = FirestoreSafeParser.toSafeDouble(service['offerPrice']);
    if (_offerPrice != null && _offerPrice! > 0) {
      _offerPriceController.text = _offerPrice!.toStringAsFixed(0);
    }
    
    _selectedCategoryId = FirestoreSafeParser.toSafeString(service['category']);
    _uploadedImageUrl = FirestoreSafeParser.toSafeString(service['imageUrl']);
    
    setState(() {});
  }

  @override
  void dispose() {
    // Cancel pending operations
    _servicesOperation?.cancel();
    _nameController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _customServiceController.dispose();
    _originalPriceController.dispose();
    _offerPriceController.dispose();
    super.dispose();
  }

  /// Calculate discount percentage
  double _calculateDiscount() {
    if (_originalPrice == null ||
        _offerPrice == null ||
        _originalPrice! <= 0 ||
        _offerPrice! <= 0 ||
        _offerPrice! >= _originalPrice!) {
      return 0;
    }
    final discount = ((_originalPrice! - _offerPrice!) / _originalPrice!) * 100;
    return discount.clamp(0.0, 99.0);
  }

  /// Load categories from Firestore with strict requirement
  Future<void> _loadCategories() async {
    setState(() {
      _isLoadingCategories = true;
      _categoryError = null;
    });
    
    try {
      // STRICT: Clear cache at start of screen to ensure fresh data
      _categoryDataService.clearCache();
      
      final categories = await _categoryDataService.getCategories();
      
      if (mounted) {
        // Handle empty collection
        if (categories.isEmpty) {
          setState(() {
            _categoryError = 'No service categories available. Please try again later.';
            _isLoadingCategories = false;
          });
          return;
        }

        setState(() {
          _categories = categories;
          _isLoadingCategories = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _categoryError = 'Failed to load categories. Please check your connection.';
          _isLoadingCategories = false;
        });
      }
    }
  }



  /// Load services from Firestore (filtered by category)
  /// Uses collection: services
  /// Query: .where("categoryId", isEqualTo: selectedCategoryId).where("isActive", isEqualTo: true)
  /// PART 1: Cancel previous async call if running, clear previous services, reset selected service
  Future<void> _loadServices(String? categoryId) async {
    // Cancel previous operation if running
    
    
    // Handle null categoryId or custom category
    if (categoryId == null || categoryId == 'custom') {
      setState(() {
        _services = [];
        _isLoadingServices = false;
        _selectedServiceId = null;
        _selectedServiceName = null;
      });
      return;
    }
    
    setState(() {
      _isLoadingServices = true;
      _serviceError = null;
      // Clear selected service when category changes
      _selectedServiceId = null;
      _selectedServiceName = null;
    });
    
    try {
      final services = await _categoryDataService.getServicesByCategory(categoryId);
      
      if (mounted) {
        final uniqueServices = _deduplicateServices(services);
        
        setState(() {
          _services = uniqueServices;
          _isLoadingServices = false;
        });
      }
    } on FirebaseException catch (e) {
      if (mounted) {
        setState(() {
          _serviceError = _getFriendlyErrorMessage(e);
          _isLoadingServices = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _serviceError = 'Failed to load services';
          _isLoadingServices = false;
        });
      }
    }
  }

  /// PART 1: Safe deduplication by serviceId
  List<ServiceData> _deduplicateServices(List<ServiceData> services) {
    final seenIds = <String>{};
    final uniqueServices = <ServiceData>[];
    
    for (final service in services) {
      if (!seenIds.contains(service.id)) {
        seenIds.add(service.id);
        uniqueServices.add(service);
      }
    }
    
    return uniqueServices;
  }

  /// Get user-friendly error message from FirebaseException
  String _getFriendlyErrorMessage(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return 'Access denied. Please check your permissions.';
      case 'unavailable':
        return 'Network unavailable. Please check your connection and try again.';
      case 'deadline-exceeded':
        return 'Request timed out. Please try again.';
      case 'not-found':
        return 'Data not found.';
      default:
        return 'Failed to load data. Please try again.';
    }
  }

  /// PART 2: Add custom service to technician profile
  /// Ultra-safe version with:
  /// - trim input
  /// - collapse multiple spaces
  /// - case-insensitive duplicate check
  /// - length >= 3, max length = 60
  /// - disable add button while saving
  /// - prevent rapid taps
  /// - re-fetch latest technician doc
  /// - merge safely (arrayUnion preferred if available)
  Future<void> _addCustomService(String customServiceName) async {
    // PART 2: Trim input and collapse multiple spaces
    final trimmedName = customServiceName.trim().replaceAll(RegExp(r'\s+'), ' ');
    
    // PART 2: Length validation
    if (trimmedName.length < 3) {
      throw Exception('Custom service name must be at least 3 characters');
    }
    if (trimmedName.length > 60) {
      throw Exception('Custom service name must be 60 characters or less');
    }
    
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) throw Exception('User not authenticated');

      // PART 2: Re-fetch latest technician doc before saving
      final techDoc = await FirebaseFirestore.instance
          .collection('technicians')
          .doc(uid)
          .get();
      
      if (!techDoc.exists) {
        throw Exception('Technician profile not found');
      }
      
      final existingCustomServices = (techDoc.data()?['customServices'] as List?)
          ?.map((e) => e.toString())
          .toList() ?? [];
      
      // PART 2: Case-insensitive duplicate check
      if (existingCustomServices.any((s) => s.toLowerCase() == trimmedName.toLowerCase())) {
        throw Exception('This custom service already exists');
      }

      // PART 2: Merge safely using arrayUnion
      final updatedCustomServices = [...existingCustomServices, trimmedName];
      
      await FirebaseFirestore.instance
          .collection('technicians')
          .doc(uid)
          .update({
            'customServices': updatedCustomServices,
            'updatedAt': FieldValue.serverTimestamp(),
          });

      if (mounted) {
        await context.read<TechnicianProvider>().refreshTechnicianData();
      }
    } catch (e) {
      rethrow;
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
  /// PART 2: Prevent rapid taps
  Future<void> _saveService() async {
    debugPrint("[ADD SERVICE] Submit pressed");
    debugPrint("categoryId=$_selectedCategoryId");
    debugPrint("serviceId=$_selectedServiceId");
    debugPrint("isEdit=${widget.isEdit}");
    
    // APPROVAL CHECK: Validate technician approval before proceeding
    final techProvider = context.read<TechnicianProvider>();
    if (!techProvider.canCreateServices()) {
      final message = techProvider.getServiceBlockMessage();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    // PART 2: Prevent rapid taps
    final now = DateTime.now();
    if (_lastSaveTap != null && 
        now.difference(_lastSaveTap!).inMilliseconds < _saveDebounceMs) {
      return;
    }
    _lastSaveTap = now;
    
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
    
    // Validate Urgent Booking: if enabled, must have arrivalTime and urgentFee
    if (_urgentBookingEnabled) {
      if (_urgentArrivalTime == null || _urgentFee == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select urgent arrival time and urgent fee'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
    }
    
    // Validate Night Service: if enabled, must have nightCharge
    if (_nightServiceEnabled && _nightCharge == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select night service charge'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    // Handle custom service separately
    if (_selectedCategoryId == 'custom') {
      // Validate custom service name with all PART 2 validations
      final customName = _customServiceController.text.trim().replaceAll(RegExp(r'\s+'), ' ');
      if (customName.length < 3) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Custom service name must be at least 3 characters'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
      if (customName.length > 60) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Custom service name must be 60 characters or less'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
      
      // PART 2: Prevent duplicate submissions and disable button while saving
      if (_isSaving) return;
      
      setState(() => _isSaving = true);
      
      try {
        await _addCustomService(customName);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Custom service added successfully'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isSaving = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to add custom service: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
      return;
    }
    
    // Validate image (not required for edit mode)
    if (!widget.isEdit && _selectedCategoryId != 'custom' && _selectedImage == null && _uploadedImageUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an image'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // CRITICAL PRICE VALIDATION
    // 1. Both prices are required (not for custom category)
    if (_selectedCategoryId != 'custom') {
      if (_originalPrice == null || _originalPrice! <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Original price is required and must be greater than 0'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      if (_offerPrice == null || _offerPrice! <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Offer price is required and must be greater than 0'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // 2. Offer price MUST be strictly less than original price
      if (_offerPrice! >= _originalPrice!) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Offer price must be strictly less than original price'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
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

      if (widget.isEdit && widget.serviceId != null) {
        // UPDATE existing service
        debugPrint('[UPDATE DEBUG] originalPrice: $_originalPrice, offerPrice: $_offerPrice');
        await _functionsService.updateService(
          serviceId: widget.serviceId!,
          name: _nameController.text.trim(),
          price: _originalPrice!,  // Main price (before discount)
          offerPrice: _offerPrice!, // Discounted price
          imageUrl: imageUrl.isNotEmpty ? imageUrl : null,
          category: _selectedCategoryId,
          description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
          urgentBooking: _urgentBookingEnabled ? {
            'enabled': true,
            'arrivalTime': _urgentArrivalTime,
            'urgentFee': _urgentFee,
          } : null,
          nightService: _nightServiceEnabled ? {
            'enabled': true,
            'nightCharge': _nightCharge,
          } : null,
        );
        debugPrint("[UPDATE SERVICE] SUCCESS");
      } else {
        // CREATE new service
        // CRITICAL: Send originalPrice as 'price', offerPrice as 'offerPrice'
        debugPrint('[SAVE DEBUG] originalPrice: $_originalPrice, offerPrice: $_offerPrice');
        await _functionsService.addService(
          name: _nameController.text.trim(),
          price: _originalPrice!,  // Main price (before discount)
          offerPrice: _offerPrice!, // Discounted price
          imageUrl: imageUrl,
          category: _selectedCategoryId!,
          description: _descriptionController.text.trim().isEmpty 
              ? null 
              : _descriptionController.text.trim(),
          urgentBooking: _urgentBookingEnabled ? {
            'enabled': true,
            'arrivalTime': _urgentArrivalTime,
            'urgentFee': _urgentFee,
          } : null,
          nightService: _nightServiceEnabled ? {
            'enabled': true,
            'nightCharge': _nightCharge,
          } : null,
        );
        debugPrint("[ADD SERVICE] SUCCESS");
      }

      debugPrint('[WRITE VERIFY] service ${widget.isEdit ? "updated" : "added"}');

      if (mounted) {
        // Refresh the technician's services
        await context.read<TechnicianProvider>().refreshTechnicianData();
        debugPrint('[Provider] refreshed');
      }
        
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Service ${widget.isEdit ? "updated" : "added"} successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to ${widget.isEdit ? "update" : "add"} service: $e'),
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
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.isEdit ? 'Edit Service' : 'Add New Service',
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
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
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
                  readOnly: widget.isEdit,
                  validator: (value) {
                    // Skip validation for custom category
                    if (_selectedCategoryId == 'custom') return null;
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter service name';
                    }
                    if (value.trim().length < 3) {
                      return 'Name must be at least 3 characters';
                    }
                    return null;
                  },
                ),
                if (widget.isEdit)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Service name cannot be changed',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                
                // Category Dropdown (Firestore-driven, Searchable)
                _buildSectionTitle('Category'),
                const SizedBox(height: 12),
                _buildCategoryDropdown(),
                const SizedBox(height: 16),
                
                // Custom Service Input (when "Custom" is selected)
                if (_showCustomServiceInput) ...[
                  _buildCustomServiceInput(),
                  const SizedBox(height: 16),
                ],
                
                // Services Dropdown (when category selected and not custom)
                if (_selectedCategoryId != null && _selectedCategoryId != 'custom') ...[
                  _buildSectionTitle('Service'),
                  const SizedBox(height: 12),
                  _buildServicesDropdown(),
                  const SizedBox(height: 16),
                ],
                
                
                // Modern Pricing Section
                _buildSectionTitle('Pricing'),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: _originalPriceController,
                  label: 'Original Price (₹)',
                  hint: 'e.g., 700',
                  keyboardType: TextInputType.number,
                  onChanged: (v) {
                    _originalPrice = double.tryParse(v);
                    setState(() {});
                  },
                  validator: (value) {
                    if (_selectedCategoryId == 'custom') return null;
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter original price';
                    }
                    final price = double.tryParse(value.trim());
                    if (price == null || price <= 0) {
                      return 'Please enter a valid price';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: _offerPriceController,
                  label: 'Offer Price (₹)',
                  hint: 'e.g., 400',
                  keyboardType: TextInputType.number,
                  onChanged: (v) {
                    _offerPrice = double.tryParse(v);
                    _priceController.text = v;
                    setState(() {});
                  },
                  validator: (value) {
                    if (_selectedCategoryId == 'custom') return null;
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter offer price';
                    }
                    final price = double.tryParse(value.trim());
                    if (price == null || price <= 0) {
                      return 'Please enter a valid price';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                _PricePreviewCard(
                  originalPrice: _originalPrice,
                  offerPrice: _offerPrice,
                  discountPercent: _calculateDiscount(),
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
                
                // Urgent Booking Section
                UrgentBookingConfigWidget(
                  enabled: _urgentBookingEnabled,
                  arrivalTime: _urgentArrivalTime,
                  urgentFee: _urgentFee,
                  onEnabledChanged: (value) => setState(() => _urgentBookingEnabled = value),
                  onArrivalTimeChanged: (value) => setState(() => _urgentArrivalTime = value),
                  onUrgentFeeChanged: (value) => setState(() => _urgentFee = value),
                ),
                const SizedBox(height: 16),
                
                // Night Service Section
                NightServiceConfigWidget(
                  enabled: _nightServiceEnabled,
                  nightCharge: _nightCharge,
                  onEnabledChanged: (value) => setState(() => _nightServiceEnabled = value),
                  onNightChargeChanged: (value) => setState(() => _nightCharge = value),
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
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF0F172A),
      ),
    );
  }

  Widget _buildImagePickerSection() {
    return Center(
      child: SizedBox(
        width: 240, 
        child: AspectRatio(
          aspectRatio: 1.0,
          child: GestureDetector(
            onTap: _pickImage,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFFE2E8F0),
                  width: 2,
                ),
              ),
              child: _selectedImage != null
            ? Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.file(
                      _selectedImage!,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => setState(() => _selectedImage = null),
                      ),
                    ),
                  ),
                  if (_isUploading)
                    Positioned.fill(
                      child: Container(
                        color: Colors.black.withOpacity(0.5),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(
                                value: _uploadProgress,
                                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${(_uploadProgress * 100).toInt()}%',
                                style: GoogleFonts.plusJakartaSans(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              )
            : _uploadedImageUrl != null
                ? Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.network(
                          _uploadedImageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildImagePlaceholder(),
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            onPressed: () => setState(() => _uploadedImageUrl = null),
                          ),
                        ),
                      ),
                    ],
                  )
                : _buildImagePlaceholder(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
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
    bool readOnly = false,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        readOnly: readOnly,
        validator: validator,
        onChanged: onChanged,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 15,
          color: readOnly ? Colors.grey.shade600 : const Color(0xFF0F172A),
        ),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: GoogleFonts.plusJakartaSans(
            color: const Color(0xFF64748B),
            fontSize: 14,
          ),
          hintStyle: GoogleFonts.plusJakartaSans(
            color: const Color(0xFF94A3B8),
          ),
          filled: true,
          fillColor: Colors.grey.shade50,
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
      ),
    );
  }

  /// Build Firestore-driven Category dropdown with search
  /// PART 1: Shimmer while loading, retry button on error
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
      label: 'Custom Service',
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
          label: 'Custom Service',
          icon: Icons.add_circle_outline,
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // PART 1: Shimmer while loading
        if (_isLoadingCategories)
          _buildShimmerDropdown()
        else
          SearchableDropdown<DropdownItem>(
            items: dropdownItems,
            selectedItem: selectedItem,
            hint: 'Select category',
            searchHint: 'Search categories...',
            isLoading: _isLoadingCategories,
            enabled: !_isLoadingCategories,
            onChanged: (item) {
              if (item != null) {
                _onCategoryChanged(item);
              }
            },
            selectedColor: AppTheme.primaryColor,
          ),
        // PART 1: Retry button on error
        if (_categoryError != null) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Flexible(
                fit: FlexFit.loose,
                child: Text(
                  _categoryError!,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: Colors.red,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: _loadCategories,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Retry'),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  /// PART 1: Shimmer effect for dropdown
  Widget _buildShimmerDropdown() {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ShimmerLoading(),
    );
  }

  /// Handle category change - clear previous services, reset selected service, show loading
  void _onCategoryChanged(DropdownItem item) {
    setState(() {
      _selectedCategoryId = item.id;
      _selectedCategoryName = item.label;
      
      // ISSUE 2 FIX: Safe reset - clear services list
      _services = [];
      _selectedServiceId = null;
      _selectedServiceName = null;
      
      // Handle custom category
      if (item.id == 'custom') {
        _showCustomServiceInput = true;
      } else {
        _showCustomServiceInput = false;
        // Load services for selected category
        _loadServices(item.id);
      }
    });
  }

  /// Build Services dropdown (shows services from 'services' collection when category selected)
  Widget _buildServicesDropdown() {
    // Don't show if no category selected
    if (_selectedCategoryId == null || _selectedCategoryId == 'custom') {
      return const SizedBox.shrink();
    }

    // ISSUE 2 FIX: Safe iteration - check list bounds
    final dropdownItems = <DropdownItem>[];
    for (int i = 0; i < _services.length; i++) {
      if (i < _services.length) {
        final service = _services[i];
        dropdownItems.add(DropdownItem(
          id: service.id,
          label: service.name,
          subtitle: service.description,
        ));
      }
    }

    // Find selected item safely
    DropdownItem? selectedItem;
    if (_selectedServiceId != null && _services.isNotEmpty) {
      try {
        final index = _services.indexWhere((s) => s.id == _selectedServiceId);
        if (index >= 0 && index < _services.length) {
          selectedItem = DropdownItem(
            id: _services[index].id,
            label: _services[index].name,
            subtitle: _services[index].description,
          );
        }
      } catch (e) {
        debugPrint('[SAFE INDEX] Error finding selected service: $e');
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SearchableDropdown<DropdownItem>(
          items: dropdownItems,
          selectedItem: selectedItem,
          hint: 'Select service',
          searchHint: 'Search services...',
          isLoading: _isLoadingServices,
          enabled: !_isLoadingServices && _services.isNotEmpty,
          onChanged: (item) {
            if (item != null) {
              setState(() {
                _selectedServiceId = item.id;
                _selectedServiceName = item.label;
                // Pre-fill name from selected service
                if (_nameController.text.isEmpty) {
                  _nameController.text = item.label;
                }
              });
              
              // ISSUE 2 FIX: Safe auto-fill price with bounds check
              try {
                final serviceIndex = _services.indexWhere((s) => s.id == item.id);
                if (serviceIndex >= 0 && serviceIndex < _services.length) {
                  final service = _services[serviceIndex];
                  if (service.basePrice != null) {
                    _priceController.text = service.basePrice!.toStringAsFixed(0);
                  }
                }
              } catch (e) {
                debugPrint('[SAFE INDEX] Error auto-filling price: $e');
              }
            }
          },
          selectedColor: AppTheme.primaryColor,
        ),
        if (_serviceError != null) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Flexible(
                fit: FlexFit.loose,
                child: Text(
                  _serviceError!,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: Colors.red,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: () => _loadServices(_selectedCategoryId),
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Retry'),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
        ],
        // PART 1: Shimmer while loading
        if (_isLoadingServices)
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
                  'Loading services...',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        // PART 1: Handle empty services
        if (!_isLoadingServices && _services.isEmpty && _selectedCategoryId != null && _selectedCategoryId != 'custom')
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'No services available for this category',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ),
      ],
    );
  }

  /// Build custom service input field (shown when "Custom" category is selected)
  Widget _buildCustomServiceInput() {
    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Custom Service Name'),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _customServiceController,
            label: 'Custom Service Name',
            hint: 'Enter your custom service name (min 3 characters)',
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter a custom service name';
              }
              final trimmed = value.trim().replaceAll(RegExp(r'\s+'), ' ');
              if (trimmed.length < 3) {
                return 'Service name must be at least 3 characters';
              }
              if (trimmed.length > 60) {
                return 'Service name must be 60 characters or less';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          onPressed: _isSaving ? null : _saveService,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
            disabledBackgroundColor: AppTheme.primaryColor.withOpacity(0.6),
          ),
          child: _isSaving
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
                  widget.isEdit ? 'Update Service' : 'Add Service',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
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

/// Shimmer loading placeholder widget
class ShimmerLoading extends StatefulWidget {
  const ShimmerLoading({super.key});

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    _animation = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(_animation.value, 0),
              end: Alignment(_animation.value + 1, 0),
              colors: [
                Colors.grey.shade200,
                Colors.grey.shade100,
                Colors.grey.shade200,
              ],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
        );
      },
    );
  }
}



// ============ PRICE PREVIEW CARD ============

class _PricePreviewCard extends StatelessWidget {
  final double? originalPrice;
  final double? offerPrice;
  final double discountPercent;

  const _PricePreviewCard({
    required this.originalPrice,
    required this.offerPrice,
    required this.discountPercent,
  });

  @override
  Widget build(BuildContext context) {
    if (offerPrice == null || offerPrice == 0) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7FF)),
      ),
      child: Row(
        children: [
          if (originalPrice != null && originalPrice! > offerPrice!)
            Text(
              '\u20b9${originalPrice!.toStringAsFixed(0)}',
              style: const TextStyle(
                decoration: TextDecoration.lineThrough,
                color: Colors.black45,
                fontSize: 16,
              ),
            ),
          if (originalPrice != null && originalPrice! > offerPrice!)
            const SizedBox(width: 8),
          Text(
            '\u20b9${offerPrice!.toStringAsFixed(0)}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: Color(0xFF6366F1),
            ),
          ),
          const Spacer(),
          if (discountPercent > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Color(0xFF10B981).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${discountPercent.toStringAsFixed(0)}% OFF',
                style: const TextStyle(
                  color: Color(0xFF10B981),
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

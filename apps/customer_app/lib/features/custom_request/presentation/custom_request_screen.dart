import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'dart:io';

import 'package:customer_app/core/theme/app_theme.dart';
import 'package:customer_app/core/services/firestore_service.dart';
import 'package:customer_app/core/services/storage_service.dart';
import 'package:customer_app/core/services/auth_service.dart';
import 'package:customer_app/core/models/address.dart';
import '../../profile/presentation/saved_addresses_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CustomRequestScreen extends StatefulWidget {
  const CustomRequestScreen({super.key});

  @override
  State<CustomRequestScreen> createState() => _CustomRequestScreenState();
}

class _CustomRequestScreenState extends State<CustomRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _customCategoryController = TextEditingController();
  final _customSubCategoryController = TextEditingController();
  final _imagePicker = ImagePicker();
  
  String? _selectedCategory;
  String? _selectedSubCategory;
  String? _selectedPriority;
  String? _selectedTimeSlot;
  Address? _selectedAddress;
  DateTime? _preferredDate;
  List<File> _selectedImages = [];
  bool _isSubmitting = false;
  
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _subCategories = [];
  bool _isLoadingCategories = true;
  bool _isLoadingSubCategories = false;

  final List<String> _priorities = [
    'Low',
    'Medium', 
    'High',
    'Urgent'
  ];

  final List<String> _timeSlots = [
    '9:00 AM - 12:00 PM',
    '12:00 PM - 3:00 PM',
    '3:00 PM - 6:00 PM',
    '6:00 PM - 9:00 PM',
    'Flexible'
  ];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _customCategoryController.dispose();
    _customSubCategoryController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final firestoreService = Provider.of<FirestoreService>(context, listen: false);
      final categories = await firestoreService.getCategories();
      
      // Add custom option
      categories.add({'id': 'custom', 'name': 'Custom', 'icon': 'edit'});
      
      setState(() {
        _categories = categories;
        _isLoadingCategories = false;
      });
    } catch (e) {
      setState(() => _isLoadingCategories = false);
      print('Error loading categories: $e');
    }
  }

  Future<void> _loadSubCategories(String categoryId) async {
    if (categoryId == 'custom') {
      setState(() {
        _subCategories = [{'id': 'custom', 'name': 'Custom'}];
        _isLoadingSubCategories = false;
      });
      return;
    }
    
    setState(() => _isLoadingSubCategories = true);
    try {
      final firestoreService = Provider.of<FirestoreService>(context, listen: false);
      final subCategories = await firestoreService.fetchSubCategories(categoryId);
      
      // Add custom option
      subCategories.add({'id': 'custom', 'name': 'Custom'});
      
      setState(() {
        _subCategories = subCategories;
        _selectedSubCategory = null;
        _isLoadingSubCategories = false;
      });
    } catch (e) {
      setState(() => _isLoadingSubCategories = false);
      print('Error loading subcategories: $e');
    }
  }

  Future<void> _pickImages() async {
    if (_selectedImages.length >= 3) {
      _showError('Maximum 3 images allowed');
      return;
    }
    
    final images = await _imagePicker.pickMultiImage(
      imageQuality: 70,
      maxWidth: 1200,
    );
    
    if (images.isNotEmpty) {
      final remainingSlots = 3 - _selectedImages.length;
      final imagesToAdd = images.take(remainingSlots).map((img) => File(img.path)).toList();
      setState(() {
        _selectedImages.addAll(imagesToAdd);
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> _selectAddress() async {
    final address = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SavedAddressesScreen(isSelectionMode: true),
      ),
    );
    if (address != null && mounted) {
      setState(() => _selectedAddress = address as Address);
    }
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      _showError('Please select a category');
      return;
    }
    if (_selectedAddress == null) {
      _showError('Please select an address');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final userId = authService.currentUser?.uid;
      
      if (userId == null) throw Exception('User not authenticated');

      List<String> imageUrls = [];
      if (_selectedImages.isNotEmpty) {
        final storageService = StorageService();
        final requestId = DateTime.now().millisecondsSinceEpoch.toString();
        
        for (int i = 0; i < _selectedImages.length; i++) {
          final urls = await storageService.uploadMultipleFiles(
            files: [_selectedImages[i]],
            path: 'custom_requests/$requestId/images/image_${i + 1}',
          );
          if (urls.isNotEmpty) {
            imageUrls.add(urls.first);
          }
        }
      }

      final category = _selectedCategory == 'custom' 
          ? _customCategoryController.text.trim()
          : _selectedCategory!;
      
      final subCategory = _selectedSubCategory == 'custom'
          ? _customSubCategoryController.text.trim()
          : _selectedSubCategory;

      final firestoreService = FirestoreService();
      await firestoreService.createCustomRequest({
        'customerId': userId,
        'title': _titleController.text.trim(),
        'category': category,
        'subCategory': subCategory,
        'description': _descriptionController.text.trim(),
        'images': imageUrls,
        'address': _selectedAddress!.toMap(),
        'district': _selectedAddress!.district,
        'state': _selectedAddress!.state,
        'latitude': _selectedAddress!.latitude,
        'longitude': _selectedAddress!.longitude,
        'preferredDate': _preferredDate?.toIso8601String(),
        'preferredTime': _selectedTimeSlot,
        'priority': _selectedPriority ?? 'Medium',
        'status': 'open',
        'createdAt': FieldValue.serverTimestamp(),
      });

      print('[CUSTOM_REQUEST] Request submitted successfully');

      if (!mounted) return;
      _showSuccess();
    } catch (e) {
      print('[CUSTOM_REQUEST] Error: $e');
      if (mounted) _showError('Failed to submit: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccess() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle, color: Colors.green, size: 48),
            ),
            const SizedBox(height: 20),
            Text(
              'Request Sent!',
              style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 20),
            ),
            const SizedBox(height: 12),
            Text(
              'Our team will review your request and contact you soon.',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(color: Colors.grey[600], fontSize: 14),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _resetForm();
                },
                child: const Text('Continue'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _resetForm() {
    _titleController.clear();
    _descriptionController.clear();
    _customCategoryController.clear();
    _customSubCategoryController.clear();
    setState(() {
      _selectedCategory = null;
      _selectedSubCategory = null;
      _selectedPriority = null;
      _selectedTimeSlot = null;
      _selectedAddress = null;
      _preferredDate = null;
      _selectedImages.clear();
      _subCategories.clear();
    });
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'open':
        return Colors.blue;
      case 'assigned':
        return Colors.orange;
      case 'accepted':
        return Colors.green;
      case 'in_progress':
        return Colors.purple;
      case 'completed':
        return Colors.teal;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Custom Service Request',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w800),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppTheme.textColor,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFF6F8FF),
              Color(0xFFEFF2FF)
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTitle(),
                const SizedBox(height: 24),
                _buildForm(),
                const SizedBox(height: 32),
                _buildMyRequestsSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return Text(
      'Request Custom Service',
      style: GoogleFonts.outfit(
        fontSize: 28,
        fontWeight: FontWeight.w900,
        color: AppTheme.textColor,
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Service Title
          _buildFieldLabel('Service Title', Icons.title),
          const SizedBox(height: 8),
          TextFormField(
            controller: _titleController,
            decoration: _buildInputDecoration('e.g., Fix leaking tap'),
            validator: (val) => val?.isEmpty ?? true ? 'Title is required' : null,
          ),
          const SizedBox(height: 20),

          // Category
          _buildFieldLabel('Category', Icons.category),
          const SizedBox(height: 8),
          _isLoadingCategories
              ? const CircularProgressIndicator()
              : DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: _buildInputDecoration('Select category'),
                  items: _categories.map((cat) => DropdownMenuItem<String>(
                    value: cat['id'] as String, 
                    child: Text(cat['name'] as String, style: GoogleFonts.outfit()),
                  )).toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedCategory = val;
                      _selectedSubCategory = null;
                      _subCategories.clear();
                    });
                    if (val != null) {
                      _loadSubCategories(val);
                    }
                  },
                  validator: (val) => val == null ? 'Please select a category' : null,
                ),
          const SizedBox(height: 20),

          // Custom Category Input
          if (_selectedCategory == 'custom') ...[
            _buildFieldLabel('Custom Category', Icons.edit),
            const SizedBox(height: 8),
            TextFormField(
              controller: _customCategoryController,
              decoration: _buildInputDecoration('Enter custom category'),
              validator: (val) => val?.isEmpty ?? true ? 'Custom category is required' : null,
            ),
            const SizedBox(height: 20),
          ],

          // Subcategory
          if (_selectedCategory != null && _selectedCategory != 'custom') ...[
            _buildFieldLabel('Subcategory', Icons.subdirectory_arrow_right),
            const SizedBox(height: 8),
            _isLoadingSubCategories
                ? const CircularProgressIndicator()
                : DropdownButtonFormField<String>(
                    value: _selectedSubCategory,
                    decoration: _buildInputDecoration('Select subcategory'),
                    items: _subCategories.map((subCat) => DropdownMenuItem<String>(
                      value: subCat['id'] as String,
                      child: Text(subCat['name'] as String, style: GoogleFonts.outfit()),
                    )).toList(),
                    onChanged: (val) => setState(() => _selectedSubCategory = val),
                  ),
            const SizedBox(height: 20),
          ],

          // Custom Subcategory Input
          if (_selectedSubCategory == 'custom') ...[
            _buildFieldLabel('Custom Subcategory', Icons.edit),
            const SizedBox(height: 8),
            TextFormField(
              controller: _customSubCategoryController,
              decoration: _buildInputDecoration('Enter custom subcategory'),
              validator: (val) => val?.isEmpty ?? true ? 'Custom subcategory is required' : null,
            ),
            const SizedBox(height: 20),
          ],

          // Description
          _buildFieldLabel('Problem Description', Icons.description),
          const SizedBox(height: 8),
          TextFormField(
            controller: _descriptionController,
            maxLines: 4,
            decoration: _buildInputDecoration('Describe the issue in detail...'),
            validator: (val) => (val?.isEmpty ?? true) || (val?.length ?? 0) < 10
                ? 'Please provide at least 10 characters'
                : null,
          ),
          const SizedBox(height: 20),

          // Image Upload (Max 3)
          _buildFieldLabel('Photos (Max 3)', Icons.photo_camera),
          const SizedBox(height: 8),
          _buildImageUploader(),
          const SizedBox(height: 20),

          // Preferred Date
          _buildFieldLabel('Preferred Date (Optional)', Icons.calendar_today),
          const SizedBox(height: 8),
          _buildDatePicker(),
          const SizedBox(height: 20),

          // Time Slot
          _buildFieldLabel('Preferred Time (Optional)', Icons.access_time),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedTimeSlot,
            decoration: _buildInputDecoration('Select time slot'),
            items: _timeSlots.map((slot) => DropdownMenuItem(
              value: slot,
              child: Text(slot, style: GoogleFonts.outfit()),
            )).toList(),
            onChanged: (val) => setState(() => _selectedTimeSlot = val),
          ),
          const SizedBox(height: 20),

          // Priority
          _buildFieldLabel('Priority', Icons.priority_high),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedPriority,
            decoration: _buildInputDecoration('Select priority'),
            items: _priorities.map((priority) => DropdownMenuItem(
              value: priority,
              child: Row(
                children: [
                  Icon(
                    _getPriorityIcon(priority),
                    color: _getPriorityColor(priority),
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(priority, style: GoogleFonts.outfit()),
                ],
              ),
            )).toList(),
            onChanged: (val) => setState(() => _selectedPriority = val),
          ),
          const SizedBox(height: 20),

          // Service Location
          _buildFieldLabel('Service Location', Icons.location_on),
          const SizedBox(height: 8),
          _buildAddressSelector(),
          const SizedBox(height: 32),

          // Submit Button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: _isSubmitting ? null : _submitRequest,
              icon: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.send, size: 20),
              label: Text(
                'Submit Request',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w700, 
                  fontSize: 16
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyRequestsSection() {
    final authService = Provider.of<AuthService>(context, listen: false);
    final userId = authService.currentUser?.uid;

    if (userId == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'My Requests',
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: AppTheme.textColor,
          ),
        ),
        const SizedBox(height: 16),
        StreamBuilder<List<Map<String, dynamic>>>(
          stream: FirestoreService().streamCustomRequests(userId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                      const SizedBox(height: 16),
                      Text(
                        'Error loading requests',
                        style: GoogleFonts.outfit(color: Colors.red[600]),
                      ),
                    ],
                  ),
                ),
              );
            }

            final requests = snapshot.data ?? [];

            if (requests.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text(
                        'No requests yet',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Create your first request above',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: requests.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final request = requests[index];
                return _buildRequestCard(request);
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> request) {
    final status = request['status'] ?? 'open';
    final statusColor = _getStatusColor(status);
    
    DateTime createdAt;
    try {
      if (request['createdAt'] is Timestamp) {
        createdAt = (request['createdAt'] as Timestamp).toDate();
      } else if (request['createdAt'] is String) {
        createdAt = DateTime.parse(request['createdAt']);
      } else {
        createdAt = DateTime.now();
      }
    } catch (e) {
      createdAt = DateTime.now();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  request['title'] ?? 'Untitled Request',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: AppTheme.textColor,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: GoogleFonts.outfit(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            request['category'] ?? 'N/A',
            style: GoogleFonts.outfit(
              fontSize: 12,
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            DateFormat('MMM dd, yyyy').format(createdAt),
            style: GoogleFonts.outfit(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods
  Widget _buildFieldLabel(String label, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.primaryColor),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: AppTheme.textColor,
          ),
        ),
      ],
    );
  }

  InputDecoration _buildInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.outfit(color: Colors.grey[500]),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      filled: true,
      fillColor: Colors.white,
    );
  }

  Widget _buildImageUploader() {
    return Column(
      children: [
        Row(
          children: List.generate(3, (index) {
            if (index < _selectedImages.length) {
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: index < 2 ? 8 : 0),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          _selectedImages[index],
                          height: 100,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => _removeImage(index),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close, size: 16, color: Colors.red),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            } else {
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: index < 2 ? 8 : 0),
                  child: GestureDetector(
                    onTap: _selectedImages.length < 3 ? _pickImages : null,
                    child: Container(
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _selectedImages.length < 3 ? Colors.grey[300]! : Colors.grey[200]!,
                          style: BorderStyle.solid,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_photo_alternate,
                            size: 24,
                            color: _selectedImages.length < 3 ? Colors.grey[400] : Colors.grey[300],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Add',
                            style: GoogleFonts.outfit(
                              fontSize: 10,
                              color: _selectedImages.length < 3 ? Colors.grey[600] : Colors.grey[400],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }
          }),
        ),
        if (_selectedImages.length > 0)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '${_selectedImages.length}/3 images selected',
              style: GoogleFonts.outfit(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDatePicker() {
    return GestureDetector(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: DateTime.now().add(const Duration(days: 1)),
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 90)),
        );
        if (date != null) setState(() => _preferredDate = date);
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today,
              color: _preferredDate != null ? AppTheme.primaryColor : Colors.grey[500],
            ),
            const SizedBox(width: 12),
            Text(
              _preferredDate != null
                  ? DateFormat('MMM dd, yyyy').format(_preferredDate!)
                  : 'Select preferred date',
              style: GoogleFonts.outfit(
                color: _preferredDate != null ? AppTheme.textColor : Colors.grey[600],
                fontWeight: _preferredDate != null ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressSelector() {
    return GestureDetector(
      onTap: _selectAddress,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _selectedAddress != null ? AppTheme.primaryColor : Colors.grey[300]!,
            width: _selectedAddress != null ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.location_on,
              color: _selectedAddress != null ? AppTheme.primaryColor : Colors.grey[500],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _selectedAddress?.label ?? 'Select service location',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w600,
                      color: _selectedAddress != null ? AppTheme.textColor : Colors.grey[600],
                    ),
                  ),
                  if (_selectedAddress != null)
                    Text(
                      _selectedAddress!.fullAddress,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getPriorityIcon(String priority) {
    switch (priority.toLowerCase()) {
      case 'low':
        return Icons.keyboard_arrow_down;
      case 'medium':
        return Icons.remove;
      case 'high':
        return Icons.keyboard_arrow_up;
      case 'urgent':
        return Icons.priority_high;
      default:
        return Icons.remove;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'low':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'high':
        return Colors.red;
      case 'urgent':
        return Colors.red[800]!;
      default:
        return Colors.grey;
    }
  }
}

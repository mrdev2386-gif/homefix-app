import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/models/custom_request.dart';
import '../../../../core/models/category.dart';
import '../../../../core/models/address.dart';
import '../../../../core/models/user_model.dart';
import '../../../../core/services/functions_service.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/theme/app_theme.dart';

class CustomRequestScreen extends StatefulWidget {
  const CustomRequestScreen({super.key});

  @override
  State<CustomRequestScreen> createState() => _CustomRequestScreenState();
}

class _CustomRequestScreenState extends State<CustomRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _budgetMinController = TextEditingController();
  final _budgetMaxController = TextEditingController();

  Category? _selectedCategory;
  String _preferredDate = '';
  String _preferredTime = '';
  Address? _selectedAddress;
  Urgency _urgency = Urgency.normal;
  List<File> _selectedImages = [];
  List<String> _imageBase64 = [];

  bool _isLoading = false;
  bool _isSubmitting = false;

  List<Category> _categories = [];
  List<Address> _addresses = [];

  @override
  void initState() {
    super.initState();
    _fetchCategories();
    _fetchAddresses();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _budgetMinController.dispose();
    _budgetMaxController.dispose();
    super.dispose();
  }

  Future<void> _fetchCategories() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('categories')
          .where('isActive', isEqualTo: true)
          .orderBy('order')
          .get();

      if (mounted) {
        setState(() {
          _categories = snapshot.docs.map((doc) => Category.fromFirestore(doc)).toList();
        });
      }
    } catch (e) {
      debugPrint('Error fetching categories: $e');
    }
  }

  Future<void> _fetchAddresses() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.user?.uid == null) return;

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('customers')
          .doc(authProvider.user!.uid)
          .collection('addresses')
          .get();

      if (mounted) {
        setState(() {
          _addresses = snapshot.docs.map((doc) => Address.fromFirestore(doc)).toList();
          if (_addresses.isNotEmpty) {
            _selectedAddress = _addresses.first;
          }
        });
      }
    } catch (e) {
      debugPrint('Error fetching addresses: $e');
    }
  }

  Future<void> _pickImages() async {
    if (_selectedImages.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum 5 images allowed')),
      );
      return;
    }

    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage(
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 80,
    );

    if (pickedFiles.isNotEmpty && mounted) {
      setState(() {
        _selectedImages.addAll(pickedFiles.map((e) => File(e.path)));
      });

      // Convert to base64
      for (var file in pickedFiles) {
        final bytes = await file.readAsBytes();
        final base64 = 'data:image/jpeg;base64,${base64Encode(bytes)}';
        if (_imageBase64.length < 5) {
          _imageBase64.add(base64);
        }
      }
    }
  }

  void _removeImage(int index) {
    if (mounted) {
      setState(() {
        _selectedImages.removeAt(index);
        if (index < _imageBase64.length) {
          _imageBase64.removeAt(index);
        }
      });
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.fromSeed(seedColor: AppTheme.primaryColor),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _preferredDate = picked.toIso8601String().split('T').first;
      });
    }
  }

  Future<void> _selectTimeSlot() async {
    final slots = [
      '09:00 - 12:00',
      '12:00 - 15:00',
      '15:00 - 18:00',
      '18:00 - 21:00',
    ];

    final picked = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Select Time Slot',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            ...slots.map((slot) => ListTile(
                  title: Text(slot),
                  onTap: () => Navigator.pop(context, slot),
                )),
          ],
        ),
      ),
    );

    if (picked != null && mounted) {
      setState(() {
        _preferredTime = picked;
      });
    }
  }

  bool _validateForm() {
    final errors = <String>[];

    if (_selectedCategory == null) {
      errors.add('Please select a service category');
    }
    if (_titleController.text.trim().length < 5) {
      errors.add('Title must be at least 5 characters');
    }
    if (_descriptionController.text.trim().length < 20) {
      errors.add('Description must be at least 20 characters');
    }
    if (_preferredDate.isEmpty) {
      errors.add('Please select a preferred date');
    }
    if (_preferredTime.isEmpty) {
      errors.add('Please select a time slot');
    }
    if (_selectedAddress == null) {
      errors.add('Please select an address');
    }

    if (errors.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: errors.map((e) => Text(e)).toList(),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }

    return true;
  }

  Future<void> _submitRequest() async {
    // Dismiss keyboard before submitting
    FocusScope.of(context).unfocus();
    
    if (!_validateForm()) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      final requestData = {
        'categoryId': _selectedCategory!.id,
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'imageUrls': _imageBase64,
        'preferredDate': _preferredDate,
        'preferredTime': _preferredTime,
        'addressId': _selectedAddress!.id,
        'budgetMin': double.tryParse(_budgetMinController.text),
        'budgetMax': double.tryParse(_budgetMaxController.text),
        'urgency': _urgency.value,
      };

      final functionsService = FunctionsService();
      final result = await functionsService.createCustomRequest(requestData);

      if (mounted) {
        // Clear form after successful submission
        _clearForm();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Request submitted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _clearForm() {
    _titleController.clear();
    _descriptionController.clear();
    _budgetMinController.clear();
    _budgetMaxController.clear();
    setState(() {
      _selectedCategory = null;
      _preferredDate = '';
      _preferredTime = '';
      _selectedAddress = null;
      _urgency = Urgency.normal;
      _selectedImages = [];
      _imageBase64 = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Custom Request',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCategorySection(),
                    const SizedBox(height: 16),
                    _buildTitleSection(),
                    const SizedBox(height: 16),
                    _buildDescriptionSection(),
                    const SizedBox(height: 16),
                    _buildImagesSection(),
                    const SizedBox(height: 16),
                    _buildScheduleSection(),
                    const SizedBox(height: 16),
                    _buildAddressSection(),
                    const SizedBox(height: 16),
                    _buildBudgetSection(),
                    const SizedBox(height: 16),
                    _buildUrgencySection(),
                    const SizedBox(height: 100), // Space for bottom button
                  ],
                ),
              ),
            ),
      bottomSheet: _buildSubmitButton(),
    );
  }

  Widget _buildCategorySection() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[300]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.category, color: AppTheme.primaryColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Service Category',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                const Spacer(),
                Text(
                  '*',
                  style: TextStyle(color: Colors.red[700], fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<Category>(
              value: _selectedCategory,
              hint: Text(
                'Select a category',
                style: GoogleFonts.poppins(fontSize: 14),
              ),
              items: _categories.map((category) => DropdownMenuItem(
                    value: category,
                    child: Row(
                      children: [
                        if (category.imageUrl != null)
                          Image.network(category.imageUrl!, width: 24, height: 24),
                        const SizedBox(width: 8),
                        Text(
                          category.name,
                          style: GoogleFonts.poppins(fontSize: 14),
                        ),
                      ],
                    ),
                  )).toList(),
              onChanged: (value) => setState(() => _selectedCategory = value),
              validator: (value) {
                if (value == null) return 'Please select a category';
                return null;
              },
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTitleSection() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[300]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.title, color: AppTheme.primaryColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Problem Title',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                const Spacer(),
                Text(
                  '*',
                  style: TextStyle(color: Colors.red[700], fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: 'Brief description of the issue',
                hintStyle: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[500]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
              maxLength: 100,
              validator: (value) {
                if (value == null || value.trim().length < 5) {
                  return 'Title must be at least 5 characters';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDescriptionSection() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[300]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.description, color: AppTheme.primaryColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Detailed Description',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                const Spacer(),
                Text(
                  '*',
                  style: TextStyle(color: Colors.red[700], fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                hintText: 'Describe your problem in detail. Include any relevant information that might help the technician.',
                hintStyle: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[500]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
              maxLines: 5,
              maxLength: 1000,
              validator: (value) {
                if (value == null || value.trim().length < 20) {
                  return 'Description must be at least 20 characters';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagesSection() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[300]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.photo_camera, color: AppTheme.primaryColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Photos (Optional)',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                const Spacer(),
                Text(
                  '${_selectedImages.length}/5',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_selectedImages.isNotEmpty)
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _selectedImages.length,
                  itemBuilder: (context, index) => Stack(
                    children: [
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        width: 100,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          image: DecorationImage(
                            image: FileImage(_selectedImages[index]),
                            fit: BoxFit.cover,
                          ),
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
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _pickImages,
              icon: const Icon(Icons.add_photo_alternate),
              label: Text(
                _selectedImages.isEmpty ? 'Add Photos' : 'Add More Photos',
                style: GoogleFonts.poppins(),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                side: BorderSide(color: AppTheme.primaryColor),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleSection() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[300]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.calendar_today, color: AppTheme.primaryColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Preferred Schedule',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                const Spacer(),
                Text(
                  '*',
                  style: TextStyle(color: Colors.red[700], fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _selectDate,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                        color: _preferredDate.isEmpty ? Colors.grey[100] : Colors.white,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.event,
                            size: 20,
                            color: _preferredDate.isEmpty ? Colors.grey[500] : AppTheme.primaryColor,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _preferredDate.isEmpty ? 'Select Date' : _preferredDate,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: _preferredDate.isEmpty ? Colors.grey[500] : Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: _selectTimeSlot,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                        color: _preferredTime.isEmpty ? Colors.grey[100] : Colors.white,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 20,
                            color: _preferredTime.isEmpty ? Colors.grey[500] : AppTheme.primaryColor,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _preferredTime.isEmpty ? 'Time Slot' : _preferredTime,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: _preferredTime.isEmpty ? Colors.grey[500] : Colors.black,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressSection() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[300]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.location_on, color: AppTheme.primaryColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Service Address',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                const Spacer(),
                Text(
                  '*',
                  style: TextStyle(color: Colors.red[700], fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<Address>(
              value: _selectedAddress,
              hint: Text(
                'Select an address',
                style: GoogleFonts.poppins(fontSize: 14),
              ),
              items: _addresses.map((address) => DropdownMenuItem(
                    value: address,
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width - 100,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            address.label,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            address.fullAddress,
                            style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  )).toList(),
              onChanged: (value) => setState(() => _selectedAddress = value),
              validator: (value) {
                if (value == null) return 'Please select an address';
                return null;
              },
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
            ),
            if (_addresses.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: TextButton.icon(
                  onPressed: () {
                    // Navigate to address management
                    Navigator.pushNamed(context, '/addresses');
                  },
                  icon: const Icon(Icons.add),
                  label: Text('Add a new address', style: GoogleFonts.poppins()),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetSection() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[300]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.attach_money, color: AppTheme.primaryColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Budget Range (Optional)',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _budgetMinController,
                    decoration: InputDecoration(
                      hintText: 'Min',
                      hintStyle: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[500]),
                      prefixIcon: const Icon(Icons.currency_rupee, size: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'to',
                  style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _budgetMaxController,
                    decoration: InputDecoration(
                      hintText: 'Max',
                      hintStyle: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[500]),
                      prefixIcon: const Icon(Icons.currency_rupee, size: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUrgencySection() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[300]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.priority_high, color: AppTheme.primaryColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Urgency',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: Urgency.values.map((urgency) {
                final isSelected = _urgency == urgency;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _urgency = urgency),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? urgency.color.withOpacity(0.1) : Colors.grey[100],
                        border: Border.all(
                          color: isSelected ? urgency.color : Colors.grey[300]!,
                          width: isSelected ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            urgency == Urgency.normal
                                ? Icons.schedule
                                : urgency == Urgency.urgent
                                    ? Icons.access_time_filled
                                    : Icons.emergency,
                            color: isSelected ? urgency.color : Colors.grey[500],
                            size: 24,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            urgency.displayName,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                              color: isSelected ? urgency.color : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _isSubmitting ? null : _submitRequest,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: _isSubmitting
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(
                  'Submit Request',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ),
    );
  }
}

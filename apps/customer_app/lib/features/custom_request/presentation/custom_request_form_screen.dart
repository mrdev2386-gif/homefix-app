import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import '../../../core/services/storage_service.dart';
import '../../../core/theme/app_theme.dart';

class CustomRequestFormScreen extends StatefulWidget {
  const CustomRequestFormScreen({Key? key}) : super(key: key);

  @override
  State<CustomRequestFormScreen> createState() => _CustomRequestFormScreenState();
}

class _CustomRequestFormScreenState extends State<CustomRequestFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _budgetController = TextEditingController();
  
  final StorageService _storageService = StorageService();
  
  String? _selectedCategory;
  List<File> _selectedImages = [];
  DateTime? _selectedDate;
  String _selectedTimeSlot = 'Morning';
  String _urgencyLevel = 'normal';
  bool _isSubmitting = false;

  final List<String> _categories = [
    'Electrical',
    'Plumbing',
    'AC Repair',
    'Cleaning',
    'Painting',
    'Appliance Repair',
    'Carpentry',
    'Other',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    if (_selectedImages.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum 5 images allowed')),
      );
      return;
    }

    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    if (source == ImageSource.camera) {
      final pickedFile = await picker.pickImage(source: source);
      if (pickedFile != null) {
        setState(() {
          _selectedImages.add(File(pickedFile.path));
        });
      }
    } else {
      final pickedFiles = await picker.pickMultiImage();
      if (pickedFiles.isNotEmpty) {
        final remainingSlots = 5 - _selectedImages.length;
        final filesToAdd = pickedFiles.take(remainingSlots).map((xFile) => File(xFile.path)).toList();
        setState(() {
          _selectedImages.addAll(filesToAdd);
        });
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 30)),
    );
    
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _showCategoryBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Category',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ..._categories.map((category) => ListTile(
              title: Text(category),
              onTap: () {
                setState(() {
                  _selectedCategory = category;
                });
                Navigator.pop(context);
              },
              trailing: _selectedCategory == category
                  ? const Icon(Icons.check_circle, color: AppTheme.primaryColor)
                  : null,
            )),
          ],
        ),
      ),
    );
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      List<String> imageUrls = [];
      if (_selectedImages.isNotEmpty) {
        for (final image in _selectedImages) {
          final url = await _storageService.uploadCustomRequestImage(image, user.uid);
          imageUrls.add(url);
        }
      }

      final requestData = {
        'customerId': user.uid,
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'category': _selectedCategory,
        'budget': _budgetController.text.isNotEmpty ? double.tryParse(_budgetController.text) : null,
        'location': 'Current Location',
        'images': imageUrls,
        'preferredDate': _selectedDate?.toIso8601String(),
        'preferredTime': _selectedTimeSlot,
        'urgency': _urgencyLevel,
        'status': 'submitted',
        'createdAt': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance.collection('custom_requests').add(requestData);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Request submitted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('Request Custom Service', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text('Service Details', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                hintText: 'e.g., Custom furniture assembly',
                border: OutlineInputBorder(),
              ),
              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Describe your requirement...',
                border: OutlineInputBorder(),
              ),
              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 24),
            Text('Category', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            InkWell(
              onTap: _showCategoryBottomSheet,
              child: InputDecorator(
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.arrow_drop_down),
                ),
                child: Text(_selectedCategory ?? 'Select Category'),
              ),
            ),
            const SizedBox(height: 24),
            Text('Images', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            if (_selectedImages.isNotEmpty) ...[
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _selectedImages.length,
                  itemBuilder: (context, index) {
                    return Stack(
                      children: [
                        Container(
                          margin: const EdgeInsets.only(right: 12),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              _selectedImages[index],
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 16,
                          child: GestureDetector(
                            onTap: () => _removeImage(index),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close, color: Colors.white, size: 16),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
            ],
            OutlinedButton.icon(
              onPressed: _pickImages,
              icon: const Icon(Icons.add_photo_alternate),
              label: Text('${_selectedImages.isEmpty ? 'Add' : 'Add More'} Images (${_selectedImages.length}/5)'),
            ),
            const SizedBox(height: 24),
            Text('Budget (Optional)', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextFormField(
              controller: _budgetController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Expected Budget',
                hintText: 'Enter amount in ₹',
                prefixText: '₹ ',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            Text('Preferred Date', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            InkWell(
              onTap: _selectDate,
              child: InputDecorator(
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                child: Text(_selectedDate != null ? DateFormat('dd MMM yyyy').format(_selectedDate!) : 'Select Date'),
              ),
            ),
            const SizedBox(height: 24),
            Text('Preferred Time', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildTimeChip('Morning'),
                const SizedBox(width: 8),
                _buildTimeChip('Afternoon'),
                const SizedBox(width: 8),
                _buildTimeChip('Evening'),
              ],
            ),
            const SizedBox(height: 24),
            Text('Urgency', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildUrgencyChip('normal', 'Normal', Colors.green),
                const SizedBox(width: 8),
                _buildUrgencyChip('urgent', 'Urgent', Colors.orange),
                const SizedBox(width: 8),
                _buildUrgencyChip('emergency', 'Emergency', Colors.red),
              ],
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submitRequest,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isSubmitting
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Submit Request', style: TextStyle(fontSize: 16)),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeChip(String slot) {
    final isSelected = _selectedTimeSlot == slot;
    return Expanded(
      child: ChoiceChip(
        label: Text(slot),
        selected: isSelected,
        onSelected: (selected) {
          if (selected) setState(() => _selectedTimeSlot = slot);
        },
      ),
    );
  }

  Widget _buildUrgencyChip(String value, String label, Color color) {
    final isSelected = _urgencyLevel == value;
    return Expanded(
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        selectedColor: color.withOpacity(0.2),
        onSelected: (selected) {
          if (selected) setState(() => _urgencyLevel = value);
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:technician_app/core/providers/technician_provider.dart';
import 'package:technician_app/core/constants/service_categories.dart';

class Step1BasicIdentity extends StatefulWidget {
  final Map<String, dynamic> formData;
  final Function(String, dynamic) onDataChanged;

  const Step1BasicIdentity({
    super.key,
    required this.formData,
    required this.onDataChanged,
  });

  @override
  State<Step1BasicIdentity> createState() => _Step1BasicIdentityState();
}

class _Step1BasicIdentityState extends State<Step1BasicIdentity> {
  late TextEditingController _nameController;
  late TextEditingController _cityController;
  late TextEditingController _searchController;
  File? _profilePhoto;
  String? _selectedGender;
  DateTime? _selectedDOB;
  List<String> _selectedCategories = [];
  String _categorySearchQuery = '';
  bool _isUploadingPhoto = false;
  String? _categoryError;

  final List<String> _genderOptions = ['Male', 'Female', 'Other'];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.formData['fullName'] ?? '',
    );
    _cityController = TextEditingController(
      text: widget.formData['district'] ?? '',
    );
    _searchController = TextEditingController();
    _selectedGender = widget.formData['gender'];
    _selectedDOB = widget.formData['dob'];
    
    // Backward compatibility: convert single category to list
    final primaryCat = widget.formData['primaryCategoryId'];
    if (primaryCat != null) {
      _selectedCategories = primaryCat is List ? List<String>.from(primaryCat) : [primaryCat];
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _cityController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _pickProfilePhoto() async {
    if (_isUploadingPhoto) return;

    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() => _isUploadingPhoto = true);

        final file = File(image.path);
        final provider = context.read<TechnicianProvider>();

        try {
          final url = await provider.uploadDocumentImage(
            file,
            'profile_photo',
          );

          if (mounted) {
            setState(() {
              _profilePhoto = file;
              _isUploadingPhoto = false;
            });
            widget.onDataChanged('profilePhotoUrl', url);
          }
        } catch (e) {
          if (mounted) {
            setState(() => _isUploadingPhoto = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Upload failed: $e')),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Error picking photo: $e');
    }
  }

  Future<void> _selectDOB() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDOB ?? DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
    );

    if (picked != null) {
      setState(() => _selectedDOB = picked);
      widget.onDataChanged('dob', picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tell us about yourself',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'We need some basic information to get started',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: const Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 32),
          _buildPhotoUpload(),
          const SizedBox(height: 24),
          _buildTextField(
            controller: _nameController,
            label: 'Full Name',
            hint: 'Enter your full name',
            icon: Icons.person_outline,
            onChanged: (value) => widget.onDataChanged('fullName', value),
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _cityController,
            label: 'City',
            hint: 'Enter your city',
            icon: Icons.location_on_outlined,
            onChanged: (value) => widget.onDataChanged('district', value),
          ),
          const SizedBox(height: 16),
          _buildGenderSelector(),
          const SizedBox(height: 16),
          _buildDOBSelector(),
          const SizedBox(height: 16),
          _buildCategorySelector(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildPhotoUpload() {
    return GestureDetector(
      onTap: _isUploadingPhoto ? null : _pickProfilePhoto,
      child: Container(
        height: 140,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFE2E8F0),
            width: 2,
          ),
        ),
        child: _isUploadingPhoto
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : _profilePhoto != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.file(
                      _profilePhoto!,
                      fit: BoxFit.cover,
                    ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.camera_alt_outlined,
                          color: Color(0xFF6366F1),
                          size: 28,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Take Profile Photo',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Required for verification',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: const Color(0xFF9CA3AF),
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required Function(String) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFFE2E8F0),
              width: 1,
            ),
          ),
          child: TextField(
            controller: controller,
            onChanged: onChanged,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
              prefixIcon: Icon(icon, color: const Color(0xFF6366F1), size: 20),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGenderSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Gender (Optional)',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: _genderOptions.map((gender) {
            final isSelected = _selectedGender == gender;
            return FilterChip(
              label: Text(gender),
              selected: isSelected,
              onSelected: (selected) {
                setState(() => _selectedGender = gender);
                widget.onDataChanged('gender', gender);
              },
              backgroundColor: Colors.white,
              selectedColor: const Color(0xFF6366F1),
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF0F172A),
                fontWeight: FontWeight.w600,
              ),
              side: BorderSide(
                color: isSelected
                    ? const Color(0xFF6366F1)
                    : const Color(0xFFE2E8F0),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDOBSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Date of Birth (Optional)',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _selectDOB,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFE2E8F0),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  color: Color(0xFF6366F1),
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  _selectedDOB != null
                      ? '${_selectedDOB!.day}/${_selectedDOB!.month}/${_selectedDOB!.year}'
                      : 'Select date',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    color: _selectedDOB != null
                        ? const Color(0xFF0F172A)
                        : const Color(0xFF9CA3AF),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<Map<String, String>> _getFilteredCategories() {
    if (_categorySearchQuery.isEmpty) {
      return ServiceCategories.categories;
    }
    return ServiceCategories.categories
        .where((cat) => cat['name']!.toLowerCase().contains(_categorySearchQuery.toLowerCase()))
        .toList();
  }

  void _toggleCategory(String categoryId) {
    setState(() {
      if (_selectedCategories.contains(categoryId)) {
        _selectedCategories.remove(categoryId);
      } else {
        _selectedCategories.add(categoryId);
      }
      _categoryError = null;
    });
    widget.onDataChanged('primaryCategoryId', _selectedCategories);
  }

  bool _validateCategories() {
    if (_selectedCategories.isEmpty) {
      setState(() => _categoryError = 'Select at least one category');
      return false;
    }
    return true;
  }

  Widget _buildCategorySelector() {
    final filteredCategories = _getFilteredCategories();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Service Categories',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 8),
        // Search field
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
          ),
          child: TextField(
            controller: _searchController,
            onChanged: (value) {
              setState(() => _categorySearchQuery = value);
            },
            decoration: InputDecoration(
              hintText: 'Search categories...',
              hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
              prefixIcon: const Icon(Icons.search, color: Color(0xFF6366F1), size: 20),
              suffixIcon: _categorySearchQuery.isNotEmpty
                  ? GestureDetector(
                      onTap: () {
                        _searchController.clear();
                        setState(() => _categorySearchQuery = '');
                      },
                      child: const Icon(Icons.clear, color: Color(0xFF9CA3AF), size: 20),
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Chip grid
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _categoryError != null ? Colors.red : const Color(0xFFE2E8F0),
              width: 1,
            ),
          ),
          padding: const EdgeInsets.all(12),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: filteredCategories.map((category) {
              final isSelected = _selectedCategories.contains(category['id']);
              return FilterChip(
                label: Text(category['name']!),
                selected: isSelected,
                onSelected: (_) => _toggleCategory(category['id']!),
                backgroundColor: Colors.white,
                selectedColor: const Color(0xFF6366F1),
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFF0F172A),
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
                side: BorderSide(
                  color: isSelected ? const Color(0xFF6366F1) : const Color(0xFFE2E8F0),
                ),
              );
            }).toList(),
          ),
        ),
        if (_categoryError != null) ...[const SizedBox(height: 8),
          Text(
            _categoryError!,
            style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.red),
          ),
        ],
        if (_selectedCategories.isNotEmpty) ...[const SizedBox(height: 8),
          Text(
            '${_selectedCategories.length} selected',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: const Color(0xFF6366F1),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}

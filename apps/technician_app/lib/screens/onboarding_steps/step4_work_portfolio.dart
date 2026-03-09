import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:technician_app/core/providers/technician_provider.dart';

class Step4WorkPortfolio extends StatefulWidget {
  final Map<String, dynamic> formData;
  final Function(String, dynamic) onDataChanged;

  const Step4WorkPortfolio({
    super.key,
    required this.formData,
    required this.onDataChanged,
  });

  @override
  State<Step4WorkPortfolio> createState() => _Step4WorkPortfolioState();
}

class _Step4WorkPortfolioState extends State<Step4WorkPortfolio> {
  late TextEditingController _experienceDescriptionController;
  
  List<String> _portfolioUrls = [];
  List<bool> _uploadingStates = [false, false, false, false, false];
  static const int maxPhotos = 5;
  
  List<String> _selectedTools = [];
  String? _workPreference;
  
  static const List<String> availableTools = [
    'Drill Machine',
    'Ladder',
    'Safety Kit',
    'Spray Machine',
    'Professional Toolkit',
    'Measuring Tools',
    'Electrical Tester',
    'Pipe Wrench',
    'Screwdriver Set',
    'Hammer',
  ];
  
  static const List<String> workPreferences = [
    'Residential Work',
    'Commercial Work',
    'Both',
  ];

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }
  
  void _initializeControllers() {
    _experienceDescriptionController = TextEditingController(
      text: widget.formData['experienceDescription'] ?? '',
    );
    
    final existingUrls = widget.formData['portfolioPhotos'] as List<String>? ?? [];
    _portfolioUrls = List<String>.from(existingUrls);
    
    final existingTools = widget.formData['tools'] as List<String>? ?? [];
    _selectedTools = List<String>.from(existingTools);
    
    _workPreference = widget.formData['workPreference'];
  }
  
  @override
  void dispose() {
    _experienceDescriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(int index) async {
    if (_uploadingStates[index]) return;

    final source = await _showImageSourceDialog();
    if (source == null) return;

    final picker = ImagePicker();
    final image = await picker.pickImage(source: source, imageQuality: 80);

    if (image != null) {
      setState(() => _uploadingStates[index] = true);

      try {
        final provider = context.read<TechnicianProvider>();
        final photoId = DateTime.now().millisecondsSinceEpoch.toString();
        final url = await provider.uploadDocumentImage(File(image.path), 'portfolio_$photoId');

        setState(() {
          if (index < _portfolioUrls.length) {
            _portfolioUrls[index] = url;
          } else {
            _portfolioUrls.add(url);
          }
          _uploadingStates[index] = false;
        });
        widget.onDataChanged('portfolioPhotos', _portfolioUrls);
      } catch (e) {
        setState(() => _uploadingStates[index] = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Upload failed: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<ImageSource?> _showImageSourceDialog() async {
    return showModalBottomSheet<ImageSource>(
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
                'Select Image Source',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              _buildImageSourceOption(
                icon: Icons.camera_alt,
                title: 'Camera',
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              const SizedBox(height: 12),
              _buildImageSourceOption(
                icon: Icons.photo_library,
                title: 'Gallery',
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
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
          color: const Color(0xFF6366F1).withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF6366F1)),
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

  void _removePhoto(int index) {
    setState(() => _portfolioUrls.removeAt(index));
    widget.onDataChanged('portfolioPhotos', _portfolioUrls);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 32),
          _buildExperienceDescription(),
          const SizedBox(height: 32),
          _buildToolsSection(),
          const SizedBox(height: 32),
          _buildWorkPreferenceSection(),
          const SizedBox(height: 32),
          _buildPortfolioSection(),
          const SizedBox(height: 24),
          _buildInfoNote(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Show Your Previous Work',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Upload photos of your past work to build trust with customers.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            color: const Color(0xFF6B7280),
          ),
        ),
      ],
    );
  }

  Widget _buildExperienceDescription() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Work Experience Description',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _experienceDescriptionController,
          maxLines: 4,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            color: const Color(0xFF0F172A),
          ),
          decoration: InputDecoration(
            hintText: 'Describe your work experience and specialties',
            hintStyle: GoogleFonts.plusJakartaSans(
              color: const Color(0xFF94A3B8),
            ),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
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
              borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
            ),
          ),
          onChanged: (value) => widget.onDataChanged('experienceDescription', value),
        ),
      ],
    );
  }

  Widget _buildToolsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tools & Equipment',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Select the tools and equipment you have',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            color: const Color(0xFF6B7280),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: availableTools.map((tool) {
            final isSelected = _selectedTools.contains(tool);
            return FilterChip(
              label: Text(tool),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedTools.add(tool);
                  } else {
                    _selectedTools.remove(tool);
                  }
                });
                widget.onDataChanged('tools', _selectedTools);
              },
              backgroundColor: Colors.white,
              selectedColor: const Color(0xFF6366F1).withOpacity(0.1),
              checkmarkColor: const Color(0xFF6366F1),
              labelStyle: GoogleFonts.plusJakartaSans(
                color: isSelected ? const Color(0xFF6366F1) : const Color(0xFF64748B),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              side: BorderSide(
                color: isSelected ? const Color(0xFF6366F1) : const Color(0xFFE2E8F0),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildWorkPreferenceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Work Type Preference',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 16),
        ...workPreferences.map((preference) {
          return RadioListTile<String>(
            title: Text(
              preference,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                color: const Color(0xFF0F172A),
              ),
            ),
            value: preference,
            groupValue: _workPreference,
            onChanged: (value) {
              setState(() => _workPreference = value);
              widget.onDataChanged('workPreference', value);
            },
            activeColor: const Color(0xFF6366F1),
            contentPadding: EdgeInsets.zero,
          );
        }).toList(),
      ],
    );
  }

  Widget _buildPortfolioSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Portfolio Photos (Optional)',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${_portfolioUrls.length}/$maxPhotos photos uploaded',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            color: const Color(0xFF6B7280),
          ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1,
          ),
          itemCount: maxPhotos,
          itemBuilder: (context, index) {
            final hasPhoto = index < _portfolioUrls.length;
            final isUploading = _uploadingStates[index];

            return GestureDetector(
              onTap: hasPhoto ? null : () => _pickImage(index),
              child: Container(
                decoration: BoxDecoration(
                  color: hasPhoto ? Colors.transparent : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: hasPhoto ? Colors.transparent : const Color(0xFFE2E8F0),
                    width: 2,
                  ),
                ),
                child: isUploading
                    ? const Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
                        ),
                      )
                    : hasPhoto
                        ? Stack(
                            fit: StackFit.expand,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  _portfolioUrls[index],
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Center(
                                      child: Icon(Icons.error_outline, color: Colors.red),
                                    );
                                  },
                                ),
                              ),
                              Positioned(
                                top: 4,
                                right: 4,
                                child: GestureDetector(
                                  onTap: () => _removePhoto(index),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.6),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.add_photo_alternate_outlined,
                                color: Color(0xFF94A3B8),
                                size: 32,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Add Photo',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  color: const Color(0xFF94A3B8),
                                ),
                              ),
                            ],
                          ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildInfoNote() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F9FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF93C5FD)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline,
            color: Color(0xFF2563EB),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Portfolio photos help customers see your work quality and increase booking chances by up to 60%.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: const Color(0xFF1E40AF),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
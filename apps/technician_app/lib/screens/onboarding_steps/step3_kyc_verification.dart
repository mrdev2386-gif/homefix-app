import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:technician_app/core/providers/technician_provider.dart';
import 'package:technician_app/core/services/onboarding_service.dart';

class Step3KycVerification extends StatefulWidget {
  final Map<String, dynamic> formData;
  final Function(String, dynamic) onDataChanged;

  const Step3KycVerification({
    super.key,
    required this.formData,
    required this.onDataChanged,
  });

  @override
  State<Step3KycVerification> createState() => _Step3KycVerificationState();
}

class _Step3KycVerificationState extends State<Step3KycVerification> {
  late TextEditingController _aadhaarController;
  File? _aadhaarFront;
  File? _aadhaarBack;
  bool _isUploadingFront = false;
  bool _isUploadingBack = false;
  String? _aadhaarError;

  @override
  void initState() {
    super.initState();
    _aadhaarController = TextEditingController(
      text: widget.formData['aadhaarNumber'] ?? '',
    );
    
    // Initialize image states from URLs if available
    _initializeImageStates();
  }
  
  void _initializeImageStates() {
    // Check if we have URLs for uploaded images
    final frontUrl = widget.formData['aadhaarFrontUrl'];
    final backUrl = widget.formData['aadhaarBackUrl'];
    
    // For UI purposes, we'll show these as "uploaded" if URLs exist
    // The actual File objects aren't needed for display since we show URLs
    if (frontUrl != null && frontUrl.toString().isNotEmpty) {
      // We have a front image URL - mark as uploaded
      debugPrint('[KYC] Found existing aadhaar front URL');
    }
    
    if (backUrl != null && backUrl.toString().isNotEmpty) {
      debugPrint('[KYC] Found existing aadhaar back URL');
    }
  }

  @override
  void dispose() {
    _aadhaarController.dispose();
    super.dispose();
  }

  Future<void> _captureImage(String type) async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );

      if (image != null) {
        final file = File(image.path);
        final provider = context.read<TechnicianProvider>();

        setState(() {
          if (type == 'aadhaarFront') _isUploadingFront = true;
          if (type == 'aadhaarBack') _isUploadingBack = true;
        });

        try {
          final url = await provider.uploadDocumentImage(file, type);

          if (mounted) {
            setState(() {
              if (type == 'aadhaarFront') {
                _aadhaarFront = file;
                _isUploadingFront = false;
              } else if (type == 'aadhaarBack') {
                _aadhaarBack = file;
                _isUploadingBack = false;
              }
            });
            widget.onDataChanged('${type}Url', url);
          }
        } catch (e) {
          if (mounted) {
            setState(() {
              if (type == 'aadhaarFront') _isUploadingFront = false;
              if (type == 'aadhaarBack') _isUploadingBack = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Upload failed: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Error capturing image: $e');
    }
  }

  void _validateAadhaar() {
    final error = OnboardingService.validateAadhaar(_aadhaarController.text);
    setState(() => _aadhaarError = error);
  }

  String _formatAadhaar(String value) {
    final cleaned = value.replaceAll(' ', '');
    final buffer = StringBuffer();
    for (int i = 0; i < cleaned.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(cleaned[i]);
    }
    return buffer.toString();
  }

  bool get _isFormComplete {
    return _aadhaarController.text.length == 12 &&
           _aadhaarError == null &&
           _aadhaarFront != null &&
           _aadhaarBack != null;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 32),
          _buildAadhaarCard(),
          const SizedBox(height: 20),
          _buildDocumentCard(
            title: 'Aadhaar Front',
            description: 'Clear photo of front side',
            icon: Icons.credit_card,
            image: _aadhaarFront,
            isUploading: _isUploadingFront,
            onTap: () => _captureImage('aadhaarFront'),
          ),
          const SizedBox(height: 20),
          _buildDocumentCard(
            title: 'Aadhaar Back',
            description: 'Clear photo of back side',
            icon: Icons.credit_card,
            image: _aadhaarBack,
            isUploading: _isUploadingBack,
            onTap: () => _captureImage('aadhaarBack'),
          ),
          const SizedBox(height: 20),
          _buildSecurityNote(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'KYC Verification',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Verify your identity to start earning with HomeFix',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            color: const Color(0xFF64748B),
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildAadhaarCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
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
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.credit_card,
                  color: Color(0xFF6366F1),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Aadhaar Number',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  Text(
                    'Enter your 12-digit Aadhaar number',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _aadhaarError != null 
                    ? Colors.red.withValues(alpha: 0.3)
                    : const Color(0xFFE2E8F0),
                width: 1,
              ),
            ),
            child: TextField(
              controller: _aadhaarController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(12),
                TextInputFormatter.withFunction((oldValue, newValue) {
                  return TextEditingValue(
                    text: _formatAadhaar(newValue.text),
                    selection: TextSelection.collapsed(
                      offset: _formatAadhaar(newValue.text).length,
                    ),
                  );
                }),
              ],
              onChanged: (value) {
                final cleaned = value.replaceAll(' ', '');
                widget.onDataChanged('aadhaarNumber', cleaned);
                _validateAadhaar();
              },
              decoration: InputDecoration(
                hintText: 'XXXX XXXX XXXX',
                hintStyle: GoogleFonts.plusJakartaSans(
                  color: const Color(0xFF9CA3AF),
                  fontSize: 16,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(16),
              ),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                letterSpacing: 1.2,
              ),
            ),
          ),
          if (_aadhaarError != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 16),
                const SizedBox(width: 6),
                Text(
                  _aadhaarError!,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDocumentCard({
    required String title,
    required String description,
    required IconData icon,
    required File? image,
    required bool isUploading,
    required VoidCallback onTap,
  }) {
    // Check if we have a URL for this document type
    String? imageUrl;
    if (title.contains('Front')) {
      imageUrl = widget.formData['aadhaarFrontUrl'];
    } else if (title.contains('Back')) {
      imageUrl = widget.formData['aadhaarBackUrl'];
    }
    
    final hasImage = image != null || (imageUrl != null && imageUrl.isNotEmpty);
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: hasImage 
                        ? const Color(0xFF10B981).withValues(alpha: 0.1)
                        : const Color(0xFF6366F1).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    hasImage ? Icons.check_circle : icon,
                    color: hasImage ? const Color(0xFF10B981) : const Color(0xFF6366F1),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        description,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                if (hasImage)
                  const Icon(
                    Icons.check_circle,
                    color: Color(0xFF10B981),
                    size: 24,
                  ),
              ],
            ),
          ),
          GestureDetector(
            onTap: isUploading ? null : onTap,
            child: Container(
              margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              height: 140,
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFE2E8F0),
                  width: 2,
                  style: BorderStyle.solid,
                ),
              ),
              child: isUploading
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(strokeWidth: 2),
                          SizedBox(height: 8),
                          Text('Uploading...', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    )
                  : hasImage
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: image != null
                              ? Image.file(
                                  image,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                )
                              : Image.network(
                                  imageUrl!,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  loadingBuilder: (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return const Center(
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    );
                                  },
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Center(
                                      child: Icon(Icons.error, color: Colors.red),
                                    );
                                  },
                                ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                color: Color(0xFF6366F1),
                                size: 24,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Tap to capture photo',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF6366F1),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Ensure document is clear and readable',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                color: const Color(0xFF9CA3AF),
                              ),
                            ),
                          ],
                        ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityNote() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F9FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF0EA5E9).withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.security,
            color: Color(0xFF0EA5E9),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Your documents are encrypted and used only for verification. We never share your personal information.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: const Color(0xFF0C4A6E),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
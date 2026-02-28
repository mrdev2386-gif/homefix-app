import 'package:flutter/material.dart';
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
  File? _selfie;
  bool _isUploadingFront = false;
  bool _isUploadingBack = false;
  bool _isUploadingSelfie = false;

  @override
  void initState() {
    super.initState();
    _aadhaarController = TextEditingController(
      text: widget.formData['aadhaarNumber'] ?? '',
    );
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
          if (type == 'front') _isUploadingFront = true;
          if (type == 'back') _isUploadingBack = true;
          if (type == 'selfie') _isUploadingSelfie = true;
        });

        try {
          final url = await provider.uploadDocumentImage(file, type);

          if (mounted) {
            setState(() {
              if (type == 'front') {
                _aadhaarFront = file;
                _isUploadingFront = false;
              } else if (type == 'back') {
                _aadhaarBack = file;
                _isUploadingBack = false;
              } else if (type == 'selfie') {
                _selfie = file;
                _isUploadingSelfie = false;
              }
            });
            widget.onDataChanged('${type}Url', url);
          }
        } catch (e) {
          if (mounted) {
            setState(() {
              if (type == 'front') _isUploadingFront = false;
              if (type == 'back') _isUploadingBack = false;
              if (type == 'selfie') _isUploadingSelfie = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Upload failed: $e')),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Error capturing image: $e');
    }
  }

  String? _validateAadhaar() {
    return OnboardingService.validateAadhaar(_aadhaarController.text);
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
            'KYC Verification',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Verify your identity for trust and safety',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: const Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 32),
          _buildSecurityNotice(),
          const SizedBox(height: 24),
          _buildAadhaarField(),
          const SizedBox(height: 24),
          _buildDocumentCapture('front', 'Aadhaar Front', _aadhaarFront,
              _isUploadingFront),
          const SizedBox(height: 24),
          _buildDocumentCapture(
              'back', 'Aadhaar Back', _aadhaarBack, _isUploadingBack),
          const SizedBox(height: 24),
          _buildDocumentCapture(
              'selfie', 'Selfie Photo', _selfie, _isUploadingSelfie),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSecurityNotice() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFFCD34D),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline,
            color: Color(0xFFD97706),
            size: 20,
          ),
          const SizedBox(width: 12),
          Flexible(
            fit: FlexFit.loose,
            child: Text(
              'Your documents are encrypted and stored securely. We never share your personal information.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: const Color(0xFF92400E),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAadhaarField() {
    final error = _validateAadhaar();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Aadhaar Number',
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
              color: error != null ? Colors.red : const Color(0xFFE2E8F0),
              width: 1,
            ),
          ),
          child: TextField(
            controller: _aadhaarController,
            keyboardType: TextInputType.number,
            maxLength: 12,
            onChanged: (value) {
              widget.onDataChanged('aadhaarNumber', value);
              setState(() {});
            },
            decoration: InputDecoration(
              hintText: 'Enter 12-digit Aadhaar',
              hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
              prefixIcon: const Icon(
                Icons.credit_card_outlined,
                color: Color(0xFF6366F1),
                size: 20,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              counterText: '',
            ),
          ),
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              error,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: Colors.red,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDocumentCapture(
    String type,
    String label,
    File? image,
    bool isUploading,
  ) {
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
        GestureDetector(
          onTap: isUploading ? null : () => _captureImage(type),
          child: Container(
            height: 120,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFE2E8F0),
                width: 2,
              ),
            ),
            child: isUploading
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : image != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.file(
                          image,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3F4F6),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.camera_alt_outlined,
                              color: Color(0xFF6366F1),
                              size: 24,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Capture $label',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import '../../../core/providers/technician_provider.dart';

class KycStatusScreen extends StatefulWidget {
  const KycStatusScreen({super.key});

  @override
  State<KycStatusScreen> createState() => _KycStatusScreenState();
}

class _KycStatusScreenState extends State<KycStatusScreen> {
  final _formKey = GlobalKey<FormState>();
  final _aadharController = TextEditingController();
  final _panController = TextEditingController();
  final _nameController = TextEditingController();
  
  File? _aadharFront;
  File? _selfie;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final tech = context.read<TechnicianProvider>().technician;
      if(tech != null) {
          _nameController.text = tech.name;
      }
    });
  }

  Future<void> _pickImage(String type) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: type == 'selfie' ? ImageSource.camera : ImageSource.gallery,
      imageQuality: 70,
    );
    if (picked != null) {
      setState(() {
        if (type == 'aadhar') _aadharFront = File(picked.path);
        if (type == 'selfie') _selfie = File(picked.path);
      });
    }
  }

  Future<void> _submitKyc() async {
    if(!_formKey.currentState!.validate()) return;
    if(_aadharFront == null || _selfie == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please upload all required photos")));
        return;
    }

    setState(() => _isSubmitting = true);
    try {
        final user = FirebaseAuth.instance.currentUser!;
        
        // Email verification check
        if (!user.emailVerified) {
            throw Exception("Please verify your email address before submitting KYC.");
        }

        final uid = user.uid;
        
        final aadharRef = FirebaseStorage.instance.ref().child('kyc/$uid/aadhar_front.jpg');
        await aadharRef.putFile(_aadharFront!);
        final aadharUrl = await aadharRef.getDownloadURL();

        final selfieRef = FirebaseStorage.instance.ref().child('kyc/$uid/selfie.jpg');
        await selfieRef.putFile(_selfie!);
        final selfieUrl = await selfieRef.getDownloadURL();

        final callable = FirebaseFunctions.instance.httpsCallable('submitKYC');
        await callable.call({
            'fullName': _nameController.text.trim(),
            'aadharNumber': _aadharController.text.trim(),
            'panNumber': _panController.text.trim(),
            'frontUrl': aadharUrl,
            'selfieUrl': selfieUrl,
            'idType': 'aadhar',
        });

        if(mounted) {
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Documents submitted for verification")));
        }

    } catch (e) {
        if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Submission failed: $e")));
    } finally {
        if(mounted) setState(() => _isSubmitting = false);
    }

  }

  @override
  Widget build(BuildContext context) {
    final tech = context.watch<TechnicianProvider>().technician;
    final status = tech?.kycStatus;

    if (status == 'submitted' || status == 'under_review') {
      return _buildReviewState('Review in Progress', 'We are verifying your identity. This usually takes less than 24 hours.', Icons.fact_check_rounded, const Color(0xFFF59E0B));
    }

    if (status == 'approved') {
       return _buildReviewState('Account Verified!', 'Congratulations! Your profile is now active on HomeFix.', Icons.verified_rounded, const Color(0xFF10B981));
    }

    return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: Text("Identity Verification", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        ),
        body: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Form(
                key: _formKey,
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                        Text("Complete your KYC", style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
                        const SizedBox(height: 12),
                        Text("Mandatory for all HomeFix partners to ensure safety and trust.", style: GoogleFonts.outfit(color: const Color(0xFF64748B), fontSize: 16, height: 1.5)),
                        const SizedBox(height: 40),
                        
                        _buildTextField(_nameController, "Full Name (as per Aadhar)", Icons.person_outline),
                        const SizedBox(height: 20),
                        _buildTextField(_aadharController, "Aadhar Number", Icons.credit_card, keyboardType: TextInputType.number),
                        const SizedBox(height: 20),
                        _buildTextField(_panController, "PAN Number", Icons.badge_outlined),
                        
                        const SizedBox(height: 40),
                        Text("Identity Proofs", style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        
                        _buildUploadCard("Aadhar Card Front", _aadharFront, () => _pickImage('aadhar')),
                        const SizedBox(height: 16),
                        _buildUploadCard("Current Selfie", _selfie, () => _pickImage('selfie'), isCamera: true),
                        
                        const SizedBox(height: 56),
                        ElevatedButton(
                            onPressed: _isSubmitting ? null : _submitKyc,
                            child: _isSubmitting 
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                                : const Text("Submit Documents"),
                        ),
                        const SizedBox(height: 40),
                    ]
                )
            )
        )
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {TextInputType? keyboardType}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: GoogleFonts.outfit(fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF6366F1), size: 20),
      ),
      validator: (v) => v!.isEmpty ? "Required field" : null,
    );
  }

  Widget _buildUploadCard(String label, File? file, VoidCallback onTap, {bool isCamera = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: file != null ? const Color(0xFF10B981) : const Color(0xFFE2E8F0)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(12)),
              child: Icon(isCamera ? Icons.camera_alt_rounded : Icons.upload_file_rounded, color: const Color(0xFF6366F1)),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
                  Text(file != null ? "Selected: ${file.path.split('/').last}" : "Tap to upload", 
                    style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey), overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            if (file != null) const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981)),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewState(String title, String subtitle, IconData icon, Color color) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(48.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(icon, size: 80, color: color),
              ),
              const SizedBox(height: 40),
              Text(title, textAlign: TextAlign.center, style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
              const SizedBox(height: 16),
              Text(subtitle, textAlign: TextAlign.center, style: GoogleFonts.outfit(color: const Color(0xFF64748B), fontSize: 16, height: 1.5)),
              const SizedBox(height: 64),
              if (title == 'Account Verified!') 
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(), 
                  child: const Text("Go to Dashboard"),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

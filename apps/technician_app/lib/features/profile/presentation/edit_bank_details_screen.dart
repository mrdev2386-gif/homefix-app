import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/technician_provider.dart';
import '../../../core/models/technician.dart';
import '../../../core/services/functions_service.dart';

class EditBankDetailsScreen extends StatefulWidget {
  const EditBankDetailsScreen({super.key});

  @override
  State<EditBankDetailsScreen> createState() => _EditBankDetailsScreenState();
}

class _EditBankDetailsScreenState extends State<EditBankDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _accountHolderController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _ifscCodeController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _functionsService = FunctionsService();
  
  bool _isSaving = false;
  bool _showAccountNumber = false;
  Technician? _technician;
  String _bankVerificationStatus = 'not_submitted'; // not_submitted, verifying, verified, failed
  bool _bankVerified = false;
  bool _canResubmit = false;
  String? _rejectionReason;

  @override
  void initState() {
    super.initState();
    _loadCurrentData();
  }

  void _loadCurrentData() {
    final provider = context.read<TechnicianProvider>();
    _technician = provider.technician;
    
    if (_technician != null) {
      final techData = _technician!.toMap();
      _bankVerificationStatus = techData['bankVerificationStatus'] ?? 'not_submitted';
      _bankVerified = techData['bankVerified'] ?? false;
      _rejectionReason = techData['bankVerificationMessage'];
      
      // Determine if user can resubmit
      _canResubmit = _bankVerificationStatus == 'failed' || _bankVerificationStatus == 'not_submitted';
      
      // SECURITY: Only prefill if editable (not_submitted or failed)
      // Never expose raw account number for verified/verifying
      if (_canResubmit) {
        _accountHolderController.text = techData['accountHolderName'] ?? '';
        _bankNameController.text = techData['bankName'] ?? '';
        _accountNumberController.text = techData['accountNumber'] ?? '';
        _ifscCodeController.text = techData['ifscCode'] ?? '';
      }
    }
  }

  @override
  void dispose() {
    _accountHolderController.dispose();
    _accountNumberController.dispose();
    _ifscCodeController.dispose();
    _bankNameController.dispose();
    super.dispose();
  }

  String? _validateIfscCode(String? value) {
    if (value == null || value.isEmpty) {
      return 'IFSC Code is required';
    }
    final ifscRegex = RegExp(r'^[A-Z]{4}0[A-Z0-9]{6}$');
    if (!ifscRegex.hasMatch(value.toUpperCase())) {
      return 'Invalid IFSC Code format';
    }
    return null;
  }

  String? _validateAccountNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Account number required';
    }
    if (!RegExp(r'^[0-9]{9,18}$').hasMatch(value.trim())) {
      return 'Invalid Account Number';
    }
    return null;
  }

  Future<void> _saveBankDetails() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isSaving) return;

    setState(() => _isSaving = true);

    try {
      print('[BANK_VERIFY] Starting verification...');
      
      // FIX 1: Capture response
      final result = await _functionsService.verifyTechnicianBankAccountSecure(
        accountHolderName: _accountHolderController.text.trim(),
        accountNumber: _accountNumberController.text.trim(),
        ifscCode: _ifscCodeController.text.trim().toUpperCase(),
      );

      print('[BANK_VERIFY] Response received: $result');

      if (!mounted) return;

      // FIX 2: Validate response before proceeding
      if (result['success'] != true) {
        throw Exception(result['message'] ?? 'Verification failed');
      }

      print('[BANK_VERIFY] Verification successful, refreshing data...');
      
      // FIX 3: Refresh technician data
      await context.read<TechnicianProvider>().refreshTechnicianData();

      if (!mounted) return;

      print('[BANK_VERIFY] Data refreshed, showing success message');
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bank verification initiated successfully'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
      
      // FIX 4: Delay navigation to ensure UI updates
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      print('[BANK_VERIFY] Error: $e');
      
      if (mounted) {
        // FIX 5: Always reset loading state
        setState(() => _isSaving = false);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Dynamic UI based on bank verification status
    if (_bankVerificationStatus == 'verifying') {
      return _buildVerifyingView();
    } else if (_bankVerified == true && _bankVerificationStatus == 'verified') {
      return _buildVerifiedView();
    } else {
      // not_submitted or failed - show editable form
      return _buildEditableForm();
    }
  }

  Widget _buildVerifyingView() {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Bank Details', style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Color(0xFFDEF7EC),
                  shape: BoxShape.circle,
                ),
                child: const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Verifying...',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'We are verifying your bank details. This usually takes a few moments.',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 32),
              if (_technician != null) ..._buildMaskedDetails(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVerifiedView() {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Bank Details', style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.verified, size: 60, color: Color(0xFF10B981)),
              ),
              const SizedBox(height: 24),
              Text(
                'Bank Details Verified ✅',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Your bank details have been verified and approved. You can now receive payouts.',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 32),
              if (_technician != null) ..._buildMaskedDetails(),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildMaskedDetails() {
    final techData = _technician!.toMap();
    final accountNumber = techData['accountNumber'] ?? '';
    final maskedAccount = accountNumber.length > 4 ? '****${accountNumber.substring(accountNumber.length - 4)}' : accountNumber;
    
    return [
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            _buildDetailRow('Account Holder', techData['accountHolderName'] ?? '-'),
            const Divider(height: 24),
            _buildDetailRow('Bank Name', techData['bankName'] ?? '-'),
            const Divider(height: 24),
            _buildDetailRow('Account Number', maskedAccount),
            const Divider(height: 24),
            _buildDetailRow('IFSC Code', techData['ifscCode'] ?? '-'),
          ],
        ),
      ),
    ];
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            color: const Color(0xFF64748B),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }

  Widget _buildEditableForm() {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Bank Details', style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_bankVerificationStatus == 'failed') ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Bank Verification Failed', style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.red)),
                            const SizedBox(height: 4),
                            Text(_rejectionReason ?? 'Please update and resubmit', style: GoogleFonts.plusJakartaSans(fontSize: 13, color: Colors.red.shade700)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: const Color(0xFF10B981).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    children: [
                      const Icon(Icons.security, color: Color(0xFF10B981)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text('Your bank details are securely encrypted and stored.', style: GoogleFonts.plusJakartaSans(fontSize: 14, color: const Color(0xFF10B981))),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
              Text('Account Holder Name', style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF64748B))),
              const SizedBox(height: 8),
              TextFormField(
                controller: _accountHolderController,
                decoration: InputDecoration(hintText: 'Enter account holder name', filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                validator: (value) => value == null || value.trim().isEmpty ? 'Account holder name is required' : value.trim().length < 3 ? 'Name must be at least 3 characters' : null,
              ),
              const SizedBox(height: 20),
              Text('Bank Name', style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF64748B))),
              const SizedBox(height: 8),
              TextFormField(
                controller: _bankNameController,
                decoration: InputDecoration(hintText: 'Enter bank name', filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                validator: (value) => value == null || value.trim().isEmpty ? 'Bank name is required' : null,
              ),
              const SizedBox(height: 20),
              Text('Account Number', style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF64748B))),
              const SizedBox(height: 8),
              TextFormField(
                controller: _accountNumberController,
                keyboardType: TextInputType.number,
                obscureText: !_showAccountNumber,
                decoration: InputDecoration(
                  hintText: 'Enter account number',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  suffixIcon: IconButton(icon: Icon(_showAccountNumber ? Icons.visibility_off : Icons.visibility), onPressed: () => setState(() => _showAccountNumber = !_showAccountNumber)),
                ),
                validator: _validateAccountNumber,
              ),
              const SizedBox(height: 20),
              Text('IFSC Code', style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF64748B))),
              const SizedBox(height: 8),
              TextFormField(
                controller: _ifscCodeController,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(hintText: 'e.g., SBIN0001234', filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                validator: _validateIfscCode,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveBankDetails,
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366F1), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: _isSaving ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white))) : Text(_bankVerificationStatus == 'failed' ? 'Resubmit Bank Details' : 'Submit Bank Details', style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

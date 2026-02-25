import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class Step4BankDetails extends StatefulWidget {
  final Map<String, dynamic> formData;
  final Function(String, dynamic) onDataChanged;

  const Step4BankDetails({
    super.key,
    required this.formData,
    required this.onDataChanged,
  });

  @override
  State<Step4BankDetails> createState() => _Step4BankDetailsState();
}

class _Step4BankDetailsState extends State<Step4BankDetails> {
  late TextEditingController _accountHolderController;
  late TextEditingController _accountNumberController;
  late TextEditingController _ifscController;
  late TextEditingController _bankNameController;
  late TextEditingController _upiController;

  @override
  void initState() {
    super.initState();
    _accountHolderController = TextEditingController(
      text: widget.formData['accountHolder'] ?? '',
    );
    _accountNumberController = TextEditingController(
      text: widget.formData['accountNumber'] ?? '',
    );
    _ifscController = TextEditingController(
      text: widget.formData['ifscCode'] ?? '',
    );
    _bankNameController = TextEditingController(
      text: widget.formData['bankName'] ?? '',
    );
    _upiController = TextEditingController(
      text: widget.formData['upiId'] ?? '',
    );
  }

  @override
  void dispose() {
    _accountHolderController.dispose();
    _accountNumberController.dispose();
    _ifscController.dispose();
    _bankNameController.dispose();
    _upiController.dispose();
    super.dispose();
  }

  String? _validateIFSC(String value) {
    if (value.isEmpty) return null;
    final ifscRegex = RegExp(r'^[A-Z]{4}0[A-Z0-9]{6}$');
    if (!ifscRegex.hasMatch(value)) {
      return 'Invalid IFSC code format';
    }
    return null;
  }

  String? _validateAccountNumber(String value) {
    if (value.isEmpty) return null;
    if (value.length < 9 || value.length > 18) {
      return 'Account number must be 9-18 digits';
    }
    if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
      return 'Account number must contain only digits';
    }
    return null;
  }

  String? _validateUPI(String value) {
    if (value.isEmpty) return null;
    final upiRegex = RegExp(r'^[a-zA-Z0-9._-]+@[a-zA-Z]{3,}$');
    if (!upiRegex.hasMatch(value)) {
      return 'Invalid UPI ID format';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bank & Payout Details',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Where we\'ll send your earnings',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: const Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 32),
          _buildSecurityNotice(),
          const SizedBox(height: 24),
          _buildTextField(
            controller: _accountHolderController,
            label: 'Account Holder Name',
            hint: 'Name as per bank records',
            icon: Icons.person_outline,
            onChanged: (value) =>
                widget.onDataChanged('accountHolder', value),
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _accountNumberController,
            label: 'Account Number',
            hint: 'Enter account number',
            icon: Icons.account_balance_outlined,
            keyboardType: TextInputType.number,
            validator: _validateAccountNumber,
            onChanged: (value) =>
                widget.onDataChanged('accountNumber', value),
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _ifscController,
            label: 'IFSC Code',
            hint: 'e.g., SBIN0001234',
            icon: Icons.code_outlined,
            textTransform: TextInputAction.none,
            validator: _validateIFSC,
            onChanged: (value) => widget.onDataChanged('ifscCode', value),
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _bankNameController,
            label: 'Bank Name',
            hint: 'Your bank name',
            icon: Icons.business_outlined,
            onChanged: (value) => widget.onDataChanged('bankName', value),
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _upiController,
            label: 'UPI ID (Optional)',
            hint: 'yourname@upi',
            icon: Icons.payment_outlined,
            validator: _validateUPI,
            onChanged: (value) => widget.onDataChanged('upiId', value),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSecurityNotice() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFDEF7EC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFA7F3D0),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.lock_outline,
            color: Color(0xFF059669),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Your bank details are encrypted and stored securely. We use industry-standard security protocols.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: const Color(0xFF065F46),
                height: 1.5,
              ),
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
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    TextInputAction textTransform = TextInputAction.next,
    String? Function(String)? validator,
    required Function(String) onChanged,
  }) {
    final error = validator?.call(controller.text);
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
              color: error != null ? Colors.red : const Color(0xFFE2E8F0),
              width: 1,
            ),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            textInputAction: textTransform,
            onChanged: (value) {
              onChanged(value);
              setState(() {});
            },
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
}

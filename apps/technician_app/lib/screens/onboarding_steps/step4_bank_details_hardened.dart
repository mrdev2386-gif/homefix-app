import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class Step4BankDetailsHardened extends StatefulWidget {
  final Map<String, dynamic> formData;
  final Function(String, dynamic) onDataChanged;

  const Step4BankDetailsHardened({
    super.key,
    required this.formData,
    required this.onDataChanged,
  });

  @override
  State<Step4BankDetailsHardened> createState() => _Step4BankDetailsHardenedState();
}

class _Step4BankDetailsHardenedState extends State<Step4BankDetailsHardened> {
  late TextEditingController _accountHolderController;
  late TextEditingController _accountNumberController;
  late TextEditingController _confirmAccountController;
  late TextEditingController _ifscController;
  late TextEditingController _bankNameController;
  late TextEditingController _upiController;
  bool _showAccountNumber = false;
  bool _showConfirmAccount = false;

  @override
  void initState() {
    super.initState();
    _accountHolderController = TextEditingController(
      text: formData['accountHolder'] ?? '',
    );
    _accountNumberController = TextEditingController(
      text: formData['accountNumber'] ?? '',
    );
    _confirmAccountController = TextEditingController(
      text: formData['confirmAccountNumber'] ?? '',
    );
    _ifscController = TextEditingController(
      text: formData['ifscCode'] ?? '',
    );
    _bankNameController = TextEditingController(
      text: formData['bankName'] ?? '',
    );
    _upiController = TextEditingController(
      text: formData['upiId'] ?? '',
    );
  }

  @override
  void dispose() {
    _accountHolderController.dispose();
    _accountNumberController.dispose();
    _confirmAccountController.dispose();
    _ifscController.dispose();
    _bankNameController.dispose();
    _upiController.dispose();
    super.dispose();
  }

  String? _validateAccountNumber(String value) {
    if (value.isEmpty) return null;
    if (value.length < 9 || value.length > 18) return 'Account: 9-18 digits';
    if (!RegExp(r'^[0-9]+$').hasMatch(value)) return 'Digits only';
    return null;
  }

  String? _validateAccountMatch() {
    if (_accountNumberController.text.isEmpty || _confirmAccountController.text.isEmpty) return null;
    if (_accountNumberController.text != _confirmAccountController.text) {
      return 'Accounts do not match';
    }
    return null;
  }

  String? _validateIFSC(String value) {
    if (value.isEmpty) return null;
    if (!RegExp(r'^[A-Z]{4}0[A-Z0-9]{6}$').hasMatch(value)) return 'Invalid IFSC';
    return null;
  }

  String? _validateUPI(String value) {
    if (value.isEmpty) return null;
    if (!RegExp(r'^[a-zA-Z0-9._-]+@[a-zA-Z]{3,}$').hasMatch(value)) return 'Invalid UPI';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final accountError = _validateAccountNumber(_accountNumberController.text);
    final confirmError = _validateAccountMatch();
    final ifscError = _validateIFSC(_ifscController.text);
    final upiError = _validateUPI(_upiController.text);

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
            onChanged: (value) => onDataChanged('accountHolder', value),
          ),
          const SizedBox(height: 16),
          _buildMaskedField(
            controller: _accountNumberController,
            label: 'Account Number',
            hint: 'Enter account number',
            icon: Icons.account_balance_outlined,
            error: accountError,
            showPassword: _showAccountNumber,
            onToggle: () => setState(() => _showAccountNumber = !_showAccountNumber),
            onChanged: (value) {
              onDataChanged('accountNumber', value);
              setState(() {});
            },
          ),
          const SizedBox(height: 16),
          _buildMaskedField(
            controller: _confirmAccountController,
            label: 'Confirm Account Number',
            hint: 'Re-enter account number',
            icon: Icons.check_circle_outline,
            error: confirmError,
            showPassword: _showConfirmAccount,
            onToggle: () => setState(() => _showConfirmAccount = !_showConfirmAccount),
            onChanged: (value) {
              onDataChanged('confirmAccountNumber', value);
              setState(() {});
            },
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _ifscController,
            label: 'IFSC Code',
            hint: 'e.g., SBIN0001234',
            icon: Icons.code_outlined,
            error: ifscError,
            onChanged: (value) {
              onDataChanged('ifscCode', value);
              setState(() {});
            },
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _bankNameController,
            label: 'Bank Name',
            hint: 'Your bank name',
            icon: Icons.business_outlined,
            onChanged: (value) => onDataChanged('bankName', value),
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _upiController,
            label: 'UPI ID (Optional)',
            hint: 'yourname@upi',
            icon: Icons.payment_outlined,
            error: upiError,
            onChanged: (value) {
              onDataChanged('upiId', value);
              setState(() {});
            },
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
        border: Border.all(color: const Color(0xFFA7F3D0), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lock_outline, color: Color(0xFF059669), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Your bank details are encrypted. Account numbers are never logged.',
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
    String? error,
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
              color: error != null ? Colors.red : const Color(0xFFE2E8F0),
              width: 1,
            ),
          ),
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.text,
            onChanged: onChanged,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
              prefixIcon: Icon(icon, color: const Color(0xFF6366F1), size: 20),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              error,
              style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.red),
            ),
          ),
      ],
    );
  }

  Widget _buildMaskedField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? error,
    required bool showPassword,
    required VoidCallback onToggle,
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
              color: error != null ? Colors.red : const Color(0xFFE2E8F0),
              width: 1,
            ),
          ),
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            obscureText: !showPassword,
            onChanged: onChanged,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
              prefixIcon: Icon(icon, color: const Color(0xFF6366F1), size: 20),
              suffixIcon: IconButton(
                icon: Icon(
                  showPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  color: const Color(0xFF6366F1),
                  size: 20,
                ),
                onPressed: onToggle,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              error,
              style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.red),
            ),
          ),
      ],
    );
  }
}

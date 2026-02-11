import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../providers/partner_onboarding_provider.dart';

/// Bank Details Step - Step 7 of 8
/// 
/// FIXES:
/// - Uses StatefulWidget with persistent TextEditingControllers
/// - Shows inline validation errors
/// - Modern card-based UI
class OnboardingStepBank extends StatefulWidget {
  final Animation<double> fadeAnimation;
  final Animation<Offset> slideAnimation;

  const OnboardingStepBank({
    super.key,
    required this.fadeAnimation,
    required this.slideAnimation,
  });

  @override
  State<OnboardingStepBank> createState() => _OnboardingStepBankState();
}

class _OnboardingStepBankState extends State<OnboardingStepBank> {
  late TextEditingController _holderNameController;
  late TextEditingController _accountNumberController;
  late TextEditingController _ifscController;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final provider = context.read<PartnerOnboardingProvider>();
      _holderNameController = TextEditingController(text: provider.bankHolderName);
      _accountNumberController = TextEditingController(text: provider.bankAccountNumber);
      _ifscController = TextEditingController(text: provider.bankIfscCode);
      _initialized = true;
    }
  }

  @override
  void dispose() {
    _holderNameController.dispose();
    _accountNumberController.dispose();
    _ifscController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PartnerOnboardingProvider>(
      builder: (context, provider, child) {
        return FadeTransition(
          opacity: widget.fadeAnimation,
          child: SlideTransition(
            position: widget.slideAnimation,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.primaryColor.withOpacity(0.1),
                            AppTheme.primaryColor.withOpacity(0.05),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.account_balance_outlined,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Bank Details',
                                  style: GoogleFonts.outfit(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    color: AppTheme.textColor,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'For receiving your payments',
                                  style: GoogleFonts.outfit(
                                    fontSize: 14,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Form Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          _buildTextField(
                            controller: _holderNameController,
                            label: 'Account Holder Name',
                            hint: 'As per bank records',
                            icon: Icons.person_outline_rounded,
                            onChanged: provider.setBankHolderName,
                            errorText: _getHolderNameError(provider.bankHolderName),
                          ),
                          const SizedBox(height: 20),
                          _buildTextField(
                            controller: _accountNumberController,
                            label: 'Account Number',
                            hint: 'Enter account number',
                            icon: Icons.numbers_outlined,
                            onChanged: provider.setBankAccountNumber,
                            keyboardType: TextInputType.number,
                            errorText: _getAccountError(provider.bankAccountNumber),
                          ),
                          const SizedBox(height: 20),
                          _buildTextField(
                            controller: _ifscController,
                            label: 'IFSC Code',
                            hint: 'e.g., SBIN0001234',
                            icon: Icons.code_outlined,
                            onChanged: (value) => provider.setBankIfscCode(value.toUpperCase()),
                            textCapitalization: TextCapitalization.characters,
                            maxLength: 11,
                            errorText: _getIfscError(provider.bankIfscCode),
                          ),
                        ],
                      ),
                    ),
                    
                    // Security Info
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF93C5FD)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF3B82F6).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.security_outlined,
                              color: Color(0xFF2563EB),
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Your data is secure',
                                  style: GoogleFonts.outfit(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF1E40AF),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Bank details are encrypted and stored securely. We never share your information.',
                                  style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    color: const Color(0xFF1E40AF),
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Payment Info
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF86EFAC)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.payments_outlined,
                                color: Color(0xFF16A34A),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Payment Schedule',
                                style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF166534),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            '• Payments are processed weekly\n'
                            '• Minimum payout: ₹500\n'
                            '• Direct bank transfer (NEFT/IMPS)',
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              color: const Color(0xFF166534),
                              height: 1.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String? _getHolderNameError(String name) {
    if (name.isEmpty) return null;
    if (name.trim().length < 3) return 'Name must be at least 3 characters';
    return null;
  }

  String? _getAccountError(String account) {
    if (account.isEmpty) return null;
    if (!RegExp(r'^\d+$').hasMatch(account)) return 'Only digits allowed';
    if (account.length < 9) return 'Account number must be at least 9 digits';
    return null;
  }

  String? _getIfscError(String ifsc) {
    if (ifsc.isEmpty) return null;
    if (ifsc.length != 11) return 'IFSC must be exactly 11 characters';
    if (!RegExp(r'^[A-Z]{4}0[A-Z0-9]{6}$').hasMatch(ifsc.toUpperCase())) {
      return 'Invalid IFSC format (e.g., SBIN0001234)';
    }
    return null;
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required Function(String) onChanged,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    int? maxLength,
    String? errorText,
  }) {
    final hasError = errorText != null;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppTheme.textColor,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '*',
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.red,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          onChanged: onChanged,
          keyboardType: keyboardType,
          textCapitalization: textCapitalization,
          maxLength: maxLength,
          style: GoogleFonts.outfit(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppTheme.textColor,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.outfit(
              color: Colors.grey.shade400,
              fontWeight: FontWeight.w500,
            ),
            prefixIcon: Icon(
              icon,
              color: hasError ? Colors.red : AppTheme.primaryColor,
              size: 22,
            ),
            counterText: '',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: hasError ? Colors.red.shade200 : Colors.grey.shade200,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: hasError ? Colors.red : AppTheme.primaryColor,
                width: 2,
              ),
            ),
            filled: true,
            fillColor: hasError ? Colors.red.shade50 : Colors.grey.shade50,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.error_outline, size: 14, color: Colors.red),
              const SizedBox(width: 4),
              Text(
                errorText,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: Colors.red,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

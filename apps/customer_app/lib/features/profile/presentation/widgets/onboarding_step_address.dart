import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:customer_app/core/theme/app_theme.dart';
import '../../providers/partner_onboarding_provider.dart';

/// Service Address Step - Step 6 of 8
/// 
/// FIXES:
/// - Uses StatefulWidget with persistent TextEditingController
/// - Shows inline validation errors
/// - Modern card-based UI
class OnboardingStepAddress extends StatefulWidget {
  final Animation<double> fadeAnimation;
  final Animation<Offset> slideAnimation;

  const OnboardingStepAddress({
    super.key,
    required this.fadeAnimation,
    required this.slideAnimation,
  });

  @override
  State<OnboardingStepAddress> createState() => _OnboardingStepAddressState();
}

class _OnboardingStepAddressState extends State<OnboardingStepAddress> {
  late TextEditingController _addressController;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final provider = context.read<PartnerOnboardingProvider>();
      _addressController = TextEditingController(text: provider.address);
      _initialized = true;
    }
  }

  @override
  void dispose() {
    _addressController.dispose();
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
                              Icons.location_on_outlined,
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
                                  'Service Address',
                                  style: GoogleFonts.outfit(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    color: AppTheme.textColor,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Where will you provide services?',
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Complete Address',
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
                            controller: _addressController,
                            onChanged: provider.setAddress,
                            maxLines: 5,
                            style: GoogleFonts.outfit(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textColor,
                            ),
                            decoration: InputDecoration(
                              hintText: 'House/Flat No., Building Name,\nStreet, Area/Locality,\nCity, State - PIN Code',
                              hintStyle: GoogleFonts.outfit(
                                color: Colors.grey.shade400,
                                fontWeight: FontWeight.w500,
                                height: 1.5,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(color: Colors.grey.shade200),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(color: Colors.grey.shade200),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
                              ),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                              contentPadding: const EdgeInsets.all(16),
                            ),
                          ),
                          
                          // Character count
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              if (provider.address.trim().length < 10 && provider.address.isNotEmpty)
                                Row(
                                  children: [
                                    const Icon(Icons.info_outline, size: 14, color: Colors.orange),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Minimum 10 characters required',
                                      style: GoogleFonts.outfit(
                                        fontSize: 12,
                                        color: Colors.orange,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                )
                              else
                                const SizedBox(),
                              Text(
                                '${provider.address.length} characters',
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    // Service Area Info
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF93C5FD)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.info_outline,
                                color: Color(0xFF2563EB),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Service Area',
                                style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF1E40AF),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'This address will be used to match you with nearby customers. You can update your service radius later in settings.',
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              color: const Color(0xFF1E40AF),
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Address Tips
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFFCD34D)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.tips_and_updates_outlined,
                                color: Color(0xFFD97706),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Tips',
                                style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF92400E),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            '• Include landmark for easy identification\n'
                            '• Ensure PIN code is correct\n'
                            '• This helps customers find you easily',
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              color: const Color(0xFF92400E),
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
}

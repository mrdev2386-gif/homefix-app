// SIMPLIFIED WALLET BANK SECTION
// Replace _buildBankAccountsSection in wallet_screen.dart

Widget _buildBankAccountsSection() {
  return Consumer<TechnicianProvider>(
    builder: (context, techProvider, child) {
      if (techProvider.isLoading) {
        return const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Center(child: CircularProgressIndicator()),
        );
      }

      final technician = techProvider.technician;
      final hasBankDetails = technician != null &&
          technician.bankName != null &&
          technician.bankName!.isNotEmpty &&
          technician.accountNumber != null &&
          technician.accountNumber!.isNotEmpty &&
          technician.ifscCode != null &&
          technician.ifscCode!.isNotEmpty;

      final bankStatus = technician?.bankStatus;

      AppLogger.firestore(
        'Wallet bank data',
        data: {
          'hasBankDetails': hasBankDetails,
          'bankStatus': bankStatus,
        },
      );

      // NO BANK DETAILS - Show redirect to profile
      if (!hasBankDetails) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primaryColor.withValues(alpha: 0.1),
                        AppTheme.primaryColor.withValues(alpha: 0.05),
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.account_balance_outlined,
                    size: 40,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'No bank account linked',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.bold,
                    fontSize: 19,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Add your bank details from Profile to enable withdrawals',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6366F1).withValues(alpha: 0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _navigateToBankDetails(context),
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.add_circle_outline_rounded, color: Colors.white, size: 22),
                            const SizedBox(width: 10),
                            Text(
                              'Add Bank Account',
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }

      // BANK DETAILS EXIST - Show status-based UI
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Bank Account',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getBankStatusColor(bankStatus).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getBankStatusText(bankStatus),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _getBankStatusColor(bankStatus),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // VERIFYING STATUS
            if (bankStatus == 'verifying')
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Verifying bank account...',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              color: Colors.orange.shade900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'This usually takes a few seconds',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.orange.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            
            // REJECTED STATUS
            if (bankStatus == 'rejected')
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red.shade700, size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Bank verification failed',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              color: Colors.red.shade900,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      technician.bankVerificationMessage ?? 'Please check your bank details and try again',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.red.shade700,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => _navigateToBankDetails(context),
                      icon: const Icon(Icons.edit, size: 18),
                      label: const Text('Update Bank Details'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            
            // APPROVED STATUS - Show bank details
            if (bankStatus == 'approved')
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 15,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.account_balance,
                            color: Color(0xFF6366F1),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                technician.bankName ?? 'Bank',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF1E293B),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                technician.accountHolderName ?? 'Account Holder',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    const Divider(height: 1),
                    const SizedBox(height: 18),
                    _buildBankDetailRow(
                      'Account Number',
                      _maskAccountNumber(technician.accountNumber ?? ''),
                    ),
                    const SizedBox(height: 14),
                    _buildBankDetailRow(
                      'IFSC Code',
                      technician.ifscCode ?? '',
                    ),
                  ],
                ),
              ),
          ],
        ),
      );
    },
  );
}

// Navigation helper
void _navigateToBankDetails(BuildContext context) {
  Navigator.pushNamed(context, '/profile');
  // Profile screen should auto-scroll to Bank & Payout section
}

// Helper methods (same as before)
Widget _buildBankDetailRow(String label, String value) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 13, color: Colors.grey[600])),
      Text(
        value,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF1E293B),
        ),
      ),
    ],
  );
}

String _maskAccountNumber(String accountNumber) {
  if (accountNumber.length <= 4) return accountNumber;
  final lastFour = accountNumber.substring(accountNumber.length - 4);
  return 'XXXX$lastFour';
}

Color _getBankStatusColor(String? status) {
  switch (status) {
    case 'approved':
      return const Color(0xFF10B981);
    case 'verifying':
      return const Color(0xFFF59E0B);
    case 'rejected':
      return const Color(0xFFEF4444);
    default:
      return Colors.grey;
  }
}

String _getBankStatusText(String? status) {
  switch (status) {
    case 'approved':
      return 'Verified';
    case 'verifying':
      return 'Verifying...';
    case 'rejected':
      return 'Failed';
    default:
      return 'Not Submitted';
  }
}

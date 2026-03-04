// WALLET SCREEN BANK DETAILS FIX
// Replace the following in wallet_screen.dart:

// 1. REMOVE these lines from class fields:
//   List<TechnicianBankAccount> _bankAccounts = [];
//   bool _isLoadingBanks = true;

// 2. REPLACE initState with:
@override
void initState() {
  super.initState();
  // Bank details loaded from TechnicianProvider - no separate fetch needed
}

// 3. DELETE the entire _loadBankAccounts() method

// 4. REPLACE _buildBankAccountsSection() with:
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
          technician.accountNumber != null &&
          technician.ifscCode != null;

      if (!hasBankDetails) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Icon(Icons.account_balance_outlined, size: 56, color: Colors.grey[300]),
                const SizedBox(height: 24),
                Text(
                  'No bank account linked',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Add a bank account to withdraw your earnings',
                  style: TextStyle(color: Colors.grey[500], fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _showAddBankDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Bank Account'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ],
            ),
          ),
        );
      }

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Linked Bank Account',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getBankStatusColor(technician.bankStatus).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getBankStatusText(technician.bankStatus),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _getBankStatusColor(technician.bankStatus),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
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
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.account_balance, color: Color(0xFF6366F1), size: 24),
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
                                color: const Color(0xFF0F172A),
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
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 16),
                  _buildBankDetailRow('Account Number', _maskAccountNumber(technician.accountNumber ?? '')),
                  const SizedBox(height: 12),
                  _buildBankDetailRow('IFSC Code', technician.ifscCode ?? ''),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );
}

// 5. ADD these helper methods:
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
          color: const Color(0xFF0F172A),
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
    case 'pending':
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
    case 'pending':
      return 'Pending';
    case 'rejected':
      return 'Rejected';
    default:
      return 'Not Submitted';
  }
}

// 6. UPDATE _buildActionButtonsRow to use TechnicianProvider:
// Find the line: final canWithdraw = hasBalance && wallet.canWithdraw && !_isWithdrawing && _bankAccounts.isNotEmpty;
// Replace with Consumer pattern checking technician.bankName != null

// 7. UPDATE RefreshIndicator onRefresh:
// Replace: await _loadBankAccounts();
// With: await context.read<TechnicianProvider>().refreshTechnicianData();

// 8. ADD import at top:
// import '../core/utils/app_logger.dart';

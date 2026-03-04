// UPDATED WITHDRAW BUTTON LOGIC
// Replace _buildActionButtonsRow in wallet_screen.dart

Widget _buildActionButtonsRow(TechnicianWallet wallet) {
  return Consumer<TechnicianProvider>(
    builder: (context, techProvider, child) {
      final technician = techProvider.technician;
      final hasBankDetails = technician != null &&
          technician.bankName != null &&
          technician.bankName!.isNotEmpty &&
          technician.accountNumber != null &&
          technician.accountNumber!.isNotEmpty &&
          technician.ifscCode != null &&
          technician.ifscCode!.isNotEmpty;
      
      final bankStatus = technician?.bankStatus;
      final isBankApproved = bankStatus == 'approved';
      final hasBalance = wallet.availableBalance > 0;
      
      // Withdraw enabled ONLY when bank is approved
      final canWithdraw = hasBalance && 
                         wallet.canWithdraw && 
                         !_isWithdrawing && 
                         hasBankDetails && 
                         isBankApproved;

      // Determine button state message
      String? disabledMessage;
      if (!hasBankDetails) {
        disabledMessage = 'Add bank account to withdraw';
      } else if (bankStatus == 'verifying') {
        disabledMessage = 'Bank verification in progress';
      } else if (bankStatus == 'rejected') {
        disabledMessage = 'Bank verification failed';
      } else if (!hasBalance) {
        disabledMessage = 'Insufficient balance';
      }

      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Show warning message if withdraw disabled
            if (!canWithdraw && disabledMessage != null)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange.shade700, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        disabledMessage,
                        style: TextStyle(
                          color: Colors.orange.shade900,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: _ModernActionButton(
                    icon: Icons.account_balance_wallet_outlined,
                    label: 'Withdraw',
                    onTap: canWithdraw ? _showWithdrawDialog : null,
                    gradientColors: canWithdraw
                        ? const [Color(0xFF10B981), Color(0xFF059669)]
                        : [Colors.grey.shade300, Colors.grey.shade400],
                    isDisabled: !canWithdraw,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ModernActionButton(
                    icon: Icons.history,
                    label: 'History',
                    onTap: () => _navigateToTransactionHistory(context),
                    gradientColors: const [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    },
  );
}

void _navigateToTransactionHistory(BuildContext context) {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const TransactionHistoryScreen()),
  );
}

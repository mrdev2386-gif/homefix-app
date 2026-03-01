import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import '../core/app_theme.dart';
import '../core/services/wallet_service.dart';
import '../core/models/wallet.dart';
import '../core/models/wallet_transaction.dart';
import '../core/models/bank_account.dart';
import '../core/providers/technician_provider.dart';
import 'add_bank_account_screen.dart';

/// Premium Technician Wallet Screen
/// 
/// Features:
/// - Glass morphism wallet header card
/// - Real-time balance updates via StreamBuilder
/// - Secure withdrawal flow via Cloud Functions
/// - Transaction history with grouping by date
/// - Shimmer loading states
/// - Premium fintech-style UI
/// 
/// NO Add Money feature - per requirements
class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final WalletService _walletService = WalletService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Bank accounts loaded once
  List<TechnicianBankAccount> _bankAccounts = [];
  bool _isWithdrawing = false;
  bool _isLoadingBanks = true;
  
  @override
  void initState() {
    super.initState();
    _loadBankAccounts();
  }

  Future<void> _loadBankAccounts() async {
    try {
      final technicianId = FirebaseAuth.instance.currentUser?.uid;
      if (technicianId == null) return;

      final snapshot = await _firestore
          .collection('technician_bank_accounts')
          .where('technicianId', isEqualTo: technicianId)
          .where('status', isEqualTo: 'verified')
          .get();

      if (mounted) {
        setState(() {
          _bankAccounts = snapshot.docs
              .map((doc) => TechnicianBankAccount.fromFirestore(doc))
              .toList();
          _isLoadingBanks = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading bank accounts: $e');
      if (mounted) {
        setState(() => _isLoadingBanks = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      body: SafeArea(
        child: _buildContent(),
      ),
    );
  }

  /// Build main content using StreamBuilder for realtime wallet updates
  Widget _buildContent() {
    return StreamBuilder<TechnicianWallet>(
      stream: _walletService.watchWallet(),
      builder: (context, walletSnapshot) {
        return StreamBuilder<List<WalletTransaction>>(
          stream: _walletService.watchTransactions(limit: 15),
          builder: (context, txnSnapshot) {
            // Handle loading states with shimmer
            if (walletSnapshot.connectionState == ConnectionState.waiting) {
              return _buildShimmerLoading();
            }
            
            if (walletSnapshot.hasError) {
              return _buildErrorWidget(walletSnapshot.error?.toString() ?? 'Unknown error');
            }
            
            final wallet = walletSnapshot.data;
            final transactions = txnSnapshot.data ?? [];
            
            if (wallet == null) {
              return _buildErrorWidget('Wallet not found');
            }
            
            return RefreshIndicator(
              onRefresh: () async {
                await _loadBankAccounts();
              },
              color: AppTheme.primaryColor,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Column(
                      children: [
                        _buildGlassHeader(wallet),
                        const SizedBox(height: 20),
                        _buildQuickActions(wallet),
                        const SizedBox(height: 20),
                        _buildBankAccountsSection(),
                        const SizedBox(height: 20),
                        _buildTransactionHistory(transactions),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// Shimmer loading state for premium feel
  Widget _buildShimmerLoading() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Column(
          children: [
            const SizedBox(height: 16),
            // Glass header shimmer
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              height: 200,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            const SizedBox(height: 20),
            // Quick actions shimmer
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: List.generate(2, (index) => Expanded(
                  child: Container(
                    height: 80,
                    margin: EdgeInsets.only(left: index == 0 ? 0 : 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                )),
              ),
            ),
            const SizedBox(height: 20),
            // Transactions shimmer
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: List.generate(5, (index) => Container(
                  height: 72,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                )),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Premium glass morphism header card
  Widget _buildGlassHeader(TechnicianWallet wallet) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF6366F1),
            Color(0xFF8B5CF6),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withValues(alpha: 0.15),
              Colors.white.withValues(alpha: 0.05),
            ],
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row with title and KYC badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Available Balance',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        wallet.isKycVerified ? Icons.verified : Icons.pending,
                        color: Colors.white,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        wallet.isKycVerified ? 'Verified' : 'KYC Pending',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Large balance display
            Text(
              '₹${_formatAmount(wallet.availableBalance)}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 42,
                fontWeight: FontWeight.bold,
                letterSpacing: -1.5,
              ),
            ),
            const SizedBox(height: 24),
            // Balance breakdown row
            Row(
              children: [
                Expanded(
                  child: _buildBalanceChip(
                    'Pending',
                    wallet.pendingBalance,
                    Icons.hourglass_empty,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildBalanceChip(
                    'On Hold',
                    wallet.onHoldBalance,
                    Icons.lock_outline,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildBalanceChip(
                    'Lifetime',
                    wallet.lifetimeEarnings,
                    Icons.trending_up,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceChip(String label, double amount, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white60, size: 18),
          const SizedBox(height: 4),
          Text(
            '₹${_formatAmount(amount)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  /// Quick actions row with QR Receive
  Widget _buildQuickActions(TechnicianWallet wallet) {
    final hasBalance = wallet.availableBalance > 0;
    final canWithdraw = hasBalance && wallet.canWithdraw && !_isWithdrawing && _bankAccounts.isNotEmpty;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildActionButton(
              icon: Icons.qr_code_2,
              label: 'Receive QR',
              onTap: _showReceiveQRSheet,
              gradient: const [Color(0xFF10B981), Color(0xFF059669)],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildActionButton(
              icon: Icons.account_balance,
              label: 'Add Bank',
              onTap: _showAddBankDialog,
              gradient: const [Color(0xFF3B82F6), Color(0xFF2563EB)],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: _buildActionButton(
              icon: _isWithdrawing ? Icons.hourglass_empty : Icons.arrow_downward,
              label: _isWithdrawing ? 'Processing...' : 'Withdraw',
              onTap: canWithdraw ? () => _showWithdrawBottomSheet(wallet) : null,
              isPrimary: true,
              isLoading: _isWithdrawing,
              gradient: const [Color(0xFF6366F1), Color(0xFF8B5CF6)],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
    required List<Color> gradient,
    bool isPrimary = false,
    bool isLoading = false,
  }) {
    final isDisabled = onTap == null || isLoading;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            gradient: isDisabled 
                ? null 
                : LinearGradient(colors: gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
            color: isDisabled ? Colors.grey[300] : null,
            borderRadius: BorderRadius.circular(16),
            boxShadow: isDisabled ? null : [
              BoxShadow(
                color: gradient.first.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isLoading)
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isPrimary ? Colors.white : gradient.first,
                    ),
                  ),
                )
              else
                Icon(
                  icon,
                  color: isDisabled ? Colors.grey[500] : Colors.white,
                  size: 22,
                ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isDisabled ? Colors.grey[500] : Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Bank accounts section
  Widget _buildBankAccountsSection() {
    if (_isLoadingBanks) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    
    if (_bankAccounts.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.account_balance_outlined,
                  size: 32,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'No bank account linked',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Add a bank account to withdraw your earnings',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _showAddBankDialog,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Bank Account'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 12),
            child: Text(
              'Linked Bank Account',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ..._bankAccounts.map((account) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade100),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.account_balance,
                    color: AppTheme.primaryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        account.bankName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${account.accountHolderName} • ${account.maskedAccountNumber}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                if (account.isVerified)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.successColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle, size: 14, color: AppTheme.successColor),
                        const SizedBox(width: 4),
                        Text(
                          'Verified',
                          style: TextStyle(
                            color: AppTheme.successColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  /// Transaction history with grouping by date
  Widget _buildTransactionHistory(List<WalletTransaction> transactions) {
    // Group transactions by date
    final groupedTransactions = _groupTransactionsByDate(transactions);
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Transaction History',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (transactions.isNotEmpty)
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const TransactionHistoryScreen(),
                      ),
                    );
                  },
                  child: const Text('View All'),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (transactions.isEmpty)
            _buildEmptyTransactionsState()
          else
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: groupedTransactions.length > 5 ? 5 : groupedTransactions.length,
                separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade100),
                itemBuilder: (context, index) {
                  final item = groupedTransactions[index];
                  if (item is String) {
                    // Date header
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      color: Colors.grey.shade50,
                      child: Text(
                        item,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: Colors.grey[700],
                        ),
                      ),
                    );
                  }
                  return _buildTransactionTile(item as WalletTransaction);
                },
              ),
            ),
        ],
      ),
    );
  }

  /// Group transactions by date for better UX
  List<dynamic> _groupTransactionsByDate(List<WalletTransaction> transactions) {
    final List<dynamic> grouped = [];
    String? currentDate;
    
    for (final txn in transactions) {
      final txnDate = DateFormat('MMMM d, yyyy').format(txn.createdAt);
      if (txnDate != currentDate) {
        currentDate = txnDate;
        grouped.add(txnDate);
      }
      grouped.add(txn);
    }
    
    return grouped;
  }

  Widget _buildEmptyTransactionsState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.receipt_long_outlined,
              size: 40,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No transactions yet',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Your transaction history will appear here',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionTile(WalletTransaction txn) {
    final isCredit = txn.type == TransactionType.credit;
    final isPayout = txn.type == TransactionType.payout;
    
    Color iconColor = AppTheme.successColor;
    IconData icon = Icons.arrow_upward;
    String typeLabel = 'Credit';
    
    if (isPayout) {
      iconColor = AppTheme.warningColor;
      icon = Icons.arrow_downward;
      typeLabel = 'Withdrawal';
    } else if (!isCredit) {
      iconColor = AppTheme.errorColor;
      icon = Icons.arrow_downward;
      typeLabel = 'Debit';
    } else if (txn.source == TransactionSource.refund) {
      iconColor = AppTheme.infoColor;
      icon = Icons.replay;
      typeLabel = 'Refund';
    }

    return InkWell(
      onTap: () => _showTransactionDetails(txn),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    txn.description ?? typeLabel,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    DateFormat('MMM d, h:mm a').format(txn.createdAt),
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${isCredit || txn.type == TransactionType.release ? '+' : '-'}₹${_formatAmount(txn.amount)}',
                  style: TextStyle(
                    color: (isCredit || txn.type == TransactionType.release) 
                        ? AppTheme.successColor 
                        : AppTheme.errorColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: txn.status == TransactionStatus.completed
                        ? AppTheme.successColor.withValues(alpha: 0.1)
                        : AppTheme.warningColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    txn.displayStatus,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: txn.status == TransactionStatus.completed
                          ? AppTheme.successColor
                          : AppTheme.warningColor,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showTransactionDetails(WalletTransaction txn) {
    final isCredit = txn.type == TransactionType.credit || txn.type == TransactionType.release;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: (isCredit ? AppTheme.successColor : AppTheme.errorColor).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isCredit ? Icons.arrow_upward : Icons.arrow_downward,
                color: isCredit ? AppTheme.successColor : AppTheme.errorColor,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '${isCredit ? '+' : '-'}₹${_formatAmount(txn.amount)}',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: isCredit ? AppTheme.successColor : AppTheme.errorColor,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: txn.status == TransactionStatus.completed
                    ? AppTheme.successColor.withValues(alpha: 0.1)
                    : AppTheme.warningColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                txn.displayStatus.toUpperCase(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: txn.status == TransactionStatus.completed
                      ? AppTheme.successColor
                      : AppTheme.warningColor,
                ),
              ),
            ),
            const SizedBox(height: 24),
            _buildDetailRow('Transaction ID', txn.txnId.substring(0, min(20, txn.txnId.length))),
            _buildDetailRow('Type', txn.displayType),
            _buildDetailRow('Source', txn.displaySource),
            _buildDetailRow('Date', DateFormat('MMMM d, yyyy • h:mm a').format(txn.createdAt)),
            if (txn.referenceId != null)
              _buildDetailRow('Reference', txn.referenceId!),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  /// Premium withdrawal bottom sheet
  void _showWithdrawBottomSheet(TechnicianWallet wallet) {
    if (_bankAccounts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add a bank account first'),
          backgroundColor: AppTheme.warningColor,
        ),
      );
      return;
    }

    final amountController = TextEditingController();
    TechnicianBankAccount? selectedAccount = _bankAccounts.first;
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Title
                  const Text(
                    'Withdraw Money',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Available: ₹${_formatAmount(wallet.availableBalance)}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Amount input
                  TextFormField(
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                    ],
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Amount',
                      prefixText: '₹ ',
                      prefixStyle: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6366F1),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter amount';
                      }
                      final amount = double.tryParse(value);
                      if (amount == null || amount <= 0) {
                        return 'Please enter valid amount';
                      }
                      if (amount < 100) {
                        return 'Minimum withdrawal is ₹100';
                      }
                      if (amount > wallet.availableBalance) {
                        return 'Insufficient balance';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  
                  // Quick amount chips
                  Wrap(
                    spacing: 8,
                    children: [
                      _buildQuickAmountChip(amountController, 500, wallet.availableBalance),
                      _buildQuickAmountChip(amountController, 1000, wallet.availableBalance),
                      _buildQuickAmountChip(amountController, 2500, wallet.availableBalance),
                      _buildQuickAmountChip(amountController, wallet.availableBalance.toDouble(), wallet.availableBalance),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  // Bank account selector
                  const Text(
                    'Withdraw to',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.account_balance,
                            color: AppTheme.primaryColor,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                selectedAccount?.bankName ?? 'Select account',
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                              Text(
                                '${selectedAccount?.accountHolderName} • ${selectedAccount?.maskedAccountNumber}',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_bankAccounts.length > 1)
                          IconButton(
                            icon: const Icon(Icons.keyboard_arrow_down),
                            onPressed: () {
                              // Show bank selection dialog
                              _showBankSelectionDialog(wallet, selectedAccount, (account) {
                                setModalState(() => selectedAccount = account);
                              });
                            },
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Withdraw button
                  ElevatedButton(
                    onPressed: _isWithdrawing ? null : () async {
                      if (formKey.currentState!.validate()) {
                        Navigator.pop(context);
                        await _processWithdrawal(
                          double.parse(amountController.text),
                          selectedAccount!.id,
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isWithdrawing
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(Colors.white),
                            ),
                          )
                        : const Text(
                            'Withdraw',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAmountChip(TextEditingController controller, double amount, double maxAmount) {
    final displayAmount = amount > maxAmount ? maxAmount : amount;
    return ActionChip(
      label: Text('₹${displayAmount.toStringAsFixed(0)}'),
      onPressed: () {
        controller.text = displayAmount.toStringAsFixed(0);
      },
      backgroundColor: Colors.grey.shade100,
      labelStyle: const TextStyle(fontWeight: FontWeight.w600),
    );
  }

  void _showBankSelectionDialog(TechnicianWallet wallet, TechnicianBankAccount? current, Function(TechnicianBankAccount) onSelect) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Bank Account'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: _bankAccounts.map((account) => ListTile(
            leading: const Icon(Icons.account_balance),
            title: Text(account.bankName),
            subtitle: Text('${account.accountHolderName} • ${account.maskedAccountNumber}'),
            trailing: account.id == current?.id ? const Icon(Icons.check, color: AppTheme.primaryColor) : null,
            onTap: () {
              onSelect(account);
              Navigator.pop(context);
            },
          )).toList(),
        ),
      ),
    );
  }

  Future<void> _processWithdrawal(double amount, String bankAccountId) async {
    if (_isWithdrawing) return;

    final safeAmount = max(0.0, amount);
    debugPrint('[WALLET] withdraw requested: ₹$safeAmount');
    
    try {
      setState(() => _isWithdrawing = true);
      
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryColor),
        ),
      );

      final result = await _walletService.requestWithdrawal(
        amount: safeAmount,
        bankAccountId: bankAccountId,
      );

      Navigator.pop(context); // Dismiss loading

      if (result.success) {
        _showSuccessDialog(result);
      } else {
        _showErrorDialog(result.message);
      }
    } catch (e) {
      Navigator.pop(context); // Dismiss loading
      _showErrorDialog(e.toString());
    } finally {
      if (mounted) {
        setState(() => _isWithdrawing = false);
      }
    }
  }

  void _showSuccessDialog(WithdrawalResult result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.successColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle,
                color: AppTheme.successColor,
                size: 48,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Withdrawal Requested!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              result.message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Done'),
            ),
          ],
        ),
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.errorColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                color: AppTheme.errorColor,
                size: 48,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Withdrawal Failed',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor),
              child: const Text('OK'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddBankDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddBankAccountScreen()),
    ).then((_) => _loadBankAccounts());
  }

  void _showReceiveQRSheet() {
    final tech = Provider.of<TechnicianProvider>(context, listen: false).technician;
    if (tech == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.qr_code_2,
                size: 48,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              tech.fullName,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Scan to pay via Razorpay',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.qr_code_scanner,
                    size: 120,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'QR Code will be generated here',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: 'razorpay://pay/${tech.uid}'));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Payment link copied')),
                      );
                    },
                    icon: const Icon(Icons.copy, size: 18),
                    label: const Text('Copy Link'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: AppTheme.primaryColor),
                      foregroundColor: AppTheme.primaryColor,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.share, size: 18),
                    label: const Text('Share'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.errorColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                size: 48,
                color: AppTheme.errorColor,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.errorColor),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadBankAccounts,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatAmount(double amount) {
    if (amount >= 10000000) {
      return '${(amount / 10000000).toStringAsFixed(2)}Cr';
    } else if (amount >= 100000) {
      return '${(amount / 100000).toStringAsFixed(2)}L';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(2)}K';
    }
    return amount.toStringAsFixed(2);
  }
}

/// Transaction History Screen - Full list with pagination
class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  final WalletService _walletService = WalletService();
  final List<WalletTransaction> _transactions = [];
  bool _isLoading = true;
  bool _hasMore = true;
  String? _lastDocId;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    try {
      if (!_hasMore && _lastDocId != null) return;
      
      setState(() => _isLoading = true);

      final result = await _walletService.getTransactionHistory(
        limit: 20,
        startAfter: _lastDocId,
      );

      setState(() {
        _transactions.addAll(result);
        _lastDocId = result.isNotEmpty ? result.last.txnId : null;
        _hasMore = result.length >= 20;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction History'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: _transactions.isEmpty && _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _transactions.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: () async {
                    setState(() {
                      _transactions.clear();
                      _lastDocId = null;
                      _hasMore = true;
                    });
                    await _loadTransactions();
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _transactions.length + (_hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _transactions.length) {
                        return _isLoading
                            ? const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(16),
                                  child: CircularProgressIndicator(),
                                ),
                              )
                            : TextButton(
                                onPressed: _loadTransactions,
                                child: const Text('Load More'),
                              );
                      }
                      return _buildTransactionCard(_transactions[index]);
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.receipt_long_outlined,
              size: 48,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No transactions yet',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your transaction history will appear here',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(WalletTransaction txn) {
    final isCredit = txn.type == TransactionType.credit || txn.type == TransactionType.release;
    final isPayout = txn.type == TransactionType.payout;
    
    Color iconColor = AppTheme.successColor;
    IconData icon = Icons.arrow_upward;
    String typeLabel = 'Credit';
    
    if (isPayout) {
      iconColor = AppTheme.warningColor;
      icon = Icons.arrow_downward;
      typeLabel = 'Withdrawal';
    } else if (!isCredit) {
      iconColor = AppTheme.errorColor;
      icon = Icons.arrow_downward;
      typeLabel = 'Debit';
    } else if (txn.source == TransactionSource.refund) {
      iconColor = AppTheme.infoColor;
      icon = Icons.replay;
      typeLabel = 'Refund';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  txn.description ?? typeLabel,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('MMM d, yyyy • h:mm a').format(txn.createdAt),
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                if (txn.referenceId != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Ref: ${txn.referenceId}',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isCredit ? '+' : '-'}₹${txn.amount.toStringAsFixed(2)}',
                style: TextStyle(
                  color: isCredit ? AppTheme.successColor : AppTheme.errorColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: txn.status == TransactionStatus.completed
                      ? AppTheme.successColor.withValues(alpha: 0.1)
                      : txn.status == TransactionStatus.failed
                          ? AppTheme.errorColor.withValues(alpha: 0.1)
                          : AppTheme.warningColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  txn.displayStatus,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: txn.status == TransactionStatus.completed
                        ? AppTheme.successColor
                        : txn.status == TransactionStatus.failed
                            ? AppTheme.errorColor
                            : AppTheme.warningColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

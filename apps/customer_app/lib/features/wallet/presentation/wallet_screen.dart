import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/wallet_service.dart';
import '../../../core/models/wallet_transaction.dart';

/// Premium Customer Wallet Screen
/// 
/// Features:
/// - Glass morphism wallet header card
/// - Real-time balance updates via StreamBuilder
/// - Transaction history with grouping by date
/// - Shimmer loading states
/// - Premium fintech-style UI
/// 
/// NO withdrawal - Customers cannot withdraw
/// NO Add Money - Per requirements
class CustomerWalletScreen extends StatefulWidget {
  const CustomerWalletScreen({super.key});

  @override
  State<CustomerWalletScreen> createState() => _CustomerWalletScreenState();
}

class _CustomerWalletScreenState extends State<CustomerWalletScreen> {
  final WalletService _walletService = WalletService();
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    return StreamBuilder<double>(
      stream: _walletService.watchBalance(),
      builder: (context, balanceSnapshot) {
        return StreamBuilder<List<WalletTransaction>>(
          stream: _walletService.watchTransactions(limit: 15),
          builder: (context, txnSnapshot) {
            if (balanceSnapshot.connectionState == ConnectionState.waiting) {
              return _buildShimmerLoading();
            }
            
            if (balanceSnapshot.hasError) {
              return _buildErrorWidget(balanceSnapshot.error?.toString() ?? 'Unknown error');
            }
            
            final balance = balanceSnapshot.data ?? 0.0;
            final transactions = txnSnapshot.data ?? [];
            
            return RefreshIndicator(
              onRefresh: () async {
                await _walletService.getBalance();
              },
              color: AppTheme.primaryColor,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Column(
                      children: [
                        _buildGlassHeader(balance),
                        const SizedBox(height: 24),
                        _buildHowItWorksSection(),
                        const SizedBox(height: 24),
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

  Widget _buildShimmerLoading() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Column(
          children: [
            const SizedBox(height: 16),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              height: 180,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: List.generate(2, (index) => Expanded(
                  child: Container(
                    height: 100,
                    margin: EdgeInsets.only(left: index == 0 ? 0 : 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                )),
              ),
            ),
            const SizedBox(height: 24),
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

  Widget _buildGlassHeader(double balance) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF10B981), Color(0xFF059669)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withValues(alpha: 0.4),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Wallet Balance',
                  style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.account_balance_wallet, color: Colors.white, size: 14),
                      SizedBox(width: 4),
                      Text('Active', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '₹${_formatAmount(balance)}',
              style: const TextStyle(color: Colors.white, fontSize: 42, fontWeight: FontWeight.bold, letterSpacing: -1.5),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.white70, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('Use wallet balance to pay for services', style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 13)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHowItWorksSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('How it works', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildHowItWorksCard(icon: Icons.card_giftcard, title: 'Earn', description: 'Get rewards & refunds', color: AppColors.success)),
              const SizedBox(width: 12),
              Expanded(child: _buildHowItWorksCard(icon: Icons.savings, title: 'Save', description: 'Use for payments', color: AppColors.primary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHowItWorksCard({required IconData icon, required String title, required String description, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 2),
          Text(description, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildTransactionHistory(List<WalletTransaction> transactions) {
    final groupedTransactions = _groupTransactionsByDate(transactions);
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Transaction History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              if (transactions.isNotEmpty)
                TextButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CustomerTransactionHistoryScreen())),
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
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      color: Colors.grey.shade50,
                      child: Text(item, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.grey[700])),
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
            decoration: BoxDecoration(color: AppTheme.primaryColor.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: const Icon(Icons.account_balance_wallet_outlined, size: 40, color: AppTheme.primaryColor),
          ),
          const SizedBox(height: 16),
          const Text('No transactions yet', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
          const SizedBox(height: 4),
          Text('Your wallet transactions will appear here', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildTransactionTile(WalletTransaction txn) {
    final isCredit = txn.type == 'credit';
    Color iconColor = AppColors.success;
    IconData icon = Icons.arrow_upward;
    
    if (!isCredit) {
      iconColor = AppColors.error;
      icon = Icons.arrow_downward;
    } else if (txn.reason == 'refund') {
      iconColor = AppColors.info;
      icon = Icons.replay;
    } else if (txn.reason == 'referral_reward') {
      iconColor = AppColors.warning;
      icon = Icons.card_giftcard;
    }

    return InkWell(
      onTap: () => _showTransactionDetails(txn),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_getTransactionTitle(txn), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(DateFormat('MMM d, h:mm a').format(txn.createdAt), style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                ],
              ),
            ),
            Text('${isCredit ? '+' : '-'}₹${_formatAmount(txn.amount)}', style: TextStyle(color: isCredit ? AppColors.success : AppColors.error, fontWeight: FontWeight.bold, fontSize: 15)),
          ],
        ),
      ),
    );
  }

  String _getTransactionTitle(WalletTransaction txn) {
    switch (txn.reason) {
      case 'referral_reward': return 'Referral Bonus';
      case 'refund': return 'Refund';
      case 'booking_payment': return 'Payment';
      case 'coupon': return 'Coupon Applied';
      case 'wallet_topup': return 'Wallet Top-up';
      default: return txn.type == 'credit' ? 'Credit' : 'Debit';
    }
  }

  void _showTransactionDetails(WalletTransaction txn) {
    final isCredit = txn.type == 'credit';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: (isCredit ? AppColors.success : AppColors.error).withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(isCredit ? Icons.arrow_upward : Icons.arrow_downward, color: isCredit ? AppColors.success : AppColors.error, size: 32),
            ),
            const SizedBox(height: 16),
            Text('${isCredit ? '+' : '-'}₹${_formatAmount(txn.amount)}', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: isCredit ? AppColors.success : AppColors.error)),
            const SizedBox(height: 8),
            Text(_getTransactionTitle(txn), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 24),
            _buildDetailRow('Transaction ID', txn.txnId.substring(0, 20)),
            _buildDetailRow('Type', isCredit ? 'Credit' : 'Debit'),
            _buildDetailRow('Reason', txn.reason),
            _buildDetailRow('Date', DateFormat('MMMM d, yyyy • h:mm a').format(txn.createdAt)),
            if (txn.relatedBookingId != null) _buildDetailRow('Booking ID', txn.relatedBookingId!),
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
          Flexible(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14), textAlign: TextAlign.end)),
        ],
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
              decoration: BoxDecoration(color: AppColors.error.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            ),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.error)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: () => setState(() {}), child: const Text('Retry')),
          ],
        ),
      ),
    );
  }

  String _formatAmount(double amount) {
    if (amount >= 10000000) return '${(amount / 10000000).toStringAsFixed(2)}Cr';
    if (amount >= 100000) return '${(amount / 100000).toStringAsFixed(2)}L';
    if (amount >= 1000) return '${(amount / 1000).toStringAsFixed(2)}K';
    return amount.toStringAsFixed(2);
  }
}

/// Transaction History Screen - Full list with pagination
class CustomerTransactionHistoryScreen extends StatefulWidget {
  const CustomerTransactionHistoryScreen({super.key});

  @override
  State<CustomerTransactionHistoryScreen> createState() => _CustomerTransactionHistoryScreenState();
}

class _CustomerTransactionHistoryScreenState extends State<CustomerTransactionHistoryScreen> {
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
      final result = await _walletService.getTransactionHistory(limit: 20, startAfter: _lastDocId);
      setState(() {
        _transactions.addAll(result);
        _lastDocId = result.isNotEmpty ? result.last.txnId : null;
        _hasMore = result.length >= 20;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Transaction History'), backgroundColor: AppTheme.primaryColor, foregroundColor: Colors.white),
      body: _transactions.isEmpty && _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _transactions.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: () async {
                    setState(() { _transactions.clear(); _lastDocId = null; _hasMore = true; });
                    await _loadTransactions();
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _transactions.length + (_hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _transactions.length) {
                        return _isLoading
                            ? const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()))
                            : TextButton(onPressed: _loadTransactions, child: const Text('Load More'));
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
          Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: AppTheme.primaryColor.withValues(alpha: 0.1), shape: BoxShape.circle), child: const Icon(Icons.receipt_long_outlined, size: 48, color: AppTheme.primaryColor)),
          const SizedBox(height: 16),
          const Text('No transactions yet', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18)),
          const SizedBox(height: 8),
          Text('Your transaction history will appear here', style: TextStyle(color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(WalletTransaction txn) {
    final isCredit = txn.type == 'credit';
    Color iconColor = AppColors.success;
    IconData icon = Icons.arrow_upward;
    
    if (!isCredit) {
      iconColor = AppColors.error;
      icon = Icons.arrow_downward;
    } else if (txn.reason == 'refund') {
      iconColor = AppColors.info;
      icon = Icons.replay;
    } else if (txn.reason == 'referral_reward') {
      iconColor = AppColors.warning;
      icon = Icons.card_giftcard;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(14)),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_getTransactionTitle(txn), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text(DateFormat('MMM d, yyyy • h:mm a').format(txn.createdAt), style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                if (txn.relatedBookingId != null) ...[const SizedBox(height: 4), Text('Ref: ${txn.relatedBookingId}', style: TextStyle(color: Colors.grey[500], fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis)],
              ],
            ),
          ),
          Text('${isCredit ? '+' : '-'}₹${txn.amount.toStringAsFixed(2)}', style: TextStyle(color: isCredit ? AppColors.success : AppColors.error, fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }

  String _getTransactionTitle(WalletTransaction txn) {
    switch (txn.reason) {
      case 'referral_reward': return 'Referral Bonus';
      case 'refund': return 'Refund';
      case 'booking_payment': return 'Service Payment';
      case 'coupon': return 'Coupon Applied';
      case 'wallet_topup': return 'Wallet Top-up';
      default: return txn.type == 'credit' ? 'Credit' : 'Payment';
    }
  }
}

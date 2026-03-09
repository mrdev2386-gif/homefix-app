import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/app_theme.dart';
import '../core/services/wallet_service.dart';
import '../core/models/wallet.dart';
import '../core/models/wallet_transaction.dart';
import '../core/models/bank_account.dart';
import '../core/providers/technician_provider.dart';
import 'add_bank_account_screen.dart';

/// Modern Premium Technician Wallet Screen
/// 
/// Features:
/// - Modern glassmorphism balance hero card
/// - Quick stats with animated counters
/// - Sleek action buttons with haptic feedback
/// - QR Code card for receiving payments
/// - Enhanced transaction history
/// - Real-time balance updates via StreamBuilder
/// - Ultra-modern fintech-style UI with animations
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

      // Fetch from technicians/{uid} document where bank details are stored
      final doc = await _firestore
          .collection('technicians')
          .doc(technicianId)
          .get();

      if (mounted) {
        setState(() {
          _bankAccounts = [];
          
          if (doc.exists) {
            final data = doc.data() as Map<String, dynamic>;
            final bankStatus = data['bankStatus'] ?? 'not_submitted';
            
            // Only add if bank details exist and status is not deleted
            if (bankStatus != 'not_submitted' && bankStatus != 'deleted') {
              final bankAccount = TechnicianBankAccount(
                id: technicianId,
                technicianId: technicianId,
                bankName: data['bankName'] ?? '',
                accountNumber: data['accountNumber'] ?? '',
                ifscCode: data['ifscCode'] ?? '',
                accountHolderName: data['accountHolderName'] ?? '',
                status: _parseBankStatus(bankStatus),
                createdAt: DateTime.now(),
              );
              _bankAccounts.add(bankAccount);
            }
          }
          
          _isLoadingBanks = false;
          print('[WALLET] bankAccounts length: ${_bankAccounts.length}');
          if (_bankAccounts.isNotEmpty) {
            print('[WALLET] bank status: ${_bankAccounts.first.status}');
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading bank accounts: $e');
      if (mounted) {
        setState(() => _isLoadingBanks = false);
      }
    }
  }

  BankAccountStatus _parseBankStatus(String status) {
    switch (status) {
      case 'pending':
        return BankAccountStatus.pending;
      case 'verified':
        return BankAccountStatus.verified;
      case 'rejected':
        return BankAccountStatus.rejected;
      default:
        return BankAccountStatus.pending;
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('[WALLET] screen built');
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
                        const SizedBox(height: 16),
                        // Step 1: Premium Balance Hero Card
                        _buildBalanceHero(wallet),
                        const SizedBox(height: 12),
                        // Step 3: Action Buttons Row
                        _buildActionButtonsRow(wallet),
                        const SizedBox(height: 12),
                        // Step 5: QR Code Card
                        _buildQRCard(),
                        const SizedBox(height: 20),
                        // Transaction History
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

  /// Step 1: Modern Glassmorphism Balance Hero Card
  Widget _buildBalanceHero(TechnicianWallet wallet) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF1A1A2E),  // Deep dark blue
            Color(0xFF16213E),  // Navy
            Color(0xFF0F3460),  // Dark blue
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A1A2E).withValues(alpha: 0.4),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.15),
            blurRadius: 40,
            spreadRadius: -10,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative gradient orbs
          Positioned(
            right: -40,
            top: -40,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppTheme.primaryColor.withValues(alpha: 0.3),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: -30,
            bottom: -30,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppTheme.accentColor.withValues(alpha: 0.2),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // Accent line at top
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 4,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryColor,
                    AppTheme.accentColor,
                    AppTheme.primaryColor.withValues(alpha: 0.5),
                  ],
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              ),
            ),
          ),
          // Main content
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with icon and KYC
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    // KYC Badge - modern pill design
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: wallet.isKycVerified 
                            ? AppTheme.successColor.withValues(alpha: 0.2)
                            : AppTheme.warningColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: wallet.isKycVerified 
                              ? AppTheme.successColor.withValues(alpha: 0.3)
                              : AppTheme.warningColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            wallet.isKycVerified ? Icons.verified_rounded : Icons.pending_rounded,
                            color: wallet.isKycVerified ? AppTheme.successColor : AppTheme.warningColor,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            wallet.isKycVerified ? 'Verified' : 'KYC Pending',
                            style: TextStyle(
                              color: wallet.isKycVerified ? AppTheme.successColor : AppTheme.warningColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Available Balance Label
                Text(
                  'Available Balance',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                // Balance Amount with animation
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: wallet.availableBalance.toDouble()),
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '₹',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 24,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          NumberFormat('#,##,###').format(value.toInt()),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 42,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -1.5,
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),
                // Modern Quick Stats Cards
                Row(
                  children: [
                    Expanded(
                      child: _ModernQuickStat(
                        label: 'Pending',
                        value: wallet.pendingBalance,
                        icon: Icons.schedule_rounded,
                        color: AppTheme.warningColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ModernQuickStat(
                        label: 'On Hold',
                        value: wallet.onHoldBalance,
                        icon: Icons.lock_clock_rounded,
                        color: AppTheme.infoColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ModernQuickStat(
                        label: 'Lifetime',
                        value: wallet.lifetimeEarnings,
                        icon: Icons.trending_up_rounded,
                        color: AppTheme.successColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Step 3: Modern Action Buttons Row
  Widget _buildActionButtonsRow(TechnicianWallet wallet) {
    final hasBalance = wallet.availableBalance > 0;
    final hasBankAccount = _bankAccounts.isNotEmpty;
    final bankAccount = hasBankAccount ? _bankAccounts.first : null;
    final isVerified = bankAccount?.status == BankAccountStatus.verified;
    final canWithdraw = hasBalance && wallet.canWithdraw && !_isWithdrawing && isVerified;
    
    // Determine bank button state
    String bankButtonLabel = 'Add Bank';
    VoidCallback? bankButtonAction = _showAddBankDialog;
    List<Color>? bankButtonGradient = const [Color(0xFF6366F1), Color(0xFF8B5CF6)];
    
    if (hasBankAccount) {
      if (bankAccount!.status == BankAccountStatus.verified) {
        bankButtonLabel = 'Manage Bank';
      } else if (bankAccount.status == BankAccountStatus.pending) {
        bankButtonLabel = 'Verification in Progress';
        bankButtonAction = null;
        bankButtonGradient = null;
      } else if (bankAccount.status == BankAccountStatus.rejected) {
        bankButtonLabel = 'Re-verify Bank';
      }
    }
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: _ModernActionButton(
              icon: Icons.add_circle_outline_rounded,
              label: bankButtonLabel,
              onTap: bankButtonAction,
              gradientColors: bankButtonGradient,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _ModernActionButton(
              icon: Icons.download_rounded,
              label: 'Withdraw',
              onTap: canWithdraw ? () => _showWithdrawBottomSheet(wallet) : null,
              gradientColors: canWithdraw 
                  ? const [Color(0xFF10B981), Color(0xFF059669)]
                  : null,
              isPrimary: true,
            ),
          ),
        ],
      ),
    );
  }

  /// Step 5: Modern QR Code Card - Premium Design
  Widget _buildQRCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _showReceiveQRSheet,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF10B981), Color(0xFF059669)],
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.qr_code_2_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Receive Payment',
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 17,
                                  color: const Color(0xFF1E293B),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Scan QR to receive money',
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: Color(0xFF10B981),
                          size: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.qr_code_scanner_rounded,
                            size: 32,
                            color: AppTheme.primaryColor.withValues(alpha: 0.7),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            'Show this QR code to receive payments from customers',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
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
            // Balance hero shimmer
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              height: 200,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            const SizedBox(height: 20),
            // Action buttons shimmer
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: List.generate(2, (index) => Expanded(
                  child: Container(
                    height: 52,
                    margin: EdgeInsets.only(left: index == 0 ? 0 : 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                )),
              ),
            ),
            const SizedBox(height: 20),
            // QR card shimmer
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              height: 180,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
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



  /// Transaction history with grouping by date - Modern Design
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
              Text(
                'Transaction History',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E293B),
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
                  child: Text(
                    'View All',
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          if (transactions.isEmpty)
            _buildEmptyTransactionsState()
          else
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
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
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                      color: const Color(0xFFF8FAFC),
                      child: Text(
                        item,
                        style: GoogleFonts.plusJakartaSans(
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
      padding: const EdgeInsets.all(36),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.receipt_long_outlined,
              size: 44,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'No transactions yet',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w600,
              fontSize: 17,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Your transaction history will appear here',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
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
    IconData icon = Icons.arrow_upward_rounded;
    String typeLabel = 'Credit';
    
    if (isPayout) {
      iconColor = AppTheme.warningColor;
      icon = Icons.arrow_downward_rounded;
      typeLabel = 'Withdrawal';
    } else if (!isCredit) {
      iconColor = AppTheme.errorColor;
      icon = Icons.arrow_downward_rounded;
      typeLabel = 'Debit';
    } else if (txn.source == TransactionSource.refund) {
      iconColor = AppTheme.infoColor;
      icon = Icons.replay_rounded;
      typeLabel = 'Refund';
    }

    return InkWell(
      onTap: () => _showTransactionDetails(txn),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    txn.description ?? typeLabel,
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: const Color(0xFF1E293B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
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
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${isCredit || txn.type == TransactionType.release ? '+' : '-'}₹${_formatAmount(txn.amount)}',
                    style: GoogleFonts.plusJakartaSans(
                      color: (isCredit || txn.type == TransactionType.release) 
                          ? AppTheme.successColor 
                          : AppTheme.errorColor,
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
                            : AppTheme.warningColor,
                      ),
                    ),
                  ),
                ],
              ),
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

    final bankAccount = _bankAccounts.first;
    if (bankAccount.status != BankAccountStatus.verified) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Bank account must be verified to withdraw'),
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
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.all(28),
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
            const SizedBox(height: 28),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.qr_code_2_rounded,
                size: 56,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              tech.fullName,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Scan to pay via Razorpay',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 28),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.qr_code_scanner_rounded,
                    size: 140,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'QR Code will be generated here',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
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
                    icon: const Icon(Icons.copy_rounded, size: 20),
                    label: const Text('Copy Link'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: AppTheme.primaryColor),
                      foregroundColor: AppTheme.primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.share_rounded, size: 20),
                    label: const Text('Share'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
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

// ============ MODERN HELPER WIDGETS ============

/// Modern Quick Stat widget for wallet balance breakdown
class _ModernQuickStat extends StatelessWidget {
  final String label;
  final double value;
  final IconData icon;
  final Color color;

  const _ModernQuickStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white, size: 16),
          ),
          const SizedBox(height: 8),
          Text(
            '₹${_formatCompactAmount(value)}',
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _formatCompactAmount(double amount) {
    if (amount >= 100000) {
      return '${(amount / 100000).toStringAsFixed(1)}L';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K';
    }
    return amount.toStringAsFixed(0);
  }
}

// ============ MODERN ACTION BUTTON ============

/// Modern action button widget for wallet actions
class _ModernActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final List<Color>? gradientColors;
  final bool isPrimary;

  const _ModernActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.gradientColors,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDisabled = onTap == null;
    final hasGradient = gradientColors != null && !isDisabled;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 60,
          decoration: BoxDecoration(
            gradient: hasGradient
                ? LinearGradient(
                    colors: gradientColors!,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isDisabled
                ? Colors.grey[100]
                : isPrimary
                    ? null
                    : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: isPrimary || hasGradient
                ? null
                : Border.all(
                    color: isDisabled ? Colors.grey[200]! : const Color(0xFFE2E8F0),
                  ),
            boxShadow: hasGradient || (isPrimary && !isDisabled)
                ? [
                    BoxShadow(
                      color: (gradientColors?.first ?? AppTheme.primaryColor).withValues(alpha: 0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                    ),
                  ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (hasGradient || isPrimary)
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    size: 18,
                    color: Colors.white,
                  ),
                )
              else
                Icon(
                  icon,
                  size: 20,
                  color: isDisabled ? Colors.grey[400] : const Color(0xFF64748B),
                ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  label,
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: isDisabled
                        ? Colors.grey[400]
                        : isPrimary || hasGradient
                            ? Colors.white
                            : const Color(0xFF1E293B),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
        title: Text(
          'Transaction History',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
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
    IconData icon = Icons.arrow_upward_rounded;
    String typeLabel = 'Credit';
    
    if (isPayout) {
      iconColor = AppTheme.warningColor;
      icon = Icons.arrow_downward_rounded;
      typeLabel = 'Withdrawal';
    } else if (!isCredit) {
      iconColor = AppTheme.errorColor;
      icon = Icons.arrow_downward_rounded;
      typeLabel = 'Debit';
    } else if (txn.source == TransactionSource.refund) {
      iconColor = AppTheme.infoColor;
      icon = Icons.replay_rounded;
      typeLabel = 'Refund';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  txn.description ?? typeLabel,
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: const Color(0xFF1E293B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  DateFormat('MMM d, yyyy • h:mm a').format(txn.createdAt),
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 13,
                  ),
                ),
                if (txn.referenceId != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Ref: ${txn.referenceId}',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${isCredit ? '+' : '-'}₹${txn.amount.toStringAsFixed(2)}',
                  style: GoogleFonts.plusJakartaSans(
                    color: isCredit ? AppTheme.successColor : AppTheme.errorColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: txn.status == TransactionStatus.completed
                        ? AppTheme.successColor.withValues(alpha: 0.1)
                        : txn.status == TransactionStatus.failed
                            ? AppTheme.errorColor.withValues(alpha: 0.1)
                            : AppTheme.warningColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    txn.displayStatus,
                    style: TextStyle(
                      fontSize: 12,
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
          ),
        ],
      ),
    );
  }
}

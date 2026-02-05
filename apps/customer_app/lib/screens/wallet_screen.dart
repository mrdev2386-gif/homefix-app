import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../core/app_theme.dart';
import '../core/models/wallet_transaction.dart';
import '../core/providers/auth_provider.dart';
import 'package:intl/intl.dart';

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.customer;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("My Wallet", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
      ),
      body: user == null ? const Center(child: CircularProgressIndicator()) : Column(
        children: [
          _buildBalanceCard(user.walletBalance),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Text("Transaction History", style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: StreamBuilder<List<WalletTransaction>>(
              stream: authProvider.walletTransactions,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final txns = snapshot.data ?? [];
                if (txns.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.account_balance_wallet_outlined, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text("No transactions yet", style: GoogleFonts.outfit(color: Colors.grey)),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: txns.length,
                  itemBuilder: (context, index) => _buildTransactionItem(txns[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceCard(double balance) {
    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryColor, AppTheme.accentColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Text("AVAILABLE BALANCE", style: GoogleFonts.outfit(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          const SizedBox(height: 8),
          Text("₹${balance.toStringAsFixed(0)}", style: GoogleFonts.outfit(color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
            child: Text("HomeFix Credits", style: GoogleFonts.outfit(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(WalletTransaction txn) {
    final isCredit = txn.type == 'credit';
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isCredit ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isCredit ? Icons.add_circle_outline : Icons.remove_circle_outline,
              color: isCredit ? Colors.green : Colors.red,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  txn.reason.replaceAll('_', ' ').toUpperCase(),
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                Text(
                  DateFormat('dd MMM yyyy, hh:mm a').format(txn.createdAt),
                  style: GoogleFonts.outfit(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            "${isCredit ? '+' : '-'}₹${txn.amount.toStringAsFixed(0)}",
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: isCredit ? Colors.green : Colors.red,
            ),
          ),
        ],
      ),
    );
  }
}

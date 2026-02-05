import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/providers/technician_provider.dart';
import '../../../core/firestore/wallet_service.dart';
import '../../../core/models/wallet.dart';
import '../../../core/models/earning.dart';
import '../../../core/models/payout.dart';

class EarningsScreen extends StatefulWidget {
  const EarningsScreen({super.key});

  @override
  State<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends State<EarningsScreen> with SingleTickerProviderStateMixin {
  final WalletService _walletService = WalletService();
  late TabController _tabController;
  final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TechnicianProvider>(context);
    final tech = provider.technician;

    if (tech == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text("Wallet & Earnings", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: StreamBuilder<TechnicianWallet>(
        stream: _walletService.getWallet(tech.uid),
        builder: (context, walletSnap) {
          final wallet = walletSnap.data ?? TechnicianWallet(
            availableBalance: 0,
            pendingBalance: 0,
            lifetimeEarnings: 0,
            updatedAt: DateTime.now(),
          );

          return Column(
            children: [
              _buildWalletHeader(wallet),
              const SizedBox(height: 16),
              _buildTabBar(),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildEarningsList(tech.uid),
                    _buildPayoutsList(tech.uid),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildWalletHeader(TechnicianWallet wallet) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Available Balance",
                    style: GoogleFonts.outfit(color: Colors.white.withOpacity(0.8), fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    currencyFormat.format(wallet.availableBalance),
                    style: GoogleFonts.outfit(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 40),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              _buildSmallStat("Pending", currencyFormat.format(wallet.pendingBalance)),
              const SizedBox(width: 24),
              _buildSmallStat("Lifetime", currencyFormat.format(wallet.lifetimeEarnings)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSmallStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.outfit(color: Colors.white.withOpacity(0.7), fontSize: 12)),
        const SizedBox(height: 2),
        Text(value, style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        indicatorColor: const Color(0xFF6366F1),
        labelColor: const Color(0xFF6366F1),
        unselectedLabelColor: Colors.grey,
        indicatorSize: TabBarIndicatorSize.tab,
        labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        tabs: const [
          Tab(text: "Earnings"),
          Tab(text: "Payouts"),
        ],
      ),
    );
  }

  Widget _buildEarningsList(String techId) {
    return StreamBuilder<List<TechnicianEarning>>(
      stream: _walletService.getEarnings(techId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final earnings = snapshot.data ?? [];
        if (earnings.isEmpty) {
          return _buildEmptyState("No earnings yet", Icons.insights_rounded);
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: earnings.length,
          itemBuilder: (context, index) {
            final earning = earnings[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.add_task_rounded, color: Color(0xFF10B981), size: 20),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Booking #${earning.bookingId.slice(0, 8)}", 
                          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15)),
                        Text(DateFormat('dd MMM, yyyy').format(earning.createdAt), 
                          style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "+${currencyFormat.format(earning.technicianAmount)}",
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: const Color(0xFF10B981)),
                      ),
                      Text(
                        earning.status.toUpperCase(),
                        style: GoogleFonts.outfit(
                          fontSize: 10, 
                          fontWeight: FontWeight.bold,
                          color: earning.status == 'paid' ? Colors.green : Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPayoutsList(String techId) {
    return StreamBuilder<List<TechnicianPayout>>(
      stream: _walletService.getPayouts(techId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final payouts = snapshot.data ?? [];
        if (payouts.isEmpty) {
          return _buildEmptyState("No payouts yet", Icons.account_balance_rounded);
        }

        return ListView.builder(
          padding: const EdgeInsets.all(10),
          itemCount: payouts.length,
          itemBuilder: (context, index) {
            final payout = payouts[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _getPayoutColor(payout.status).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(_getPayoutIcon(payout.status), color: _getPayoutColor(payout.status), size: 20),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Bank Withdrawal", 
                          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15)),
                        Text(DateFormat('dd MMM, HH:mm').format(payout.createdAt), 
                          style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "-${currencyFormat.format(payout.amount)}",
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.red),
                      ),
                      Text(
                        payout.status.toUpperCase(),
                        style: GoogleFonts.outfit(
                          fontSize: 10, 
                          fontWeight: FontWeight.bold,
                          color: _getPayoutColor(payout.status),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text(message, style: GoogleFonts.outfit(color: Colors.grey, fontSize: 16)),
        ],
      ),
    );
  }

  Color _getPayoutColor(String status) {
    switch (status) {
      case 'processed':
      case 'success':
        return Colors.green;
      case 'failed':
      case 'reversed':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  IconData _getPayoutIcon(String status) {
    switch (status) {
      case 'processed':
      case 'success':
        return Icons.check_circle_rounded;
      case 'failed':
      case 'reversed':
        return Icons.error_rounded;
      default:
        return Icons.pending_rounded;
    }
  }
}

extension StringExtension on String {
  String slice(int start, int end) {
    if (this.length <= end) return this;
    return this.substring(start, end);
  }
}

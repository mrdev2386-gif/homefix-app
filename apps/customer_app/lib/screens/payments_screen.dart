import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../core/app_theme.dart';
import '../core/models/payment_method.dart';
import '../core/providers/auth_provider.dart';

class PaymentsScreen extends StatelessWidget {
  const PaymentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Payment Methods", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
      ),
      body: StreamBuilder<List<PaymentMethod>>(
        stream: authProvider.paymentMethods,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final methods = snapshot.data ?? [];
          if (methods.isEmpty) {
            return _buildEmptyState();
          }
          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: methods.length,
            itemBuilder: (context, index) {
              final method = methods[index];
              return _buildPaymentCard(authProvider, method);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddPaymentDialog(context, authProvider),
        label: const Text("Add UPI"),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.payment_rounded, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text("No payment methods saved", style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildPaymentCard(AuthProvider auth, PaymentMethod method) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.account_balance_wallet, color: AppTheme.primaryColor),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(method.label, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
                Text(method.upiId ?? "****", style: GoogleFonts.outfit(color: Colors.grey, fontSize: 13)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: () => auth.deletePaymentMethod(method.id),
          ),
        ],
      ),
    );
  }

  void _showAddPaymentDialog(BuildContext context, AuthProvider auth) {
    final labelController = TextEditingController();
    final upiController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Add UPI ID", style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(controller: labelController, decoration: const InputDecoration(hintText: "Label (Personal/Business)")),
            const SizedBox(height: 12),
            TextField(controller: upiController, decoration: const InputDecoration(hintText: "UPI ID (example@upi)")),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                final method = PaymentMethod(
                  id: '',
                  type: 'upi',
                  label: labelController.text,
                  upiId: upiController.text,
                  holderName: auth.customer?.name ?? 'User',
                  createdAt: DateTime.now(),
                );
                auth.addPaymentMethod(method);
                Navigator.pop(context);
              },
              child: const Text("Save Payment Method"),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

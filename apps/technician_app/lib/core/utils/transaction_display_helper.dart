import 'package:flutter/material.dart';
import '../models/wallet_transaction.dart';
import '../app_theme.dart';

/// Helper class to determine transaction display properties
/// Consolidates duplicate logic from wallet_screen.dart
class TransactionDisplayHelper {
  /// Get display properties for a transaction (icon, color, label)
  static ({Color color, IconData icon, String label}) getDisplay(WalletTransaction txn) {
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

    return (color: iconColor, icon: icon, label: typeLabel);
  }

  /// Check if transaction is a credit (money in)
  static bool isCredit(WalletTransaction txn) {
    return txn.type == TransactionType.credit || txn.type == TransactionType.release;
  }

  /// Get sign prefix for amount display
  static String getAmountSign(WalletTransaction txn) {
    return isCredit(txn) ? '+' : '-';
  }
}

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
import '../core/utils/app_logger.dart';
import '../features/profile/presentation/technician_profile_screen.dart';

/// Modern Premium Technician Wallet Screen
/// 
/// FIXES APPLIED:
/// 1. Removed duplicate "Add Bank Account" section from wallet
/// 2. Bank management redirects to Profile Screen → Bank & Payout Section
/// 3. Correct bank account fetching from technician_bank_accounts collection
/// 4. Real-time bank account status display (pending/verified)
/// 5. Withdraw button only enabled when bank is verified
/// 6. Razorpay verification replaces admin approval
class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final WalletService _walletService = WalletService();
  bool _isWithdrawing = false;
  
  @override
  void initState() {
    super.initState();
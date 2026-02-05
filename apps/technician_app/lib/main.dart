import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:provider/provider.dart';
import 'core/providers/technician_provider.dart';
import 'core/app_theme.dart';
import 'core/services/notifications_service.dart';
import 'screens/login_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/block_screen.dart';
import 'features/kyc/presentation/kyc_status_screen.dart';
import 'firebase_options.dart';

import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_performance/firebase_performance.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint("Background message: ${message.notification?.title}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  // 1. Initialize App Check (Critical Security)
  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.playIntegrity,
  );

  // 2. Initialize Crashlytics & Performance
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  await FirebasePerformance.instance.setPerformanceCollectionEnabled(true);

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  
  // Initialize Push Notifications
  await NotificationsService.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TechnicianProvider()),
      ],
      child: const TechnicianApp(),
    ),
  );
}

class TechnicianApp extends StatelessWidget {
  const TechnicianApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'HomeFix Technician',
      theme: AppTheme.lightTheme,
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (snapshot.hasData) {
          return Consumer<TechnicianProvider>(
            builder: (context, provider, _) {
              if (provider.userRole == null) {
                return const Scaffold(body: Center(child: CircularProgressIndicator()));
              }

              if (provider.userRole != 'technician' && provider.userRole != 'admin') {
                return const BlockScreen();
              }

              if (provider.technician == null) {
                return const OnboardingScreen();
              }
              
              if (provider.technician!.kycStatus != 'approved') {
                 return const KycStatusScreen();
              }

              return const DashboardScreen();
            },
          );
        }

        return const LoginScreen();
      },
    );
  }
}

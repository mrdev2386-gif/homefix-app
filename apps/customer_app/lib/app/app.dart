import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../screens/login_screen.dart';
import '../screens/dashboard_screen.dart';
import 'routes.dart';

class CustomerApp extends StatelessWidget {
  final bool isLoggedIn;
  const CustomerApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    debugPrint("CUSTOMERAPP BUILD CALLED ✅ (isLoggedIn: $isLoggedIn)");
    
    return MaterialApp(
      title: 'HomeFix Customer',
      theme: AppTheme.lightTheme,
      home: isLoggedIn ? const DashboardScreen() : const LoginScreen(),
      routes: AppRoutes.routes,
      debugShowCheckedModeBanner: false,
      builder: (context, widget) {
        ErrorWidget.builder = (FlutterErrorDetails details) {
          return Scaffold(
            backgroundColor: Colors.red.shade900,
            body: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: SelectableText(
                  'CRITICAL ERROR DETECTED:\n\n${details.exception}',
                  style: const TextStyle(color: Colors.white, fontFamily: 'monospace'),
                ),
              ),
            ),
          );
        };
        return widget!;
      },
    );
  }
}

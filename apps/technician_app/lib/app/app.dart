import 'package:flutter/material.dart';
import 'routes.dart';
import 'theme.dart';

class TechnicianApp extends StatelessWidget {
  const TechnicianApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HomeFix Technician',
      theme: AppTheme.lightTheme,
      initialRoute: AppRoutes.login,
      routes: AppRoutes.routes,
      debugShowCheckedModeBanner: false,
    );
  }
}

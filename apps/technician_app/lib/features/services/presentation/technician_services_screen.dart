import 'package:flutter/material.dart';
import '../../technician/services/services_screen.dart';

/// Technician Services Screen - redirects to ServicesScreen
/// 
/// This is a redirect entry point for the services feature.
/// The actual implementation is in services_screen.dart
class TechnicianServicesScreen extends StatelessWidget {
  const TechnicianServicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ServicesScreen();
  }
}

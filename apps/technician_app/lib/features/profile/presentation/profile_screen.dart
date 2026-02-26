import 'package:flutter/material.dart';
import 'technician_profile_screen.dart';

/// Profile Screen - redirects to TechnicianProfileScreen
/// 
/// This is a redirect entry point for the profile feature.
/// The actual implementation is in technician_profile_screen.dart
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const TechnicianProfileScreen();
  }
}

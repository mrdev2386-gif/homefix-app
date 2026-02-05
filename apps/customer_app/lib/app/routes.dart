import 'package:flutter/material.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/bookings/presentation/booking_history_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/settings/settings_screen.dart';

class AppRoutes {
  static const String login = '/login';
  static const String otp = '/otp';
  static const String home = '/home';
  static const String bookings = '/bookings';
  static const String profile = '/profile';
  static const String settings = '/settings';
  static const String booking_history = '/booking_history';

  static Map<String, WidgetBuilder> routes = {
    login: (context) => const LoginScreen(),
    home: (context) => const DashboardScreen(),
    bookings: (context) => const BookingHistoryScreen(),
    profile: (context) => const ProfileScreen(),
    settings: (context) => const SettingsScreen(),
    booking_history: (context) => const BookingHistoryScreen(),
  };
}

import 'package:flutter/material.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/dashboard/presentation/dashboard_screen.dart';
import '../features/job_requests/presentation/job_requests_screen.dart';
import '../features/job_details/presentation/job_detail_screen.dart';
import '../features/earnings/presentation/earnings_screen.dart';
import '../features/profile/presentation/profile_screen.dart';

class AppRoutes {
  static const String login = '/login';
  static const String dashboard = '/dashboard';
  static const String jobRequests = '/job_requests';
  static const String jobDetail = '/job_detail';
  static const String earnings = '/earnings';
  static const String profile = '/profile';

  static Map<String, WidgetBuilder> routes = {
    login: (context) => const LoginScreen(),
    dashboard: (context) => const DashboardScreen(),
    jobRequests: (context) => const JobRequestsScreen(),
    jobDetail: (context) => const JobDetailScreen(),
    earnings: (context) => const EarningsScreen(),
    profile: (context) => const ProfileScreen(),
  };
}

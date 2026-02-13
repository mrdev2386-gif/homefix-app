import 'package:flutter/material.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/dashboard/presentation/dashboard_screen.dart';
import '../features/job_requests/presentation/job_requests_screen.dart';
import '../features/job_details/presentation/job_detail_screen.dart';
import '../features/earnings/presentation/earnings_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/custom_requests/presentation/custom_request_inbox_screen.dart';
import '../features/custom_requests/presentation/custom_request_detail_screen.dart';

class AppRoutes {
  static const String login = '/login';
  static const String dashboard = '/dashboard';
  static const String jobRequests = '/job_requests';
  static const String jobDetail = '/job_detail';
  static const String earnings = '/earnings';
  static const String profile = '/profile';
  static const String customRequestInbox = '/custom_request_inbox';
  static const String customRequestDetail = '/custom_request_detail';

  static Map<String, WidgetBuilder> routes = {
    login: (context) => const LoginScreen(),
    dashboard: (context) => const DashboardScreen(),
    jobRequests: (context) => const JobRequestsScreen(),
    jobDetail: (context) => const JobDetailScreen(),
    earnings: (context) => const EarningsScreen(),
    profile: (context) => const ProfileScreen(),
    customRequestInbox: (context) => const CustomRequestInboxScreen(),
  };

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    if (settings.name == customRequestDetail) {
      final requestId = settings.arguments as String?;
      return MaterialPageRoute(
        builder: (context) => CustomRequestDetailScreen(requestId: requestId ?? ''),
      );
    }
    return MaterialPageRoute(builder: (context) => const DashboardScreen());
  }
}

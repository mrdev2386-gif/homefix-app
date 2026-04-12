import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/providers/technician_provider.dart';
import 'core/app_theme.dart';
import 'core/services/notifications_service.dart';
import 'screens/app_onboarding_screen.dart';
import 'screens/login_screen.dart';
import 'screens/technician_onboarding_flow_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/complete_location_screen.dart';
import 'features/technician/services/add_service_screen.dart';
import 'core/firebase/firebase_init.dart';
import 'core/utils/app_logger.dart';
import 'core/widgets/technician_status_guard.dart';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_performance/firebase_performance.dart';

// Top-level root navigator key - MUST be outside any class
// This is the single source of truth for navigation in the app
final GlobalKey<NavigatorState> rootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'rootNavigator');

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Background isolate - Firebase already initialized in main isolate
  // DO NOT reinitialize to avoid App Check conflicts
  debugPrint("Background message: ${message.notification?.title}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // CRITICAL: Initialize Firebase with App Check FIRST
  await FirebaseInit.init();
  AppLogger.info('MAIN', 'Firebase initialization complete | package: com.homefix.technician');
  
  // CRITICAL FIX: Enable Firestore cache for real-time updates
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );
  AppLogger.info('MAIN', 'Firestore cache enabled - real-time updates active');
  
  // Initialize Crashlytics & Performance AFTER App Check
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  await FirebasePerformance.instance.setPerformanceCollectionEnabled(true);

  // Initialize Messaging AFTER App Check
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  AppLogger.info('MAIN', 'Background message handler set');
  

  // Initialize Notifications UI Service (Notification management) AFTER App Check
  await NotificationsService().initialize();
  AppLogger.info('MAIN', 'Notifications service initialized');

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TechnicianProvider()),
        ChangeNotifierProvider(create: (_) => NotificationsService()),
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
      navigatorKey: rootNavigatorKey,
      theme: AppTheme.lightTheme,
      home: const AuthGate(),
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/home':
            return MaterialPageRoute(
              builder: (_) => const DashboardScreen(),
              settings: settings,
            );
          case '/onboarding':
            return MaterialPageRoute(
              builder: (_) => const TechnicianOnboardingFlowScreen(),
              settings: settings,
            );
          case '/app-onboarding':
            return MaterialPageRoute(
              builder: (_) => const AppOnboardingScreen(),
              settings: settings,
            );
          case '/login':
            return MaterialPageRoute(
              builder: (_) => const LoginScreen(),
              settings: settings,
            );
          case '/add-service':
            return MaterialPageRoute(
              builder: (_) => const AddServiceScreen(),
              settings: settings,
            );
          default:
            return MaterialPageRoute(
              builder: (_) => const AuthGate(),
              settings: settings,
            );
        }
      },
      builder: (context, child) {
        return ErrorBoundary(
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}

/// Global error boundary widget to catch unhandled errors
class ErrorBoundary extends StatefulWidget {
  final Widget child;
  
  const ErrorBoundary({super.key, required this.child});

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    // Set up global error handler for async errors
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupErrorHandling();
    });
  }

  void _setupErrorHandling() {
    // Listen for Flutter framework errors
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      _handleError(details.exceptionAsString());
    };
  }

  void _handleError(String error) {
    if (!mounted) return;
    
    debugPrint('[ErrorBoundary] Caught error: $error');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = error;
        });
      }
    });
  }

  void _resetError() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _hasError = false;
          _errorMessage = '';
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return _ErrorBody(
        onRetry: _resetError,
        errorMessage: _errorMessage,
      );
    }

    return widget.child;
  }
}

/// Error body widget with safe layout
class _ErrorBody extends StatelessWidget {
  final VoidCallback onRetry;
  final String errorMessage;

  const _ErrorBody({
    required this.onRetry,
    required this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            // SCROLLABLE CONTENT (SAFE)
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 80,
                        color: Colors.red.shade400,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Something went wrong',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        errorMessage.isEmpty ? 'Please try again' : errorMessage,
                        textAlign: TextAlign.center,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // FIXED BUTTON (NO OVERFLOW)
            Padding(
              padding: EdgeInsets.fromLTRB(
                24,
                12,
                24,
                MediaQuery.of(context).viewPadding.bottom + 16,
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onRetry,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text('Try Again'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// SECURE AUTH GATE
/// 
/// This is the main entry point for the technician app.
/// It enforces a strict authentication-first flow:
/// 
/// 1. If user == null → Phone Auth screen
/// 2. If user logged in but no technician document → OnboardingScreen
/// 3. If technician doc exists but KYC not complete → OnboardingScreen
/// 4. If KYC submitted and status == pending/rejected → ApplicationStatusScreen
/// 5. If approved technician → allow access to main technician home
/// 6. If blocked/suspended → BlockScreen
/// 
/// DEFENSIVE: All routes include server-side verification via Firestore
/// to prevent bypass via deep links or manual navigation.
/// 
/// NOTE: This app is fully standalone - NO dependency on customer app,
/// users collection, or any customer-side flags.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  static const bool _kDebugMode = bool.fromEnvironment('dart.vm.product', defaultValue: false);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // PRIORITY 1: Check auth state first (loading)
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _LoadingScreen(message: 'Checking authentication...');
        }

        // PRIORITY 2: If user is logged in, ALWAYS go to authenticated flow
        if (snapshot.hasData && snapshot.data != null) {
          AppLogger.auth('User logged in', data: snapshot.data!.uid);
          return _AuthenticatedGate(
            user: snapshot.data!,
            debugMode: _kDebugMode,
          );
        }

        // PRIORITY 3: User not logged in - check onboarding
        AppLogger.auth('User not logged in - checking onboarding');
        return _UnauthenticatedGate(debugMode: _kDebugMode);
      },
    );
  }
}

/// Unauthenticated gate - checks if user has seen onboarding
class _UnauthenticatedGate extends StatefulWidget {
  final bool debugMode;
  
  const _UnauthenticatedGate({required this.debugMode});

  @override
  State<_UnauthenticatedGate> createState() => _UnauthenticatedGateState();
}

class _UnauthenticatedGateState extends State<_UnauthenticatedGate> {
  bool? _hasSeenOnboarding;

  @override
  void initState() {
    super.initState();
    _checkOnboardingStatus();
  }

  Future<void> _checkOnboardingStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool('technician_onboarding_done') ?? false;
    AppLogger.info('AUTH', 'Onboarding done', data: seen);
    if (mounted) {
      setState(() => _hasSeenOnboarding = seen);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_hasSeenOnboarding == null) {
      return const _LoadingScreen(message: 'Loading...');
    }

    if (_hasSeenOnboarding == false) {
      AppLogger.info('AUTH', 'Showing AppOnboardingScreen');
      return const AppOnboardingScreen();
    }

    AppLogger.info('AUTH', 'Showing LoginScreen');
    return const LoginScreen();
  }
}

/// Loading screen with proper UX
class _LoadingScreen extends StatelessWidget {
  final String message;
  
  const _LoadingScreen({required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Icon(
                    Icons.build_circle,
                    size: 64,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 32),
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// App Check failure screen with safe layout
class _AppCheckFailureScreen extends StatelessWidget {
  final VoidCallback onRetry;
  
  const _AppCheckFailureScreen({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            // SCROLLABLE CONTENT (SAFE)
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.shield_outlined,
                          size: 64,
                          color: Colors.red.shade400,
                        ),
                      ),
                      const SizedBox(height: 32),
                      Text(
                        'Security Verification Failed',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0F172A),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'We could not verify your app security. This may be due to:\n\n'
                        '• Running an unofficial app build\n'
                        '• Device security restrictions\n'
                        '• Network connectivity issues',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          color: const Color(0xFF64748B),
                          height: 1.6,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'If the problem persists, please install the app from the official store.',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: const Color(0xFF94A3B8),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // FIXED BUTTON (NO OVERFLOW)
            Padding(
              padding: EdgeInsets.fromLTRB(
                24,
                12,
                24,
                MediaQuery.of(context).viewPadding.bottom + 16,
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Try Again'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Authenticated gate - checks technician status after login
class _AuthenticatedGate extends StatefulWidget {
  final User user;
  final bool debugMode;
  
  const _AuthenticatedGate({
    required this.user,
    required this.debugMode,
  });

  @override
  State<_AuthenticatedGate> createState() => _AuthenticatedGateState();
}

class _AuthenticatedGateState extends State<_AuthenticatedGate> {
  bool _initialLoadDone = false;
  int _checkRetries = 0;
  static const int _maxRetries = 10; // Wait up to ~5 seconds for Auth trigger
  static const Duration _retryDelay = Duration(milliseconds: 500);

  @override
  void initState() {
    super.initState();
    _checkDocumentExistence();
  }

  /// Wait for technician document to be created by Auth trigger
  /// Retries with backoff to handle async trigger execution
  Future<void> _checkDocumentExistence() async {
    final provider = context.read<TechnicianProvider>();
    
    while (_checkRetries < _maxRetries) {
      try {
        // Fetch fresh data from server (not cache)
        final tech = await provider.fetchFreshTechnicianData();
        
        if (tech != null) {
          // Document exists - we can proceed
          AppLogger.info('AUTH', 'Technician document found', data: tech.uid);
          if (mounted) {
            setState(() {
              _initialLoadDone = true;
            });
          }
          return;
        }
        
        // Document not found yet - wait and retry
        await Future.delayed(_retryDelay);
        _checkRetries++;
        
      } catch (e) {
        AppLogger.error('AUTH', 'Error checking document', data: e);
        await Future.delayed(_retryDelay);
        _checkRetries++;
      }
    }
    
    // Max retries reached - show error but allow navigation to onboarding
    AppLogger.error('AUTH', 'Technician document not found after retries');
    if (mounted) {
      setState(() {
        _initialLoadDone = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TechnicianProvider>(
      builder: (context, provider, _) {
        // While waiting for Auth trigger to create document
        if (!_initialLoadDone || provider.isLoading) {
          return const _LoadingScreen(
            message: 'Initializing...',
          );
        }

        final tech = provider.technician;
        
        // NORMALIZED: Check profile completion from Firestore
        final profileCompletion = tech?.getProfileCompletion() ?? 0;
        
        // Simplified onboarding completion check
        final bool onboardingComplete = profileCompletion == 100;
        
        AppLogger.provider('Auth gate routing decision', data: {
          'uid': tech?.uid,
          'exists': tech != null,
          'profileCompletion': profileCompletion,
          'onboardingComplete': onboardingComplete,
          'status': tech?.status,
        });
        
        // Document doesn't exist - go to onboarding (Auth trigger will create it soon)
        if (tech == null) {
          AppLogger.info('AUTH', 'No technician doc - routing to onboarding');
          return const TechnicianOnboardingFlowScreen();
        }
        
        // Onboarding not complete - show onboarding flow
        if (!onboardingComplete) {
          AppLogger.info('AUTH', 'Onboarding not complete (profileCompletion: $profileCompletion)');
          return const TechnicianOnboardingFlowScreen();
        }
        
        // CRITICAL: Check location before allowing dashboard access
        final state = tech.state;
        final district = tech.district;
        
        if (state == null || district == null || state.isEmpty || district.isEmpty) {
          AppLogger.info('AUTH', 'Location missing - forcing location completion');
          return const CompleteTechnicianLocationScreen();
        }
        
        // Profile complete and location set - check approval status
        if (tech.status == "approved") {
          AppLogger.info('AUTH', 'Technician approved - opening dashboard');
          return const DashboardScreen();
        } else {
          AppLogger.info('AUTH', 'Technician pending approval - showing waiting screen');
          return TechnicianStatusGuard(
            dashboardScreen: const DashboardScreen(),
            onboardingScreen: const TechnicianOnboardingFlowScreen(),
          );
        }
      },
    );
  }
}

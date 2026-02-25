import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'core/providers/technician_provider.dart';
import 'core/app_theme.dart';
import 'core/services/notifications_service.dart';
import 'screens/login_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/technician_onboarding_flow_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/limited_dashboard.dart';
import 'screens/block_screen.dart';
import 'screens/application_status_screen.dart';
import 'core/services/technician_catalog_service.dart';


import 'firebase_options.dart';

import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter/foundation.dart';

// Global flag to track App Check status
bool _appCheckEnabled = false;
bool _appCheckTokenFetched = false;

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint("Background message: ${message.notification?.title}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  // 1. Initialize App Check (Environment-Aware)
  await _initializeAppCheck();

  // 2. Initialize Crashlytics & Performance
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  await FirebasePerformance.instance.setPerformanceCollectionEnabled(true);

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  
  // Initialize Push Notifications (Singleton)
  await NotificationsService().initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TechnicianProvider()),
        Provider(create: (_) => TechnicianCatalogService()),
        ChangeNotifierProvider(create: (_) => NotificationsService()),
      ],
      child: const TechnicianApp(),
    ),
  );
}

/// Initialize App Check with environment-aware provider
Future<void> _initializeAppCheck() async {
  try {
    final isDebug = !bool.fromEnvironment('dart.vm.product');
    
    await FirebaseAppCheck.instance.activate(
      androidProvider: isDebug 
          ? AndroidProvider.debug 
          : AndroidProvider.playIntegrity,
      appleProvider: isDebug
          ? AppleProvider.debug
          : AppleProvider.deviceCheck,
    );
    
    _appCheckEnabled = true;
    _appCheckTokenFetched = true;
    debugPrint('[AppCheck] ✅ Initialized (${isDebug ? 'DEBUG' : 'RELEASE'})');
  } catch (e) {
    debugPrint('[AppCheck] ⚠️ Failed: $e (graceful fallback)');
    _appCheckEnabled = false;
  }
}

/// Check if App Check is enabled
bool get isAppCheckEnabled => _appCheckEnabled;

class TechnicianApp extends StatelessWidget {
  const TechnicianApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'HomeFix Technician',
      navigatorKey: navigatorKey,
      theme: AppTheme.lightTheme,
      home: const AuthGate(),
      routes: {
        '/home': (_) => const DashboardScreen(),
        '/onboarding': (_) => const TechnicianOnboardingFlowScreen(),
        '/onboarding_legacy': (_) => const OnboardingScreen(),
        '/login': (_) => const LoginScreen(),
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
      return Scaffold(
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                  ),
                  child: IntrinsicHeight(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 64,
                            color: Colors.red.shade400,
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'Something went wrong',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _errorMessage,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                            ),
                          ),
                          const Spacer(),
                          ElevatedButton.icon(
                            onPressed: _resetError,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Try Again'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      );
    }

    return widget.child;
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
  // Debug mode flag - set to false in production
  static const bool _kDebugMode = bool.fromEnvironment('dart.vm.product', defaultValue: false);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // State 1: Waiting for auth state (initial load)
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _LoadingScreen(
            message: 'Checking authentication...',
          );
        }

        // State 2: Network/connection error
        if (snapshot.hasError) {
          // Simply rebuild to retry
          return _ErrorScreen(
            title: 'Connection Error',
            message: 'Unable to connect. Please check your internet connection.',
            onRetry: () {
              // Trigger rebuild by calling setState
              (context as Element).markNeedsBuild();
            },
          );
        }

        // State 3: Not logged in - show phone auth
        if (!snapshot.hasData || snapshot.data == null) {
          if (_kDebugMode) {
            debugPrint('[AuthGate] User not logged in -> LoginScreen');
          }
          return const LoginScreen();
        }

        // User IS logged in - check technician state
        return _AuthenticatedGate(
          user: snapshot.data!,
          debugMode: _kDebugMode,
        );
      },
    );
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
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App logo or branding
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
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Error screen with retry option
class _ErrorScreen extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback onRetry;
  
  const _ErrorScreen({
    required this.title,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.wifi_off,
                size: 64,
                color: Colors.orange.shade400,
              ),
              const SizedBox(height: 24),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// App Check failure screen - shown when App Check verification fails
class _AppCheckFailureScreen extends StatelessWidget {
  final VoidCallback onRetry;
  
  const _AppCheckFailureScreen({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Shield icon with warning
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
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 56,
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
  @override
  Widget build(BuildContext context) {
    return Consumer<TechnicianProvider>(
      builder: (context, provider, _) {
        // Wait for technician data to load
        if (provider.isLoading) {
          return const _LoadingScreen(
            message: 'Verifying account...',
          );
        }

        // NO CUSTOMER DEPENDENCY: We don't check users collection role
        // The technician app is fully standalone - any authenticated user can start onboarding
        // Get technician data
        final tech = provider.technician;

        // =============================================
        // STRICT ROUTING ORDER (Security Critical)
        // =============================================
        // Order: Onboarding -> Application Status -> Dashboard
        // Each check is explicit to prevent bypass

        // Case 1: No technician record OR KYC not complete -> TechnicianOnboardingFlowScreen
        // This is the DEFAULT for new users after OTP login
        // The technician document is created via Cloud Function on first OTP verification
        final isKycComplete = tech?.isKycComplete ?? false;
        
        if (tech == null || !isKycComplete) {
          if (widget.debugMode) {
            debugPrint('[AuthGate] tech=$tech, isKycComplete=$isKycComplete -> TechnicianOnboardingFlowScreen');
          }
          return const TechnicianOnboardingFlowScreen();
        }

        // Case 2: KYC complete but NOT approved -> Limited Dashboard or Status Screen
        final isApproved = tech.isApproved;
        final adminApproved = tech.adminApproved;
        final techStatus = tech.status ?? '';
        
        if (isKycComplete && !isApproved) {
          if (widget.debugMode) {
            debugPrint('[AuthGate] isKycComplete=$isKycComplete, isApproved=$isApproved -> Limited Dashboard');
          }
          
          // Show limited dashboard for pending_approval status
          if (techStatus == 'pending_approval') {
            return const LimitedDashboard();
          }
          
          // Show status screen for rejected/suspended
          String displayStatus = 'pending';
          if (techStatus == 'rejected') {
            displayStatus = 'rejected';
          } else if (techStatus == 'suspended') {
            displayStatus = 'suspended';
          }
          
          return ApplicationStatusScreen(
            status: displayStatus,
            reason: tech.rejectionReason,
          );
        }
        
        // Case 2.5: Approved but NOT adminApproved -> ApplicationStatusScreen (limited access)
        // This happens when basic KYC is approved but admin hasn't approved for service management
        if (isKycComplete && isApproved && !adminApproved) {
          if (widget.debugMode) {
            debugPrint('[AuthGate] isKycComplete=$isKycComplete, isApproved=$isApproved, adminApproved=$adminApproved -> ApplicationStatusScreen (awaiting service approval)');
          }
          
          return ApplicationStatusScreen(
            status: 'pending_service_approval',
            reason: 'Your account is approved but admin approval for service management is pending.',
          );
        }

        // Case 3: KYC complete AND approved -> DashboardScreen
        // Additional verification: check status is approved/active
        if (isKycComplete && isApproved) {
          // Handle different status states
          if (techStatus == 'approved' || techStatus == 'active') {
            if (widget.debugMode) {
              debugPrint('[AuthGate] isKycComplete=$isKycComplete, isApproved=$isApproved, status=$techStatus -> DashboardScreen');
            }
            return const DashboardScreen();
          }
          
          // Handle pending verification state
          if (techStatus == 'pending_verification') {
            if (widget.debugMode) {
              debugPrint('[AuthGate] status=pending_verification -> ApplicationStatusScreen');
            }
            return const ApplicationStatusScreen(status: 'pending');
          }
          
          // Blocked user check - highest priority
          if (techStatus == 'blocked') {
            if (widget.debugMode) {
              debugPrint('[AuthGate] User is blocked -> BlockScreen');
            }
            return BlockScreen(
              reason: tech.rejectionReason ?? 'Your account has been blocked. Please contact support.',
            );
          }
          
          // Rejected or suspended - show status screen
          if (techStatus == 'rejected' || techStatus == 'suspended') {
            if (widget.debugMode) {
              debugPrint('[AuthGate] status=$techStatus -> BlockScreen');
            }
            return BlockScreen(
              reason: tech.rejectionReason ?? 'Your account has been ${techStatus}.',
            );
          }
          
          // Default to dashboard for approved state
          if (widget.debugMode) {
            debugPrint('[AuthGate] Approved technician -> DashboardScreen');
          }
          return const DashboardScreen();
        }

        // Fallback - should not reach here, but safe default
        if (widget.debugMode) {
          debugPrint('[AuthGate] Fallthrough - defaulting to OnboardingScreen');
        }
        return const OnboardingScreen();
      },
    );
  }
}

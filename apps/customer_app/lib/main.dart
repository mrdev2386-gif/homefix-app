import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'core/theme/app_theme.dart';
import 'core/services/auth_service.dart';
import 'core/services/firestore_service.dart';
import 'core/services/functions_service.dart';
import 'core/services/storage_service.dart';
import 'core/services/notifications_service.dart';
import 'core/providers/cart_provider.dart';
import 'core/providers/auth_provider.dart';
import 'core/providers/category_provider.dart';
import 'core/providers/service_provider.dart';
import 'core/providers/booking_provider.dart';
import 'core/providers/location_provider.dart';
import 'core/providers/checkout_provider.dart';
import 'core/providers/locale_provider.dart';
import 'core/utils/app_localizations.dart';
import 'features/profile/providers/partner_onboarding_provider.dart';
import 'features/auth/screens/splash_screen.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/onboarding_screen.dart';
import 'features/home/main_wrapper_screen.dart';
import 'core/models/user_model.dart';
import 'firebase_options.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint("Background message: ${message.notification?.title}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    // 1. Initialize App Check (Critical Security)
    try {
      if (kDebugMode) {
        // Debug mode: Use debug provider to avoid "Too many attempts" error
        await FirebaseAppCheck.instance.activate(
          androidProvider: AndroidProvider.debug,
          appleProvider: AppleProvider.debug,
          webProvider: ReCaptchaV3Provider('6LfqvMsqAAAAAA-E4yG4yv6YvY-vS9k1yL_S0G4A'),
        );
        debugPrint("═══════════════════════════════════════════════════════════");
        debugPrint("🔐 AppCheck initialized in DEBUG mode");
        debugPrint("═══════════════════════════════════════════════════════════");
        
        // Listen for App Check token changes and log the debug token
        FirebaseAppCheck.instance.onTokenChange.listen((token) {
          if (token != null) {
            debugPrint("═══════════════════════════════════════════════════════════");
            debugPrint("🎫 APP CHECK DEBUG TOKEN:");
            debugPrint("   Copy this token and add it to Firebase Console:");
            debugPrint("   Firebase Console → App Check → Apps → Manage debug tokens");
            debugPrint("   Token: $token");
            debugPrint("═══════════════════════════════════════════════════════════");
          }
        });
        
        // Also try to get the token immediately
        try {
          final token = await FirebaseAppCheck.instance.getToken();
          if (token != null) {
            debugPrint("🎫 Initial App Check token obtained successfully");
          }
        } catch (tokenError) {
          debugPrint("⚠️ Could not get initial App Check token: $tokenError");
          debugPrint("   This is normal on first run. Uninstall app and run again.");
        }
      } else {
        // Production mode: Use Play Integrity
        await FirebaseAppCheck.instance.activate(
          androidProvider: AndroidProvider.playIntegrity,
          appleProvider: AppleProvider.deviceCheck,
          webProvider: ReCaptchaV3Provider('6LfqvMsqAAAAAA-E4yG4yv6YvY-vS9k1yL_S0G4A'),
        );
        debugPrint("🔐 AppCheck initialized in PRODUCTION mode (Play Integrity)");
      }
    } catch (e) {
      debugPrint("❌ AppCheck initialization failed: $e");
      debugPrint("   Uploads and Firestore operations may fail without App Check.");
    }

    // 2. Initialize Crashlytics & Performance
    if (!kIsWeb) {
      FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
      FirebasePerformance.instance.setPerformanceCollectionEnabled(true).catchError((e) {
        debugPrint("Performance initialization failed: $e");
      });
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    }
    
    // Initialize Push Notifications
    try {
      await NotificationsService.initialize();
    } catch (e) {
      debugPrint("Notifications initialization failed: $e");
    }

  } catch (e) {
    debugPrint("Firebase initialization failed: $e");
  }
  
  // Image cache tuning for better performance
  PaintingBinding.instance.imageCache.maximumSize = 100;
  PaintingBinding.instance.imageCache.maximumSizeBytes = 50 << 20; // 50 MB

  runApp(const HomeFixApp());
}

class HomeFixApp extends StatelessWidget {
  const HomeFixApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthService>(create: (_) => AuthService()),
        Provider<FirestoreService>(create: (_) => FirestoreService()),
        Provider<FunctionsService>(create: (_) => FunctionsService()),
        Provider<StorageService>(create: (_) => StorageService()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => CategoryProvider()),
        ChangeNotifierProvider(create: (_) => ServiceProvider()),
        ChangeNotifierProxyProvider<AuthProvider, CartProvider>(
          create: (_) => CartProvider(),
          update: (_, auth, cart) => cart!..updateUserId(auth.user?.uid),
        ),
        ChangeNotifierProvider(create: (_) => BookingProvider()),
        ChangeNotifierProvider(create: (_) => LocationProvider()),
        ChangeNotifierProvider(create: (_) => CheckoutProvider()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ChangeNotifierProvider(
          create: (context) => PartnerOnboardingProvider(
            context.read<StorageService>(),
          ),
        ),
      ],
      child: Consumer<LocaleProvider>(
        builder: (context, localeProvider, child) {
          return MaterialApp(
            title: 'HomeFix',
            navigatorKey: navigatorKey,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.system,
            locale: localeProvider.locale,
            supportedLocales: const [
              Locale('en'),
              Locale('hi'),
            ],
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: const AuthWrapper(),
          );
        },
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    final localeProvider = Provider.of<LocaleProvider>(context, listen: false);

    // Listen to auth state changes
    authService.authStateChanges.listen((user) async {
      if (user != null) {
        localeProvider.setUserId(user.uid);

        // Wait for user data to load
        firestoreService.streamUserModel(user.uid).listen((userData) {
          if (mounted) {
            setState(() {
              _isInitialized = true;
            });
          }
        });
      } else {
        if (mounted) {
          setState(() {
            _isInitialized = true;
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Show splash while initializing
    if (!_isInitialized) {
      return const SplashScreen();
    }

    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUser;

    if (user == null) {
      return const LoginScreen();
    }

    // Check if user data is loaded
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    return StreamBuilder<UserModel>(
      stream: firestoreService.streamUserModel(user.uid),
      builder: (context, snapshot) {
        final userData = snapshot.data;
        if (userData == null || !userData.isOnboarded) {
          return const OnboardingScreen();
        }
        return const MainWrapperScreen();
      },
    );
  }
}

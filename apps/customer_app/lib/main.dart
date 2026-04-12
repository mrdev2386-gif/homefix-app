import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:customer_app/core/theme/app_theme.dart';
import 'package:customer_app/core/services/auth_service.dart';
import 'core/services/firestore_service.dart';
import 'package:customer_app/core/services/functions_service.dart';
import 'core/services/storage_service.dart';
import 'core/services/notifications_service.dart';
import 'core/services/fcm_service.dart';
import 'core/services/category_service.dart';
import 'core/providers/cart_provider.dart';
import 'core/providers/favorites_provider.dart';
import 'core/providers/auth_provider.dart';
import 'core/providers/category_provider.dart';
import 'core/providers/booking_provider.dart';
import 'core/providers/location_provider.dart';
import 'core/providers/checkout_provider.dart';
import 'core/providers/locale_provider.dart';
import 'core/utils/app_localizations.dart';
import 'core/utils/logger.dart';
import 'features/auth/screens/splash_screen.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/onboarding_screen.dart';
import 'features/home/main_wrapper_screen.dart';
import 'features/custom_request/presentation/custom_request_screen.dart';
import 'features/profile/presentation/saved_addresses_screen.dart';
import 'features/cart/presentation/checkout_screen.dart';
import 'firebase_options.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// FIX 4: CONFIG VALIDATION - Validate required environment variables on app startup
/// Logs warnings for missing optional config (Gemini API key)
/// Throws error for missing critical config (none currently, but extensible)
void _validateConfiguration() {
  if (kDebugMode) {
    debugPrint('🔍 [CONFIG] Validating app configuration...');
    
    // Check optional Gemini API key
    const geminiApiKey = String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');
    if (geminiApiKey.isEmpty) {
      debugPrint('⚠️ [CONFIG] GEMINI_API_KEY not set - AI chat features will be disabled');
      debugPrint('   To enable: Set GEMINI_API_KEY environment variable or use Firebase Remote Config');
    } else {
      debugPrint('✅ [CONFIG] GEMINI_API_KEY configured');
    }
    
    // Add more config checks here as needed
    // Example for critical config:
    // const criticalKey = String.fromEnvironment('CRITICAL_KEY', defaultValue: '');
    // if (criticalKey.isEmpty) {
    //   throw Exception('CRITICAL_KEY environment variable is required but not set');
    // }
    
    debugPrint('✅ [CONFIG] Configuration validation complete');
  }
}

/// Background message handler - must be top-level function
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  if (kDebugMode) {
    debugPrint('[FCM BACKGROUND] ${message.notification?.title}');
    debugPrint('[FCM BACKGROUND] Data: ${message.data}');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // FIX 4: CONFIG VALIDATION - Check required environment variables on startup
  _validateConfiguration();

  // STEP 1: Initialize Firebase FIRST
  if (kDebugMode) debugPrint('🔥 Initializing Firebase...');
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  if (kDebugMode) debugPrint('✅ Firebase initialized successfully');
  
  // MICRO FIX 3: Remove sensitive data from logs
  if (kDebugMode) debugPrint('🔑 Firebase Auth initialized');
  
  // CRITICAL: Enable Firestore cache for production performance
  if (kDebugMode) debugPrint('✅ [PRODUCTION] Enabling Firestore persistence cache...');
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );
  if (kDebugMode) debugPrint('✅ Firestore cache enabled - data will be cached locally');

  // Enable Firebase App Check for production security
  if (kDebugMode) debugPrint('🔒 [SECURITY] Enabling Firebase App Check...');
  await FirebaseAppCheck.instance.activate(
    androidProvider: kDebugMode ? AndroidProvider.debug : AndroidProvider.playIntegrity,
  );
  if (kDebugMode) debugPrint('✅ Firebase App Check enabled');

  // STEP 3: Wait for Firebase Auth to be ready
  if (kDebugMode) debugPrint('🔑 Waiting for Firebase Auth to initialize...');
  final currentUser = FirebaseAuth.instance.currentUser;
  if (kDebugMode) {
    debugPrint('🔑 Current User: ${currentUser != null ? "logged in" : "not logged in"}');
  }
  
  // MICRO FIX 4: Add timeout for auth initialization
  await FirebaseAuth.instance.authStateChanges().first.timeout(
    const Duration(seconds: 10),
    onTimeout: () {
      if (kDebugMode) debugPrint('⚠️ Auth initialization timeout');
      return null;
    },
  );
  if (kDebugMode) debugPrint('✅ Firebase Auth ready');

  // CRITICAL FIX 1: Initialize FCM Service AFTER Firebase init (with timeout)
  if (kDebugMode) debugPrint('📱 Initializing FCM Service...');
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  try {
    await FCMService().initialize().timeout(
      const Duration(seconds: 15),
      onTimeout: () {
        if (kDebugMode) debugPrint('⚠️ FCM initialization timeout');
      },
    );
    if (kDebugMode) debugPrint('✅ FCM Service initialized');
  } catch (e) {
    if (kDebugMode) debugPrint('⚠️ FCM initialization error: $e');
  }
  
  // CRITICAL FIX 2: Initialize NotificationsService ONCE (singleton with timeout)
  if (kDebugMode) debugPrint('📱 Initializing NotificationsService (singleton)...');
  try {
    // HARDENING: Verify singleton is used (factory constructor)
    final notificationsService1 = NotificationsService();
    final notificationsService2 = NotificationsService();
    assert(identical(notificationsService1, notificationsService2), 'NotificationsService must be singleton');
    
    await notificationsService1.initialize().timeout(
      const Duration(seconds: 15),
      onTimeout: () {
        if (kDebugMode) debugPrint('⚠️ NotificationsService initialization timeout');
      },
    );
    if (kDebugMode) debugPrint('✅ NotificationsService initialized (singleton verified)');
  } catch (e) {
    if (kDebugMode) debugPrint('⚠️ NotificationsService initialization error: $e');
  }

  if (kDebugMode) debugPrint('🚀 Starting HomeFix App...');
  runApp(const HomeFixApp());
}

class HomeFixApp extends StatelessWidget {
  const HomeFixApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Core Services (Single Instances)
        Provider<FirestoreService>(create: (_) => FirestoreService()),
        Provider<AuthService>(create: (_) => AuthService()),
        Provider<FunctionsService>(create: (_) => FunctionsService()),
        Provider<StorageService>(create: (_) => StorageService()),
        
        // CategoryService depends on FirestoreService
        ChangeNotifierProxyProvider<FirestoreService, CategoryService>(
          create: (_) => CategoryService(),
          update: (_, firestoreService, categoryService) => 
              categoryService ?? CategoryService(firestoreService: firestoreService),
        ),
        
        // Wire up cache invalidation callback
        ProxyProvider2<AuthService, FirestoreService, AuthService>(
          update: (_, authService, firestoreService, __) {
            authService.onAuthStateChanged = () {
              if (kDebugMode) debugPrint('[CACHE] Auth state changed - clearing services cache');
              firestoreService.clearCachedServicesStream();
            };
            return authService;
          },
        ),
        
        // AuthProvider depends on CategoryService
        ChangeNotifierProxyProvider<CategoryService, AuthProvider>(
          create: (_) => AuthProvider(),
          update: (_, categoryService, authProvider) {
            authProvider!.setCategoryService(categoryService);
            return authProvider;
          },
        ),
        
        // Other providers
        ChangeNotifierProxyProvider<CategoryService, CategoryProvider>(
          create: (ctx) => CategoryProvider(categoryService: ctx.read<CategoryService>()),
          update: (_, categoryService, previous) => previous ?? CategoryProvider(categoryService: categoryService),
        ),
        ChangeNotifierProxyProvider<AuthProvider, FavoritesProvider>(
          create: (_) => FavoritesProvider(),
          update: (_, auth, favorites) => favorites!..updateUserId(auth.user?.uid),
        ),
        ChangeNotifierProxyProvider<AuthProvider, CartProvider>(
          create: (_) => CartProvider(),
          update: (_, auth, cart) => cart!..updateUserId(auth.user?.uid),
        ),
        ChangeNotifierProvider(create: (_) => BookingProvider()),
        ChangeNotifierProxyProvider<CategoryService, LocationProvider>(
          create: (ctx) => LocationProvider(categoryService: ctx.read<CategoryService>()),
          update: (_, categoryService, previous) => previous ?? LocationProvider(categoryService: categoryService),
        ),
        ChangeNotifierProvider(create: (_) => CheckoutProvider()),
        // CRITICAL: NotificationsService is a singleton - use factory constructor
        ChangeNotifierProvider<NotificationsService>(
          create: (_) => NotificationsService(),
          lazy: false, // Ensure it's created immediately
        ),
      ],
      child: ChangeNotifierProvider(
        create: (_) => LocaleProvider(),
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
              routes: {
                '/onboarding': (context) => const OnboardingScreen(),
                '/home': (context) => const MainWrapperScreen(),
                '/customRequest': (context) => const CustomRequestScreen(),
                '/addresses': (context) => const SavedAddressesScreen(),
                '/checkout': (context) => const CheckoutScreen(),
              },
              home: const AuthWrapper(),
            );
          },
        ),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = authSnapshot.data;

        if (user == null) {
          return const LoginScreen();
        }

        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('customers')
              .doc(user.uid)
              .get(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            if (!snapshot.hasData || !snapshot.data!.exists) {
              return const OnboardingScreen();
            }

            final data = snapshot.data!.data() as Map<String, dynamic>;

            final isComplete =
                data['profileCompleted'] == true &&
                data['isOnboarded'] == true &&
                (data['district'] ?? '').toString().isNotEmpty;

            if (isComplete) {
              return const MainWrapperScreen();
            } else {
              return const OnboardingScreen();
            }
          },
        );
      },
    );
  }
}

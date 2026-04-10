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
import 'core/services/push_notification_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
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
import 'firebase_options.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// Background message handler - must be top-level function
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('[FCM] Background message received: ${message.notification?.title}');
  // Handle background notification
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // STEP 1: Initialize Firebase FIRST
  print('🔥 Initializing Firebase...');
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  print('✅ Firebase initialized successfully');
  
  // CRITICAL: Enable Firestore cache for production performance
  print('✅ [PRODUCTION] Enabling Firestore persistence cache...');
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );
  print('✅ Firestore cache enabled - data will be cached locally');

  // Enable Firebase App Check for production security
  print('🔒 [SECURITY] Enabling Firebase App Check...');
  await FirebaseAppCheck.instance.activate(
    androidProvider: kDebugMode ? AndroidProvider.debug : AndroidProvider.playIntegrity,
  );
  print('✅ Firebase App Check enabled');

  // STEP 3: Wait for Firebase Auth to be ready
  print('🔑 Waiting for Firebase Auth to initialize...');
  final currentUser = FirebaseAuth.instance.currentUser;
  print('🔑 Current User: ${currentUser?.uid ?? "null (not logged in)"}');
  print('🔑 Current User Email: ${currentUser?.email ?? "N/A"}');
  print('🔑 Current User Phone: ${currentUser?.phoneNumber ?? "N/A"}');
  
  await FirebaseAuth.instance.authStateChanges().first.timeout(
    const Duration(seconds: 5),
    onTimeout: () {
      print('⚠️ Auth initialization timeout (no user logged in)');
      return null;
    },
  );
  print('✅ Firebase Auth ready');
  print('✅ FirebaseAuth.instance is accessible: ${FirebaseAuth.instance != null}');

  // CRITICAL FIX 1: Initialize PushNotificationService AFTER Firebase init
  print('📱 Initializing Push Notification Service...');
  final pushNotificationService = PushNotificationService();
  await pushNotificationService.initialize();
  print('✅ Push Notification Service initialized');
  
  // Setup background message handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  print('✅ Background message handler registered');

  print('🚀 Starting HomeFix App...');
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
        Provider<FunctionsService>(create: (_) => FunctionsService()),
        Provider<StorageService>(create: (_) => StorageService()),
        ChangeNotifierProvider<CategoryService>(create: (_) => CategoryService()),
        ChangeNotifierProxyProvider<CategoryService, AuthProvider>(
          create: (_) => AuthProvider(),
          update: (_, categoryService, authProvider) {
            authProvider!.setCategoryService(categoryService);
            return authProvider;
          },
        ),
        ChangeNotifierProvider(create: (_) => CategoryProvider()),
        ChangeNotifierProxyProvider<AuthProvider, FavoritesProvider>(
          create: (_) => FavoritesProvider(),
          update: (_, auth, favorites) => favorites!..updateUserId(auth.user?.uid),
        ),
        ChangeNotifierProxyProvider<AuthProvider, CartProvider>(
          create: (_) => CartProvider(),
          update: (_, auth, cart) => cart!..updateUserId(auth.user?.uid),
        ),
        ChangeNotifierProvider(create: (_) => BookingProvider()),
        ChangeNotifierProvider(create: (_) => LocationProvider()),
        ChangeNotifierProvider(create: (_) => CheckoutProvider()),
        ChangeNotifierProvider(create: (_) => NotificationsService()),
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

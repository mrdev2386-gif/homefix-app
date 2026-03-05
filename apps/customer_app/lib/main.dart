import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
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
import 'core/providers/cart_provider.dart';
import 'core/providers/favorites_provider.dart';
import 'core/providers/auth_provider.dart';
import 'core/providers/category_provider.dart';
import 'core/providers/booking_provider.dart';
import 'core/providers/location_provider.dart';
import 'core/providers/checkout_provider.dart';
import 'core/providers/locale_provider.dart';
import 'core/utils/app_localizations.dart';
import 'features/auth/screens/splash_screen.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/onboarding_screen.dart';
import 'features/home/main_wrapper_screen.dart';
import 'features/custom_request/presentation/custom_request_form_screen.dart';
import 'features/profile/presentation/saved_addresses_screen.dart';
import 'core/models/user_model.dart';
import 'firebase_options.dart';
import 'core/firebase/firebase_init.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint("Background message: ${message.notification?.title}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Initialize App Check (Critical Security)
    await initializeFirebase();

    // 2. Initialize Crashlytics & Performance
    if (!kIsWeb) {
      FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
      FirebasePerformance.instance.setPerformanceCollectionEnabled(true).catchError((e) {
        debugPrint("Performance initialization failed: $e");
      });
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    }
    
    // 4. Initialize Push Notifications (FCM Token Management)
    try {
      await PushNotificationService().initialize();
    } catch (e) {
      debugPrint("Push notification service initialization failed: $e");
    }

    // 4.5 Initialize Notifications UI Service (Notification management)
    try {
      await NotificationsService().initialize();
    } catch (e) {
      debugPrint("Notifications initialization failed: $e");
    }

    // 5. Seed initial data
    try {
      // DatabaseSeeder.seedInitialData(); // Commented out - not needed for basic functionality
    } catch (e) {
      debugPrint("Database seeding failed: $e");
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
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ChangeNotifierProvider(create: (_) => NotificationsService()),
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
            routes: {
              '/customRequest': (context) => const CustomRequestFormScreen(),
              '/addresses': (context) => const SavedAddressesScreen(),
            },
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
  // FIX: Store subscription references to prevent memory leaks
  StreamSubscription? _authSubscription;
  StreamSubscription? _userDataSubscription;

  @override
  void initState() {
    super.initState();
    _initializeAuth();
  }

  @override
  void dispose() {
    // FIX: Cancel all subscriptions on dispose to prevent setState-after-dispose
    _authSubscription?.cancel();
    _userDataSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initializeAuth() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    final localeProvider = Provider.of<LocaleProvider>(context, listen: false);

    _authSubscription = authService.authStateChanges.listen((user) async {
      // FIX: Cancel previous user data subscription before creating new one
      _userDataSubscription?.cancel();
      _userDataSubscription = null;

      if (user != null) {
        localeProvider.setUserId(user.uid);

        _userDataSubscription = firestoreService.streamUserModel(user.uid).listen((userData) {
          if (mounted) {
            setState(() {
              _isInitialized = true;
            });
          }
        }, onError: (e) {
          // FIX: Handle stream errors — prevent stuck splash screen
          debugPrint('❌ [AuthWrapper] User data stream error: $e');
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

    // Initialize services with user ID
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<LocationProvider>(context, listen: false).initialize(user.uid);
    });

    // Check if user data is loaded - with ROOT PROFILE GUARD
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    return StreamBuilder<UserModel>(
      stream: firestoreService.streamUserModel(user.uid),
      builder: (context, snapshot) {
        // Show splash while loading user data
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreen();
        }
        
        // FIX: Handle errors gracefully — don't get stuck on splash
        if (snapshot.hasError) {
          debugPrint('❌ [AuthWrapper] StreamBuilder error: ${snapshot.error}');
          // Still allow access to app — onboarding can handle missing data
          return const OnboardingScreen();
        }
        
        final userData = snapshot.data;
        
        // ROOT PROFILE GUARD - Check profile completion before allowing access
        if (kDebugMode) {
          debugPrint('[ROOT_PROFILE_GUARD] profileCompleted: ${userData?.profileCompleted}, district: ${userData?.district}');
        }
        
        // Check if profile is completed with district
        if (userData == null) {
          return const OnboardingScreen();
        }
        
        if (!userData.profileCompleted || userData.district == null || userData.district!.isEmpty) {
          return const OnboardingScreen();
        }
        
        return const MainWrapperScreen();
      },
    );
  }
}

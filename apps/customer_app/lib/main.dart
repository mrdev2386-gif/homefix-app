import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
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
import 'features/auth/screens/splash_screen.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/onboarding_screen.dart';
import 'features/home/main_wrapper_screen.dart';
import 'core/models/user_model.dart';
import 'core/firestore/seed_service.dart';
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
      await FirebaseAppCheck.instance.activate(
        androidProvider: AndroidProvider.playIntegrity,
        appleProvider: AppleProvider.deviceCheck,
        // Using a dummy key for now, caught in try-catch to prevent fatal crash
        webProvider: ReCaptchaV3Provider('6LfqvMsqAAAAAA-E4yG4yv6YvY-vS9k1yL_S0G4A'), 
      );
    } catch (e) {
      debugPrint("AppCheck initialization skipped or failed: $e");
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

    // Synchronize Services Catalog
    if (!kIsWeb) {
      try {
        await SeedService.seedServicesIfEmpty();
      } catch (e) {
        debugPrint("Seed service failed: $e");
      }
    }
  } catch (e) {
    debugPrint("Firebase initialization failed: $e");
  }
  
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
      ],
      child: MaterialApp(
        title: 'HomeFix',
        navigatorKey: navigatorKey,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        home: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);

    return StreamBuilder(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreen();
        }
        
        final user = snapshot.data;
        if (user != null) {
          return StreamBuilder<UserModel>(
            stream: firestoreService.streamUserModel(user.uid),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const SplashScreen();
              }
              
              final userData = userSnapshot.data;
              if (userData == null || !userData.isOnboarded) {
                return const OnboardingScreen();
              }
              
              return const MainWrapperScreen();
            },
          );
        }
        
        return const LoginScreen();
      },
    );
  }
}

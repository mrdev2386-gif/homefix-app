import 'dart:async';
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
import 'core/models/user_model.dart';
import 'firebase_options.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  AppLogger.firebase('FCM', 'Background message: ${message.notification?.title}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // STEP 1: Initialize Firebase FIRST
  print('🔥 Initializing Firebase...');
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  print('✅ Firebase initialized successfully');

  // DISABLED FOR DEBUG (fix unauthenticated issue)
  // await FirebaseAppCheck.instance.activate(
  //   androidProvider: AndroidProvider.debug,
  // );

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

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isInitialized = false;
  StreamSubscription? _authSubscription;
  StreamSubscription? _userDataSubscription;

  @override
  void initState() {
    super.initState();
    _initializeAuth();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _userDataSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initializeAuth() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    final localeProvider = Provider.of<LocaleProvider>(context, listen: false);

    _authSubscription = authService.authStateChanges.listen((user) async {
      _userDataSubscription?.cancel();
      _userDataSubscription = null;

      if (user != null) {
        localeProvider.setUserId(user.uid);
        await localeProvider.initialize(user.uid);

        _userDataSubscription = firestoreService.streamUserModel(user.uid).listen(
          (_) {
            if (mounted) setState(() => _isInitialized = true);
          },
          onError: (e) {
            AppLogger.error('AuthWrapper', 'User data stream error', e);
            if (mounted) setState(() => _isInitialized = true);
          },
        );
      } else {
        if (mounted) setState(() => _isInitialized = true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) return const SplashScreen();

    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUser;

    if (user == null) return const LoginScreen();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<LocationProvider>(context, listen: false).initialize(user.uid);
    });

    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    return StreamBuilder<UserModel>(
      stream: firestoreService.streamUserModel(user.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreen();
        }

        // On stream error: do a direct Firestore fetch as fallback
        // instead of blindly routing to OnboardingScreen
        if (snapshot.hasError) {
          AppLogger.error('AuthWrapper', 'StreamBuilder error — falling back to direct fetch', snapshot.error);
          return _ProfileFallbackLoader(uid: user.uid);
        }

        final userData = snapshot.data;

        if (kDebugMode) {
          AppLogger.debug('AuthWrapper',
              'profileCompleted=${userData?.profileCompleted}, '
              'isOnboarded=${userData?.isOnboarded}, '
              'district=${userData?.district}');
        }

        return _routeFromProfile(userData);
      },
    );
  }

  /// Central routing logic — Firestore is the single source of truth.
  /// Requires BOTH profileCompleted AND isOnboarded AND non-empty district.
  static Widget _routeFromProfile(UserModel? userData) {
    if (userData == null) {
      AppLogger.debug('AuthWrapper', 'userData is null, routing to OnboardingScreen');
      return const OnboardingScreen();
    }

    final bool ready = userData.profileCompleted &&
        userData.isOnboarded &&
        (userData.district?.isNotEmpty ?? false);

    AppLogger.debug('AuthWrapper', 
        'profileCompleted=${userData.profileCompleted}, '
        'isOnboarded=${userData.isOnboarded}, '
        'district=${userData.district}, '
        'ready=$ready');

    return ready ? const MainWrapperScreen() : const OnboardingScreen();
  }
}

/// Fallback widget: performs a single direct Firestore .get() when the
/// stream errors (e.g. temporary permission delay on first login).
/// Retries once after 500 ms before giving up.
class _ProfileFallbackLoader extends StatefulWidget {
  final String uid;
  const _ProfileFallbackLoader({required this.uid});

  @override
  State<_ProfileFallbackLoader> createState() => _ProfileFallbackLoaderState();
}

class _ProfileFallbackLoaderState extends State<_ProfileFallbackLoader> {
  @override
  void initState() {
    super.initState();
    _fetchWithRetry();
  }

  Future<void> _fetchWithRetry() async {
    UserModel? userData;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('customers')
          .doc(widget.uid)
          .get();
      final data = doc.data() ?? {};
      userData = doc.exists ? UserModel.fromFirestore(doc) : null;
      AppLogger.firebase('FallbackLoader', 'Direct fetch succeeded — profileCompleted=${data["profileCompleted"]}');
    } catch (e) {
      AppLogger.error('FallbackLoader', 'First fetch failed, retrying in 500ms', e);
      await Future.delayed(const Duration(milliseconds: 500));
      try {
        final doc = await FirebaseFirestore.instance
            .collection('customers')
            .doc(widget.uid)
            .get();
        userData = doc.exists ? UserModel.fromFirestore(doc) : null;
      } catch (e2) {
        AppLogger.error('FallbackLoader', 'Retry also failed — showing onboarding', e2);
      }
    }

    if (!mounted) return;
    final dest = _AuthWrapperState._routeFromProfile(userData);
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => dest),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) => const SplashScreen();
}

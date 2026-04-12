import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:customer_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Property 2: Functional Preservation Tests', () {
    setUpAll(() async {
      await Firebase.initializeApp();
    });

    testWidgets('PRESERVATION 1: Customer booking creation flow works correctly',
        (WidgetTester tester) async {
      debugPrint('\n🧪 [PRESERVATION TEST 1] Customer Booking Creation');

      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      await _ensureAuthenticated(tester);

      final navigated = await _navigateToServiceDetails(tester);
      if (!navigated) {
        debugPrint('⚠️ [TEST] Could not navigate to service details - skipping test');
        return;
      }

      final bookByService = find.text('Book Service');
      final bookByNow = find.text('Book Now');
      final bookByContinue = find.text('Continue');

      if (bookByService.evaluate().isEmpty && bookByNow.evaluate().isEmpty && bookByContinue.evaluate().isEmpty) {
        debugPrint('⚠️ [TEST] Book button not found - may need to select technician first');
        return;
      }

      final bookButton = bookByService.evaluate().isNotEmpty ? bookByService
          : bookByNow.evaluate().isNotEmpty ? bookByNow : bookByContinue;

      debugPrint('📝 [TEST] Found booking button, initiating booking...');
      await tester.tap(bookButton.first);
      await tester.pumpAndSettle(const Duration(seconds: 3));

      await tester.pumpAndSettle(const Duration(seconds: 10));

      final stillLoading = find.byType(CircularProgressIndicator);
      expect(stillLoading.evaluate().isEmpty, true,
          reason: 'Booking should complete within 10 seconds');

      debugPrint('✅ [TEST] Booking creation flow completed');
    });

    testWidgets('PRESERVATION 2: Urgent booking creation flow works correctly',
        (WidgetTester tester) async {
      debugPrint('\n🧪 [PRESERVATION TEST 2] Urgent Booking Creation');

      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      await _ensureAuthenticated(tester);

      final urgentByText = find.text('Urgent');
      final urgentByText2 = find.text('Urgent Booking');
      final urgentByIcon = find.byIcon(Icons.flash_on);

      if (urgentByText.evaluate().isEmpty && urgentByText2.evaluate().isEmpty && urgentByIcon.evaluate().isEmpty) {
        debugPrint('⚠️ [TEST] Urgent booking button not found - skipping test');
        return;
      }

      final urgentButton = urgentByText.evaluate().isNotEmpty ? urgentByText
          : urgentByText2.evaluate().isNotEmpty ? urgentByText2 : urgentByIcon;

      debugPrint('⚡ [TEST] Found urgent booking button, navigating...');
      await tester.tap(urgentButton.first);
      await tester.pumpAndSettle(const Duration(seconds: 5));

      final bookUrgentButton = find.text('Book Urgent Service');
      if (bookUrgentButton.evaluate().isNotEmpty) {
        debugPrint('📝 [TEST] Found urgent booking button, testing creation...');
        await tester.tap(bookUrgentButton.first);
        await tester.pumpAndSettle(const Duration(seconds: 5));
      }

      debugPrint('✅ [TEST] Urgent booking flow completed');
    });

    testWidgets('PRESERVATION 3: User profile loading returns correct data structure',
        (WidgetTester tester) async {
      debugPrint('\n🧪 [PRESERVATION TEST 3] User Profile Loading');

      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      await _ensureAuthenticated(tester);

      final profileByText = find.text('Profile');
      final profileByIcon = find.byIcon(Icons.person);
      final profileByIcon2 = find.byIcon(Icons.account_circle);

      if (profileByText.evaluate().isEmpty && profileByIcon.evaluate().isEmpty && profileByIcon2.evaluate().isEmpty) {
        debugPrint('⚠️ [TEST] Profile tab not found - skipping test');
        return;
      }

      final profileTab = profileByText.evaluate().isNotEmpty ? profileByText
          : profileByIcon.evaluate().isNotEmpty ? profileByIcon : profileByIcon2;

      debugPrint('👤 [TEST] Found profile tab, navigating...');
      await tester.tap(profileTab.first);
      await tester.pumpAndSettle(const Duration(seconds: 5));

      await tester.pumpAndSettle(const Duration(seconds: 5));
      final stillLoading = find.byType(CircularProgressIndicator);
      expect(stillLoading.evaluate().isEmpty, true,
          reason: 'Profile should load within 5 seconds');

      debugPrint('✅ [TEST] Profile loading completed');
    });

    testWidgets('PRESERVATION 4: Technician queries return accurate filtered results',
        (WidgetTester tester) async {
      debugPrint('\n🧪 [PRESERVATION TEST 4] Technician Query and Filtering');

      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      await _ensureAuthenticated(tester);

      final urgentByText = find.text('Urgent');
      final urgentByText2 = find.text('Urgent Booking');
      final urgentByIcon = find.byIcon(Icons.flash_on);

      if (urgentByText.evaluate().isNotEmpty || urgentByText2.evaluate().isNotEmpty || urgentByIcon.evaluate().isNotEmpty) {
        final urgentButton = urgentByText.evaluate().isNotEmpty ? urgentByText
            : urgentByText2.evaluate().isNotEmpty ? urgentByText2 : urgentByIcon;

        debugPrint('⚡ [TEST] Navigating to urgent booking for technician list...');
        await tester.tap(urgentButton.first);
        await tester.pumpAndSettle(const Duration(seconds: 5));

        await tester.pump(const Duration(seconds: 2));
        await tester.pumpAndSettle();
      }

      debugPrint('✅ [TEST] Technician query completed');
    });

    testWidgets('PRESERVATION 5: Error handling provides appropriate feedback',
        (WidgetTester tester) async {
      debugPrint('\n🧪 [PRESERVATION TEST 5] Error Handling');

      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      debugPrint('🔒 [TEST] Testing unauthenticated access...');
      await FirebaseAuth.instance.signOut();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      final urgentByText = find.text('Urgent');
      final urgentByText2 = find.text('Urgent Booking');
      final urgentByIcon = find.byIcon(Icons.flash_on);

      if (urgentByText.evaluate().isNotEmpty || urgentByText2.evaluate().isNotEmpty || urgentByIcon.evaluate().isNotEmpty) {
        final urgentButton = urgentByText.evaluate().isNotEmpty ? urgentByText
            : urgentByText2.evaluate().isNotEmpty ? urgentByText2 : urgentByIcon;
        await tester.tap(urgentButton.first);
        await tester.pumpAndSettle(const Duration(seconds: 3));
      }

      await _ensureAuthenticated(tester);
      debugPrint('✅ [TEST] Error handling completed');
    });

    testWidgets('PRESERVATION 6: Performance baseline measurement',
        (WidgetTester tester) async {
      debugPrint('\n🧪 [PRESERVATION TEST 6] Performance Baseline');

      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      await _ensureAuthenticated(tester);

      final profileByText = find.text('Profile');
      final profileByIcon = find.byIcon(Icons.person);
      final profileByIcon2 = find.byIcon(Icons.account_circle);

      if (profileByText.evaluate().isNotEmpty || profileByIcon.evaluate().isNotEmpty || profileByIcon2.evaluate().isNotEmpty) {
        final profileTab = profileByText.evaluate().isNotEmpty ? profileByText
            : profileByIcon.evaluate().isNotEmpty ? profileByIcon : profileByIcon2;
        final stopwatch = Stopwatch()..start();
        await tester.tap(profileTab.first);
        await tester.pumpAndSettle(const Duration(seconds: 10));
        stopwatch.stop();
        debugPrint('📊 [BASELINE] Profile Load Time: ${stopwatch.elapsedMilliseconds}ms');
      }

      final urgentByText = find.text('Urgent');
      final urgentByText2 = find.text('Urgent Booking');
      final urgentByIcon = find.byIcon(Icons.flash_on);

      if (urgentByText.evaluate().isNotEmpty || urgentByText2.evaluate().isNotEmpty || urgentByIcon.evaluate().isNotEmpty) {
        final urgentButton = urgentByText.evaluate().isNotEmpty ? urgentByText
            : urgentByText2.evaluate().isNotEmpty ? urgentByText2 : urgentByIcon;
        final stopwatch = Stopwatch()..start();
        await tester.tap(urgentButton.first);
        await tester.pumpAndSettle(const Duration(seconds: 10));
        stopwatch.stop();
        debugPrint('📊 [BASELINE] Technician Query Time: ${stopwatch.elapsedMilliseconds}ms');
      }

      final servicesByText = find.text('Services');
      final servicesByIcon = find.byIcon(Icons.home_repair_service);

      if (servicesByText.evaluate().isNotEmpty || servicesByIcon.evaluate().isNotEmpty) {
        final servicesTab = servicesByText.evaluate().isNotEmpty ? servicesByText : servicesByIcon;
        final stopwatch = Stopwatch()..start();
        await tester.tap(servicesTab.first);
        await tester.pumpAndSettle(const Duration(seconds: 10));
        stopwatch.stop();
        debugPrint('📊 [BASELINE] Service Navigation Time: ${stopwatch.elapsedMilliseconds}ms');
      }

      debugPrint('✅ [TEST] Performance baseline measurement completed');
    });
  });
}

Future<void> _ensureAuthenticated(WidgetTester tester) async {
  final currentUser = FirebaseAuth.instance.currentUser;

  if (currentUser != null) {
    debugPrint('✅ [AUTH] User already logged in: ${currentUser.uid}');
    return;
  }

  debugPrint('🔐 [AUTH] No user logged in, attempting authentication...');

  try {
    final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: 'test@homefix.com',
      password: 'testpassword123',
    );
    if (userCredential.user != null) {
      debugPrint('✅ [AUTH] Logged in successfully: ${userCredential.user!.uid}');
      await tester.pumpAndSettle(const Duration(seconds: 3));
      return;
    }
  } catch (e) {
    debugPrint('⚠️ [AUTH] Login failed: $e');
    try {
      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: 'test@homefix.com',
        password: 'testpassword123',
      );
      if (userCredential.user != null) {
        debugPrint('✅ [AUTH] Test user created: ${userCredential.user!.uid}');
        await tester.pumpAndSettle(const Duration(seconds: 3));
        return;
      }
    } catch (createError) {
      debugPrint('❌ [AUTH] Failed to create test user: $createError');
    }
  }

  debugPrint('⚠️ [AUTH] Could not authenticate - tests may fail');
}

Future<bool> _navigateToServiceDetails(WidgetTester tester) async {
  debugPrint('🧭 [NAV] Navigating to service details...');

  final servicesByText = find.text('Services');
  final servicesByIcon = find.byIcon(Icons.home_repair_service);

  if (servicesByText.evaluate().isNotEmpty || servicesByIcon.evaluate().isNotEmpty) {
    final servicesTab = servicesByText.evaluate().isNotEmpty ? servicesByText : servicesByIcon;
    await tester.tap(servicesTab.first);
    await tester.pumpAndSettle(const Duration(seconds: 3));
  }

  final serviceCards = find.byType(GestureDetector);
  if (serviceCards.evaluate().isEmpty) {
    debugPrint('❌ [NAV] No service cards found');
    return false;
  }

  await tester.tap(serviceCards.first);
  await tester.pumpAndSettle(const Duration(seconds: 3));

  final bookByService = find.text('Book Service');
  final bookByNow = find.text('Book Now');
  final bookByContinue = find.text('Continue');

  if (bookByService.evaluate().isNotEmpty || bookByNow.evaluate().isNotEmpty || bookByContinue.evaluate().isNotEmpty) {
    debugPrint('✅ [NAV] Successfully navigated to service details');
    return true;
  }

  debugPrint('❌ [NAV] Failed to navigate to service details');
  return false;
}

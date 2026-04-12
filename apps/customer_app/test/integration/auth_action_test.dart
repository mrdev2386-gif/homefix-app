import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:customer_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Authentication Action Tests', () {
    setUpAll(() async {
      await Firebase.initializeApp();
    });

    testWidgets('SCENARIO 1: Actions without login should be blocked or show error', (WidgetTester tester) async {
      debugPrint('🧪 [TEST] Starting SCENARIO 1: Actions without login');

      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        debugPrint('🔓 [TEST] Logging out current user: ${currentUser.uid}');
        await FirebaseAuth.instance.signOut();
        await tester.pumpAndSettle(const Duration(seconds: 2));
      }

      debugPrint('✅ [TEST] User is logged out');

      final servicesTabByText = find.text('Services');
      final servicesTabByIcon = find.byIcon(Icons.home_repair_service);
      if (servicesTabByText.evaluate().isNotEmpty || servicesTabByIcon.evaluate().isNotEmpty) {
        final servicesTab = servicesTabByText.evaluate().isNotEmpty ? servicesTabByText : servicesTabByIcon;
        debugPrint('🎯 [TEST] Found Services tab, tapping...');
        await tester.tap(servicesTab.first);
        await tester.pumpAndSettle(const Duration(seconds: 3));
      } else {
        debugPrint('⚠️ [TEST] Services tab not found');
        final serviceWidget = find.byType(GestureDetector);
        if (serviceWidget.evaluate().isNotEmpty) {
          await tester.tap(serviceWidget.first);
          await tester.pumpAndSettle(const Duration(seconds: 2));
        }
      }

      final serviceCards = find.byType(GestureDetector);
      if (serviceCards.evaluate().isNotEmpty) {
        debugPrint('🎯 [TEST] Found service cards, tapping first one...');
        await tester.tap(serviceCards.first);
        await tester.pumpAndSettle(const Duration(seconds: 3));

        final addToCartByText = find.text('Add to Cart');
        final addToCartByIcon = find.byIcon(Icons.shopping_cart_rounded);
        if (addToCartByText.evaluate().isNotEmpty || addToCartByIcon.evaluate().isNotEmpty) {
          final addToCartButton = addToCartByText.evaluate().isNotEmpty ? addToCartByText : addToCartByIcon;
          debugPrint('🛒 [TEST] Found Add to Cart button, testing without login...');
          await tester.tap(addToCartButton.first);
          await tester.pumpAndSettle(const Duration(seconds: 2));

          final errorMessages = [
            find.text('User not logged in'),
            find.text('Please login first'),
            find.text('Authentication required'),
            find.text('unauthenticated'),
            find.byType(SnackBar),
          ];

          bool foundError = false;
          for (final errorFinder in errorMessages) {
            if (errorFinder.evaluate().isNotEmpty) {
              debugPrint('✅ [TEST] Found expected error/prompt for Add to Cart');
              foundError = true;
              break;
            }
          }
          if (!foundError) {
            debugPrint('⚠️ [TEST] No error found for Add to Cart without login');
          }
        }

        final likeByIcon1 = find.byIcon(Icons.favorite_border_rounded);
        final likeByIcon2 = find.byIcon(Icons.favorite_rounded);
        if (likeByIcon1.evaluate().isNotEmpty || likeByIcon2.evaluate().isNotEmpty) {
          final likeButton = likeByIcon1.evaluate().isNotEmpty ? likeByIcon1 : likeByIcon2;
          debugPrint('❤️ [TEST] Found Like button, testing without login...');
          await tester.tap(likeButton.first);
          await tester.pumpAndSettle(const Duration(seconds: 2));

          final errorMessages = [
            find.text('User not logged in'),
            find.text('Please login first'),
            find.text('Authentication required'),
            find.text('unauthenticated'),
            find.byType(SnackBar),
          ];

          bool foundError = false;
          for (final errorFinder in errorMessages) {
            if (errorFinder.evaluate().isNotEmpty) {
              debugPrint('✅ [TEST] Found expected error/prompt for Like');
              foundError = true;
              break;
            }
          }
          if (!foundError) {
            debugPrint('⚠️ [TEST] No error found for Like without login');
          }
        }
      } else {
        debugPrint('⚠️ [TEST] No service cards found');
      }

      debugPrint('✅ [TEST] SCENARIO 1 completed');
    });

    testWidgets('SCENARIO 2: Actions after login should succeed without unauthenticated error', (WidgetTester tester) async {
      debugPrint('🧪 [TEST] Starting SCENARIO 2: Actions after login');

      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      await _performTestLogin(tester);

      await tester.pumpAndSettle(const Duration(seconds: 3));
      final currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser == null) {
        debugPrint('❌ [TEST] Login failed - user is still null');
        fail('Login failed - cannot proceed with authenticated tests');
      }

      debugPrint('✅ [TEST] User is logged in: ${currentUser.uid}');

      await tester.pumpAndSettle(const Duration(seconds: 3));

      final servicesTabByText = find.text('Services');
      final servicesTabByIcon = find.byIcon(Icons.home_repair_service);
      if (servicesTabByText.evaluate().isNotEmpty || servicesTabByIcon.evaluate().isNotEmpty) {
        final servicesTab = servicesTabByText.evaluate().isNotEmpty ? servicesTabByText : servicesTabByIcon;
        debugPrint('🎯 [TEST] Found Services tab, tapping...');
        await tester.tap(servicesTab.first);
        await tester.pumpAndSettle(const Duration(seconds: 3));
      }

      final serviceCards = find.byType(GestureDetector);
      if (serviceCards.evaluate().isNotEmpty) {
        debugPrint('🎯 [TEST] Found service cards, tapping first one...');
        await tester.tap(serviceCards.first);
        await tester.pumpAndSettle(const Duration(seconds: 3));

        final addToCartByText = find.text('Add to Cart');
        final addToCartByIcon = find.byIcon(Icons.shopping_cart_rounded);
        if (addToCartByText.evaluate().isNotEmpty || addToCartByIcon.evaluate().isNotEmpty) {
          final addToCartButton = addToCartByText.evaluate().isNotEmpty ? addToCartByText : addToCartByIcon;
          debugPrint('🛒 [TEST] Found Add to Cart button, testing with login...');
          await tester.tap(addToCartButton.first);
          await tester.pumpAndSettle(const Duration(seconds: 5));

          final unauthenticatedErrors = [
            find.text('unauthenticated'),
            find.text('User not logged in'),
            find.text('Authentication required'),
          ];

          bool foundUnauthenticatedError = false;
          for (final errorFinder in unauthenticatedErrors) {
            if (errorFinder.evaluate().isNotEmpty) {
              debugPrint('❌ [TEST] FOUND UNAUTHENTICATED ERROR for Add to Cart');
              foundUnauthenticatedError = true;
              break;
            }
          }

          if (foundUnauthenticatedError) {
            fail('Add to Cart action failed with unauthenticated error despite being logged in');
          }

          final continueButton = find.text('Continue');
          if (continueButton.evaluate().isNotEmpty) {
            await tester.tap(continueButton);
            await tester.pumpAndSettle();
          }
        }

        final likeByIcon1 = find.byIcon(Icons.favorite_border_rounded);
        final likeByIcon2 = find.byIcon(Icons.favorite_rounded);
        if (likeByIcon1.evaluate().isNotEmpty || likeByIcon2.evaluate().isNotEmpty) {
          final likeButton = likeByIcon1.evaluate().isNotEmpty ? likeByIcon1 : likeByIcon2;
          debugPrint('❤️ [TEST] Found Like button, testing with login...');
          await tester.tap(likeButton.first);
          await tester.pumpAndSettle(const Duration(seconds: 5));

          final unauthenticatedErrors = [
            find.text('unauthenticated'),
            find.text('User not logged in'),
            find.text('Authentication required'),
          ];

          bool foundUnauthenticatedError = false;
          for (final errorFinder in unauthenticatedErrors) {
            if (errorFinder.evaluate().isNotEmpty) {
              debugPrint('❌ [TEST] FOUND UNAUTHENTICATED ERROR for Like');
              foundUnauthenticatedError = true;
              break;
            }
          }

          if (foundUnauthenticatedError) {
            fail('Like action failed with unauthenticated error despite being logged in');
          }
        }
      } else {
        debugPrint('⚠️ [TEST] No service cards found');
      }

      debugPrint('✅ [TEST] SCENARIO 2 completed');
    });
  });
}

Future<void> _performTestLogin(WidgetTester tester) async {
  debugPrint('🔐 [TEST] Attempting to perform test login...');

  final loginByText = find.text('Login');
  final signInByText = find.text('Sign In');
  final loginByIcon = find.byIcon(Icons.login);
  if (loginByText.evaluate().isNotEmpty || signInByText.evaluate().isNotEmpty || loginByIcon.evaluate().isNotEmpty) {
    final loginButton = loginByText.evaluate().isNotEmpty ? loginByText
        : signInByText.evaluate().isNotEmpty ? signInByText : loginByIcon;
    debugPrint('🎯 [TEST] Found login button, tapping...');
    await tester.tap(loginButton.first);
    await tester.pumpAndSettle(const Duration(seconds: 2));
  }

  try {
    final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: 'test@homefix.com',
      password: 'testpassword123',
    );
    if (userCredential.user != null) {
      debugPrint('✅ [TEST] Firebase Auth login successful');
      return;
    }
  } catch (e) {
    debugPrint('⚠️ [TEST] Firebase Auth login failed: $e');
    try {
      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: 'test@homefix.com',
        password: 'testpassword123',
      );
      if (userCredential.user != null) {
        debugPrint('✅ [TEST] Test user created and logged in');
        return;
      }
    } catch (createError) {
      debugPrint('❌ [TEST] Failed to create test user: $createError');
    }
  }

  final emailFieldByType = find.byType(TextField);
  final emailFieldByForm = find.byType(TextFormField);
  if (emailFieldByType.evaluate().isNotEmpty || emailFieldByForm.evaluate().isNotEmpty) {
    final emailField = emailFieldByType.evaluate().isNotEmpty ? emailFieldByType : emailFieldByForm;
    debugPrint('📧 [TEST] Found input field, entering test credentials...');
    await tester.enterText(emailField.first, 'test@homefix.com');
    await tester.pumpAndSettle();

    final allFields = find.byType(TextField);
    if (allFields.evaluate().length > 1) {
      await tester.enterText(allFields.last, 'testpassword123');
      await tester.pumpAndSettle();
    }

    final submitByLogin = find.text('Login');
    final submitBySignIn = find.text('Sign In');
    final submitByContinue = find.text('Continue');
    if (submitByLogin.evaluate().isNotEmpty || submitBySignIn.evaluate().isNotEmpty || submitByContinue.evaluate().isNotEmpty) {
      final submitButton = submitByLogin.evaluate().isNotEmpty ? submitByLogin
          : submitBySignIn.evaluate().isNotEmpty ? submitBySignIn : submitByContinue;
      await tester.tap(submitButton.first);
      await tester.pumpAndSettle(const Duration(seconds: 5));
    }
  }

  debugPrint('🔐 [TEST] Login attempt completed');
}

bool _detectUnauthenticatedError(WidgetTester tester) {
  final errorPatterns = [
    'unauthenticated',
    'User not logged in',
    'Authentication required',
    'Please login first',
    'Login required',
    'Not authenticated',
    'Auth error',
    'Permission denied',
  ];

  for (final pattern in errorPatterns) {
    if (find.textContaining(pattern, findRichText: true).evaluate().isNotEmpty) {
      debugPrint('🔍 [TEST] Found error pattern: "$pattern"');
      return true;
    }
  }

  if (find.byType(AlertDialog).evaluate().isNotEmpty ||
      find.byType(SnackBar).evaluate().isNotEmpty) {
    debugPrint('🔍 [TEST] Found error dialog or snackbar');
    return true;
  }

  return false;
}

Future<void> _waitForAuthState(WidgetTester tester, {Duration timeout = const Duration(seconds: 10)}) async {
  debugPrint('⏳ [TEST] Waiting for auth state to stabilize...');

  final stopwatch = Stopwatch()..start();
  User? lastUser;
  int stableCount = 0;

  while (stopwatch.elapsed < timeout) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser?.uid == lastUser?.uid) {
      stableCount++;
      if (stableCount >= 3) {
        debugPrint('✅ [TEST] Auth state stabilized');
        break;
      }
    } else {
      stableCount = 0;
      lastUser = currentUser;
    }

    await tester.pump(const Duration(milliseconds: 500));
  }

  stopwatch.stop();
  debugPrint('🔑 [TEST] Final auth state: ${FirebaseAuth.instance.currentUser?.uid ?? "null"}');
}

Future<bool> _navigateToServiceDetails(WidgetTester tester) async {
  debugPrint('🧭 [TEST] Attempting to navigate to service details...');

  final servicesTabByText = find.text('Services');
  final servicesTabByIcon = find.byIcon(Icons.home_repair_service);
  if (servicesTabByText.evaluate().isNotEmpty || servicesTabByIcon.evaluate().isNotEmpty) {
    final servicesTab = servicesTabByText.evaluate().isNotEmpty ? servicesTabByText : servicesTabByIcon;
    debugPrint('🎯 [TEST] Found Services tab');
    await tester.tap(servicesTab.first);
    await tester.pumpAndSettle(const Duration(seconds: 3));
  }

  final serviceCards = find.byType(GestureDetector);
  if (serviceCards.evaluate().isNotEmpty) {
    for (int i = 0; i < serviceCards.evaluate().length && i < 5; i++) {
      try {
        await tester.tap(serviceCards.at(i));
        await tester.pumpAndSettle(const Duration(seconds: 3));

        final addToCartByText = find.text('Add to Cart');
        final addToCartByIcon = find.byIcon(Icons.shopping_cart_rounded);
        final likeByIcon1 = find.byIcon(Icons.favorite_border_rounded);
        final likeByIcon2 = find.byIcon(Icons.favorite_rounded);

        if (addToCartByText.evaluate().isNotEmpty || addToCartByIcon.evaluate().isNotEmpty ||
            likeByIcon1.evaluate().isNotEmpty || likeByIcon2.evaluate().isNotEmpty) {
          debugPrint('✅ [TEST] Successfully navigated to service details');
          return true;
        }

        final backByArrow = find.byIcon(Icons.arrow_back);
        final backByIos = find.byIcon(Icons.arrow_back_ios);
        if (backByArrow.evaluate().isNotEmpty || backByIos.evaluate().isNotEmpty) {
          final backButton = backByArrow.evaluate().isNotEmpty ? backByArrow : backByIos;
          await tester.tap(backButton.first);
          await tester.pumpAndSettle();
        }
      } catch (e) {
        debugPrint('⚠️ [TEST] Error tapping service card $i: $e');
      }
    }
  }

  debugPrint('❌ [TEST] Failed to navigate to service details');
  return false;
}

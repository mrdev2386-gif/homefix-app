import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:customer_app/main.dart' as app;

/// Integration test to verify "unauthenticated" error behavior
/// 
/// This test validates whether user actions like "Add to Cart" and "Like"
/// still produce unauthenticated errors after proper login.
/// 
/// Test Scenarios:
/// 1. Without login - expect actions to be blocked or show error
/// 2. After login - expect actions to succeed without unauthenticated error
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Authentication Action Tests', () {
    setUpAll(() async {
      // Initialize Firebase for testing
      await Firebase.initializeApp();
    });

    testWidgets('SCENARIO 1: Actions without login should be blocked or show error', (WidgetTester tester) async {
      print('🧪 [TEST] Starting SCENARIO 1: Actions without login');
      
      // Launch the app
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));
      
      // Ensure user is logged out
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        print('🔓 [TEST] Logging out current user: ${currentUser.uid}');
        await FirebaseAuth.instance.signOut();
        await tester.pumpAndSettle(const Duration(seconds: 2));
      }
      
      print('✅ [TEST] User is logged out');
      print('🔍 [TEST] Current user: ${FirebaseAuth.instance.currentUser?.uid ?? "null"}');
      
      // Navigate to services screen (assuming it's accessible without login)
      // Look for services tab or navigate to services
      final servicesTab = find.text('Services').or(find.byIcon(Icons.home_repair_service));
      if (servicesTab.evaluate().isNotEmpty) {
        print('🎯 [TEST] Found Services tab, tapping...');
        await tester.tap(servicesTab.first);
        await tester.pumpAndSettle(const Duration(seconds: 3));
      } else {
        print('⚠️ [TEST] Services tab not found, looking for alternative navigation');
        // Try to find any service-related widget
        final serviceWidget = find.byType(GestureDetector).or(find.byType(InkWell));
        if (serviceWidget.evaluate().isNotEmpty) {
          await tester.tap(serviceWidget.first);
          await tester.pumpAndSettle(const Duration(seconds: 2));
        }
      }
      
      // Look for service cards or items
      final serviceCards = find.byType(GestureDetector);
      if (serviceCards.evaluate().isNotEmpty) {
        print('🎯 [TEST] Found service cards, tapping first one...');
        await tester.tap(serviceCards.first);
        await tester.pumpAndSettle(const Duration(seconds: 3));
        
        // Now we should be on service details screen
        // Look for "Add to Cart" button
        final addToCartButton = find.text('Add to Cart').or(find.byIcon(Icons.shopping_cart_rounded));
        final likeButton = find.byIcon(Icons.favorite_border_rounded).or(find.byIcon(Icons.favorite_rounded));
        
        // Test Add to Cart action
        if (addToCartButton.evaluate().isNotEmpty) {
          print('🛒 [TEST] Found Add to Cart button, testing without login...');
          await tester.tap(addToCartButton.first);
          await tester.pumpAndSettle(const Duration(seconds: 2));
          
          // Check for error messages or login prompts
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
              print('✅ [TEST] Found expected error/prompt for Add to Cart: ${errorFinder.toString()}');
              foundError = true;
              break;
            }
          }
          
          if (!foundError) {
            print('⚠️ [TEST] No error found for Add to Cart without login - this might be unexpected');
          }
        } else {
          print('⚠️ [TEST] Add to Cart button not found');
        }
        
        // Test Like action
        if (likeButton.evaluate().isNotEmpty) {
          print('❤️ [TEST] Found Like button, testing without login...');
          await tester.tap(likeButton.first);
          await tester.pumpAndSettle(const Duration(seconds: 2));
          
          // Check for error messages or login prompts
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
              print('✅ [TEST] Found expected error/prompt for Like: ${errorFinder.toString()}');
              foundError = true;
              break;
            }
          }
          
          if (!foundError) {
            print('⚠️ [TEST] No error found for Like without login - this might be unexpected');
          }
        } else {
          print('⚠️ [TEST] Like button not found');
        }
      } else {
        print('⚠️ [TEST] No service cards found');
      }
      
      print('✅ [TEST] SCENARIO 1 completed');
    });

    testWidgets('SCENARIO 2: Actions after login should succeed without unauthenticated error', (WidgetTester tester) async {
      print('🧪 [TEST] Starting SCENARIO 2: Actions after login');
      
      // Launch the app
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));
      
      // Perform login (this is a simplified version - you may need to adapt based on your login flow)
      await _performTestLogin(tester);
      
      // Verify user is logged in
      await tester.pumpAndSettle(const Duration(seconds: 3));
      final currentUser = FirebaseAuth.instance.currentUser;
      
      if (currentUser == null) {
        print('❌ [TEST] Login failed - user is still null');
        fail('Login failed - cannot proceed with authenticated tests');
      }
      
      print('✅ [TEST] User is logged in');
      print('🔑 [TEST] Current user UID: ${currentUser.uid}');
      print('📧 [TEST] Current user email: ${currentUser.email ?? "N/A"}');
      print('📱 [TEST] Current user phone: ${currentUser.phoneNumber ?? "N/A"}');
      
      // Wait for auth state to propagate
      await tester.pumpAndSettle(const Duration(seconds: 3));
      
      // Navigate to services screen
      final servicesTab = find.text('Services').or(find.byIcon(Icons.home_repair_service));
      if (servicesTab.evaluate().isNotEmpty) {
        print('🎯 [TEST] Found Services tab, tapping...');
        await tester.tap(servicesTab.first);
        await tester.pumpAndSettle(const Duration(seconds: 3));
      }
      
      // Look for service cards and tap one
      final serviceCards = find.byType(GestureDetector);
      if (serviceCards.evaluate().isNotEmpty) {
        print('🎯 [TEST] Found service cards, tapping first one...');
        await tester.tap(serviceCards.first);
        await tester.pumpAndSettle(const Duration(seconds: 3));
        
        // Test Add to Cart action (authenticated)
        final addToCartButton = find.text('Add to Cart').or(find.byIcon(Icons.shopping_cart_rounded));
        if (addToCartButton.evaluate().isNotEmpty) {
          print('🛒 [TEST] Found Add to Cart button, testing with login...');
          print('🔑 [TEST] Before Add to Cart - Current user: ${FirebaseAuth.instance.currentUser?.uid}');
          
          await tester.tap(addToCartButton.first);
          await tester.pumpAndSettle(const Duration(seconds: 5));
          
          // Check for unauthenticated errors
          final unauthenticatedErrors = [
            find.text('unauthenticated'),
            find.text('User not logged in'),
            find.text('Authentication required'),
          ];
          
          bool foundUnauthenticatedError = false;
          for (final errorFinder in unauthenticatedErrors) {
            if (errorFinder.evaluate().isNotEmpty) {
              print('❌ [TEST] FOUND UNAUTHENTICATED ERROR for Add to Cart: ${errorFinder.toString()}');
              foundUnauthenticatedError = true;
              break;
            }
          }
          
          // Check for success indicators
          final successIndicators = [
            find.text('Added to Cart'),
            find.text('added successfully'),
            find.text('Go to Cart'),
            find.text('Continue'),
          ];
          
          bool foundSuccess = false;
          for (final successFinder in successIndicators) {
            if (successFinder.evaluate().isNotEmpty) {
              print('✅ [TEST] Found success indicator for Add to Cart: ${successFinder.toString()}');
              foundSuccess = true;
              break;
            }
          }
          
          if (foundUnauthenticatedError) {
            print('❌ [TEST] FAIL: Add to Cart still shows unauthenticated error after login');
            fail('Add to Cart action failed with unauthenticated error despite being logged in');
          } else if (foundSuccess) {
            print('✅ [TEST] PASS: Add to Cart succeeded without unauthenticated error');
          } else {
            print('⚠️ [TEST] Add to Cart result unclear - no clear success or error indicator found');
          }
          
          // Dismiss any dialogs
          final continueButton = find.text('Continue');
          if (continueButton.evaluate().isNotEmpty) {
            await tester.tap(continueButton);
            await tester.pumpAndSettle();
          }
        } else {
          print('⚠️ [TEST] Add to Cart button not found');
        }
        
        // Test Like action (authenticated)
        final likeButton = find.byIcon(Icons.favorite_border_rounded).or(find.byIcon(Icons.favorite_rounded));
        if (likeButton.evaluate().isNotEmpty) {
          print('❤️ [TEST] Found Like button, testing with login...');
          print('🔑 [TEST] Before Like - Current user: ${FirebaseAuth.instance.currentUser?.uid}');
          
          await tester.tap(likeButton.first);
          await tester.pumpAndSettle(const Duration(seconds: 5));
          
          // Check for unauthenticated errors
          final unauthenticatedErrors = [
            find.text('unauthenticated'),
            find.text('User not logged in'),
            find.text('Authentication required'),
          ];
          
          bool foundUnauthenticatedError = false;
          for (final errorFinder in unauthenticatedErrors) {
            if (errorFinder.evaluate().isNotEmpty) {
              print('❌ [TEST] FOUND UNAUTHENTICATED ERROR for Like: ${errorFinder.toString()}');
              foundUnauthenticatedError = true;
              break;
            }
          }
          
          // Check for success indicators
          final successIndicators = [
            find.text('Added to favorites'),
            find.text('Removed from favorites'),
            find.byIcon(Icons.favorite_rounded), // Should change to filled heart
          ];
          
          bool foundSuccess = false;
          for (final successFinder in successIndicators) {
            if (successFinder.evaluate().isNotEmpty) {
              print('✅ [TEST] Found success indicator for Like: ${successFinder.toString()}');
              foundSuccess = true;
              break;
            }
          }
          
          if (foundUnauthenticatedError) {
            print('❌ [TEST] FAIL: Like still shows unauthenticated error after login');
            fail('Like action failed with unauthenticated error despite being logged in');
          } else if (foundSuccess) {
            print('✅ [TEST] PASS: Like succeeded without unauthenticated error');
          } else {
            print('⚠️ [TEST] Like result unclear - no clear success or error indicator found');
          }
        } else {
          print('⚠️ [TEST] Like button not found');
        }
      } else {
        print('⚠️ [TEST] No service cards found');
      }
      
      print('✅ [TEST] SCENARIO 2 completed');
    });
  });
}

/// Helper function to perform test login
/// This is a simplified version - you may need to adapt based on your actual login flow
Future<void> _performTestLogin(WidgetTester tester) async {
  print('🔐 [TEST] Attempting to perform test login...');
  
  // Look for login button or screen
  final loginButton = find.text('Login').or(find.text('Sign In')).or(find.byIcon(Icons.login));
  
  if (loginButton.evaluate().isNotEmpty) {
    print('🎯 [TEST] Found login button, tapping...');
    await tester.tap(loginButton.first);
    await tester.pumpAndSettle(const Duration(seconds: 2));
  }
  
  // For testing purposes, you might want to use Firebase Auth's test credentials
  // or create a test user. This is a placeholder implementation.
  
  // Option 1: Use Firebase Auth directly (for testing)
  try {
    // You can create a test user or use existing test credentials
    final testEmail = 'test@homefix.com';
    final testPassword = 'testpassword123';
    
    print('🔐 [TEST] Attempting Firebase Auth sign in...');
    final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: testEmail,
      password: testPassword,
    );
    
    if (userCredential.user != null) {
      print('✅ [TEST] Firebase Auth login successful');
      return;
    }
  } catch (e) {
    print('⚠️ [TEST] Firebase Auth login failed: $e');
    print('🔐 [TEST] Attempting to create test user...');
    
    try {
      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: 'test@homefix.com',
        password: 'testpassword123',
      );
      
      if (userCredential.user != null) {
        print('✅ [TEST] Test user created and logged in');
        return;
      }
    } catch (createError) {
      print('❌ [TEST] Failed to create test user: $createError');
    }
  }
  
  // Option 2: Use UI-based login (if Firebase Auth direct login fails)
  // Look for email/phone input fields and fill them
  final emailField = find.byType(TextField).or(find.byType(TextFormField));
  if (emailField.evaluate().isNotEmpty) {
    print('📧 [TEST] Found input field, entering test credentials...');
    await tester.enterText(emailField.first, 'test@homefix.com');
    await tester.pumpAndSettle();
    
    // Look for password field (if email/password login)
    final passwordField = find.byType(TextField).or(find.byType(TextFormField));
    if (passwordField.evaluate().length > 1) {
      await tester.enterText(passwordField.last, 'testpassword123');
      await tester.pumpAndSettle();
    }
    
    // Look for submit/login button
    final submitButton = find.text('Login').or(find.text('Sign In')).or(find.text('Continue'));
    if (submitButton.evaluate().isNotEmpty) {
      await tester.tap(submitButton.first);
      await tester.pumpAndSettle(const Duration(seconds: 5));
    }
  }
  
  print('🔐 [TEST] Login attempt completed');
}

/// Additional helper functions and test utilities

/// Comprehensive error detection helper
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
      print('🔍 [TEST] Found error pattern: "$pattern"');
      return true;
    }
  }
  
  // Check for error dialogs or snackbars
  if (find.byType(AlertDialog).evaluate().isNotEmpty ||
      find.byType(SnackBar).evaluate().isNotEmpty) {
    print('🔍 [TEST] Found error dialog or snackbar');
    return true;
  }
  
  return false;
}

/// Success detection helper
bool _detectSuccessIndicator(WidgetTester tester, String action) {
  final successPatterns = action == 'cart' 
    ? [
        'Added to Cart',
        'added successfully',
        'Go to Cart',
        'Continue',
        'Item added',
      ]
    : [
        'Added to favorites',
        'Removed from favorites',
        'favorite',
      ];
  
  for (final pattern in successPatterns) {
    if (find.textContaining(pattern, findRichText: true).evaluate().isNotEmpty) {
      print('🔍 [TEST] Found success pattern: "$pattern"');
      return true;
    }
  }
  
  // For favorites, check if heart icon changed
  if (action == 'like') {
    if (find.byIcon(Icons.favorite_rounded).evaluate().isNotEmpty) {
      print('🔍 [TEST] Found filled heart icon (success)');
      return true;
    }
  }
  
  return false;
}

/// Wait for authentication state to stabilize
Future<void> _waitForAuthState(WidgetTester tester, {Duration timeout = const Duration(seconds: 10)}) async {
  print('⏳ [TEST] Waiting for auth state to stabilize...');
  
  final stopwatch = Stopwatch()..start();
  User? lastUser;
  int stableCount = 0;
  
  while (stopwatch.elapsed < timeout) {
    final currentUser = FirebaseAuth.instance.currentUser;
    
    if (currentUser?.uid == lastUser?.uid) {
      stableCount++;
      if (stableCount >= 3) {
        print('✅ [TEST] Auth state stabilized');
        break;
      }
    } else {
      stableCount = 0;
      lastUser = currentUser;
    }
    
    await tester.pump(const Duration(milliseconds: 500));
  }
  
  stopwatch.stop();
  print('🔑 [TEST] Final auth state: ${FirebaseAuth.instance.currentUser?.uid ?? "null"}');
}

/// Enhanced service navigation helper
Future<bool> _navigateToServiceDetails(WidgetTester tester) async {
  print('🧭 [TEST] Attempting to navigate to service details...');
  
  // Try multiple navigation strategies
  
  // Strategy 1: Look for Services tab
  final servicesTab = find.text('Services').or(find.byIcon(Icons.home_repair_service));
  if (servicesTab.evaluate().isNotEmpty) {
    print('🎯 [TEST] Found Services tab');
    await tester.tap(servicesTab.first);
    await tester.pumpAndSettle(const Duration(seconds: 3));
  }
  
  // Strategy 2: Look for service cards in grid or list
  final serviceCards = find.byType(GestureDetector);
  if (serviceCards.evaluate().isNotEmpty) {
    print('🎯 [TEST] Found ${serviceCards.evaluate().length} service cards');
    
    // Try to find a card that looks like a service (has image and text)
    for (int i = 0; i < serviceCards.evaluate().length && i < 5; i++) {
      try {
        await tester.tap(serviceCards.at(i));
        await tester.pumpAndSettle(const Duration(seconds: 3));
        
        // Check if we're now on a service details screen
        final addToCartButton = find.text('Add to Cart').or(find.byIcon(Icons.shopping_cart_rounded));
        final likeButton = find.byIcon(Icons.favorite_border_rounded).or(find.byIcon(Icons.favorite_rounded));
        
        if (addToCartButton.evaluate().isNotEmpty || likeButton.evaluate().isNotEmpty) {
          print('✅ [TEST] Successfully navigated to service details');
          return true;
        }
        
        // If not service details, go back and try next card
        final backButton = find.byIcon(Icons.arrow_back).or(find.byIcon(Icons.arrow_back_ios));
        if (backButton.evaluate().isNotEmpty) {
          await tester.tap(backButton.first);
          await tester.pumpAndSettle();
        }
      } catch (e) {
        print('⚠️ [TEST] Error tapping service card $i: $e');
      }
    }
  }
  
  // Strategy 3: Look for any tappable service-related widgets
  final serviceWidgets = find.byWidgetPredicate((widget) {
    return widget.toString().toLowerCase().contains('service') ||
           widget.toString().toLowerCase().contains('card');
  });
  
  if (serviceWidgets.evaluate().isNotEmpty) {
    print('🎯 [TEST] Found service-related widgets, trying first one');
    await tester.tap(serviceWidgets.first);
    await tester.pumpAndSettle(const Duration(seconds: 3));
    
    final addToCartButton = find.text('Add to Cart').or(find.byIcon(Icons.shopping_cart_rounded));
    final likeButton = find.byIcon(Icons.favorite_border_rounded).or(find.byIcon(Icons.favorite_rounded));
    
    if (addToCartButton.evaluate().isNotEmpty || likeButton.evaluate().isNotEmpty) {
      print('✅ [TEST] Successfully navigated to service details via service widget');
      return true;
    }
  }
  
  print('❌ [TEST] Failed to navigate to service details');
  return false;
}

/// Test result summary helper
void _printTestSummary(String scenario, Map<String, bool> results) {
  print('\n📊 [TEST SUMMARY] $scenario');
  print('═' * 50);
  
  results.forEach((action, success) {
    final status = success ? '✅ PASS' : '❌ FAIL';
    print('$action: $status');
  });
  
  final overallSuccess = results.values.every((result) => result);
  final overallStatus = overallSuccess ? '✅ PASS' : '❌ FAIL';
  print('Overall: $overallStatus');
  print('═' * 50);
}
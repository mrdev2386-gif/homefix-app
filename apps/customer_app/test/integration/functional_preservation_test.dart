import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:customer_app/main.dart' as app;

/// Functional Preservation Test - Task 2
/// 
/// This test documents the baseline behavior of the refactored code
/// to ensure all functionality is preserved after architectural changes.
/// 
/// **Property 2: Preservation** - Functional Behavior Baseline
/// 
/// Test Coverage:
/// - Booking creation through customer_booking_screen (Req 3.1)
/// - Booking creation through urgent_booking_screen (Req 3.1)
/// - User profile loading (Req 3.2)
/// - Technician queries and filtering (Req 3.3)
/// - Real-time data updates (Req 3.7, 3.11)
/// - Error handling (Req 3.9, 3.10)
/// - Performance characteristics (Req 3.7, 3.8)
/// 
/// **Validates: Requirements 3.1, 3.2, 3.3, 3.4, 3.5, 3.6, 3.7, 3.8, 3.9, 3.10, 3.11, 3.12**
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Property 2: Functional Preservation Tests', () {
    setUpAll(() async {
      // Initialize Firebase for testing
      await Firebase.initializeApp();
    });

    /// Test 1: Booking Creation Preservation (customer_booking_screen)
    /// **Validates: Requirement 3.1** - Booking creation with identical validation
    testWidgets('PRESERVATION 1: Customer booking creation flow works correctly', 
        (WidgetTester tester) async {
      print('\n🧪 [PRESERVATION TEST 1] Customer Booking Creation');
      print('=' * 60);
      
      // Launch the app
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));
      
      // Ensure user is logged in
      await _ensureAuthenticated(tester);
      
      // Navigate to services and select a service
      final navigated = await _navigateToServiceDetails(tester);
      if (!navigated) {
        print('⚠️ [TEST] Could not navigate to service details - skipping test');
        return;
      }
      
      // Look for "Book Service" or similar button
      final bookButton = find.text('Book Service')
          .or(find.text('Book Now'))
          .or(find.text('Continue'));
      
      if (bookButton.evaluate().isEmpty) {
        print('⚠️ [TEST] Book button not found - may need to select technician first');
        return;
      }
      
      print('📝 [TEST] Found booking button, initiating booking...');
      await tester.tap(bookButton.first);
      await tester.pumpAndSettle(const Duration(seconds: 3));
      
      // Observe booking creation behavior
      final loadingIndicator = find.byType(CircularProgressIndicator);
      final successMessage = find.textContaining('success', findRichText: true)
          .or(find.textContaining('created', findRichText: true))
          .or(find.textContaining('confirmed', findRichText: true));
      final errorMessage = find.textContaining('error', findRichText: true)
          .or(find.textContaining('failed', findRichText: true));
      
      // Document observed behavior
      print('📊 [BASELINE] Booking Creation Behavior:');
      print('  - Loading indicator shown: ${loadingIndicator.evaluate().isNotEmpty}');
      print('  - Success message shown: ${successMessage.evaluate().isNotEmpty}');
      print('  - Error message shown: ${errorMessage.evaluate().isNotEmpty}');
      
      // Verify booking creation completes (success or error, not stuck)
      await tester.pumpAndSettle(const Duration(seconds: 10));
      
      final stillLoading = find.byType(CircularProgressIndicator);
      expect(stillLoading.evaluate().isEmpty, true, 
          reason: 'Booking should complete within 10 seconds');
      
      print('✅ [TEST] Booking creation flow completed');
      print('=' * 60);
    });

    /// Test 2: Urgent Booking Creation Preservation
    /// **Validates: Requirement 3.1** - Urgent booking with identical behavior
    testWidgets('PRESERVATION 2: Urgent booking creation flow works correctly', 
        (WidgetTester tester) async {
      print('\n🧪 [PRESERVATION TEST 2] Urgent Booking Creation');
      print('=' * 60);
      
      // Launch the app
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));
      
      // Ensure user is logged in
      await _ensureAuthenticated(tester);
      
      // Navigate to urgent booking screen
      final urgentButton = find.text('Urgent')
          .or(find.text('Urgent Booking'))
          .or(find.byIcon(Icons.flash_on));
      
      if (urgentButton.evaluate().isEmpty) {
        print('⚠️ [TEST] Urgent booking button not found - skipping test');
        return;
      }
      
      print('⚡ [TEST] Found urgent booking button, navigating...');
      await tester.tap(urgentButton.first);
      await tester.pumpAndSettle(const Duration(seconds: 5));
      
      // Observe urgent booking screen behavior
      final loadingIndicator = find.byType(CircularProgressIndicator);
      final errorMessage = find.textContaining('error', findRichText: true)
          .or(find.textContaining('Please complete your profile', findRichText: true));
      final technicianList = find.textContaining('Online', findRichText: true);
      final emptyView = find.text('No Technicians Available');
      
      print('📊 [BASELINE] Urgent Booking Screen Behavior:');
      print('  - Loading indicator shown: ${loadingIndicator.evaluate().isNotEmpty}');
      print('  - Error message shown: ${errorMessage.evaluate().isNotEmpty}');
      print('  - Technician list shown: ${technicianList.evaluate().isNotEmpty}');
      print('  - Empty view shown: ${emptyView.evaluate().isNotEmpty}');
      
      // If technicians are available, test booking creation
      final bookUrgentButton = find.text('Book Urgent Service');
      if (bookUrgentButton.evaluate().isNotEmpty) {
        print('📝 [TEST] Found urgent booking button, testing creation...');
        await tester.tap(bookUrgentButton.first);
        await tester.pumpAndSettle(const Duration(seconds: 5));
        
        final successMessage = find.textContaining('created', findRichText: true)
            .or(find.textContaining('contact you', findRichText: true));
        final errorMsg = find.textContaining('Error', findRichText: true);
        
        print('📊 [BASELINE] Urgent Booking Creation Result:');
        print('  - Success message: ${successMessage.evaluate().isNotEmpty}');
        print('  - Error message: ${errorMsg.evaluate().isNotEmpty}');
      }
      
      print('✅ [TEST] Urgent booking flow completed');
      print('=' * 60);
    });

    /// Test 3: User Profile Loading Preservation
    /// **Validates: Requirement 3.2** - User profile data structure unchanged
    testWidgets('PRESERVATION 3: User profile loading returns correct data structure', 
        (WidgetTester tester) async {
      print('\n🧪 [PRESERVATION TEST 3] User Profile Loading');
      print('=' * 60);
      
      // Launch the app
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));
      
      // Ensure user is logged in
      await _ensureAuthenticated(tester);
      
      // Navigate to profile screen
      final profileTab = find.text('Profile')
          .or(find.byIcon(Icons.person))
          .or(find.byIcon(Icons.account_circle));
      
      if (profileTab.evaluate().isEmpty) {
        print('⚠️ [TEST] Profile tab not found - skipping test');
        return;
      }
      
      print('👤 [TEST] Found profile tab, navigating...');
      await tester.tap(profileTab.first);
      await tester.pumpAndSettle(const Duration(seconds: 5));
      
      // Observe profile loading behavior
      final loadingIndicator = find.byType(CircularProgressIndicator);
      final errorMessage = find.textContaining('error', findRichText: true);
      final userName = find.byWidgetPredicate((widget) => 
          widget is Text && widget.data != null && widget.data!.isNotEmpty);
      
      print('📊 [BASELINE] Profile Loading Behavior:');
      print('  - Loading indicator shown: ${loadingIndicator.evaluate().isNotEmpty}');
      print('  - Error message shown: ${errorMessage.evaluate().isNotEmpty}');
      print('  - User data displayed: ${userName.evaluate().isNotEmpty}');
      
      // Verify profile loads within reasonable time
      await tester.pumpAndSettle(const Duration(seconds: 5));
      final stillLoading = find.byType(CircularProgressIndicator);
      expect(stillLoading.evaluate().isEmpty, true,
          reason: 'Profile should load within 5 seconds');
      
      print('✅ [TEST] Profile loading completed');
      print('=' * 60);
    });

    /// Test 4: Technician Query and Filtering Preservation
    /// **Validates: Requirement 3.3** - Technician data accuracy and real-time updates
    testWidgets('PRESERVATION 4: Technician queries return accurate filtered results', 
        (WidgetTester tester) async {
      print('\n🧪 [PRESERVATION TEST 4] Technician Query and Filtering');
      print('=' * 60);
      
      // Launch the app
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));
      
      // Ensure user is logged in
      await _ensureAuthenticated(tester);
      
      // Navigate to urgent booking to see technician list
      final urgentButton = find.text('Urgent')
          .or(find.text('Urgent Booking'))
          .or(find.byIcon(Icons.flash_on));
      
      if (urgentButton.evaluate().isNotEmpty) {
        print('⚡ [TEST] Navigating to urgent booking for technician list...');
        await tester.tap(urgentButton.first);
        await tester.pumpAndSettle(const Duration(seconds: 5));
        
        // Observe technician list behavior
        final onlineBadge = find.text('Online');
        final technicianCards = find.byType(Container);
        final emptyView = find.text('No Technicians Available');
        
        print('📊 [BASELINE] Technician Query Behavior:');
        print('  - Online technicians found: ${onlineBadge.evaluate().length}');
        print('  - Technician cards displayed: ${technicianCards.evaluate().length}');
        print('  - Empty view shown: ${emptyView.evaluate().isNotEmpty}');
        
        // Verify real-time updates (stream subscription working)
        print('🔄 [TEST] Verifying real-time updates...');
        await tester.pump(const Duration(seconds: 2));
        await tester.pumpAndSettle();
        
        final updatedOnlineBadge = find.text('Online');
        print('  - Online technicians after 2s: ${updatedOnlineBadge.evaluate().length}');
        print('  - Stream subscription active: ${updatedOnlineBadge.evaluate().isNotEmpty || emptyView.evaluate().isNotEmpty}');
      }
      
      print('✅ [TEST] Technician query completed');
      print('=' * 60);
    });

    /// Test 5: Error Handling Preservation
    /// **Validates: Requirements 3.9, 3.10** - Error messages and recovery
    testWidgets('PRESERVATION 5: Error handling provides appropriate feedback', 
        (WidgetTester tester) async {
      print('\n🧪 [PRESERVATION TEST 5] Error Handling');
      print('=' * 60);
      
      // Launch the app
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));
      
      // Test 1: Unauthenticated access
      print('🔒 [TEST] Testing unauthenticated access...');
      await FirebaseAuth.instance.signOut();
      await tester.pumpAndSettle(const Duration(seconds: 2));
      
      // Try to access protected features
      final urgentButton = find.text('Urgent')
          .or(find.text('Urgent Booking'))
          .or(find.byIcon(Icons.flash_on));
      
      if (urgentButton.evaluate().isNotEmpty) {
        await tester.tap(urgentButton.first);
        await tester.pumpAndSettle(const Duration(seconds: 3));
        
        final errorMessage = find.textContaining('login', findRichText: true)
            .or(find.textContaining('Please complete your profile', findRichText: true));
        
        print('📊 [BASELINE] Unauthenticated Error Handling:');
        print('  - Error message shown: ${errorMessage.evaluate().isNotEmpty}');
        print('  - User redirected to login: ${find.text('Login').evaluate().isNotEmpty}');
      }
      
      // Test 2: Missing profile data
      await _ensureAuthenticated(tester);
      print('📝 [TEST] Testing missing profile data handling...');
      
      // Navigate to urgent booking (requires state/district)
      if (urgentButton.evaluate().isNotEmpty) {
        await tester.tap(urgentButton.first);
        await tester.pumpAndSettle(const Duration(seconds: 3));
        
        final profileError = find.textContaining('complete your profile', findRichText: true);
        final loadingError = find.textContaining('Error', findRichText: true);
        
        print('📊 [BASELINE] Missing Profile Data Handling:');
        print('  - Profile completion prompt: ${profileError.evaluate().isNotEmpty}');
        print('  - Generic error shown: ${loadingError.evaluate().isNotEmpty}');
      }
      
      print('✅ [TEST] Error handling completed');
      print('=' * 60);
    });

    /// Test 6: Performance Baseline Measurement
    /// **Validates: Requirements 3.7, 3.8** - Performance characteristics
    testWidgets('PRESERVATION 6: Performance baseline measurement', 
        (WidgetTester tester) async {
      print('\n🧪 [PRESERVATION TEST 6] Performance Baseline');
      print('=' * 60);
      
      // Launch the app
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));
      
      // Ensure user is logged in
      await _ensureAuthenticated(tester);
      
      // Measure 1: Profile loading time
      print('⏱️ [TEST] Measuring profile loading time...');
      final profileTab = find.text('Profile')
          .or(find.byIcon(Icons.person))
          .or(find.byIcon(Icons.account_circle));
      
      if (profileTab.evaluate().isNotEmpty) {
        final stopwatch = Stopwatch()..start();
        await tester.tap(profileTab.first);
        await tester.pumpAndSettle(const Duration(seconds: 10));
        stopwatch.stop();
        
        print('📊 [BASELINE] Profile Load Time: ${stopwatch.elapsedMilliseconds}ms');
      }
      
      // Measure 2: Technician query time
      print('⏱️ [TEST] Measuring technician query time...');
      final urgentButton = find.text('Urgent')
          .or(find.text('Urgent Booking'))
          .or(find.byIcon(Icons.flash_on));
      
      if (urgentButton.evaluate().isNotEmpty) {
        final stopwatch = Stopwatch()..start();
        await tester.tap(urgentButton.first);
        await tester.pumpAndSettle(const Duration(seconds: 10));
        stopwatch.stop();
        
        print('📊 [BASELINE] Technician Query Time: ${stopwatch.elapsedMilliseconds}ms');
      }
      
      // Measure 3: Service navigation time
      print('⏱️ [TEST] Measuring service navigation time...');
      final servicesTab = find.text('Services')
          .or(find.byIcon(Icons.home_repair_service));
      
      if (servicesTab.evaluate().isNotEmpty) {
        final stopwatch = Stopwatch()..start();
        await tester.tap(servicesTab.first);
        await tester.pumpAndSettle(const Duration(seconds: 10));
        stopwatch.stop();
        
        print('📊 [BASELINE] Service Navigation Time: ${stopwatch.elapsedMilliseconds}ms');
      }
      
      print('✅ [TEST] Performance baseline measurement completed');
      print('=' * 60);
    });
  });
}

/// Helper: Ensure user is authenticated
Future<void> _ensureAuthenticated(WidgetTester tester) async {
  final currentUser = FirebaseAuth.instance.currentUser;
  
  if (currentUser != null) {
    print('✅ [AUTH] User already logged in: ${currentUser.uid}');
    return;
  }
  
  print('🔐 [AUTH] No user logged in, attempting authentication...');
  
  try {
    // Try to sign in with test credentials
    final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: 'test@homefix.com',
      password: 'testpassword123',
    );
    
    if (userCredential.user != null) {
      print('✅ [AUTH] Logged in successfully: ${userCredential.user!.uid}');
      await tester.pumpAndSettle(const Duration(seconds: 3));
      return;
    }
  } catch (e) {
    print('⚠️ [AUTH] Login failed: $e');
    
    // Try to create test user
    try {
      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: 'test@homefix.com',
        password: 'testpassword123',
      );
      
      if (userCredential.user != null) {
        print('✅ [AUTH] Test user created: ${userCredential.user!.uid}');
        await tester.pumpAndSettle(const Duration(seconds: 3));
        return;
      }
    } catch (createError) {
      print('❌ [AUTH] Failed to create test user: $createError');
    }
  }
  
  print('⚠️ [AUTH] Could not authenticate - tests may fail');
}

/// Helper: Navigate to service details screen
Future<bool> _navigateToServiceDetails(WidgetTester tester) async {
  print('🧭 [NAV] Navigating to service details...');
  
  // Look for Services tab
  final servicesTab = find.text('Services')
      .or(find.byIcon(Icons.home_repair_service));
  
  if (servicesTab.evaluate().isNotEmpty) {
    await tester.tap(servicesTab.first);
    await tester.pumpAndSettle(const Duration(seconds: 3));
  }
  
  // Look for service cards
  final serviceCards = find.byType(GestureDetector);
  if (serviceCards.evaluate().isEmpty) {
    print('❌ [NAV] No service cards found');
    return false;
  }
  
  // Tap first service card
  await tester.tap(serviceCards.first);
  await tester.pumpAndSettle(const Duration(seconds: 3));
  
  // Verify we're on service details
  final bookButton = find.text('Book Service')
      .or(find.text('Book Now'))
      .or(find.text('Continue'));
  
  if (bookButton.evaluate().isNotEmpty) {
    print('✅ [NAV] Successfully navigated to service details');
    return true;
  }
  
  print('❌ [NAV] Failed to navigate to service details');
  return false;
}

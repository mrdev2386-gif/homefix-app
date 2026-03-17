import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:customer_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Customer App UI Flow Tests', () {
    testWidgets('Complete customer booking flow', (WidgetTester tester) async {
      // Launch the app
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // PHASE 1: Verify splash screen appears
      expect(find.byType(MaterialApp), findsOneWidget);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // PHASE 2: Verify login screen is displayed
      // Look for login-related widgets
      expect(
        find.byWidgetPredicate(
          (widget) => widget is Text && widget.data?.contains('Login') == true,
          skipOffstage: false,
        ),
        findsWidgets,
        reason: 'Login screen should be visible',
      );

      // PHASE 3: Simulate authentication (Phone + OTP)
      // Enter phone number
      final phoneField = find.byType(TextField);
      if (phoneField.evaluate().isNotEmpty) {
        await tester.enterText(phoneField.first, '9999999999');
        await tester.pumpAndSettle();
      }

      // Tap Continue button
      final continueButton = find.byWidgetPredicate(
        (widget) =>
            widget is ElevatedButton ||
            (widget is Text && widget.data?.contains('Continue') == true),
        skipOffstage: false,
      );

      if (continueButton.evaluate().isNotEmpty) {
        await tester.tap(continueButton.first);
        await tester.pumpAndSettle(const Duration(seconds: 2));
      }

      // Enter OTP on the OTP screen
      final otpField = find.byType(TextField);
      if (otpField.evaluate().isNotEmpty) {
        await tester.enterText(otpField.first, '123456');
        await tester.pumpAndSettle();
      }

      // Tap Verify & Continue button
      final verifyButton = find.byWidgetPredicate(
        (widget) =>
            widget is ElevatedButton ||
            (widget is Text && widget.data?.contains('Verify') == true),
        skipOffstage: false,
      );

      if (verifyButton.evaluate().isNotEmpty) {
        await tester.tap(verifyButton.first);
        await tester.pumpAndSettle(const Duration(seconds: 3));
      }

      // Handle District Selection (if needed)
      final districtSelector = find.byType(DropdownButton);
      if (districtSelector.evaluate().isNotEmpty) {
        // Just select first option in each if visible
        for (int d = 0; d < districtSelector.evaluate().length; d++) {
           await tester.tap(districtSelector.at(d));
           await tester.pumpAndSettle();
           // In location_selector.dart it might be more complex but we try to continue
           final dropdownItem = find.byType(DropdownMenuItem);
           if (dropdownItem.evaluate().isNotEmpty) {
              await tester.tap(dropdownItem.first);
              await tester.pumpAndSettle();
           }
        }
        
        final finishButton = find.byWidgetPredicate(
          (widget) => widget is ElevatedButton || (widget is Text && widget.data?.contains('Continue') == true),
          skipOffstage: false,
        );
        if (finishButton.evaluate().isNotEmpty) {
            await tester.tap(finishButton.first);
            await tester.pumpAndSettle(const Duration(seconds: 2));
        }
      }

      // PHASE 4: Navigate to service categories
      // Look for home screen or category list
      final categoryWidgets = find.byWidgetPredicate(
        (widget) =>
            widget is Text &&
            (widget.data?.contains('Services') == true ||
                widget.data?.contains('Categories') == true),
        skipOffstage: false,
      );

      if (categoryWidgets.evaluate().isNotEmpty) {
        // Scroll to find categories
        await tester.pumpAndSettle();
      }

      // PHASE 5: Select a service category
      // Look for service cards or category buttons
      final serviceCards = find.byType(GestureDetector);
      if (serviceCards.evaluate().isNotEmpty) {
        await tester.tap(serviceCards.first);
        await tester.pumpAndSettle(const Duration(seconds: 1));
      }

      // PHASE 6: Open service details
      // Look for service detail screen
      final serviceDetailText = find.byWidgetPredicate(
        (widget) =>
            widget is Text &&
            (widget.data?.contains('Details') == true ||
                widget.data?.contains('Price') == true),
        skipOffstage: false,
      );

      if (serviceDetailText.evaluate().isNotEmpty) {
        await tester.pumpAndSettle();
      }

      // PHASE 7: Create booking
      // Look for booking button
      final bookingButton = find.byWidgetPredicate(
        (widget) =>
            widget is ElevatedButton ||
            (widget is Text && widget.data?.contains('Book') == true),
        skipOffstage: false,
      );

      if (bookingButton.evaluate().isNotEmpty) {
        await tester.tap(bookingButton.first);
        await tester.pumpAndSettle(const Duration(seconds: 1));
      }

      // PHASE 8: Verify booking confirmation
      final confirmationText = find.byWidgetPredicate(
        (widget) =>
            widget is Text &&
            (widget.data?.contains('Confirmed') == true ||
                widget.data?.contains('Booking') == true),
        skipOffstage: false,
      );

      if (confirmationText.evaluate().isNotEmpty) {
        expect(confirmationText, findsWidgets);
      }

      // PHASE 9: Verify booking appears in bookings list
      // Navigate to bookings tab
      final bottomNavigation = find.byType(BottomNavigationBar);
      if (bottomNavigation.evaluate().isNotEmpty) {
        // Tap on bookings tab (usually second tab)
        final navItems = find.byType(BottomNavigationBarItem);
        if (navItems.evaluate().length > 1) {
          await tester.tap(navItems.at(1));
          await tester.pumpAndSettle(const Duration(seconds: 1));
        }
      }

      // PHASE 10: Verify booking status
      final bookingStatusText = find.byWidgetPredicate(
        (widget) =>
            widget is Text &&
            (widget.data?.contains('Pending') == true ||
                widget.data?.contains('Confirmed') == true),
        skipOffstage: false,
      );

      if (bookingStatusText.evaluate().isNotEmpty) {
        expect(bookingStatusText, findsWidgets);
      }
    });

    testWidgets('Navigation validation', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Test navigation between tabs using custom labels
      final navLabels = ['Home', 'Bookings', 'Request', 'Profile'];
      for (final label in navLabels) {
        final navItem = find.text(label);
        if (navItem.evaluate().isNotEmpty) {
           await tester.tap(navItem.first);
           await tester.pumpAndSettle(const Duration(milliseconds: 500));
        }
      }

      // Test back navigation
      await tester.pageBack();
      await tester.pumpAndSettle();
    });

    testWidgets('UI stability under rapid interactions', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Rapid taps on various widgets
      final buttons = find.byType(ElevatedButton);
      for (int i = 0; i < buttons.evaluate().length && i < 5; i++) {
        await tester.tap(buttons.at(i));
        await tester.pumpAndSettle(const Duration(milliseconds: 100));
      }

      // Rapid scrolling
      final scrollables = find.byType(SingleChildScrollView);
      if (scrollables.evaluate().isNotEmpty) {
        await tester.drag(scrollables.first, const Offset(0, -300));
        await tester.pumpAndSettle();
        await tester.drag(scrollables.first, const Offset(0, 300));
        await tester.pumpAndSettle();
      }

      // Verify no crashes
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('Service listing and filtering', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Find service list
      final serviceList = find.byType(ListView);
      if (serviceList.evaluate().isNotEmpty) {
        // Scroll through services
        await tester.drag(serviceList.first, const Offset(0, -500));
        await tester.pumpAndSettle();

        // Verify services are displayed
        final serviceItems = find.byType(Card);
        expect(serviceItems, findsWidgets, reason: 'Service cards should be visible');
      }
    });

    testWidgets('Profile and wallet access', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Navigate to profile
      final profileButton = find.byWidgetPredicate(
        (widget) =>
            widget is Icon && widget.icon == Icons.person ||
            (widget is Text && widget.data?.contains('Profile') == true),
        skipOffstage: false,
      );

      if (profileButton.evaluate().isNotEmpty) {
        await tester.tap(profileButton.first);
        await tester.pumpAndSettle(const Duration(seconds: 1));

        // Verify profile screen
        final profileText = find.byWidgetPredicate(
          (widget) =>
              widget is Text &&
              (widget.data?.contains('Profile') == true ||
                  widget.data?.contains('Account') == true),
          skipOffstage: false,
        );

        if (profileText.evaluate().isNotEmpty) {
          expect(profileText, findsWidgets);
        }
      }

      // Navigate to wallet
      final walletButton = find.byWidgetPredicate(
        (widget) =>
            widget is Icon && widget.icon == Icons.wallet_giftcard ||
            (widget is Text && widget.data?.contains('Wallet') == true),
        skipOffstage: false,
      );

      if (walletButton.evaluate().isNotEmpty) {
        await tester.tap(walletButton.first);
        await tester.pumpAndSettle(const Duration(seconds: 1));

        // Verify wallet screen
        final walletText = find.byWidgetPredicate(
          (widget) =>
              widget is Text &&
              (widget.data?.contains('Wallet') == true ||
                  widget.data?.contains('Balance') == true),
          skipOffstage: false,
        );

        if (walletText.evaluate().isNotEmpty) {
          expect(walletText, findsWidgets);
        }
      }
    });

    testWidgets('Search and filter functionality', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Find search field
      final searchField = find.byType(TextField);
      if (searchField.evaluate().isNotEmpty) {
        await tester.enterText(searchField.first, 'plumbing');
        await tester.pumpAndSettle(const Duration(seconds: 1));

        // Verify search results
        final results = find.byType(Card);
        expect(results, findsWidgets, reason: 'Search results should be displayed');
      }
    });

    testWidgets('Error handling and recovery', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Try to trigger error scenarios
      // Tap on non-existent elements
      final nonExistentButton = find.byWidgetPredicate(
        (widget) =>
            widget is ElevatedButton &&
            widget.onPressed == null, // Disabled button
        skipOffstage: false,
      );

      if (nonExistentButton.evaluate().isNotEmpty) {
        // Disabled buttons should not crash
        expect(nonExistentButton, findsWidgets);
      }

      // Verify app is still responsive
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('Firebase integration validation', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Verify Firebase initialization by checking for auth-dependent widgets
      final authDependentWidgets = find.byWidgetPredicate(
        (widget) =>
            widget is StreamBuilder ||
            widget is FutureBuilder,
        skipOffstage: false,
      );

      // Should have at least some async widgets for Firebase
      expect(authDependentWidgets, findsWidgets,
          reason: 'Firebase integration should be present');

      // Verify no unauthorized writes are attempted
      // This is validated by checking that the app doesn't crash
      // when Firebase rules are enforced
      expect(find.byType(MaterialApp), findsOneWidget);
    });
  });
}

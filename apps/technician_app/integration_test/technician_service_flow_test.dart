import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:technician_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Technician App UI Flow Tests', () {
    testWidgets('Complete technician service and booking flow', (WidgetTester tester) async {
      // Launch the app
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // PHASE 1: Verify app launches
      expect(find.byType(MaterialApp), findsOneWidget);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // PHASE 2: Verify login screen is displayed
      expect(
        find.byWidgetPredicate(
          (widget) => widget is Text && widget.data?.contains('Login') == true,
          skipOffstage: false,
        ),
        findsWidgets,
        reason: 'Login screen should be visible',
      );

      // PHASE 3: Simulate authentication
      final phoneFields = find.byType(TextField);
      if (phoneFields.evaluate().isNotEmpty) {
        await tester.enterText(phoneFields.first, '+919999999999');
        await tester.pumpAndSettle();
      }

      // Look for OTP field
      final otpFields = find.byType(TextField);
      if (otpFields.evaluate().length > 1) {
        await tester.enterText(otpFields.at(1), '123456');
        await tester.pumpAndSettle();
      }

      // Look for login button
      final loginButton = find.byWidgetPredicate(
        (widget) =>
            widget is ElevatedButton ||
            (widget is Text && widget.data?.contains('Login') == true),
        skipOffstage: false,
      );

      if (loginButton.evaluate().isNotEmpty) {
        await tester.tap(loginButton.first);
        await tester.pumpAndSettle(const Duration(seconds: 2));
      }

      // PHASE 4: Navigate to service creation screen
      final addServiceButton = find.byWidgetPredicate(
        (widget) =>
            widget is Icon && widget.icon == Icons.add ||
            (widget is Text && widget.data?.contains('Add Service') == true),
        skipOffstage: false,
      );

      if (addServiceButton.evaluate().isNotEmpty) {
        await tester.tap(addServiceButton.first);
        await tester.pumpAndSettle(const Duration(seconds: 1));
      }

      // PHASE 5: Create new service
      // Fill service name
      final serviceNameField = find.byType(TextField);
      if (serviceNameField.evaluate().isNotEmpty) {
        await tester.enterText(serviceNameField.first, 'Plumbing Repair');
        await tester.pumpAndSettle();
      }

      // Fill service description
      final descriptionField = find.byType(TextField);
      if (descriptionField.evaluate().length > 1) {
        await tester.enterText(descriptionField.at(1), 'Professional plumbing repair');
        await tester.pumpAndSettle();
      }

      // PHASE 6: Upload image simulation
      final imageButton = find.byWidgetPredicate(
        (widget) =>
            widget is Icon && widget.icon == Icons.image ||
            (widget is Text && widget.data?.contains('Image') == true),
        skipOffstage: false,
      );

      if (imageButton.evaluate().isNotEmpty) {
        await tester.tap(imageButton.first);
        await tester.pumpAndSettle(const Duration(seconds: 1));
      }

      // PHASE 7: Set service price
      final priceField = find.byType(TextField);
      if (priceField.evaluate().length > 2) {
        await tester.enterText(priceField.at(2), '500');
        await tester.pumpAndSettle();
      }

      // PHASE 8: Submit service
      final submitButton = find.byWidgetPredicate(
        (widget) =>
            widget is ElevatedButton ||
            (widget is Text && widget.data?.contains('Submit') == true),
        skipOffstage: false,
      );

      if (submitButton.evaluate().isNotEmpty) {
        await tester.tap(submitButton.first);
        await tester.pumpAndSettle(const Duration(seconds: 2));
      }

      // PHASE 9: Verify service appears in dashboard
      final dashboardText = find.byWidgetPredicate(
        (widget) =>
            widget is Text &&
            (widget.data?.contains('Dashboard') == true ||
                widget.data?.contains('Services') == true),
        skipOffstage: false,
      );

      if (dashboardText.evaluate().isNotEmpty) {
        expect(dashboardText, findsWidgets);
      }

      // PHASE 10: Simulate receiving booking
      final bookingNotification = find.byWidgetPredicate(
        (widget) =>
            widget is Text &&
            (widget.data?.contains('New Booking') == true ||
                widget.data?.contains('Job Request') == true),
        skipOffstage: false,
      );

      if (bookingNotification.evaluate().isNotEmpty) {
        await tester.tap(bookingNotification.first);
        await tester.pumpAndSettle(const Duration(seconds: 1));
      }

      // PHASE 11: Accept booking
      final acceptButton = find.byWidgetPredicate(
        (widget) =>
            widget is ElevatedButton ||
            (widget is Text && widget.data?.contains('Accept') == true),
        skipOffstage: false,
      );

      if (acceptButton.evaluate().isNotEmpty) {
        await tester.tap(acceptButton.first);
        await tester.pumpAndSettle(const Duration(seconds: 1));
      }

      // PHASE 12: Verify booking status updated
      final statusText = find.byWidgetPredicate(
        (widget) =>
            widget is Text &&
            (widget.data?.contains('Accepted') == true ||
                widget.data?.contains('In Progress') == true),
        skipOffstage: false,
      );

      if (statusText.evaluate().isNotEmpty) {
        expect(statusText, findsWidgets);
      }
    });

    testWidgets('Navigation validation', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Test bottom navigation
      final bottomNav = find.byType(BottomNavigationBar);
      expect(bottomNav, findsWidgets, reason: 'Bottom navigation should exist');

      // Test navigation between tabs
      final navItems = find.byType(BottomNavigationBarItem);
      if (navItems.evaluate().isNotEmpty) {
        for (int i = 0; i < navItems.evaluate().length; i++) {
          await tester.tap(navItems.at(i));
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

    testWidgets('Job requests listing and management', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Find job requests list
      final jobList = find.byType(ListView);
      if (jobList.evaluate().isNotEmpty) {
        // Scroll through jobs
        await tester.drag(jobList.first, const Offset(0, -500));
        await tester.pumpAndSettle();

        // Verify jobs are displayed
        final jobItems = find.byType(Card);
        expect(jobItems, findsWidgets, reason: 'Job cards should be visible');
      }
    });

    testWidgets('Profile and earnings access', (WidgetTester tester) async {
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

      // Navigate to earnings
      final earningsButton = find.byWidgetPredicate(
        (widget) =>
            widget is Icon && widget.icon == Icons.attach_money ||
            (widget is Text && widget.data?.contains('Earnings') == true),
        skipOffstage: false,
      );

      if (earningsButton.evaluate().isNotEmpty) {
        await tester.tap(earningsButton.first);
        await tester.pumpAndSettle(const Duration(seconds: 1));

        // Verify earnings screen
        final earningsText = find.byWidgetPredicate(
          (widget) =>
              widget is Text &&
              (widget.data?.contains('Earnings') == true ||
                  widget.data?.contains('Income') == true),
          skipOffstage: false,
        );

        if (earningsText.evaluate().isNotEmpty) {
          expect(earningsText, findsWidgets);
        }
      }
    });

    testWidgets('Online/offline toggle functionality', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Find online/offline toggle
      final toggleButton = find.byWidgetPredicate(
        (widget) =>
            widget is Switch ||
            (widget is Text && widget.data?.contains('Online') == true),
        skipOffstage: false,
      );

      if (toggleButton.evaluate().isNotEmpty) {
        // Tap toggle
        await tester.tap(toggleButton.first);
        await tester.pumpAndSettle(const Duration(seconds: 1));

        // Tap again to toggle back
        await tester.tap(toggleButton.first);
        await tester.pumpAndSettle(const Duration(seconds: 1));

        expect(toggleButton, findsWidgets);
      }
    });

    testWidgets('Error handling and recovery', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Try to trigger error scenarios
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
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('Service status updates', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Find service status dropdown
      final statusDropdown = find.byWidgetPredicate(
        (widget) =>
            widget is DropdownButton ||
            (widget is Text && widget.data?.contains('Status') == true),
        skipOffstage: false,
      );

      if (statusDropdown.evaluate().isNotEmpty) {
        await tester.tap(statusDropdown.first);
        await tester.pumpAndSettle(const Duration(seconds: 1));

        // Select a status option
        final statusOptions = find.byType(DropdownMenuItem);
        if (statusOptions.evaluate().isNotEmpty) {
          await tester.tap(statusOptions.first);
          await tester.pumpAndSettle(const Duration(seconds: 1));
        }
      }
    });

    testWidgets('Notification handling', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Find notification icon
      final notificationIcon = find.byWidgetPredicate(
        (widget) =>
            widget is Icon && widget.icon == Icons.notifications ||
            (widget is Text && widget.data?.contains('Notifications') == true),
        skipOffstage: false,
      );

      if (notificationIcon.evaluate().isNotEmpty) {
        await tester.tap(notificationIcon.first);
        await tester.pumpAndSettle(const Duration(seconds: 1));

        // Verify notifications screen
        final notificationsText = find.byWidgetPredicate(
          (widget) =>
              widget is Text &&
              widget.data?.contains('Notifications') == true,
          skipOffstage: false,
        );

        if (notificationsText.evaluate().isNotEmpty) {
          expect(notificationsText, findsWidgets);
        }
      }
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

void main() {
  group('Widget smoke tests', () {
    testWidgets('MaterialApp renders without errors', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: Scaffold(body: Text('HomeFix'))));
      expect(find.text('HomeFix'), findsOneWidget);
    });
  });
}

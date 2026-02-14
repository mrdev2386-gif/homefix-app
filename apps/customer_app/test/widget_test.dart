import 'package:flutter_test/flutter_test.dart';
import 'package:customer_app/main.dart';

void main() {
  testWidgets('Smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const HomeFixApp());
  });
}

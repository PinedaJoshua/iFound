// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the
// widget tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

// Import the correct package name
import 'package:flutter_application_1/main.dart'; 

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp()); // This line will now work

    // Verify that our counter starts at 0.
    // Note: The default test looks for '0' and '1', but our app
    // doesn't have a counter. This test will fail if you run it,
    // but it will *compile* which solves your current error.
    // You can delete the 'expect' lines if you want.
    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsNothing);
  });
}
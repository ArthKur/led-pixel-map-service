// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:led_calculator_2_0/main.dart';

void main() {
  testWidgets('LED Calculator smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const LEDCalculatorApp());

    // Verify that our search field exists.
    expect(find.text('Search for LED product...'), findsOneWidget);
    expect(find.text('Width'), findsOneWidget);
    expect(find.text('Height'), findsOneWidget);
  });
}

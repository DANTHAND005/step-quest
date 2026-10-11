import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:step_quest/api.dart';
import 'package:step_quest/screens/login_screen.dart';
import 'package:step_quest/widgets.dart';

void main() {
  test('formatNumber adds commas', () {
    expect(formatNumber(0), '0');
    expect(formatNumber(999), '999');
    expect(formatNumber(1000), '1,000');
    expect(formatNumber(1234567), '1,234,567');
  });

  testWidgets('login asks for username and password', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final api = await Api.load();
    await tester.pumpWidget(MaterialApp(home: LoginScreen(api: api)));

    await tester.tap(find.widgetWithText(FilledButton, 'Log in'));
    await tester.pump();

    expect(find.text('Enter your username'), findsOneWidget);
    expect(find.text('Enter your password'), findsOneWidget);
  });

  testWidgets('sign up mode checks password length', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final api = await Api.load();
    await tester.pumpWidget(MaterialApp(home: LoginScreen(api: api)));

    await tester.tap(find.text('New here? Create an account'));
    await tester.pump();
    await tester.enterText(find.widgetWithText(TextFormField, 'Username'), 'daniel');
    await tester.enterText(find.widgetWithText(TextFormField, 'Password'), 'short');
    await tester.tap(find.widgetWithText(FilledButton, 'Create account'));
    await tester.pump();

    expect(find.text('Use at least 8 characters'), findsOneWidget);
  });
}

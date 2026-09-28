import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gateway_mobile/main.dart';

void main() {
  testWidgets('sandbox login opens the functional mobile home', (tester) async {
    await tester.pumpWidget(const AcquirerMobile());

    expect(find.text('AfPay'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 2400));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('login-username')), 'test');
    await tester.enterText(find.byKey(const Key('login-password')), 'test');
    await tester.tap(find.widgetWithText(FilledButton, 'Sign In'));
    await tester.pumpAndSettle();

    expect(find.text('Current Balance'), findsOneWidget);
    expect(find.text('Send'), findsOneWidget);
    expect(find.text('Recent Transactions'), findsOneWidget);

    await tester.tap(find.text('Transactions').last);
    await tester.pumpAndSettle();
    expect(
      find.text('Search transactions, merchants or amounts...'),
      findsOneWidget,
    );
  });
}

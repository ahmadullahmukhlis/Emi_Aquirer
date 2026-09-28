import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:afpay_pos/main.dart';

void main() {
  testWidgets('sandbox login opens the functional POS terminal', (
    tester,
  ) async {
    await tester.pumpWidget(const PosApp());

    expect(find.text('MSHpay'), findsOneWidget);
    expect(find.text('Use sandbox test account'), findsOneWidget);

    await tester.tap(find.byKey(const Key('sandbox-login')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Merchant acceptance terminal'), findsOneWidget);
    expect(find.text('ENTER AMOUNT'), findsOneWidget);
    expect(find.text('Operations'), findsOneWidget);

    await tester.drag(find.byType(ListView), const Offset(0, -700));
    await tester.pump();
    expect(find.text('Charge customer'), findsOneWidget);
  });
}

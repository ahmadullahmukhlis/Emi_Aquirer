import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gateway_mobile/core/app_theme.dart';
import 'package:gateway_mobile/core/banking_header.dart';
import 'package:gateway_mobile/features/shell/app_shell.dart';
import 'package:gateway_mobile/services/gateway_client.dart';

void main() {
  for (final width in [320.0, 390.0, 768.0]) {
    testWidgets('banking tabs and payment header at width $width', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final client = GatewayClient()..startDemoSession();
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: AppShell(client: client),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(BankingHeader), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.ensureVisible(find.text('See All').first);
      await tester.tap(find.text('See All').first);
      await tester.pumpAndSettle();
      expect(
        find.text('Search transactions, merchants or amounts...'),
        findsOneWidget,
      );
      await tester.enterText(find.byType(TextField), 'Amazon');
      await tester.pumpAndSettle();
      expect(find.widgetWithText(ListTile, 'Amazon'), findsOneWidget);
      expect(find.text('Salary Credit'), findsNothing);

      for (final tab in ['Cards', 'Services', 'Profile', 'Home']) {
        await tester.tap(
          find.descendant(
            of: find.byType(NavigationBar),
            matching: find.text(tab),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byType(BankingHeader), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
      await tester.scrollUntilVisible(
        find.text('Send'),
        -150,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Send'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(BankingHeader, 'Send Money'), findsOneWidget);
      expect(find.byType(BackButton), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.byType(NavigationBar), findsOneWidget);
    });
  }
}

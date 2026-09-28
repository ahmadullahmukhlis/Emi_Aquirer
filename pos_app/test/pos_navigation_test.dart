import 'package:afpay_pos/core/app_theme.dart';
import 'package:afpay_pos/features/terminal/pos_terminal_page.dart';
import 'package:afpay_pos/services/gateway_client.dart';
import 'package:afpay_ui/afpay_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('flutter_tts'),
          (_) async => 1,
        );
  });
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('flutter_tts'), null);
  });

  for (final width in [320.0, 390.0, 768.0]) {
    testWidgets('POS shared header, navigation and validation at $width', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          theme: PosTheme.light,
          home: PosTerminalPage(client: GatewayClient()..startDemoSession()),
        ),
      );
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.widgetWithText(BankingHeader, 'MSHpay'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.enterText(find.byType(TextField).first, '2500');
      await tester.tap(find.text('Operations'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(BankingHeader, 'Operations'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.scrollUntilVisible(
        find.text('Submit Purchase'),
        150,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Submit Purchase'));
      await tester.pump();
      await tester.scrollUntilVisible(
        find.text('Enter terminal, merchant, and amount.'),
        150,
        scrollable: find.byType(Scrollable).first,
      );
      expect(
        find.text('Enter terminal, merchant, and amount.'),
        findsOneWidget,
      );
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text('Terminal'),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.widgetWithText(BankingHeader, 'MSHpay'), findsOneWidget);
      expect(find.text('2500'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    });
  }
}

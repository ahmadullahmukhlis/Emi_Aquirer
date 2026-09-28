import 'package:flutter/material.dart';

import 'core/app_theme.dart';
import 'features/auth/pos_login_page.dart';
import 'services/gateway_client.dart';

class PosApp extends StatelessWidget {
  const PosApp({super.key, this.client});

  final GatewayClient? client;

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'AfPay POS',
    theme: PosTheme.light,
    home: PosLoginPage(client: client ?? GatewayClient()),
  );
}

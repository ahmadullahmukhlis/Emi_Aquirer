import 'package:flutter/material.dart';

import 'core/app_theme.dart';
import 'features/auth/splash_page.dart';
import 'services/gateway_client.dart';

class AcquirerMobile extends StatelessWidget {
  const AcquirerMobile({super.key, this.client});

  final GatewayClient? client;

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'AfPay Mobile',
    theme: AppTheme.light,
    home: SplashPage(client: client ?? GatewayClient()),
  );
}

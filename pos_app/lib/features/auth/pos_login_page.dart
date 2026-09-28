import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:afpay_ui/afpay_ui.dart';

import '../../core/app_theme.dart';
import '../../services/gateway_client.dart';
import '../terminal/pos_terminal_page.dart';

class PosLoginPage extends StatefulWidget {
  const PosLoginPage({super.key, required this.client});
  final GatewayClient client;

  @override
  State<PosLoginPage> createState() => _PosLoginPageState();
}

class _PosLoginPageState extends State<PosLoginPage> {
  final _username = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  String? _error;

  Future<void> _signIn() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.client.login(_username.text.trim(), _password.text);
      if (!mounted) return;
      await Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => PosTerminalPage(client: widget.client),
        ),
      );
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'Sign in failed. Check your operator account and gateway connection.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _useSandboxAccount() async {
    widget.client.startDemoSession();
    await Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => PosTerminalPage(client: widget.client)),
    );
  }

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: const BankingHeader(
      title: Text('MSHpay'),
      automaticallyImplyLeading: false,
    ),
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Center(child: BrandMark(size: 64, withContainer: true)),
                const SizedBox(height: 18),
                const Text(
                  'Welcome back',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: PosColors.ink,
                  ),
                ),
                const Text(
                  'Secure merchant operator sign-in',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                TextField(
                  controller: _username,
                  decoration: const InputDecoration(
                    labelText: 'Operator username',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _password,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                const SizedBox(height: 18),
                FilledButton(
                  onPressed: _busy ? null : _signIn,
                  style: FilledButton.styleFrom(
                    backgroundColor: PosColors.ink,
                    padding: const EdgeInsets.all(16),
                  ),
                  child: Text(_busy ? 'Signing in…' : 'Sign in'),
                ),
                if (kDebugMode) ...[
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    key: const Key('sandbox-login'),
                    onPressed: _busy ? null : _useSandboxAccount,
                    icon: const Icon(Icons.science_outlined),
                    label: const Text('Use sandbox test account'),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Debug builds only · protected test tokens only',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, color: Colors.blueGrey),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

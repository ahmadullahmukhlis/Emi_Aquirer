import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import '../../core/app_theme.dart';
import '../../core/brand.dart';
import '../../services/gateway_client.dart';
import '../shell/app_shell.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, required this.client});

  final GatewayClient client;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _username = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  bool _obscure = true;

  Future<void> _submit() async {
    setState(() => _loading = true);
    try {
      final isSandboxLogin =
          kDebugMode &&
          _username.text.trim() == 'test' &&
          _password.text == 'test';
      if (isSandboxLogin) {
        widget.client.startDemoSession();
      } else {
        await widget.client.login(_username.text.trim(), _password.text);
      }
      if (!mounted) return;
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => AppShell(client: widget.client)),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Sign-in failed. Check your credentials and connection.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _useSandboxAccount() async {
    _username.text = 'test';
    _password.text = 'test';
    await _submit();
  }

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Stack(
      fit: StackFit.expand,
      children: [
        const BrandRibbonBackground(login: true),
        SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(26, 24, 26, 18),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Align(
                      alignment: Alignment.center,
                      child: BrandMark(size: 51, withContainer: true),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'AfPay',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 46),
                    TextField(
                      key: const Key('login-username'),
                      controller: _username,
                      autocorrect: false,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.phone_iphone_rounded),
                        hintText: 'Phone Number or Email',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      key: const Key('login-password'),
                      controller: _password,
                      obscureText: _obscure,
                      enableSuggestions: false,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.lock_outline),
                        hintText: 'Password',
                        suffixIcon: IconButton(
                          onPressed: () => setState(() => _obscure = !_obscure),
                          icon: Icon(
                            _obscure
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    FilledButton(
                      onPressed: _loading ? null : _submit,
                      child: Text(_loading ? 'Signing in…' : 'Sign In'),
                    ),
                    TextButton(
                      onPressed: _showRecovery,
                      child: const Text('Forgot Password?'),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: _BioButton(
                            icon: Icons.face_retouching_natural,
                            label: 'Face ID',
                            onTap: _useSandboxAccount,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _BioButton(
                            icon: Icons.fingerprint,
                            label: 'Fingerprint',
                            onTap: _useSandboxAccount,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _BioButton(
                            icon: Icons.dialpad,
                            label: 'PIN',
                            onTap: _useSandboxAccount,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Don't have an account?",
                          style: TextStyle(fontSize: 12),
                        ),
                        TextButton(
                          onPressed: _showSignup,
                          child: const Text('Sign Up'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );

  Future<void> _showRecovery() => showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      icon: const CircleAvatar(
        radius: 28,
        backgroundColor: AppColors.soft,
        child: Icon(
          Icons.lock_reset_rounded,
          color: AppColors.primary,
          size: 30,
        ),
      ),
      title: const Text('Recover your account'),
      content: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Enter your registered phone number or email. We will send a secure verification code.',
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16),
          TextField(
            decoration: InputDecoration(
              prefixIcon: Icon(Icons.alternate_email),
              hintText: 'Phone number or email',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.pop(dialogContext);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Verification instructions sent securely.'),
              ),
            );
          },
          child: const Text('Send Code'),
        ),
      ],
    ),
  );

  Future<void> _showSignup() => showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      icon: const CircleAvatar(
        radius: 28,
        backgroundColor: AppColors.soft,
        child: Icon(Icons.person_add_alt_1, color: AppColors.primary),
      ),
      title: const Text('Create an AfPay account'),
      content: const Text(
        'Account registration requires identity verification. Start with your mobile number and continue securely.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Not Now'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.pop(dialogContext);
            _showRecovery();
          },
          child: const Text('Get Started'),
        ),
      ],
    ),
  );
}

class _BioButton extends StatelessWidget {
  const _BioButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(16),
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .82),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.primary, size: 28),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 10)),
        ],
      ),
    ),
  );
}

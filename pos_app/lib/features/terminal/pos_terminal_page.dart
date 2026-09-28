import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../../core/app_theme.dart';
import '../../services/gateway_client.dart';
import '../operations/pos_operations_page.dart';
import 'card_prompt.dart';

class PosTerminalPage extends StatefulWidget {
  const PosTerminalPage({super.key, required this.client});
  final GatewayClient client;

  @override
  State<PosTerminalPage> createState() => _PosTerminalPageState();
}

class _PosTerminalPageState extends State<PosTerminalPage>
    with SingleTickerProviderStateMixin {
  final _amount = TextEditingController();
  final _terminal = TextEditingController(text: 'T0000001');
  final _merchant = TextEditingController(text: 'M00000000000001');
  final _token = TextEditingController();
  final _tts = FlutterTts();
  late final AnimationController _animation;
  String _language = 'English';
  String _status = 'Ready to accept payment';
  String _message = 'Tap, insert, or present a token from an approved reader.';
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _animation = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  Future<void> _takePayment() async {
    final value = int.tryParse(_amount.text);
    if (value == null || value <= 0 || _token.text.trim().isEmpty) {
      setState(() {
        _status = 'Check payment details';
        _message = 'Enter a positive AFN amount and an approved payment token.';
      });
      return;
    }
    setState(() {
      _loading = true;
      _status = 'Authorizing…';
    });
    try {
      final result = await widget.client.purchase(
        terminalId: _terminal.text.trim(),
        merchantId: _merchant.text.trim(),
        amountMinor: value,
        token: _token.text.trim(),
      );
      if (mounted) {
        setState(() {
          _status = result['status']?.toString() ?? 'Submitted';
          _message =
              '${result['responseCode'] ?? ''} · ${result['message'] ?? 'Transaction submitted'}';
        });
      }
    } on DioException catch (error) {
      if (mounted) {
        setState(() {
          _status = 'Payment unavailable';
          _message =
              error.response?.data?['message']?.toString() ??
              'The gateway could not process this request.';
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _animation.dispose();
    _tts.stop();
    _amount.dispose();
    _terminal.dispose();
    _merchant.dispose();
    _token.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    floatingActionButton: FloatingActionButton.extended(
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PosOperationsPage(client: widget.client),
        ),
      ),
      icon: const Icon(Icons.apps),
      label: const Text('Operations'),
    ),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: ListView(
            padding: const EdgeInsets.all(22),
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: PosColors.ink,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.point_of_sale_rounded,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AfPay POS',
                          style: TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          'Merchant acceptance terminal',
                          style: TextStyle(color: Colors.blueGrey),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => widget.client.heartbeat(
                      _terminal.text,
                      'LOCAL-DEMO-SERIAL',
                    ),
                    icon: const Icon(Icons.wifi_tethering_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 26),
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: PosColors.ink,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  children: [
                    const Text(
                      'ENTER AMOUNT',
                      style: TextStyle(
                        color: Color(0xffc8f4f0),
                        letterSpacing: 1.4,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextField(
                      controller: _amount,
                      autofocus: true,
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 46,
                      ),
                      decoration: const InputDecoration(
                        hintText: '0',
                        hintStyle: TextStyle(color: Color(0xff9bd5d0)),
                        border: InputBorder.none,
                        suffixText: 'AFN',
                        suffixStyle: TextStyle(
                          color: Color(0xffc8f4f0),
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const Divider(color: Color(0xff197a7b)),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Online • encrypted channel',
                          style: TextStyle(color: Color(0xffc8f4f0)),
                        ),
                        Icon(
                          Icons.verified_user_outlined,
                          color: Color(0xff72e1ab),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              CardPrompt(
                language: _language,
                animation: Tween<double>(begin: .92, end: 1.08).animate(
                  CurvedAnimation(parent: _animation, curve: Curves.easeInOut),
                ),
                onLanguageChanged: (value) => setState(() => _language = value),
                tts: _tts,
              ),
              const SizedBox(height: 18),
              _TerminalField(
                label: 'Terminal ID',
                controller: _terminal,
                icon: Icons.storefront_outlined,
              ),
              const SizedBox(height: 12),
              _TerminalField(
                label: 'Merchant ID',
                controller: _merchant,
                icon: Icons.business_outlined,
              ),
              const SizedBox(height: 12),
              _TerminalField(
                label: 'Approved reader token',
                controller: _token,
                icon: Icons.contactless_outlined,
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _loading ? null : _takePayment,
                style: FilledButton.styleFrom(
                  backgroundColor: PosColors.accent,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                ),
                icon: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.lock_outline),
                label: Text(
                  _loading ? 'Processing payment' : 'Charge customer',
                ),
              ),
              const SizedBox(height: 18),
              Card(
                child: ListTile(
                  leading: Icon(
                    _status == 'APPROVED'
                        ? Icons.check_circle
                        : Icons.info_outline,
                    color: _status == 'APPROVED'
                        ? Colors.green
                        : PosColors.accent,
                  ),
                  title: Text(
                    _status,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle: Text(_message),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Security boundary: this app accepts a protected reader token only. PIN blocks, CVV, PAN, EMV TLV and keys remain in certified terminal/HSM paths.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.blueGrey, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _TerminalField extends StatelessWidget {
  const _TerminalField({
    required this.label,
    required this.controller,
    required this.icon,
  });
  final String label;
  final TextEditingController controller;
  final IconData icon;

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    decoration: InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: Colors.white,
    ),
  );
}

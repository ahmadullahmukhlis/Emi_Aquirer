import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../services/gateway_client.dart';

class PosOperationsPage extends StatefulWidget {
  const PosOperationsPage({super.key, required this.client});
  final GatewayClient client;

  @override
  State<PosOperationsPage> createState() => _PosOperationsPageState();
}

class _PosOperationsPageState extends State<PosOperationsPage> {
  static const operations = {
    'Purchase': 'PURCHASE',
    'Cash in': 'CASH_IN',
    'Cash out': 'CASH_OUT',
    'Balance inquiry': 'BALANCE_INQUIRY',
    'Payment info': 'PAYMENT_INFO',
    'Save payment': 'SAVE_PAYMENT',
    'Card title fetch': 'CARD_TITLE_FETCH',
    'Card to card': 'CARD_TO_CARD',
    'Reversal': 'REVERSAL',
  };
  String _selected = 'Purchase';
  final _terminal = TextEditingController();
  final _merchant = TextEditingController();
  final _amount = TextEditingController();
  final _token = TextEditingController();
  final _original = TextEditingController();
  String? _message;
  bool _busy = false;

  Future<void> _send() async {
    final value = int.tryParse(_amount.text);
    final noAmount = {
      'Balance inquiry',
      'Payment info',
      'Card title fetch',
    }.contains(_selected);
    if (_terminal.text.isEmpty ||
        _merchant.text.isEmpty ||
        (!noAmount && (value == null || value <= 0))) {
      setState(() => _message = 'Enter terminal, merchant, and amount.');
      return;
    }
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final result = await widget.client.operation(operations[_selected]!, {
        'merchantId': _merchant.text.trim(),
        'terminalId': _terminal.text.trim(),
        'amountMinor': noAmount ? null : value,
        'currency': 'AFN',
        'cardToken': _token.text.trim().isEmpty
            ? 'protected-reader-token'
            : _token.text.trim(),
        'originalTransactionId': _original.text.trim().isEmpty
            ? null
            : _original.text.trim(),
      });
      _message =
          '${result['status']} · ${result['responseCode']} · ${result['message']}';
    } on DioException {
      _message =
          'Gateway request failed. If the outcome is unknown, do not hand over cash; use transaction lookup.';
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    for (final controller in [
      _terminal,
      _merchant,
      _amount,
      _token,
      _original,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('POS operations')),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        DropdownButtonFormField<String>(
          initialValue: _selected,
          decoration: const InputDecoration(labelText: 'Operation'),
          items: operations.keys
              .map((name) => DropdownMenuItem(value: name, child: Text(name)))
              .toList(),
          onChanged: (value) => setState(() => _selected = value!),
        ),
        const SizedBox(height: 12),
        _Field(label: 'Terminal ID', controller: _terminal),
        _Field(label: 'Merchant ID', controller: _merchant),
        _Field(label: 'Amount (minor AFN)', controller: _amount),
        _Field(label: 'Protected reader token', controller: _token),
        _Field(label: 'Original transaction ID', controller: _original),
        FilledButton(
          onPressed: _busy ? null : _send,
          child: Text(_busy ? 'Sending…' : 'Submit $_selected'),
        ),
        if (_message != null)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Text(_message!),
          ),
      ],
    ),
  );
}

class _Field extends StatelessWidget {
  const _Field({required this.label, required this.controller});
  final String label;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextField(
      controller: controller,
      decoration: InputDecoration(labelText: label),
    ),
  );
}

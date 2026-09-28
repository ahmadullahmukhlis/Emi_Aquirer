import 'package:flutter/material.dart';
import '../../core/banking_header.dart';

import '../../core/app_theme.dart';
import '../../core/ui.dart';
import '../../services/gateway_client.dart';
import '../transactions/transaction_detail_page.dart';

class MobileRechargePage extends StatefulWidget {
  const MobileRechargePage({super.key, required this.client});
  final GatewayClient client;
  @override
  State<MobileRechargePage> createState() => _MobileRechargePageState();
}

class _MobileRechargePageState extends State<MobileRechargePage> {
  final _formKey = GlobalKey<FormState>();
  final _phone = TextEditingController();
  final _customAmount = TextEditingController();
  bool prepaid = true;
  String operatorName = 'AWCC';
  int amount = 100;
  int step = 0;
  bool processing = false;
  static const operators = {
    'AWCC': 'AWCC-TOPUP',
    'MTN': 'MTN-TOPUP',
    'Salaam': 'SALAAM-TOPUP',
    'Etisalat': 'ETISALAT-TOPUP',
  };

  @override
  void dispose() {
    _phone.dispose();
    _customAmount.dispose();
    super.dispose();
  }

  int? get selectedAmount =>
      amount == 0 ? int.tryParse(_customAmount.text.trim()) : amount;

  void _continue() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    setState(() => step = 1);
  }

  Future<void> _submit() async {
    if (processing) return;
    setState(() {
      processing = true;
      step = 2;
    });
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    try {
      final value = selectedAmount!;
      final result = await widget.client.transaction('purchase', {
        'requestId': id,
        'idempotencyKey': 'topup-$id',
        'merchantId': operators[operatorName],
        'amountMinor': value * 100,
        'currency': 'AFN',
        'cardToken': null,
      });
      if (!mounted) return;
      await Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => TransactionDetailPage(
            transaction: {
              ...result,
              'title': '$operatorName Mobile Recharge',
              'category': 'Bills',
              'date': 'Just now',
              'amount': '- $value AFN',
              'reference': _phone.text.trim(),
              'method': 'Primary card •••• 3456',
            },
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        processing = false;
        step = 1;
      });
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          icon: const CircleAvatar(
            radius: 27,
            backgroundColor: Color(0xffffebee),
            child: Icon(Icons.error_outline, color: Colors.red),
          ),
          title: const Text('Recharge not confirmed'),
          content: const Text(
            'The provider did not confirm this recharge. Check transaction history before trying again to avoid a duplicate top-up.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Review Details'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                Navigator.pop(context);
              },
              child: const Text('Transaction History'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: BankingHeader(title: const Text('Mobile Recharge')),
    body: Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 6, 18, 10),
          child: Row(
            children: [
              _Step(1, 'Details', step >= 0),
              const _Line(),
              _Step(2, 'Review', step >= 1),
              const _Line(),
              _Step(3, 'Result', step >= 2),
            ],
          ),
        ),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: step == 0
                ? _details()
                : step == 1
                ? _review()
                : _processing(),
          ),
        ),
      ],
    ),
  );

  Widget _details() => Form(
    key: _formKey,
    child: ListView(
      key: const ValueKey(0),
      padding: const EdgeInsets.all(18),
      children: [
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(value: true, label: Text('Prepaid')),
            ButtonSegment(value: false, label: Text('Postpaid')),
          ],
          selected: {prepaid},
          onSelectionChanged: (s) => setState(() => prepaid = s.first),
        ),
        const SizedBox(height: 18),
        TextFormField(
          controller: _phone,
          keyboardType: TextInputType.phone,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.phone_iphone),
            labelText: 'Mobile number',
            hintText: '+93 7XX XXX XXX',
            suffixIcon: Icon(Icons.contacts_outlined),
          ),
          validator: (value) {
            final normalized = (value ?? '').replaceAll(RegExp(r'[\s-]'), '');
            if (normalized.isEmpty) return 'Mobile number is required';
            if (!RegExp(r'^(\+93|0)?7\d{8}$').hasMatch(normalized)) {
              return 'Enter a valid Afghanistan mobile number';
            }
            return null;
          },
        ),
        const SizedBox(height: 22),
        const Text(
          'Select Operator',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        Row(
          children: operators.keys
              .map(
                (name) => Expanded(
                  child: InkWell(
                    onTap: () => setState(() => operatorName = name),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(
                          color: operatorName == name
                              ? AppColors.primary
                              : const Color(0xffe8edf5),
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.signal_cellular_alt,
                            color: name == 'MTN'
                                ? Colors.orange
                                : name == 'Salaam'
                                ? Colors.green
                                : AppColors.primary,
                          ),
                          const SizedBox(height: 5),
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 22),
        const Text(
          'Select Amount',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 9,
          runSpacing: 9,
          children: [50, 100, 200, 500, 1000, 0]
              .map(
                (v) => ChoiceChip(
                  label: SizedBox(
                    width: 72,
                    child: Text(
                      v == 0 ? 'Custom' : '$v AFN',
                      textAlign: TextAlign.center,
                    ),
                  ),
                  selected: amount == v,
                  onSelected: (_) => setState(() => amount = v),
                ),
              )
              .toList(),
        ),
        if (amount == 0) ...[
          const SizedBox(height: 12),
          TextFormField(
            controller: _customAmount,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.payments_outlined),
              labelText: 'Custom amount (AFN)',
            ),
            validator: (value) {
              if (amount != 0) return null;
              final parsed = int.tryParse(value ?? '');
              if (parsed == null || parsed < 10) {
                return 'Minimum recharge is 10 AFN';
              }
              if (parsed > 10000) return 'Maximum recharge is 10,000 AFN';
              return null;
            },
          ),
        ],
        const SizedBox(height: 28),
        FilledButton(
          onPressed: _continue,
          child: const Text('Review Recharge'),
        ),
      ],
    ),
  );

  Widget _review() {
    final value = selectedAmount ?? 0;
    return ListView(
      key: const ValueKey(1),
      padding: const EdgeInsets.all(18),
      children: [
        const Center(
          child: CircleAvatar(
            radius: 32,
            backgroundColor: AppColors.soft,
            child: Icon(Icons.phone_iphone, color: AppColors.primary, size: 32),
          ),
        ),
        const SizedBox(height: 12),
        const Center(
          child: Text(
            'Confirm Recharge',
            style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
          ),
        ),
        const SizedBox(height: 18),
        PageCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _ReviewRow('Mobile number', _phone.text.trim()),
              _ReviewRow('Operator', operatorName),
              _ReviewRow('Plan', prepaid ? 'Prepaid' : 'Postpaid'),
              _ReviewRow('Recharge amount', '$value AFN'),
              const Divider(),
              _ReviewRow('Total', '$value AFN', strong: true),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline, color: AppColors.primary, size: 18),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Verify the number carefully. Completed mobile recharges usually cannot be reversed.',
                style: TextStyle(fontSize: 11, color: AppColors.muted),
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),
        FilledButton(
          onPressed: _submit,
          child: Text('Confirm $value AFN Recharge'),
        ),
        TextButton(
          onPressed: () => setState(() => step = 0),
          child: const Text('Edit Details'),
        ),
      ],
    );
  }

  Widget _processing() => Center(
    key: const ValueKey(2),
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 22),
          const Text(
            'Processing recharge',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 7),
          Text(
            'Connecting securely to $operatorName. Please do not close the app or submit again.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.muted),
          ),
        ],
      ),
    ),
  );
}

class _Step extends StatelessWidget {
  const _Step(this.number, this.label, this.active);
  final int number;
  final String label;
  final bool active;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      CircleAvatar(
        radius: 14,
        backgroundColor: active ? AppColors.primary : const Color(0xffdce3ed),
        child: Text(
          '$number',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      const SizedBox(height: 4),
      Text(
        label,
        style: TextStyle(
          fontSize: 9,
          color: active ? AppColors.primary : AppColors.muted,
          fontWeight: FontWeight.w700,
        ),
      ),
    ],
  );
}

class _Line extends StatelessWidget {
  const _Line();
  @override
  Widget build(BuildContext context) =>
      const Expanded(child: Divider(indent: 7, endIndent: 7));
}

class _ReviewRow extends StatelessWidget {
  const _ReviewRow(this.label, this.value, {this.strong = false});
  final String label, value;
  final bool strong;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: strong ? AppColors.ink : AppColors.muted,
              fontWeight: strong ? FontWeight.w800 : FontWeight.normal,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: strong ? 17 : 13,
          ),
        ),
      ],
    ),
  );
}

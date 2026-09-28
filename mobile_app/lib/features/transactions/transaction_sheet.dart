import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../services/gateway_client.dart';
import 'transaction_detail_page.dart';

Future<void> showTransactionSheet(
  BuildContext context, {
  required GatewayClient client,
  required String label,
  String? initialMerchant,
  int? initialAmountMinor,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  backgroundColor: Colors.transparent,
  builder: (_) => _TransactionSheet(
    client: client,
    label: label,
    initialMerchant: initialMerchant,
    initialAmountMinor: initialAmountMinor,
  ),
);

class _TransactionSheet extends StatefulWidget {
  const _TransactionSheet({
    required this.client,
    required this.label,
    this.initialMerchant,
    this.initialAmountMinor,
  });
  final GatewayClient client;
  final String label;
  final String? initialMerchant;
  final int? initialAmountMinor;
  @override
  State<_TransactionSheet> createState() => _TransactionSheetState();
}

class _TransactionSheetState extends State<_TransactionSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _merchant;
  late final TextEditingController _amount;
  late final TextEditingController _reference;
  bool _submitting = false;

  String get _operation =>
      const {
        'Transfer': 'CARD_TO_CARD',
        'Receive': 'CARD_TO_WALLET',
        'Pay bills': 'PAYMENT_INFO',
        'Balance': 'BALANCE_INQUIRY',
        'Scan & pay': 'PURCHASE',
        'More': 'PAYMENT_INFO',
        'Pending recovery': 'RECOVERY',
      }[widget.label] ??
      'PURCHASE';

  @override
  void initState() {
    super.initState();
    _merchant = TextEditingController(text: widget.initialMerchant);
    _amount = TextEditingController(
      text: widget.initialAmountMinor?.toString() ?? '',
    );
    _reference = TextEditingController();
  }

  @override
  void dispose() {
    _merchant.dispose();
    _amount.dispose();
    _reference.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const CircleAvatar(
          radius: 27,
          backgroundColor: AppColors.soft,
          child: Icon(Icons.verified_user_outlined, color: AppColors.primary),
        ),
        title: Text('Confirm ${widget.label}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_merchant.text.trim().isNotEmpty)
              _ConfirmRow('Recipient / merchant', _merchant.text.trim()),
            if (_amount.text.trim().isNotEmpty)
              _ConfirmRow(
                'Amount',
                'AFN ${(int.tryParse(_amount.text) ?? 0) / 100}',
              ),
            if (_reference.text.trim().isNotEmpty)
              _ConfirmRow('Reference', _reference.text.trim()),
            const SizedBox(height: 8),
            const Text(
              'Confirm only if these details are correct.',
              style: TextStyle(fontSize: 11, color: AppColors.muted),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Edit'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _submitting = true);
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    try {
      final result = _operation == 'RECOVERY'
          ? await widget.client.transactionTimeline(_reference.text)
          : await widget.client.transaction(_operation, {
              'requestId': id,
              'idempotencyKey': 'mobile-$id',
              'merchantId': _merchant.text.trim(),
              'amountMinor': int.tryParse(_amount.text),
              'currency': 'AFN',
              'cardToken': _reference.text.trim().isEmpty
                  ? null
                  : _reference.text.trim(),
            });
      if (!mounted) return;
      final navigator = Navigator.of(context);
      final detail = <String, dynamic>{
        ...result,
        'title': widget.label,
        'category': _operation == 'CARD_TO_CARD'
            ? 'Sent'
            : _operation == 'CARD_TO_WALLET'
            ? 'Received'
            : _operation == 'PAYMENT_INFO'
            ? 'Bills'
            : 'Shopping',
        'date': 'Just now',
        'amount': _amount.text.isEmpty
            ? 'AFN —'
            : 'AFN ${(int.tryParse(_amount.text) ?? 0) / 100}',
        'reference': _reference.text.trim().isEmpty
            ? 'Secure mobile request'
            : _reference.text.trim(),
      };
      navigator.pop();
      // Wait for the route removal animation before opening the receipt.
      await Future<void>.delayed(const Duration(milliseconds: 320));
      if (!navigator.mounted) return;
      await navigator.push(
        MaterialPageRoute(
          builder: (_) => TransactionDetailPage(transaction: detail),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _submitting = false);
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          icon: const CircleAvatar(
            radius: 28,
            backgroundColor: Color(0xffffebee),
            child: Icon(Icons.wifi_off_rounded, color: Colors.red),
          ),
          title: const Text('Request unavailable'),
          content: const Text(
            'We could not confirm this request. For your safety, do not submit it again until you check transaction history.',
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Check Again Later'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.fromLTRB(
      20,
      12,
      20,
      20 + MediaQuery.viewInsetsOf(context).bottom,
    ),
    decoration: const BoxDecoration(
      color: AppColors.background,
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    child: Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xffd8dfeb),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 16),
            CircleAvatar(
              radius: 25,
              backgroundColor: AppColors.soft,
              child: Icon(_icon, color: AppColors.primary),
            ),
            const SizedBox(height: 10),
            Text(
              widget.label,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 5),
            const Text(
              'Enter and verify the secure transaction details',
              style: TextStyle(fontSize: 11, color: AppColors.muted),
            ),
            const SizedBox(height: 18),
            if (_operation != 'RECOVERY')
              TextFormField(
                controller: _merchant,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.store_outlined),
                  labelText: 'Merchant or recipient ID',
                ),
                validator: (value) => (value ?? '').trim().isEmpty
                    ? 'Merchant or recipient is required'
                    : null,
              ),
            if (_operation != 'RECOVERY') const SizedBox(height: 10),
            if (_operation != 'BALANCE_INQUIRY' && _operation != 'PAYMENT_INFO')
              TextFormField(
                controller: _amount,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.payments_outlined),
                  labelText: 'Amount (minor AFN)',
                ),
                validator: (value) {
                  final parsed = int.tryParse(value ?? '');
                  return parsed == null || parsed <= 0
                      ? 'Enter a valid amount greater than zero'
                      : null;
                },
              ),
            if (_operation != 'BALANCE_INQUIRY' && _operation != 'PAYMENT_INFO')
              const SizedBox(height: 10),
            TextFormField(
              controller: _reference,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.shield_outlined),
                labelText: _operation == 'RECOVERY'
                    ? 'Original transaction ID'
                    : 'Protected token/reference',
              ),
              validator: (value) =>
                  _operation == 'RECOVERY' && (value ?? '').trim().isEmpty
                  ? 'Original transaction ID is required'
                  : null,
            ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Continue Securely'),
            ),
            const SizedBox(height: 9),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock, size: 13, color: AppColors.muted),
                SizedBox(width: 4),
                Text(
                  'Protected by encrypted gateway processing',
                  style: TextStyle(fontSize: 10, color: AppColors.muted),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );

  IconData get _icon => switch (_operation) {
    'CARD_TO_CARD' => Icons.send_rounded,
    'CARD_TO_WALLET' => Icons.download_rounded,
    'BALANCE_INQUIRY' => Icons.account_balance_wallet_outlined,
    'RECOVERY' => Icons.history_rounded,
    _ => Icons.receipt_long_rounded,
  };
}

class _ConfirmRow extends StatelessWidget {
  const _ConfirmRow(this.label, this.value);
  final String label, value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: AppColors.muted, fontSize: 12),
          ),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
          ),
        ),
      ],
    ),
  );
}

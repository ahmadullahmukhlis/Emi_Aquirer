import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/app_theme.dart';
import '../../core/ui.dart';
import '../../services/gateway_client.dart';
import '../transactions/transaction_detail_page.dart';

class SendMoneyPage extends StatefulWidget {
  const SendMoneyPage({super.key, required this.client});
  final GatewayClient client;
  @override
  State<SendMoneyPage> createState() => _SendMoneyPageState();
}

class _SendMoneyPageState extends State<SendMoneyPage> {
  final _detailsKey = GlobalKey<FormState>();
  final _recipientCard = TextEditingController();
  final _amount = TextEditingController();
  final _note = TextEditingController();
  late final Future<List<Map<String, dynamic>>> _cards;
  Map<String, dynamic>? selectedCard;
  int step = 0;
  bool processing = false;

  @override
  void initState() {
    super.initState();
    _cards = widget.client.registeredCards();
  }

  @override
  void dispose() {
    _recipientCard.dispose();
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  String get pan => _recipientCard.text.replaceAll(RegExp(r'\D'), '');
  int get amountMinor =>
      ((double.tryParse(_amount.text.trim()) ?? 0) * 100).round();

  bool _luhn(String value) {
    if (value.length < 13 || value.length > 19) return false;
    var sum = 0;
    var alternate = false;
    for (var i = value.length - 1; i >= 0; i--) {
      var digit = int.parse(value[i]);
      if (alternate) {
        digit *= 2;
        if (digit > 9) digit -= 9;
      }
      sum += digit;
      alternate = !alternate;
    }
    return sum % 10 == 0;
  }

  void _toDetails() {
    if (selectedCard == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select one of your registered cards.')),
      );
      return;
    }
    setState(() => step = 1);
  }

  void _toReview() {
    if (!(_detailsKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    setState(() => step = 2);
  }

  Future<void> _submit() async {
    if (processing || selectedCard == null) return;
    setState(() => processing = true);
    try {
      final result = await widget.client.cardToCard(
        sourceCardId: selectedCard!['id'].toString(),
        recipientPan: pan,
        amountMinor: amountMinor,
        note: _note.text,
      );
      if (!mounted) return;
      await Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => TransactionDetailPage(
            transaction: {
              ...result,
              'title': 'Card Transfer',
              'category': 'Sent',
              'date': 'Just now',
              'amount': '- AFN ${(_amount.text)}',
              'method': selectedCard!['maskedPan'],
              'reference': 'Recipient •••• ${pan.substring(pan.length - 4)}',
            },
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => processing = false);
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          icon: const CircleAvatar(
            radius: 27,
            backgroundColor: Color(0xffffebee),
            child: Icon(Icons.error_outline, color: Colors.red),
          ),
          title: const Text('Transfer not confirmed'),
          content: const Text(
            'The gateway did not confirm this transfer. Do not submit it again until you check transaction history. This prevents duplicate card transfers.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Review'),
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
    appBar: AppBar(title: const Text('Send Money')),
    body: Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 6, 18, 10),
          child: Row(
            children: [
              _FlowStep(1, 'From card', step >= 0),
              const _FlowLine(),
              _FlowStep(2, 'Details', step >= 1),
              const _FlowLine(),
              _FlowStep(3, 'Review', step >= 2),
            ],
          ),
        ),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: step == 0
                ? _source()
                : step == 1
                ? _details()
                : _review(),
          ),
        ),
      ],
    ),
  );

  Widget _source() => FutureBuilder<List<Map<String, dynamic>>>(
    key: const ValueKey(0),
    future: _cards,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }
      if (snapshot.hasError) {
        return _StateMessage(
          Icons.cloud_off,
          'Cards unavailable',
          'Check your connection and try again.',
          () => setState(() {}),
        );
      }
      final cards = snapshot.data ?? const [];
      if (cards.isEmpty) {
        return _StateMessage(
          Icons.credit_card_off,
          'No registered cards',
          'Register and verify your own card from My Cards before sending money.',
          () => Navigator.pop(context),
        );
      }
      return ListView(
        padding: const EdgeInsets.all(18),
        children: [
          const Text(
            'Choose your card',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 5),
          const Text(
            'Money will be debited from this registered card.',
            style: TextStyle(color: AppColors.muted, fontSize: 12),
          ),
          const SizedBox(height: 16),
          ...cards.map((card) {
            final chosen = selectedCard?['id'] == card['id'];
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: InkWell(
                onTap: () => setState(() => selectedCard = card),
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  padding: const EdgeInsets.all(17),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: chosen
                          ? [const Color(0xff1732bb), AppColors.primary]
                          : [Colors.white, Colors.white],
                    ),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: chosen
                          ? AppColors.primary
                          : const Color(0xffe2e8f0),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.credit_card,
                        color: chosen ? Colors.white : AppColors.primary,
                      ),
                      const SizedBox(width: 13),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              card['brand']?.toString() ?? 'Card',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: chosen ? Colors.white : AppColors.ink,
                              ),
                            ),
                            Text(
                              card['maskedPan']?.toString() ?? '',
                              style: TextStyle(
                                color: chosen
                                    ? Colors.white70
                                    : AppColors.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (chosen)
                        const Icon(Icons.check_circle, color: Colors.white),
                    ],
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 12),
          FilledButton(onPressed: _toDetails, child: const Text('Continue')),
        ],
      );
    },
  );

  Widget _details() => Form(
    key: _detailsKey,
    child: ListView(
      key: const ValueKey(1),
      padding: const EdgeInsets.all(18),
      children: [
        const Text(
          'Receiver and amount',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 5),
        const Text(
          'The receiver card is used once and is never saved.',
          style: TextStyle(color: AppColors.muted, fontSize: 12),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _recipientCard,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(19),
            _CardNumberFormatter(),
          ],
          autofillHints: const [AutofillHints.creditCardNumber],
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.credit_card),
            labelText: 'Receiver card number',
            hintText: '1234 5678 9012 3456',
            helperText: 'This number will not be stored',
          ),
          validator: (value) {
            if (pan.isEmpty) return 'Receiver card number is required';
            if (!_luhn(pan)) return 'Enter a valid card number';
            return null;
          },
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _amount,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d{0,8}(\.\d{0,2})?')),
          ],
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.payments_outlined),
            labelText: 'Amount (AFN)',
            hintText: '0.00',
          ),
          validator: (value) {
            final parsed = double.tryParse(value ?? '');
            if (parsed == null || parsed <= 0) {
              return 'Enter an amount greater than zero';
            }
            if (parsed > 1000000) {
              return 'Amount exceeds the mobile transfer limit';
            }
            return null;
          },
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _note,
          maxLength: 140,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.edit_note),
            labelText: 'Note (optional)',
            hintText: 'What is this transfer for?',
          ),
        ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: _toReview,
          child: const Text('Review Transfer'),
        ),
        TextButton(
          onPressed: () => setState(() => step = 0),
          child: const Text('Change Source Card'),
        ),
      ],
    ),
  );

  Widget _review() => ListView(
    key: const ValueKey(2),
    padding: const EdgeInsets.all(18),
    children: [
      const Center(
        child: CircleAvatar(
          radius: 31,
          backgroundColor: AppColors.soft,
          child: Icon(
            Icons.verified_user_outlined,
            color: AppColors.primary,
            size: 31,
          ),
        ),
      ),
      const SizedBox(height: 11),
      const Center(
        child: Text(
          'Confirm Card Transfer',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
      ),
      const SizedBox(height: 17),
      PageCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _Summary('From', selectedCard?['maskedPan']?.toString() ?? ''),
            _Summary('To', '•••• •••• •••• ${pan.substring(pan.length - 4)}'),
            _Summary('Amount', 'AFN ${_amount.text}', strong: true),
            if (_note.text.trim().isNotEmpty)
              _Summary('Note', _note.text.trim()),
          ],
        ),
      ),
      const SizedBox(height: 12),
      const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lock_outline, color: AppColors.primary, size: 18),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Your receiver card number is encrypted in transit and is not saved in AfPay history or storage.',
              style: TextStyle(fontSize: 11, color: AppColors.muted),
            ),
          ),
        ],
      ),
      const SizedBox(height: 22),
      FilledButton(
        onPressed: processing ? null : _submit,
        child: processing
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text('Send AFN ${_amount.text}'),
      ),
      TextButton(
        onPressed: processing ? null : () => setState(() => step = 1),
        child: const Text('Edit Details'),
      ),
    ],
  );
}

class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(digits[i]);
    }
    final text = buffer.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

class _FlowStep extends StatelessWidget {
  const _FlowStep(this.number, this.label, this.active);
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
            fontSize: 10,
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

class _FlowLine extends StatelessWidget {
  const _FlowLine();
  @override
  Widget build(BuildContext context) =>
      const Expanded(child: Divider(indent: 7, endIndent: 7));
}

class _Summary extends StatelessWidget {
  const _Summary(this.label, this.value, {this.strong = false});
  final String label, value;
  final bool strong;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(label, style: const TextStyle(color: AppColors.muted)),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: strong ? 18 : 13,
            ),
          ),
        ),
      ],
    ),
  );
}

class _StateMessage extends StatelessWidget {
  const _StateMessage(this.icon, this.title, this.message, this.action);
  final IconData icon;
  final String title, message;
  final VoidCallback action;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 52, color: AppColors.muted),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: action,
            child: const Text('Go to My Cards'),
          ),
        ],
      ),
    ),
  );
}

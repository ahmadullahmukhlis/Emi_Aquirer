import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/app_theme.dart';
import '../../core/ui.dart';
import '../../services/gateway_client.dart';
import '../transactions/transaction_detail_page.dart';

class CardWalletPage extends StatefulWidget {
  const CardWalletPage({
    super.key,
    required this.client,
    required this.operation,
  });
  final GatewayClient client;
  final String operation;
  @override
  State<CardWalletPage> createState() => _CardWalletPageState();
}

class _CardWalletPageState extends State<CardWalletPage> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  late final Future<List<Map<String, dynamic>>> _cards;
  Map<String, dynamic>? card;
  int step = 0;
  bool processing = false;
  bool get cardToWallet => widget.operation == 'CARD_TO_WALLET';
  String get title => cardToWallet ? 'Card to Wallet' : 'Wallet to Card';
  @override
  void initState() {
    super.initState();
    _cards = widget.client.registeredCards();
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  int get amountMinor => ((double.tryParse(_amount.text) ?? 0) * 100).round();

  Future<void> _submit() async {
    if (processing || card == null) return;
    setState(() => processing = true);
    try {
      final result = await widget.client.cardWalletTransfer(
        operation: widget.operation,
        cardId: card!['id'].toString(),
        amountMinor: amountMinor,
      );
      if (!mounted) return;
      await Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => TransactionDetailPage(
            transaction: {
              ...result,
              'title': title,
              'category': cardToWallet ? 'Received' : 'Sent',
              'date': 'Just now',
              'amount': '${cardToWallet ? '+' : '-'} AFN ${_amount.text}',
              'method': card!['maskedPan'],
              'reference': 'AfPay Wallet',
            },
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => processing = false);
      await showDialog<void>(
        context: context,
        builder: (d) => AlertDialog(
          icon: const CircleAvatar(
            backgroundColor: Color(0xffffebee),
            child: Icon(Icons.error_outline, color: Colors.red),
          ),
          title: Text('$title not confirmed'),
          content: const Text(
            'Check transaction history before trying again. An unknown result must not be resubmitted as a new transfer.',
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(d),
              child: const Text('Review'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title)),
    body: Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              _Stage('1', 'Card', step >= 0),
              const Expanded(child: Divider(indent: 8, endIndent: 8)),
              _Stage('2', 'Amount', step >= 1),
              const Expanded(child: Divider(indent: 8, endIndent: 8)),
              _Stage('3', 'Review', step >= 2),
            ],
          ),
        ),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: step == 0
                ? _selectCard()
                : step == 1
                ? _enterAmount()
                : _review(),
          ),
        ),
      ],
    ),
  );

  Widget _selectCard() => FutureBuilder<List<Map<String, dynamic>>>(
    key: const ValueKey(0),
    future: _cards,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }
      final cards = snapshot.data ?? const [];
      if (cards.isEmpty) {
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(30),
            child: Text(
              'Register and verify a card in My Cards first.',
              textAlign: TextAlign.center,
            ),
          ),
        );
      }
      return ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Text(
            cardToWallet
                ? 'Choose the card to debit'
                : 'Choose the card to credit',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 5),
          Text(
            cardToWallet
                ? 'Funds move from your card into your AfPay wallet.'
                : 'Funds move from your AfPay wallet to your selected card.',
            style: const TextStyle(color: AppColors.muted, fontSize: 12),
          ),
          const SizedBox(height: 15),
          ...cards.map((c) {
            final selected = card?['id'] == c['id'];
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: InkWell(
                onTap: () => setState(() => card = c),
                borderRadius: BorderRadius.circular(16),
                child: PageCard(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: AppColors.soft,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.credit_card,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              c['maskedPan']?.toString() ?? '',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${c['brand'] ?? 'Card'} · ${c['holderName'] ?? ''}',
                              style: const TextStyle(
                                color: AppColors.muted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        selected
                            ? Icons.check_circle_rounded
                            : Icons.circle_outlined,
                        color: selected ? AppColors.primary : AppColors.muted,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 15),
          FilledButton(
            onPressed: card == null ? null : () => setState(() => step = 1),
            child: const Text('Continue'),
          ),
        ],
      );
    },
  );

  Widget _enterAmount() => Form(
    key: _formKey,
    child: ListView(
      key: const ValueKey(1),
      padding: const EdgeInsets.all(18),
      children: [
        const Text(
          'Enter amount',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 15),
        TextFormField(
          controller: _amount,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d{0,8}(\.\d{0,2})?')),
          ],
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.payments_outlined),
            labelText: 'Amount (AFN)',
            hintText: '0.00',
          ),
          validator: (v) {
            final n = double.tryParse(v ?? '');
            if (n == null || n <= 0) return 'Enter an amount greater than zero';
            if (n > 1000000) return 'Amount exceeds the mobile channel limit';
            return null;
          },
        ),
        const SizedBox(height: 22),
        FilledButton(
          onPressed: () {
            if (_formKey.currentState?.validate() ?? false) {
              FocusScope.of(context).unfocus();
              setState(() => step = 2);
            }
          },
          child: const Text('Review Transfer'),
        ),
        TextButton(
          onPressed: () => setState(() => step = 0),
          child: const Text('Change Card'),
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
            Icons.swap_horiz_rounded,
            color: AppColors.primary,
            size: 34,
          ),
        ),
      ),
      const SizedBox(height: 10),
      Center(
        child: Text(
          'Confirm $title',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
      ),
      const SizedBox(height: 17),
      PageCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _Row(
              'From',
              cardToWallet ? card!['maskedPan'].toString() : 'AfPay Wallet',
            ),
            _Row(
              'To',
              cardToWallet ? 'AfPay Wallet' : card!['maskedPan'].toString(),
            ),
            _Row('Amount', 'AFN ${_amount.text}', strong: true),
          ],
        ),
      ),
      const SizedBox(height: 12),
      const Text(
        'Verify the direction, card, and amount before confirming. This transaction uses a unique idempotency key.',
        style: TextStyle(fontSize: 11, color: AppColors.muted),
        textAlign: TextAlign.center,
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
            : Text('Confirm $title'),
      ),
      TextButton(
        onPressed: processing ? null : () => setState(() => step = 1),
        child: const Text('Edit Amount'),
      ),
    ],
  );
}

class _Stage extends StatelessWidget {
  const _Stage(this.number, this.label, this.active);
  final String number, label;
  final bool active;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      CircleAvatar(
        radius: 14,
        backgroundColor: active ? AppColors.primary : const Color(0xffdce3ed),
        child: Text(
          number,
          style: const TextStyle(color: Colors.white, fontSize: 10),
        ),
      ),
      const SizedBox(height: 4),
      Text(
        label,
        style: TextStyle(
          fontSize: 9,
          color: active ? AppColors.primary : AppColors.muted,
        ),
      ),
    ],
  );
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value, {this.strong = false});
  final String label, value;
  final bool strong;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Row(
      children: [
        Expanded(
          child: Text(label, style: const TextStyle(color: AppColors.muted)),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: strong ? 18 : 13,
          ),
        ),
      ],
    ),
  );
}

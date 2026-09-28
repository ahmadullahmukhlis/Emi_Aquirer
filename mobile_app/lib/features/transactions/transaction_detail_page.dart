import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../core/ui.dart';

class TransactionDetailPage extends StatelessWidget {
  const TransactionDetailPage({super.key, required this.transaction});
  final Map<String, dynamic> transaction;

  String get title =>
      transaction['title']?.toString() ??
      transaction['operation']?.toString().replaceAll('_', ' ') ??
      'Transaction';
  String get amount => transaction['amount']?.toString() ?? 'AFN —';
  String get status => transaction['status']?.toString() ?? 'Completed';

  @override
  Widget build(BuildContext context) {
    final successful =
        status.toUpperCase() == 'COMPLETED' ||
        status.toUpperCase() == 'APPROVED';
    final id =
        transaction['transactionId']?.toString() ??
        'TXN-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction Details'),
        actions: [
          IconButton(
            onPressed: () => _share(context),
            icon: const Icon(Icons.ios_share_outlined),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          PageCard(
            padding: const EdgeInsets.all(22),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 34,
                  backgroundColor:
                      (successful ? AppColors.success : Colors.orange)
                          .withValues(alpha: .12),
                  child: Icon(
                    successful ? Icons.check_rounded : Icons.schedule,
                    color: successful ? AppColors.success : Colors.orange,
                    size: 35,
                  ),
                ),
                const SizedBox(height: 13),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  amount,
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 8),
                Chip(
                  avatar: Icon(
                    successful ? Icons.check_circle : Icons.schedule,
                    size: 15,
                    color: successful ? AppColors.success : Colors.orange,
                  ),
                  label: Text(
                    status,
                    style: TextStyle(
                      color: successful ? AppColors.success : Colors.orange,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          PageCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _Detail(
                  'Date & time',
                  transaction['date']?.toString() ?? 'Today, 09:30 AM',
                ),
                _Detail('Transaction ID', id),
                _Detail(
                  'Category',
                  transaction['category']?.toString() ?? 'Payment',
                ),
                _Detail(
                  'Payment method',
                  transaction['method']?.toString() ?? 'Visa •••• 3456',
                ),
                _Detail(
                  'Reference',
                  transaction['reference']?.toString() ?? 'Mobile banking',
                ),
                _Detail(
                  'Response code',
                  transaction['responseCode']?.toString() ?? '00',
                  last: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          PageCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Status timeline',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 16),
                const _Timeline(
                  'Payment initiated',
                  'Request securely created',
                  true,
                ),
                const _Timeline(
                  'Authorized',
                  'Verified by your payment provider',
                  true,
                ),
                _Timeline(
                  successful ? 'Completed' : 'Processing',
                  successful
                      ? 'Payment completed successfully'
                      : 'Waiting for final confirmation',
                  successful,
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          OutlinedButton.icon(
            onPressed: () => _share(context),
            icon: const Icon(Icons.receipt_long_outlined),
            label: const Text('Download Receipt'),
          ),
          TextButton.icon(
            onPressed: () => showComingSoon(context, 'Transaction support'),
            icon: const Icon(Icons.help_outline),
            label: const Text('Get Help With This Transaction'),
          ),
        ],
      ),
    );
  }

  void _share(BuildContext context) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(const SnackBar(content: Text('Receipt prepared securely.')));
}

class _Detail extends StatelessWidget {
  const _Detail(this.label, this.value, {this.last = false});
  final String label, value;
  final bool last;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 11),
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
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
      if (!last) const Divider(height: 1),
    ],
  );
}

class _Timeline extends StatelessWidget {
  const _Timeline(this.title, this.subtitle, this.done);
  final String title, subtitle;
  final bool done;
  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Column(
        children: [
          CircleAvatar(
            radius: 10,
            backgroundColor: done ? AppColors.success : Colors.orange,
            child: Icon(
              done ? Icons.check : Icons.more_horiz,
              color: Colors.white,
              size: 12,
            ),
          ),
          Container(width: 2, height: 38, color: const Color(0xffe1e7f0)),
        ],
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
            Text(
              subtitle,
              style: const TextStyle(color: AppColors.muted, fontSize: 11),
            ),
          ],
        ),
      ),
    ],
  );
}

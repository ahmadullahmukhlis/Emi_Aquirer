import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../core/ui.dart';
import '../../services/gateway_client.dart';
import 'transaction_detail_page.dart';
import 'transaction_sheet.dart';

class TransactionsPage extends StatefulWidget {
  const TransactionsPage({super.key, required this.client});
  final GatewayClient client;
  @override
  State<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage> {
  String _filter = 'All';
  String _query = '';
  late final Future<List<Map<String, dynamic>>> _history;

  @override
  void initState() {
    super.initState();
    _history = widget.client.history();
  }

  static final _demo = <Map<String, dynamic>>[
    {
      'title': 'Salary Credit',
      'category': 'Received',
      'date': 'Today, 09:30 AM',
      'amount': '+ \$2,000.00',
      'status': 'Completed',
      'icon': 'salary',
    },
    {
      'title': 'Amazon',
      'category': 'Shopping',
      'date': 'Today, 11:20 AM',
      'amount': '- \$120.00',
      'status': 'Completed',
      'icon': 'shop',
    },
    {
      'title': 'Electricity Bill',
      'category': 'Bills',
      'date': 'Today, 10:15 AM',
      'amount': '- \$75.00',
      'status': 'Completed',
      'icon': 'bill',
    },
    {
      'title': 'Money to Sarah',
      'category': 'Sent',
      'date': 'Today, 09:50 AM',
      'amount': '- \$200.00',
      'status': 'Completed',
      'icon': 'send',
    },
    {
      'title': 'Received from Alex',
      'category': 'Received',
      'date': 'Yesterday, 06:14 PM',
      'amount': '+ \$500.00',
      'status': 'Completed',
      'icon': 'receive',
    },
    {
      'title': 'Netflix',
      'category': 'Shopping',
      'date': 'Yesterday, 02:20 PM',
      'amount': '- \$15.00',
      'status': 'Completed',
      'icon': 'shop',
    },
    {
      'title': 'Water Bill',
      'category': 'Bills',
      'date': 'Yesterday, 11:05 AM',
      'amount': '- \$30.00',
      'status': 'Completed',
      'icon': 'bill',
    },
    {
      'title': 'Restaurant',
      'category': 'Shopping',
      'date': 'Yesterday, 08:45 AM',
      'amount': '- \$45.00',
      'status': 'Completed',
      'icon': 'shop',
    },
  ];

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
    children: [
      TextField(
        onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
        decoration: const InputDecoration(
          prefixIcon: Icon(Icons.search),
          hintText: 'Search transactions, merchants or amounts...',
        ),
      ),
      const SizedBox(height: 10),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: ['All', 'Sent', 'Received', 'Bills', 'Shopping']
              .map(
                (v) => Padding(
                  padding: const EdgeInsets.only(right: 7),
                  child: ChoiceChip(
                    label: Text(v),
                    selected: _filter == v,
                    onSelected: (_) => setState(() => _filter = v),
                  ),
                ),
              )
              .toList(),
        ),
      ),
      const SizedBox(height: 14),
      FutureBuilder<List<Map<String, dynamic>>>(
        future: _history,
        initialData: const <Map<String, dynamic>>[],
        builder: (context, snapshot) {
          final source = [
            ...(snapshot.data ?? const <Map<String, dynamic>>[]),
            ..._demo,
          ];
          final seen = <String>{};
          final items = source.where((item) {
            final title =
                item['title']?.toString() ??
                item['operation']?.toString().replaceAll('_', ' ') ??
                'Transaction';
            final key =
                '${item['transactionId'] ?? ''}-$title-${item['date'] ?? ''}';
            if (!seen.add(key)) return false;
            final category =
                item['category']?.toString() ??
                _category(item['operation']?.toString());
            final filterMatches =
                _filter == 'All' ||
                category.toLowerCase() == _filter.toLowerCase();
            return filterMatches &&
                (title.toLowerCase().contains(_query) ||
                    (item['amount']?.toString() ?? '').toLowerCase().contains(
                      _query,
                    ));
          }).toList();
          if (items.isEmpty) {
            return const Padding(
              padding: EdgeInsets.all(38),
              child: Column(
                children: [
                  Icon(Icons.search_off, size: 45, color: AppColors.muted),
                  SizedBox(height: 10),
                  Text('No matching transactions'),
                ],
              ),
            );
          }
          final today = items
              .where(
                (e) => !(e['date']?.toString() ?? '').startsWith('Yesterday'),
              )
              .toList();
          final yesterday = items
              .where(
                (e) => (e['date']?.toString() ?? '').startsWith('Yesterday'),
              )
              .toList();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (today.isNotEmpty) ...[
                const SectionTitle('Today'),
                _Group(today, client: widget.client),
              ],
              if (yesterday.isNotEmpty) ...[
                const SizedBox(height: 13),
                const SectionTitle('Yesterday'),
                _Group(yesterday, client: widget.client),
              ],
            ],
          );
        },
      ),
    ],
  );

  static String _category(String? op) => switch (op) {
    'CARD_TO_CARD' => 'Sent',
    'CARD_TO_WALLET' => 'Received',
    'PAYMENT_INFO' => 'Bills',
    _ => 'Shopping',
  };
}

class _Group extends StatelessWidget {
  const _Group(this.items, {required this.client});
  final List<Map<String, dynamic>> items;
  final GatewayClient client;
  @override
  Widget build(BuildContext context) => PageCard(
    child: Column(
      children: items.indexed.expand((pair) {
        final index = pair.$1;
        final item = pair.$2;
        final name =
            item['title']?.toString() ??
            item['operation']?.toString().replaceAll('_', ' ') ??
            'Transaction';
        final positive = (item['amount']?.toString() ?? '').startsWith('+');
        final pending = item['status']?.toString().toUpperCase() == 'PENDING';
        return [
          ListTile(
            onTap: () => pending
                ? showTransactionSheet(
                    context,
                    client: client,
                    label: 'Pending recovery',
                  )
                : Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TransactionDetailPage(transaction: item),
                    ),
                  ),
            leading: CircleAvatar(
              backgroundColor:
                  (positive ? AppColors.success : AppColors.primary).withValues(
                    alpha: .1,
                  ),
              child: Icon(
                _icon(item['icon']?.toString()),
                color: positive ? AppColors.success : AppColors.primary,
                size: 21,
              ),
            ),
            title: Text(
              name,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
            subtitle: Text(
              item['date']?.toString() ??
                  item['status']?.toString() ??
                  'Completed',
              style: const TextStyle(fontSize: 10, color: AppColors.muted),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item['amount']?.toString() ??
                      item['responseCode']?.toString() ??
                      '',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: positive ? AppColors.success : AppColors.ink,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.chevron_right,
                  size: 17,
                  color: AppColors.muted,
                ),
              ],
            ),
          ),
          if (index != items.length - 1) const Divider(height: 1, indent: 64),
        ];
      }).toList(),
    ),
  );
  static IconData _icon(String? value) => switch (value) {
    'salary' => Icons.arrow_upward,
    'shop' => Icons.shopping_cart,
    'bill' => Icons.receipt_long,
    'send' => Icons.send,
    'receive' => Icons.arrow_downward,
    _ => Icons.receipt_long,
  };
}

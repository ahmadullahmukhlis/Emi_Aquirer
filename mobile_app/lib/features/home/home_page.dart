import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../core/ui.dart';
import '../../services/gateway_client.dart';
import '../payments/bills_page.dart';
import '../payments/card_wallet_page.dart';
import '../payments/send_money_page.dart';
import '../payments/transaction_hub_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key, required this.client});
  final GatewayClient client;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
    children: [
      Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xff65cfff), AppColors.primary],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.spa, color: Colors.white),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'AfPay',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
          ),
          IconButton(
            onPressed: () => showComingSoon(context, 'Notifications'),
            icon: const Badge(
              smallSize: 8,
              child: Icon(Icons.notifications_none_rounded),
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      Container(
        height: 155,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xff5469f7), Color(0xff087af3), Color(0xff00b9ef)],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Color(0x300867f2),
              blurRadius: 22,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Current Balance', style: TextStyle(color: Colors.white)),
                SizedBox(width: 5),
                Icon(Icons.visibility_outlined, size: 15, color: Colors.white),
              ],
            ),
            SizedBox(height: 5),
            Text(
              '\$5,280.00 ›',
              style: TextStyle(
                color: Colors.white,
                fontSize: 29,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 8),
            Text(
              '↑ 12.5% this month',
              style: TextStyle(
                color: Color(0xffcaffdf),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            Spacer(),
            Align(
              alignment: Alignment.centerRight,
              child: Icon(Icons.account_balance_wallet, color: Colors.white70),
            ),
          ],
        ),
      ),
      const SizedBox(height: 14),
      Row(
        children: [
          _Action(
            Icons.send_rounded,
            'Send',
            Colors.blue,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => SendMoneyPage(client: client)),
            ),
          ),
          _Action(
            Icons.download_rounded,
            'Receive',
            Colors.green,
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    CardWalletPage(client: client, operation: 'CARD_TO_WALLET'),
              ),
            ),
          ),
          _Action(
            Icons.receipt_long,
            'Pay Bills',
            Colors.blue,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => BillsPage(client: client)),
            ),
          ),
          _Action(
            Icons.grid_view_rounded,
            'More',
            Colors.blue,
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => TransactionHubPage(client: client),
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 18),
      SectionTitle('Recent Transactions', action: 'See All', onAction: () {}),
      const SizedBox(height: 4),
      const PageCard(
        child: Column(
          children: [
            _Transaction(
              Icons.arrow_upward_rounded,
              'Salary Credit',
              'Today, 09:30 AM',
              '+ \$2,000.00',
              AppColors.success,
            ),
            Divider(height: 1, indent: 64),
            _Transaction(
              Icons.shopping_cart,
              'Amazon',
              'Today, 11:20 AM',
              '- \$120.00',
              Colors.orange,
            ),
            Divider(height: 1, indent: 64),
            _Transaction(
              Icons.bolt,
              'Electricity Bill',
              'Today, 10:15 AM',
              '- \$75.00',
              Colors.orange,
            ),
            Divider(height: 1, indent: 64),
            _Transaction(
              Icons.send,
              'Money to Sarah',
              'Today, 09:50 AM',
              '- \$200.00',
              Colors.blue,
            ),
          ],
        ),
      ),
    ],
  );
}

class _Action extends StatelessWidget {
  const _Action(this.icon, this.label, this.color, this.onTap);
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Expanded(
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 7),
            Text(
              label,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    ),
  );
}

class _Transaction extends StatelessWidget {
  const _Transaction(this.icon, this.title, this.time, this.amount, this.color);
  final IconData icon;
  final String title, time, amount;
  final Color color;
  @override
  Widget build(BuildContext context) => ListTile(
    leading: CircleAvatar(
      backgroundColor: color.withValues(alpha: .12),
      child: Icon(icon, color: color, size: 21),
    ),
    title: Text(
      title,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
    ),
    subtitle: Text(
      time,
      style: const TextStyle(fontSize: 10, color: AppColors.muted),
    ),
    trailing: Text(
      amount,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        color: amount.startsWith('+') ? AppColors.success : AppColors.ink,
      ),
    ),
  );
}

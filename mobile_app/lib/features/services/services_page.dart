import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../core/ui.dart';
import '../../services/gateway_client.dart';
import '../payments/bills_page.dart';
import '../payments/mobile_recharge_page.dart';
import '../payments/send_money_page.dart';
import '../payments/transaction_hub_page.dart';
import '../transactions/transaction_sheet.dart';

class ServicesPage extends StatelessWidget {
  const ServicesPage({super.key, required this.client});
  final GatewayClient client;

  @override
  Widget build(BuildContext context) {
    final services = <(IconData, String, Color, VoidCallback)>[
      (
        Icons.phone_iphone,
        'Mobile\nRecharge',
        AppColors.primary,
        () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => MobileRechargePage(client: client)),
        ),
      ),
      (
        Icons.account_balance,
        'Bank\nTransfer',
        Colors.orange,
        () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => SendMoneyPage(client: client)),
        ),
      ),
      (
        Icons.credit_card,
        'Card\nPayment',
        Colors.purple,
        () =>
            showTransactionSheet(context, client: client, label: 'Scan & pay'),
      ),
      (
        Icons.bolt,
        'Utilities',
        Colors.orange,
        () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => BillsPage(client: client)),
        ),
      ),
      (
        Icons.savings,
        'Loan',
        Colors.orange,
        () => showComingSoon(context, 'Loan'),
      ),
      (
        Icons.verified_user,
        'Insurance',
        AppColors.success,
        () => showComingSoon(context, 'Insurance'),
      ),
      (
        Icons.account_balance,
        'Government',
        Colors.orange,
        () => showComingSoon(context, 'Government services'),
      ),
      (
        Icons.qr_code_scanner,
        'QR Payment',
        AppColors.primary,
        () =>
            showTransactionSheet(context, client: client, label: 'Scan & pay'),
      ),
      (
        Icons.more_horiz,
        'More',
        AppColors.ink,
        () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => TransactionHubPage(client: client)),
        ),
      ),
    ];
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
      children: [
        const Text(
          'Services',
          style: TextStyle(fontSize: 23, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 14),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: services.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.05,
          ),
          itemBuilder: (_, index) {
            final item = services[index];
            return InkWell(
              onTap: item.$4,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(item.$1, color: item.$3, size: 27),
                    const SizedBox(height: 8),
                    Text(
                      item.$2,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 18),
        InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => BillsPage(client: client)),
          ),
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xffeef4ff), Color(0xffdff1ff)],
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.primary,
                  child: Icon(Icons.receipt_long, color: Colors.white),
                ),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pay Bills Easily',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Fast, secure and convenient',
                        style: TextStyle(fontSize: 11, color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: AppColors.primary),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        const SectionTitle('Featured', action: 'See All'),
        const SizedBox(height: 8),
        Row(
          children: [
            _Featured(
              Icons.wifi,
              'Internet Bill',
              Colors.blue,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => BillsPage(client: client)),
              ),
            ),
            _Featured(
              Icons.tv,
              'TV Bill',
              Colors.purple,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => BillsPage(client: client)),
              ),
            ),
            _Featured(
              Icons.school,
              'Education',
              AppColors.success,
              () => showComingSoon(context, 'Education'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _Featured(
              Icons.health_and_safety,
              'Healthcare',
              AppColors.success,
              () => showComingSoon(context, 'Healthcare'),
            ),
            _Featured(
              Icons.volunteer_activism,
              'Donations',
              Colors.orange,
              () => showComingSoon(context, 'Donations'),
            ),
            _Featured(
              Icons.directions_car,
              'Transport',
              AppColors.primary,
              () => showComingSoon(context, 'Transport'),
            ),
          ],
        ),
      ],
    );
  }
}

class _Featured extends StatelessWidget {
  const _Featured(this.icon, this.label, this.color, this.onTap);
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Expanded(
    child: InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 7),
            Text(
              label,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    ),
  );
}

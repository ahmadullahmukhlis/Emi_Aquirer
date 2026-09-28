import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../core/ui.dart';
import '../../services/gateway_client.dart';
import '../transactions/transaction_sheet.dart';

class CardsPage extends StatelessWidget {
  const CardsPage({super.key, required this.client});
  final GatewayClient client;
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
    children: [
      const SizedBox(height: 12),
      const BankCardPreview(),
      const SizedBox(height: 16),
      Row(
        children: [
          _CardAction(
            Icons.lock,
            'Lock Card',
            () => showComingSoon(context, 'Lock card'),
          ),
          _CardAction(
            Icons.credit_card,
            'Card Details',
            () => showComingSoon(context, 'Card details'),
          ),
          _CardAction(
            Icons.tune,
            'Manage Limits',
            () => showComingSoon(context, 'Manage limits'),
          ),
          _CardAction(
            Icons.delete_outline,
            'Remove',
            () => showComingSoon(context, 'Remove card'),
            color: Colors.red,
          ),
        ],
      ),
      const SizedBox(height: 16),
      PageCard(
        child: Column(
          children: [
            AppTile(
              icon: Icons.add_circle,
              title: 'Add New Card',
              subtitle: 'Register a new debit or credit card',
              onTap: () => showComingSoon(context, 'Add card'),
            ),
            const Divider(height: 1, indent: 62),
            AppTile(
              icon: Icons.settings,
              title: 'Manage Card Settings',
              subtitle: 'Set limits, online payments, and more',
              onTap: () => showComingSoon(context, 'Card settings'),
            ),
            const Divider(height: 1, indent: 62),
            AppTile(
              icon: Icons.credit_card,
              title: 'Request a New Card',
              subtitle: 'Get a replacement or new card',
              onTap: () => showComingSoon(context, 'New card request'),
            ),
            const Divider(height: 1, indent: 62),
            AppTile(
              icon: Icons.account_balance_wallet,
              title: 'Balance inquiry',
              subtitle: 'Read permitted balance through the gateway',
              onTap: () => showTransactionSheet(
                context,
                client: client,
                label: 'Balance',
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 14),
      const SectionTitle('Linked Cards', action: 'See All'),
      const SizedBox(height: 6),
      FutureBuilder<List<Map<String, dynamic>>>(
        future: client.registeredCards(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(),
              ),
            );
          }
          final cards = snapshot.data ?? const <Map<String, dynamic>>[];
          if (cards.isEmpty) {
            return const PageCard(
              padding: EdgeInsets.all(20),
              child: Center(child: Text('No verified cards registered yet.')),
            );
          }
          return PageCard(
            child: Column(
              children: cards.indexed.expand((entry) {
                final index = entry.$1;
                final card = entry.$2;
                return [
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: card['brand'] == 'VISA'
                          ? AppColors.primary
                          : Colors.black,
                      child: const Icon(
                        Icons.credit_card,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    title: Text(card['maskedPan']?.toString() ?? 'Masked card'),
                    subtitle: Text(
                      '${card['brand'] ?? 'Card'} · ${card['holderName'] ?? ''}',
                    ),
                    trailing: const Chip(
                      label: Text(
                        'Active',
                        style: TextStyle(fontSize: 9, color: AppColors.success),
                      ),
                    ),
                  ),
                  if (index != cards.length - 1)
                    const Divider(height: 1, indent: 62),
                ];
              }).toList(),
            ),
          );
        },
      ),
    ],
  );
}

class _CardAction extends StatelessWidget {
  const _CardAction(
    this.icon,
    this.label,
    this.onTap, {
    this.color = AppColors.primary,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;
  @override
  Widget build(BuildContext context) => Expanded(
    child: InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: color, size: 21),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    ),
  );
}

import 'package:flutter/material.dart';
import '../../core/banking_header.dart';
import '../../core/app_theme.dart';
import '../../core/ui.dart';
import '../../services/gateway_client.dart';
import '../transactions/transaction_sheet.dart';
import 'bills_page.dart';
import 'card_wallet_page.dart';
import 'mobile_recharge_page.dart';
import 'send_money_page.dart';

class TransactionHubPage extends StatelessWidget {
  const TransactionHubPage({super.key, required this.client});
  final GatewayClient client;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: BankingHeader(title: const Text('All Transactions')),
    body: ListView(
      padding: const EdgeInsets.all(18),
      children: [
        const Text(
          'Move money',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 9),
        PageCard(
          child: Column(
            children: [
              AppTile(
                icon: Icons.credit_card,
                title: 'Card to Card',
                subtitle: 'Send to a switch-supported card',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SendMoneyPage(client: client),
                  ),
                ),
              ),
              const Divider(height: 1, indent: 62),
              AppTile(
                icon: Icons.account_balance_wallet_outlined,
                title: 'Card to Wallet',
                subtitle: 'Fund your MSHpay wallet from a registered card',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CardWalletPage(
                      client: client,
                      operation: 'CARD_TO_WALLET',
                    ),
                  ),
                ),
              ),
              const Divider(height: 1, indent: 62),
              AppTile(
                icon: Icons.credit_score,
                title: 'Wallet to Card',
                subtitle: 'Move wallet funds to a registered card',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CardWalletPage(
                      client: client,
                      operation: 'WALLET_TO_CARD',
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          'Pay and inquire',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 9),
        PageCard(
          child: Column(
            children: [
              AppTile(
                icon: Icons.shopping_bag_outlined,
                title: 'Purchase',
                subtitle: 'Purchase through the secure gateway',
                onTap: () => showTransactionSheet(
                  context,
                  client: client,
                  label: 'Scan & pay',
                ),
              ),
              const Divider(height: 1, indent: 62),
              AppTile(
                icon: Icons.receipt_long,
                title: 'Bill Payment',
                subtitle: 'Electricity, water, internet and more',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => BillsPage(client: client)),
                ),
              ),
              const Divider(height: 1, indent: 62),
              AppTile(
                icon: Icons.phone_iphone,
                title: 'Mobile Recharge',
                subtitle: 'Airtime only — not a money transfer',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MobileRechargePage(client: client),
                  ),
                ),
              ),
              const Divider(height: 1, indent: 62),
              AppTile(
                icon: Icons.account_balance_wallet,
                title: 'Balance Inquiry',
                subtitle: 'Check a permitted card or wallet balance',
                onTap: () => showTransactionSheet(
                  context,
                  client: client,
                  label: 'Balance',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.soft,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.security, color: AppColors.primary),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Cash-in and cash-out require an approved agent or POS terminal and are unavailable as remote mobile transactions.',
                  style: TextStyle(fontSize: 11, color: AppColors.muted),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

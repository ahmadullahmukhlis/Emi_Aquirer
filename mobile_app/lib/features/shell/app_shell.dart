import 'package:flutter/material.dart';

import '../../services/gateway_client.dart';
import '../../core/banking_header.dart';
import '../../core/ui.dart';
import '../cards/cards_page.dart';
import '../home/home_page.dart';
import '../profile/profile_page.dart';
import '../services/services_page.dart';
import '../transactions/transactions_page.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.client});

  final GatewayClient client;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomePage(
        client: widget.client,
        onSeeAll: () => setState(() => _index = 1),
      ),
      TransactionsPage(client: widget.client),
      CardsPage(client: widget.client),
      ServicesPage(client: widget.client),
      ProfilePage(client: widget.client),
    ];
    return Scaffold(
      appBar: BankingHeader(
        title: Text(
          ['MSHpay', 'Transactions', 'My Cards', 'Services', 'Profile'][_index],
        ),
        automaticallyImplyLeading: false,
        actions: [
          if (_index == 2)
            IconButton(
              tooltip: 'Add card',
              icon: const Icon(Icons.add),
              onPressed: () => showComingSoon(context, 'Add card'),
            )
          else if (_index == 4)
            IconButton(
              tooltip: 'Settings',
              icon: const Icon(Icons.settings_outlined),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsPage()),
              ),
            )
          else
            IconButton(
              tooltip: 'Notifications',
              icon: const Icon(Icons.notifications_none_rounded),
              onPressed: () => showComingSoon(context, 'Notifications'),
            ),
          const SizedBox(width: 10),
        ],
      ),
      body: SafeArea(
        top: false,
        child: IndexedStack(index: _index, children: pages),
      ),
      bottomNavigationBar: NavigationBar(
        height: 68,
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xffe8f5f3),
        selectedIndex: _index,
        onDestinationSelected: (value) {
          FocusManager.instance.primaryFocus?.unfocus();
          setState(() => _index = value);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            label: 'Transactions',
          ),
          NavigationDestination(
            icon: Icon(Icons.credit_card_outlined),
            label: 'Cards',
          ),
          NavigationDestination(
            icon: Icon(Icons.grid_view_outlined),
            selectedIcon: Icon(Icons.grid_view_rounded),
            label: 'Services',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

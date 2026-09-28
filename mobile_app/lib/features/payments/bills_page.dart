import 'package:flutter/material.dart';
import '../../core/banking_header.dart';

import '../../core/ui.dart';
import '../../services/gateway_client.dart';
import '../transactions/transaction_sheet.dart';

class BillsPage extends StatelessWidget {
  const BillsPage({super.key, required this.client});
  final GatewayClient client;
  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.bolt, 'Electricity Bill', Colors.orange),
      (Icons.water_drop, 'Water Bill', Colors.blue),
      (Icons.wifi, 'Internet Bill', Colors.teal),
      (Icons.tv, 'TV Bill', Colors.red),
      (Icons.phone_android, 'Mobile Postpaid', Colors.purple),
      (Icons.school, 'Education Fee', Colors.green),
      (Icons.health_and_safety, 'Health Insurance', Colors.redAccent),
      (Icons.account_balance, 'Government Services', Colors.orange),
    ];
    return Scaffold(
      appBar: BankingHeader(title: const Text('Pay Bills')),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          const TextField(
            decoration: InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Search biller or service...',
            ),
          ),
          const SizedBox(height: 14),
          PageCard(
            child: Column(
              children: items
                  .map(
                    (e) => AppTile(
                      icon: e.$1,
                      title: e.$2,
                      color: e.$3,
                      onTap: () => showTransactionSheet(
                        context,
                        client: client,
                        label: 'Pay bills',
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

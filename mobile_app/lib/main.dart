import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const gold = Color(0xff006d73),
    darkGold = Color(0xff003f4a),
    cream = Color(0xfff6f9fb);
const _authUrl = String.fromEnvironment(
  'AUTH_API_URL',
  defaultValue: 'http://10.0.2.2:8080/api/auth-service',
);
const _gatewayUrl = String.fromEnvironment(
  'GATEWAY_API_URL',
  defaultValue: 'http://10.0.2.2:8081/api/gateway',
);

class GatewayClient {
  GatewayClient()
    : _auth = Dio(BaseOptions(baseUrl: _authUrl)),
      _gateway = Dio(BaseOptions(baseUrl: _gatewayUrl));
  final Dio _auth, _gateway;
  final storage = const FlutterSecureStorage();
  Future<void> login(String u, String p) async {
    final r = await _auth.post('/login', data: {'username': u, 'password': p});
    final t = (r.data['data'] as Map?)?['accessToken'];
    if (t == null) throw Exception('Sign in failed');
    await storage.write(key: 'access_token', value: t.toString());
  }

  Future<Map<String, dynamic>> transaction(
    String operation,
    Map<String, dynamic> body,
  ) async {
    final t = await storage.read(key: 'access_token');
    final r = await _gateway.post(
      '/api/v1/mobile/transactions/$operation',
      data: body,
      options: Options(
        headers: t == null ? null : {'Authorization': 'Bearer $t'},
      ),
    );
    final result = Map<String, dynamic>.from(r.data);
    final saved = await history();
    saved.removeWhere(
      (item) => item['transactionId'] == result['transactionId'],
    );
    saved.insert(0, {
      ...result,
      'operation': operation,
      'createdAt': DateTime.now().toIso8601String(),
    });
    await storage.write(
      key: 'mobile_transaction_history',
      value: jsonEncode(saved.take(50).toList()),
    );
    return result;
  }

  Future<List<Map<String, dynamic>>> history() async {
    final raw = await storage.read(key: 'mobile_transaction_history');
    if (raw == null || raw.isEmpty) return [];
    try {
      return (jsonDecode(raw) as List)
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<dynamic> get(String path) async {
    final t = await storage.read(key: 'access_token');
    final r = await _gateway.get(
      path,
      options: Options(
        headers: t == null ? null : {'Authorization': 'Bearer $t'},
      ),
    );
    return r.data;
  }
}

void main() => runApp(const AcquirerMobile());

class AcquirerMobile extends StatelessWidget {
  const AcquirerMobile({super.key});
  @override
  Widget build(BuildContext c) => MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      colorSchemeSeed: gold,
      scaffoldBackgroundColor: cream,
    ),
    home: const SessionGate(),
  );
}

class SessionGate extends StatefulWidget {
  const SessionGate({super.key});
  @override
  State<SessionGate> createState() => _SessionGateState();
}

class _SessionGateState extends State<SessionGate> {
  final username = TextEditingController(), password = TextEditingController();
  bool loading = false;
  Future<void> submit() async {
    setState(() => loading = true);
    try {
      await GatewayClient().login(username.text.trim(), password.text);
      if (mounted) {
        Navigator.of(
          context,
        ).pushReplacement(MaterialPageRoute(builder: (_) => const AppShell()));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Sign-in failed. Check your credentials and connection.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  void dispose() {
    username.dispose();
    password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.account_balance, color: gold, size: 66),
              const SizedBox(height: 18),
              const Text(
                'Acquirer Mobile',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              const Text(
                'Secure merchant and payment access',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              TextField(
                controller: username,
                autocorrect: false,
                decoration: const InputDecoration(labelText: 'Username'),
              ),
              TextField(
                controller: password,
                obscureText: true,
                enableSuggestions: false,
                decoration: const InputDecoration(labelText: 'Password'),
              ),
              const SizedBox(height: 22),
              FilledButton(
                onPressed: loading ? null : submit,
                child: Text(loading ? 'Signing in…' : 'Sign in'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _CardAction extends StatelessWidget {
  const _CardAction({required this.icon, required this.label});
  final IconData icon;
  final String label;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 76,
    child: Column(
      children: [
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(17),
            boxShadow: const [
              BoxShadow(color: Color(0x12003f4a), blurRadius: 12),
            ],
          ),
          child: Icon(icon, color: gold),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
        ),
      ],
    ),
  );
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int tab = 0;
  String transactionFilter = 'All';
  @override
  Widget build(BuildContext c) {
    final pages = [home(), transactions(), cards(), profile()];
    return Scaffold(
      body: SafeArea(child: pages[tab]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (v) => setState(() => tab = v),
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
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget home() => ListView(
    padding: EdgeInsets.zero,
    children: [
      Container(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [darkGold, gold, Color(0xff0c9792)],
          ),
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(34)),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'My App',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 31,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Badge(
                  child: Icon(
                    Icons.notifications_none_rounded,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            Text(
              'Your Finances\nIn One Place',
              style: TextStyle(
                color: Colors.white,
                fontSize: 26,
                height: 1.06,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Send, pay, manage and grow — securely\nand effortlessly.',
              style: TextStyle(color: Color(0xffd5f7f3), fontSize: 14),
            ),
          ],
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Transform.translate(offset: const Offset(0, -18), child: card()),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            quick(Icons.send_rounded, 'Transfer'),
            quick(Icons.download_rounded, 'Receive'),
            quick(Icons.receipt_long_rounded, 'Pay bills'),
            quick(Icons.grid_view_rounded, 'More'),
          ],
        ),
      ),
      const Padding(
        padding: EdgeInsets.fromLTRB(20, 28, 20, 4),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Recent Transactions',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            Text(
              'See All',
              style: TextStyle(color: gold, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            row(
              Icons.shopping_bag_rounded,
              'Merchant purchase',
              'Today · Approved',
              '- AFN 1,250',
            ),
            row(
              Icons.call_received_rounded,
              'Card to wallet',
              'Yesterday · Approved',
              '+ AFN 500',
            ),
          ],
        ),
      ),
      const SizedBox(height: 20),
    ],
  );
  Widget card() => Container(
    height: 185,
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [darkGold, gold, Color(0xff11a7a0)],
      ),
      borderRadius: BorderRadius.circular(25),
      boxShadow: const [
        BoxShadow(
          color: Color(0x40003f4a),
          blurRadius: 20,
          offset: Offset(0, 10),
        ),
      ],
    ),
    child: const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Available balance', style: TextStyle(color: Color(0xffc9f5f0))),
        SizedBox(height: 8),
        Text(
          'AFN ••••••',
          style: TextStyle(
            color: Colors.white,
            fontSize: 29,
            fontWeight: FontWeight.bold,
          ),
        ),
        Spacer(),
        Text(
          '••••  ••••  ••••  3456',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
        SizedBox(height: 6),
        Text(
          'Protected primary card',
          style: TextStyle(color: Color(0xffc9f5f0)),
        ),
      ],
    ),
  );
  Widget quick(IconData i, String t) => InkWell(
    onTap: () => _transactionSheet(t),
    borderRadius: BorderRadius.circular(30),
    child: Column(
      children: [
        CircleAvatar(
          radius: 27,
          backgroundColor: const Color(0xffe4f7f5),
          child: Icon(i, color: darkGold),
        ),
        const SizedBox(height: 6),
        Text(t, style: const TextStyle(fontSize: 11)),
      ],
    ),
  );
  void _transactionSheet(String label) {
    final merchant = TextEditingController(),
        amount = TextEditingController(),
        reference = TextEditingController();
    final operation =
        {
          'Transfer': 'CARD_TO_CARD',
          'Receive': 'CARD_TO_WALLET',
          'Pay bills': 'PAYMENT_INFO',
          'Balance': 'BALANCE_INQUIRY',
          'Scan & pay': 'PURCHASE',
          'More': 'PAYMENT_INFO',
          'Pending recovery': 'RECOVERY',
        }[label] ??
        'PURCHASE';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (c) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          20 + MediaQuery.of(c).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            if (operation != 'RECOVERY')
              TextField(
                controller: merchant,
                decoration: const InputDecoration(labelText: 'Merchant ID'),
              ),
            if (operation != 'BALANCE_INQUIRY' && operation != 'PAYMENT_INFO')
              TextField(
                controller: amount,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Amount (minor AFN)',
                ),
              ),
            TextField(
              controller: reference,
              decoration: InputDecoration(
                labelText: operation == 'RECOVERY'
                    ? 'Original transaction ID'
                    : 'Protected token/reference',
              ),
            ),
            FilledButton(
              onPressed: () async {
                final id = DateTime.now().microsecondsSinceEpoch.toString();
                try {
                  final r = operation == 'RECOVERY'
                      ? await GatewayClient().get(
                          '/api/v1/transactions/${reference.text}/timeline',
                        )
                      : await GatewayClient().transaction(operation, {
                          'requestId': id,
                          'idempotencyKey': 'mobile-$id',
                          'merchantId': merchant.text,
                          'amountMinor': int.tryParse(amount.text),
                          'currency': 'AFN',
                          'cardToken': reference.text.isEmpty
                              ? null
                              : reference.text,
                        });
                  if (c.mounted) {
                    Navigator.pop(c);
                  }
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${r['status']} · ${r['message']}'),
                      ),
                    );
                  }
                } catch (_) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Request unavailable. Do not retry an unknown transaction.',
                        ),
                      ),
                    );
                  }
                }
              },
              child: const Text('Continue'),
            ),
          ],
        ),
      ),
    );
  }

  Widget row(
    IconData i,
    String t,
    String sub,
    String value, {
    VoidCallback? onTap,
  }) => ListTile(
    onTap: onTap,
    contentPadding: const EdgeInsets.symmetric(vertical: 3),
    leading: CircleAvatar(
      backgroundColor: const Color(0xffe4f7f5),
      child: Icon(i, color: gold),
    ),
    title: Text(t, style: const TextStyle(fontWeight: FontWeight.w700)),
    subtitle: Text(sub),
    trailing: Text(
      value,
      style: const TextStyle(
        color: Color(0xff15803d),
        fontWeight: FontWeight.bold,
      ),
    ),
  );
  Widget transactions() => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      const Text(
        'Transactions',
        style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 12),
      TextField(
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.search),
          suffixIcon: const Icon(Icons.tune),
          hintText: 'Search transactions, merchants…',
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
        ),
      ),
      const SizedBox(height: 12),
      Wrap(
        spacing: 8,
        children: ['All', 'Sent', 'Received', 'Bills', 'Shopping']
            .map(
              (x) => ChoiceChip(
                label: Text(x),
                selected: x == transactionFilter,
                onSelected: (_) => setState(() => transactionFilter = x),
              ),
            )
            .toList(),
      ),
      const SizedBox(height: 16),
      const Text('Today', style: TextStyle(fontWeight: FontWeight.bold)),
      row(
        Icons.shopping_cart,
        'Merchant purchase',
        'Approved · 09:12',
        '- AFN 1,250',
      ),
      row(
        Icons.pending_actions,
        'Pending recovery',
        'Tap to check authoritative status',
        'PENDING',
        onTap: () => _transactionSheet('Pending recovery'),
      ),
      const Text('Yesterday', style: TextStyle(fontWeight: FontWeight.bold)),
      row(Icons.receipt, 'Bill payment', 'Approved · 10:30', '- AFN 400'),
    ],
  );
  Widget cards() => ListView(
    padding: EdgeInsets.zero,
    children: [
      Container(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 34),
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [darkGold, gold]),
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
        ),
        child: const Row(
          children: [
            Expanded(
              child: Text(
                'My Cards',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 29,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.add, color: darkGold),
            ),
          ],
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Transform.translate(offset: const Offset(0, -18), child: card()),
      ),
      const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.circle, color: darkGold, size: 10),
          SizedBox(width: 6),
          Icon(Icons.circle, color: Color(0xffc9dddd), size: 9),
          SizedBox(width: 6),
          Icon(Icons.circle, color: Color(0xffc9dddd), size: 9),
        ],
      ),
      const Padding(
        padding: EdgeInsets.fromLTRB(20, 22, 20, 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _CardAction(icon: Icons.lock_outline_rounded, label: 'Lock Card'),
            _CardAction(icon: Icons.credit_card_rounded, label: 'Card Details'),
            _CardAction(icon: Icons.tune_rounded, label: 'Manage Limits'),
            _CardAction(icon: Icons.delete_outline_rounded, label: 'Remove'),
          ],
        ),
      ),
      const SizedBox(height: 10),
      ListTile(
        onTap: () => ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Card controls require the protected-card provider. No card number is stored here.',
            ),
          ),
        ),
        leading: const Icon(Icons.lock, color: gold),
        title: const Text('Card security'),
        subtitle: const Text('Limits and protected card settings'),
      ),
      ListTile(
        onTap: () => _transactionSheet('Balance'),
        leading: const Icon(Icons.add_card, color: gold),
        title: const Text('Add protected card reference'),
        subtitle: const Text('Tokenized/hosted capture only'),
      ),
      ListTile(
        leading: const Icon(Icons.credit_card, color: gold),
        title: const Text('Linked cards'),
        subtitle: const Text('•••• 5678   Active'),
      ),
    ],
  );
  Widget profile() => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      const Center(
        child: CircleAvatar(
          radius: 38,
          backgroundColor: gold,
          child: Icon(Icons.person, color: Colors.white, size: 42),
        ),
      ),
      const SizedBox(height: 12),
      const Center(
        child: Text(
          'Profile',
          style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
        ),
      ),
      const SizedBox(height: 20),
      const ListTile(
        leading: Icon(Icons.shield_outlined, color: gold),
        title: Text('Security'),
        subtitle: Text('Device, session and protected-token settings'),
      ),
      const ListTile(
        leading: Icon(Icons.notifications_outlined, color: gold),
        title: Text('Notifications'),
        subtitle: Text('Transaction and security alerts'),
      ),
      const ListTile(
        leading: Icon(Icons.language, color: gold),
        title: Text('Language'),
        subtitle: Text('English · Dari · Pashto'),
      ),
      const ListTile(
        leading: Icon(Icons.help_outline, color: gold),
        title: Text('Support'),
      ),
    ],
  );
}

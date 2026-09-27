import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_tts/flutter_tts.dart';

const _ink = Color(0xff003f4a),
    _accent = Color(0xff007c7b),
    _background = Color(0xfff6f9fb);
const _authApiUrl = String.fromEnvironment(
  'AUTH_API_URL',
  defaultValue: 'http://10.0.2.2:8080/api/auth-service',
);
const _gatewayApiUrl = String.fromEnvironment(
  'GATEWAY_API_URL',
  defaultValue: 'http://10.0.2.2:8081/api/gateway',
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const PosApp());
}

class PosApp extends StatelessWidget {
  const PosApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'AfPay POS',
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: _accent),
      scaffoldBackgroundColor: _background,
    ),
    home: const PosLoginPage(),
  );
}

class GatewayClient {
  GatewayClient()
    : _auth = Dio(
        BaseOptions(
          baseUrl: _authApiUrl,
          connectTimeout: const Duration(seconds: 12),
          receiveTimeout: const Duration(seconds: 30),
        ),
      ),
      _gateway = Dio(
        BaseOptions(
          baseUrl: _gatewayApiUrl,
          connectTimeout: const Duration(seconds: 12),
          receiveTimeout: const Duration(seconds: 30),
        ),
      );
  final Dio _auth;
  final Dio _gateway;
  final _storage = const FlutterSecureStorage();
  Future<void> login(String username, String password) async {
    final response = await _auth.post<Map<String, dynamic>>(
      '/login',
      data: {'username': username, 'password': password},
    );
    final body = response.data ?? {};
    final data = body['data'] as Map<String, dynamic>?;
    final token = data?['accessToken'] as String?;
    if (body['status'] != true || token == null) {
      throw DioException(
        requestOptions: response.requestOptions,
        message: body['message']?.toString() ?? 'Sign in failed',
      );
    }
    await _storage.write(key: 'access_token', value: token);
  }

  Future<Map<String, dynamic>> purchase({
    required String terminalId,
    required String merchantId,
    required int amountMinor,
    required String token,
  }) async {
    final accessToken = await _storage.read(key: 'access_token');
    final requestId = DateTime.now().microsecondsSinceEpoch.toString();
    final response = await _gateway.post<Map<String, dynamic>>(
      '/api/v1/pos/transactions/PURCHASE',
      data: {
        'requestId': requestId,
        'idempotencyKey': 'pos-$terminalId-$requestId',
        'merchantId': merchantId,
        'terminalId': terminalId,
        'amountMinor': amountMinor,
        'currency': 'AFN',
        'cardToken': token,
      },
      options: Options(
        headers: accessToken == null
            ? null
            : {'Authorization': 'Bearer $accessToken'},
      ),
    );
    return response.data ?? {};
  }

  Future<void> heartbeat(String terminalId, String serialNumber) async {
    final token = await _storage.read(key: 'access_token');
    await _gateway.post(
      '/api/v1/terminals/heartbeat',
      data: {
        'terminalId': terminalId,
        'serialNumber': serialNumber,
        'applicationVersion': '1.0.0',
        'configurationVersion': '1',
      },
      options: Options(
        headers: token == null ? null : {'Authorization': 'Bearer $token'},
      ),
    );
  }

  Future<Map<String, dynamic>> operation(
    String route,
    Map<String, dynamic> body,
  ) async {
    final token = await _storage.read(key: 'access_token');
    const operations = {
      'cash-in': 'CASH_IN',
      'cash-out': 'CASH_OUT',
      'balance-inquiries': 'BALANCE_INQUIRY',
      'payment-info': 'PAYMENT_INFO',
      'save-payment': 'SAVE_PAYMENT',
      'card-title-fetch': 'CARD_TITLE_FETCH',
      'card-to-card': 'CARD_TO_CARD',
      'reversals': 'REVERSAL',
    };
    final response = await _gateway.post<Map<String, dynamic>>(
      '/api/v1/pos/transactions/${operations[route] ?? 'PURCHASE'}',
      data: {
        'requestId': body['requestId'],
        'idempotencyKey': body['idempotencyKey'],
        'merchantId': (body['terminal'] as Map)['merchantId'],
        'terminalId': (body['terminal'] as Map)['terminalId'],
        'amountMinor': (body['amount'] as Map?)?['valueMinor'],
        'currency': 'AFN',
        'cardToken': (body['card'] as Map?)?['token'],
        'originalTransactionId': body['originalTransactionId'],
      },
      options: Options(
        headers: token == null ? null : {'Authorization': 'Bearer $token'},
      ),
    );
    return response.data ?? {};
  }
}

class PosLoginPage extends StatefulWidget {
  const PosLoginPage({super.key});
  @override
  State<PosLoginPage> createState() => _PosLoginPageState();
}

class _PosLoginPageState extends State<PosLoginPage> {
  final username = TextEditingController(),
      password = TextEditingController(),
      client = GatewayClient();
  bool busy = false;
  String? error;
  Future<void> signIn() async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await client.login(username.text.trim(), password.text);
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const PosTerminalPage()),
        );
      }
    } catch (_) {
      setState(
        () => error =
            'Sign in failed. Check your operator account and gateway connection.',
      );
    }
    if (mounted) setState(() => busy = false);
  } /*
  legacy compact login layout retained below for reference
  @override void dispose() { username.dispose(); password.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) => Scaffold(body: SafeArea(child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 420), child: Padding(padding: const EdgeInsets.all(28), child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.stretch, children: [const Icon(Icons.point_of_sale_rounded, size: 64, color: _accent), const SizedBox(height: 18), const Text('AfPay POS', textAlign: TextAlign.center, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: _ink)), const SizedBox(height: 6), const Text('Secure merchant operator sign-in', textAlign: TextAlign.center), const SizedBox(height: 30), TextField(controller: username, decoration: const InputDecoration(labelText: 'Operator username', prefixIcon: Icon(Icons.person_outline), border: OutlineInputBorder())), const SizedBox(height: 14), TextField(controller: password, obscureText: true, decoration: const InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.lock_outline), border: OutlineInputBorder())), if (error != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(error!, style: const TextStyle(color: Colors.red))), const SizedBox(height: 18), FilledButton(onPressed: busy ? null : signIn, style: FilledButton.styleFrom(backgroundColor: _ink, padding: const EdgeInsets.all(16)), child: Text(busy ? 'Signing in…' : 'Sign in'))])))));
  */

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
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.point_of_sale_rounded,
                  size: 64,
                  color: _accent,
                ),
                const SizedBox(height: 18),
                const Text(
                  'AfPay POS',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: _ink,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Secure merchant operator sign-in',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                TextField(
                  controller: username,
                  decoration: const InputDecoration(
                    labelText: 'Operator username',
                    prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: password,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icon(Icons.lock_outline),
                    border: OutlineInputBorder(),
                  ),
                ),
                if (error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      error!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                const SizedBox(height: 18),
                FilledButton(
                  onPressed: busy ? null : signIn,
                  style: FilledButton.styleFrom(
                    backgroundColor: _ink,
                    padding: const EdgeInsets.all(16),
                  ),
                  child: Text(busy ? 'Signing in...' : 'Sign in'),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class PosTerminalPage extends StatefulWidget {
  const PosTerminalPage({super.key});
  @override
  State<PosTerminalPage> createState() => _PosTerminalPageState();
}

class _PosTerminalPageState extends State<PosTerminalPage>
    with SingleTickerProviderStateMixin {
  final _amount = TextEditingController(),
      _terminal = TextEditingController(text: 'T0000001'),
      _merchant = TextEditingController(text: 'M00000000000001'),
      _token = TextEditingController();
  final _client = GatewayClient();
  final _tts = FlutterTts();
  late final AnimationController _cardAnimation;
  String _language = 'English';
  bool _loading = false;
  String _status = 'Ready to accept payment';
  String _message = 'Tap, insert, or present a token from an approved reader.';
  String get _cardPrompt => switch (_language) {
    'Pashto' => 'مهرباني وکړئ خپل کارت وکاروئ',
    'Dari' => 'لطفاً از کارت خود استفاده کنید',
    _ => 'Please use your card',
  };
  String get _speechLocale => switch (_language) {
    'Pashto' => 'ps-AF',
    'Dari' => 'fa-AF',
    _ => 'en-US',
  };
  @override
  void initState() {
    super.initState();
    _cardAnimation = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  Future<void> _announceCardPrompt() async {
    await _tts.setLanguage(_speechLocale);
    await _tts.setSpeechRate(0.42);
    await _tts.speak(_cardPrompt);
  }

  Future<void> _takePayment() async {
    final value = int.tryParse(_amount.text);
    if (value == null || value <= 0 || _token.text.trim().isEmpty) {
      setState(() {
        _status = 'Check payment details';
        _message = 'Enter a positive AFN amount and an approved payment token.';
      });
      return;
    }
    setState(() {
      _loading = true;
      _status = 'Authorizing…';
    });
    try {
      final result = await _client.purchase(
        terminalId: _terminal.text.trim(),
        merchantId: _merchant.text.trim(),
        amountMinor: value,
        token: _token.text.trim(),
      );
      setState(() {
        _status = result['status']?.toString() ?? 'Submitted';
        _message =
            '${result['responseCode'] ?? ''} · ${result['message'] ?? 'Transaction submitted'}';
      });
    } on DioException catch (e) {
      setState(() {
        _status = 'Payment unavailable';
        _message =
            e.response?.data?['message']?.toString() ??
            'The gateway could not process this request.';
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _cardAnimation.dispose();
    _tts.stop();
    _amount.dispose();
    _terminal.dispose();
    _merchant.dispose();
    _token.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    floatingActionButton: FloatingActionButton.extended(
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => PosOperations(client: _client)),
      ),
      icon: const Icon(Icons.apps),
      label: const Text('Operations'),
    ),
    body: SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) => Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: ListView(
              padding: const EdgeInsets.all(22),
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: _ink,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.point_of_sale_rounded,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'AfPay POS',
                            style: TextStyle(
                              fontSize: 21,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            'Merchant acceptance terminal',
                            style: TextStyle(color: Colors.blueGrey),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => _client.heartbeat(
                        _terminal.text,
                        'LOCAL-DEMO-SERIAL',
                      ),
                      icon: const Icon(Icons.wifi_tethering_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 26),
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: _ink,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'ENTER AMOUNT',
                        style: TextStyle(
                          color: Color(0xffc8f4f0),
                          letterSpacing: 1.4,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextField(
                        controller: _amount,
                        autofocus: true,
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 46,
                        ),
                        decoration: const InputDecoration(
                          hintText: '0',
                          hintStyle: TextStyle(color: Color(0xff9bd5d0)),
                          border: InputBorder.none,
                          suffixText: 'AFN',
                          suffixStyle: TextStyle(
                            color: Color(0xffc8f4f0),
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const Divider(color: Color(0xff197a7b)),
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Online • encrypted channel',
                            style: TextStyle(color: Color(0xffc8f4f0)),
                          ),
                          Icon(
                            Icons.verified_user_outlined,
                            color: Color(0xff72e1ab),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Card(
                  color: const Color(0xffe8f6f4),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        DropdownButtonFormField<String>(
                          initialValue: _language,
                          decoration: const InputDecoration(
                            labelText: 'Prompt language',
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'English',
                              child: Text('English'),
                            ),
                            DropdownMenuItem(
                              value: 'Pashto',
                              child: Text('پښتو'),
                            ),
                            DropdownMenuItem(
                              value: 'Dari',
                              child: Text('دری / فارسی'),
                            ),
                          ],
                          onChanged: (v) =>
                              setState(() => _language = v ?? 'English'),
                        ),
                        const SizedBox(height: 12),
                        ScaleTransition(
                          scale: Tween<double>(begin: .92, end: 1.08).animate(
                            CurvedAnimation(
                              parent: _cardAnimation,
                              curve: Curves.easeInOut,
                            ),
                          ),
                          child: const Icon(
                            Icons.contactless_rounded,
                            size: 58,
                            color: _accent,
                          ),
                        ),
                        Text(
                          _cardPrompt,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                          ),
                        ),
                        const Text(
                          'Tap, insert, or swipe only on the certified reader. Never enter PIN in this app.',
                          textAlign: TextAlign.center,
                        ),
                        TextButton.icon(
                          onPressed: _announceCardPrompt,
                          icon: const Icon(Icons.volume_up_outlined),
                          label: const Text('Play instruction'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                _input('Terminal ID', _terminal, Icons.storefront_outlined),
                const SizedBox(height: 12),
                _input('Merchant ID', _merchant, Icons.business_outlined),
                const SizedBox(height: 12),
                _input(
                  'Approved reader token',
                  _token,
                  Icons.contactless_outlined,
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: _loading ? null : _takePayment,
                  style: FilledButton.styleFrom(
                    backgroundColor: _accent,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.lock_outline),
                  label: Text(
                    _loading ? 'Processing payment' : 'Charge customer',
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xffe1e8f4)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _status == 'APPROVED'
                            ? Icons.check_circle
                            : Icons.info_outline,
                        color: _status == 'APPROVED' ? Colors.green : _accent,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _status,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              _message,
                              style: const TextStyle(color: Colors.blueGrey),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Security boundary: the POS app accepts a protected reader token only. PIN blocks, CVV, PAN, EMV TLV, and keys stay inside certified terminal/HSM paths.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.blueGrey, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  Widget _input(
    String label,
    TextEditingController controller,
    IconData icon,
  ) => TextField(
    controller: controller,
    decoration: InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    ),
  );
}

class PosOperations extends StatefulWidget {
  const PosOperations({super.key, required this.client});
  final GatewayClient client;
  @override
  State<PosOperations> createState() => _PosOperationsState();
}

class _PosOperationsState extends State<PosOperations> {
  static const routes = {
    'Purchase': 'purchase',
    'Cash in': 'cash-in',
    'Cash out': 'cash-out',
    'Balance inquiry': 'balance-inquiries',
    'Payment info': 'payment-info',
    'Save payment': 'save-payment',
    'Card title fetch': 'card-title-fetch',
    'Card to card': 'card-to-card',
    'Reversal': 'reversals',
  };
  String selected = 'Purchase';
  final terminal = TextEditingController(),
      merchant = TextEditingController(),
      amount = TextEditingController(),
      token = TextEditingController(),
      original = TextEditingController();
  String? message;
  bool busy = false;
  Future<void> send() async {
    final value = int.tryParse(amount.text);
    final noAmount =
        selected == 'Balance inquiry' ||
        selected == 'Payment info' ||
        selected == 'Card title fetch';
    if (terminal.text.isEmpty ||
        merchant.text.isEmpty ||
        (!noAmount && (value == null || value <= 0))) {
      setState(() => message = 'Enter terminal, merchant, and amount.');
      return;
    }
    if (selected == 'Cash out' && original.text.isNotEmpty) {
      setState(
        () => message =
            'Do not pay cash until a new request is confirmed APPROVED.',
      );
      return;
    }
    setState(() {
      busy = true;
      message = null;
    });
    try {
      final id = DateTime.now().microsecondsSinceEpoch.toString();
      final data = await widget.client.operation(
        routes[selected] ?? 'purchase',
        {
          'requestId': id,
          'idempotencyKey': 'pos-$selected-$id',
          'channel': 'POS',
          'terminal': {
            'terminalId': terminal.text,
            'merchantId': merchant.text,
          },
          'amount': noAmount ? null : {'valueMinor': value, 'currency': 'AFN'},
          'card': {
            'token': token.text.isEmpty ? 'protected-reader-token' : token.text,
            'entryMode': 'CONTACTLESS',
          },
          'originalTransactionId': original.text.isEmpty ? null : original.text,
        },
      );
      message =
          '${data['status']} · ${data['responseCode']} · ${data['message']}';
    } on DioException catch (_) {
      message =
          'Gateway request failed. If outcome is unknown, do not hand over cash; use transaction lookup.';
    }
    if (mounted) setState(() => busy = false);
  }

  @override
  void dispose() {
    terminal.dispose();
    merchant.dispose();
    amount.dispose();
    token.dispose();
    original.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('POS operations')),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        DropdownButtonFormField(
          initialValue: selected,
          decoration: const InputDecoration(labelText: 'Operation'),
          items: routes.keys
              .map((name) => DropdownMenuItem(value: name, child: Text(name)))
              .toList(),
          onChanged: (v) => setState(() => selected = v!),
        ),
        const SizedBox(height: 12),
        _field('Terminal ID', terminal),
        _field('Merchant ID', merchant),
        _field('Amount (minor AFN)', amount),
        _field('Protected reader token', token),
        _field('Original transaction ID', original),
        FilledButton(
          onPressed: busy ? null : send,
          child: Text(busy ? 'Sending…' : 'Submit $selected'),
        ),
        if (message != null)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Text(message!),
          ),
      ],
    ),
  );
  Widget _field(String label, TextEditingController controller) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    ),
  );
}

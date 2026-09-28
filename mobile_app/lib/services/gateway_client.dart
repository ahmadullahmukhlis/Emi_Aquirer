import 'package:dio/dio.dart';

import '../core/app_config.dart';
import 'session_store.dart';
import 'transaction_store.dart';

class GatewayClient {
  GatewayClient({SessionStore? session, TransactionStore? transactions})
    : _session = session ?? const SessionStore(),
      _transactions = transactions ?? const TransactionStore(),
      _auth = Dio(BaseOptions(baseUrl: AppConfig.authApiUrl)),
      _gateway = Dio(BaseOptions(baseUrl: AppConfig.gatewayApiUrl));

  final Dio _auth;
  final Dio _gateway;
  final SessionStore _session;
  final TransactionStore _transactions;
  bool _demoMode = false;

  void startDemoSession() {
    _demoMode = true;
  }

  Future<void> login(String username, String password) async {
    final response = await _auth.post<Map<String, dynamic>>(
      '/login',
      data: {'username': username, 'password': password},
    );
    final data = response.data?['data'];
    final token = data is Map ? data['accessToken']?.toString() : null;
    if (token == null || token.isEmpty) throw StateError('Sign in failed');
    await _session.saveToken(token);
  }

  Future<Map<String, dynamic>> transaction(
    String operation,
    Map<String, dynamic> body,
  ) async {
    if (_demoMode) {
      await Future<void>.delayed(const Duration(milliseconds: 650));
      final result = <String, dynamic>{
        'transactionId': 'DEMO-${DateTime.now().millisecondsSinceEpoch}',
        'status': 'APPROVED',
        'message': 'Transaction completed successfully',
        'responseCode': '00',
        'amount': body['amountMinor'] == null
            ? null
            : 'AFN ${(body['amountMinor'] as num) / 100}',
      };
      await _transactions.add({
        ...result,
        'operation': operation,
        'createdAt': DateTime.now().toIso8601String(),
      });
      return result;
    }
    final response = await _gateway.post<Map<String, dynamic>>(
      '/api/v1/mobile/transactions/$operation',
      data: body,
      options: await _options(),
    );
    final result = response.data ?? <String, dynamic>{};
    await _transactions.add({
      ...result,
      'operation': operation,
      'createdAt': DateTime.now().toIso8601String(),
    });
    return result;
  }

  Future<List<Map<String, dynamic>>> history() => _transactions.read();

  Future<List<Map<String, dynamic>>> registeredCards() async {
    if (_demoMode) {
      return [
        {
          'id': 'demo-primary',
          'maskedPan': '•••• •••• •••• 3456',
          'brand': 'VISA',
          'holderName': 'Sandbox User',
          'expiryMonth': 12,
          'expiryYear': 2028,
          'active': true,
        },
        {
          'id': 'demo-secondary',
          'maskedPan': '•••• •••• •••• 5678',
          'brand': 'MASTERCARD',
          'holderName': 'Sandbox User',
          'expiryMonth': 11,
          'expiryYear': 2027,
          'active': true,
        },
      ];
    }
    final response = await _gateway.get<List<dynamic>>(
      '/api/v1/mobile/cards',
      options: await _options(),
    );
    return (response.data ?? const [])
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Future<Map<String, dynamic>> cardToCard({
    required String sourceCardId,
    required String recipientPan,
    required int amountMinor,
    String? note,
  }) async {
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    Map<String, dynamic> result;
    if (_demoMode) {
      await Future<void>.delayed(const Duration(milliseconds: 750));
      result = {
        'transactionId': 'DEMO-$id',
        'status': 'APPROVED',
        'message': 'Card transfer completed',
        'responseCode': '00',
        'stan': id.substring(id.length - 6),
        'rrn': id.substring(id.length - 12),
      };
    } else {
      final response = await _gateway.post<Map<String, dynamic>>(
        '/api/v1/mobile/card-to-card',
        data: {
          'requestId': id,
          'idempotencyKey': 'c2c-$id',
          'sourceCardId': sourceCardId,
          'recipientPan': recipientPan,
          'amountMinor': amountMinor,
          'currency': 'AFN',
          'note': note?.trim().isEmpty == true ? null : note?.trim(),
        },
        options: await _options(),
      );
      result = response.data ?? <String, dynamic>{};
    }
    // Persist only the masked destination. The recipient PAN and note are deliberately excluded.
    final digits = recipientPan.replaceAll(RegExp(r'\D'), '');
    await _transactions.add({
      ...result,
      'operation': 'CARD_TO_CARD',
      'title': 'Card transfer',
      'category': 'Sent',
      'amount': '- AFN ${amountMinor / 100}',
      'reference': 'Card ending ${digits.substring(digits.length - 4)}',
      'createdAt': DateTime.now().toIso8601String(),
    });
    return result;
  }

  Future<Map<String, dynamic>> cardWalletTransfer({
    required String operation,
    required String cardId,
    required int amountMinor,
  }) async {
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    Map<String, dynamic> result;
    if (_demoMode) {
      await Future<void>.delayed(const Duration(milliseconds: 700));
      result = {
        'transactionId': 'DEMO-$id',
        'status': 'APPROVED',
        'message': 'Transfer completed',
        'responseCode': '00',
        'stan': id.substring(id.length - 6),
        'rrn': id.substring(id.length - 12),
      };
    } else {
      final response = await _gateway.post<Map<String, dynamic>>(
        '/api/v1/mobile/card-wallet',
        data: {
          'requestId': id,
          'idempotencyKey': '${operation.toLowerCase()}-$id',
          'cardId': cardId,
          'operation': operation,
          'amountMinor': amountMinor,
          'currency': 'AFN',
        },
        options: await _options(),
      );
      result = response.data ?? <String, dynamic>{};
    }
    await _transactions.add({
      ...result,
      'operation': operation,
      'title': operation == 'CARD_TO_WALLET'
          ? 'Card to Wallet'
          : 'Wallet to Card',
      'category': operation == 'CARD_TO_WALLET' ? 'Received' : 'Sent',
      'amount': 'AFN ${amountMinor / 100}',
      'createdAt': DateTime.now().toIso8601String(),
    });
    return result;
  }

  Future<Map<String, dynamic>> currentUser() async {
    if (_demoMode) {
      return {
        'firstName': 'Sandbox',
        'lastName': 'User',
        'username': 'test',
        'email': 'sandbox@afpay.local',
        'photo': null,
      };
    }
    final response = await _auth.get<Map<String, dynamic>>(
      '/mobile/me',
      options: await _options(),
    );
    return response.data ?? <String, dynamic>{};
  }

  Future<Map<String, dynamic>> transactionTimeline(String id) async {
    if (_demoMode) {
      await Future<void>.delayed(const Duration(milliseconds: 450));
      return {
        'transactionId': id,
        'status': 'APPROVED',
        'message': 'Transaction recovered successfully',
        'responseCode': '00',
      };
    }
    final response = await _gateway.get<Map<String, dynamic>>(
      '/api/v1/transactions/$id/timeline',
      options: await _options(),
    );
    return response.data ?? <String, dynamic>{};
  }

  Future<Options> _options() async {
    if (_demoMode) return Options();
    final token = await _session.readToken();
    return Options(
      headers: token == null ? null : {'Authorization': 'Bearer $token'},
    );
  }
}

import 'package:dio/dio.dart';

import '../core/app_config.dart';
import 'secure_session.dart';

class GatewayClient {
  GatewayClient({SecureSession? session})
    : _session = session ?? const SecureSession(),
      _auth = Dio(_options(AppConfig.authApiUrl)),
      _gateway = Dio(_options(AppConfig.gatewayApiUrl));

  final Dio _auth;
  final Dio _gateway;
  final SecureSession _session;
  bool _demoMode = false;

  void startDemoSession() {
    _demoMode = true;
  }

  static BaseOptions _options(String baseUrl) => BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 12),
    receiveTimeout: const Duration(seconds: 30),
  );

  Future<void> login(String username, String password) async {
    final response = await _auth.post<Map<String, dynamic>>(
      '/login',
      data: {'username': username, 'password': password},
    );
    final body = response.data ?? const <String, dynamic>{};
    final data = body['data'];
    final token = data is Map ? data['accessToken']?.toString() : null;
    if (body['status'] != true || token == null || token.isEmpty) {
      throw StateError(body['message']?.toString() ?? 'Sign in failed');
    }
    await _session.saveToken(token);
  }

  Future<Map<String, dynamic>> purchase({
    required String terminalId,
    required String merchantId,
    required int amountMinor,
    required String token,
  }) => operation('PURCHASE', {
    'requestId': DateTime.now().microsecondsSinceEpoch.toString(),
    'merchantId': merchantId,
    'terminalId': terminalId,
    'amountMinor': amountMinor,
    'currency': 'AFN',
    'cardToken': token,
  });

  Future<Map<String, dynamic>> operation(
    String operation,
    Map<String, dynamic> data,
  ) async {
    final requestId =
        data['requestId']?.toString() ??
        DateTime.now().microsecondsSinceEpoch.toString();
    final response = await _gateway.post<Map<String, dynamic>>(
      '/api/v1/pos/transactions/$operation',
      data: {
        ...data,
        'requestId': requestId,
        'idempotencyKey': data['idempotencyKey'] ?? 'pos-$operation-$requestId',
      },
      options: await _authorizedOptions(),
    );
    return response.data ?? <String, dynamic>{};
  }

  Future<void> heartbeat(String terminalId, String serialNumber) async {
    await _gateway.post<void>(
      '/api/v1/terminals/heartbeat',
      data: {
        'terminalId': terminalId,
        'serialNumber': serialNumber,
        'applicationVersion': '1.0.0',
        'configurationVersion': '1',
      },
      options: await _authorizedOptions(),
    );
  }

  Future<Options> _authorizedOptions() async {
    if (_demoMode) return Options();
    final token = await _session.readToken();
    return Options(
      headers: token == null ? null : {'Authorization': 'Bearer $token'},
    );
  }
}

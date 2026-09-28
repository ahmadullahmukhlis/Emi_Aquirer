import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TransactionStore {
  const TransactionStore([this._storage = const FlutterSecureStorage()]);

  static const _historyKey = 'mobile_transaction_history';
  final FlutterSecureStorage _storage;

  Future<List<Map<String, dynamic>>> read() async {
    final raw = await _storage.read(key: _historyKey);
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

  Future<void> add(Map<String, dynamic> transaction) async {
    final items = await read();
    items.removeWhere(
      (item) => item['transactionId'] == transaction['transactionId'],
    );
    items.insert(0, transaction);
    await _storage.write(
      key: _historyKey,
      value: jsonEncode(items.take(50).toList()),
    );
  }
}

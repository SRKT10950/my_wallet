import 'dart:convert';
import 'package:http/http.dart' as http;

const String targetApiUrl = 'https://db.mhservice.co.in/api/db/mWallet/query';
const String targetApiKey = 'hs_live_8cxzSYAq9aUv79HxDbADCdJ23yLtIWhQ';

Future<void> executeTarget(String sql, [List<dynamic>? params]) async {
  final res = await http.post(
    Uri.parse(targetApiUrl),
    headers: {
      'Content-Type': 'application/json',
      'x-api-key': targetApiKey,
    },
    body: jsonEncode({
      'query': sql,
      'params': params ?? [],
    }),
  );
  if (res.statusCode != 200) {
    throw Exception('Exec Failed (${res.statusCode}): ${res.body}');
  }
  final data = jsonDecode(res.body);
  if (data['success'] != true) {
    throw Exception('DB Error: ${data['error']}');
  }
}

Future<void> main() async {
  print('================================================================');
  print('Creating remote PostgreSQL table: transaction_items');
  print('================================================================\n');

  final createSql = '''
    CREATE TABLE IF NOT EXISTS transaction_items (
      id SERIAL PRIMARY KEY,
      transaction_id INTEGER,
      user_id VARCHAR(100) NOT NULL DEFAULT 'user_1',
      product_id INTEGER,
      item_name VARCHAR(255) NOT NULL,
      local_name VARCHAR(255) DEFAULT '',
      category VARCHAR(100) DEFAULT 'General',
      quantity NUMERIC NOT NULL DEFAULT 1.0,
      unit VARCHAR(50) NOT NULL DEFAULT 'Pcs',
      unit_price NUMERIC NOT NULL DEFAULT 0.0,
      total_price NUMERIC NOT NULL DEFAULT 0.0,
      deleted INTEGER NOT NULL DEFAULT 0,
      created_at BIGINT,
      updated_at BIGINT
    );
  ''';

  try {
    await executeTarget(createSql);
    print('✅ Successfully created table transaction_items in remote PostgreSQL database.');
  } catch (e) {
    print('❌ Error creating transaction_items table: $e');
  }
}

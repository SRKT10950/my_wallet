// ignore_for_file: avoid_print
import 'dart:convert';
import 'package:http/http.dart' as http;

const String sourceApiUrl = 'https://db.mhservice.co.in/api/db/my_wallet/query';
const String sourceApiKey = 'hs_live_U74MhX82o5lOUmzAmXxKsbX3fxNKImkl';

const String targetApiUrl = 'https://db.mhservice.co.in/api/db/mWallet/query';
const String targetApiKey = 'hs_live_8cxzSYAq9aUv79HxDbADCdJ23yLtIWhQ';

Future<List<Map<String, dynamic>>> querySource(String sql, [List<dynamic>? params]) async {
  final res = await http.post(
    Uri.parse(sourceApiUrl),
    headers: {
      'Content-Type': 'application/json',
      'x-api-key': sourceApiKey,
    },
    body: jsonEncode({
      'query': sql,
      'params': params ?? [],
    }),
  );
  if (res.statusCode != 200) {
    throw Exception('Source Query Failed (${res.statusCode}): ${res.body}');
  }
  final data = jsonDecode(res.body);
  if (data['success'] != true) {
    throw Exception('Source Error: ${data['error']}');
  }
  return List<Map<String, dynamic>>.from(data['rows'] ?? []);
}

Future<void> executeTarget(String sql, List<dynamic> params) async {
  final res = await http.post(
    Uri.parse(targetApiUrl),
    headers: {
      'Content-Type': 'application/json',
      'x-api-key': targetApiKey,
    },
    body: jsonEncode({
      'query': sql,
      'params': params,
    }),
  );
  if (res.statusCode != 200) {
    throw Exception('Target Exec Failed (${res.statusCode}): ${res.body}');
  }
  final data = jsonDecode(res.body);
  if (data['success'] != true) {
    throw Exception('Target Error: ${data['error']}');
  }
}

Future<void> main() async {
  print('================================================================');
  print('Starting Full Data Migration: [my_wallet] -> [mWallet]');
  print('Source Gateway: $sourceApiUrl');
  print('Target Gateway: $targetApiUrl');
  print('================================================================\n');

  final now = DateTime.now().millisecondsSinceEpoch;

  final tables = [
    'users',
    'categories',
    'transactions',
    'loans',
    'income_configs',
    'lend_borrows',
    'repayments',
    'investments',
    'category_budgets',
    'od_accounts',
    'od_transactions',
    'fuel_logs',
    'vehicle_configs',
    'car_trips',
    'wallet_contacts',
    'wallet_products',
  ];

  int totalRecordsMigrated = 0;

  for (final table in tables) {
    try {
      print('Fetching records from table: [$table]...');
      final rows = await querySource('SELECT * FROM $table');
      print('  Found ${rows.length} rows in [$table].');

      if (rows.isEmpty) continue;

      int migratedInTable = 0;
      for (final row in rows) {
        // Build dynamic insert columns and parameters
        final cols = <String>[];
        final valPlaceholders = <String>[];
        final vals = <dynamic>[];
        int paramIdx = 1;

        row.forEach((key, val) {
          cols.add('"$key"');
          valPlaceholders.add('\$$paramIdx');
          vals.add(val);
          paramIdx++;
        });

        // Add updated_at and last_updated_by if not present in row
        if (!row.containsKey('updated_at')) {
          cols.add('"updated_at"');
          valPlaceholders.add('\$$paramIdx');
          vals.add(now);
          paramIdx++;
        }
        if (!row.containsKey('last_updated_by')) {
          cols.add('"last_updated_by"');
          valPlaceholders.add('\$$paramIdx');
          vals.add('migration_script');
          paramIdx++;
        }

        String primaryConflictClause = '';
        if (table == 'users') {
          primaryConflictClause = 'ON CONFLICT (mobile_number) DO NOTHING';
        } else if (table == 'category_budgets') {
          primaryConflictClause = 'ON CONFLICT (user_id, "categoryId", month, year) DO NOTHING';
        } else {
          primaryConflictClause = 'ON CONFLICT (user_id, id) DO NOTHING';
        }

        final insertSql = '''
          INSERT INTO $table (${cols.join(', ')})
          VALUES (${valPlaceholders.join(', ')})
          $primaryConflictClause;
        ''';

        try {
          await executeTarget(insertSql, vals);
          migratedInTable++;
        } catch (e) {
          print('    [!] Failed to insert row into $table: $e');
        }
      }

      print('  [✓] Successfully migrated $migratedInTable/${rows.length} rows to [$table].\n');
      totalRecordsMigrated += migratedInTable;
    } catch (e) {
      print('  [✗] Error migrating table [$table]: $e\n');
    }
  }

  print('================================================================');
  print('Data Migration Completed! Total Records Migrated: $totalRecordsMigrated');
  print('================================================================');
}

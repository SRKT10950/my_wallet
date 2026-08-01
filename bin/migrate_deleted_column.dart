// ignore_for_file: avoid_print
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:postgres/postgres.dart';
import 'package:my_wallet/services/sync_config.dart';

// Migration script to add 'deleted', 'updated_at', and 'last_updated_by' columns to existing PostgreSQL tables.
// To run: dart bin/migrate_deleted_column.dart

final List<String> alterQueries = [
  'ALTER TABLE categories ADD COLUMN IF NOT EXISTS deleted INTEGER DEFAULT 0;',
  'ALTER TABLE categories ADD COLUMN IF NOT EXISTS updated_at BIGINT DEFAULT 0;',
  'ALTER TABLE categories ADD COLUMN IF NOT EXISTS last_updated_by VARCHAR(100);',
  
  'ALTER TABLE transactions ADD COLUMN IF NOT EXISTS deleted INTEGER DEFAULT 0;',
  'ALTER TABLE transactions ADD COLUMN IF NOT EXISTS updated_at BIGINT DEFAULT 0;',
  'ALTER TABLE transactions ADD COLUMN IF NOT EXISTS last_updated_by VARCHAR(100);',

  'ALTER TABLE loans ADD COLUMN IF NOT EXISTS deleted INTEGER DEFAULT 0;',
  'ALTER TABLE loans ADD COLUMN IF NOT EXISTS updated_at BIGINT DEFAULT 0;',
  'ALTER TABLE loans ADD COLUMN IF NOT EXISTS last_updated_by VARCHAR(100);',

  'ALTER TABLE income_configs ADD COLUMN IF NOT EXISTS deleted INTEGER DEFAULT 0;',
  'ALTER TABLE income_configs ADD COLUMN IF NOT EXISTS updated_at BIGINT DEFAULT 0;',
  'ALTER TABLE income_configs ADD COLUMN IF NOT EXISTS last_updated_by VARCHAR(100);',

  'ALTER TABLE lend_borrows ADD COLUMN IF NOT EXISTS deleted INTEGER DEFAULT 0;',
  'ALTER TABLE lend_borrows ADD COLUMN IF NOT EXISTS updated_at BIGINT DEFAULT 0;',
  'ALTER TABLE lend_borrows ADD COLUMN IF NOT EXISTS last_updated_by VARCHAR(100);',

  'ALTER TABLE repayments ADD COLUMN IF NOT EXISTS deleted INTEGER DEFAULT 0;',
  'ALTER TABLE repayments ADD COLUMN IF NOT EXISTS updated_at BIGINT DEFAULT 0;',
  'ALTER TABLE repayments ADD COLUMN IF NOT EXISTS last_updated_by VARCHAR(100);',

  'ALTER TABLE investments ADD COLUMN IF NOT EXISTS deleted INTEGER DEFAULT 0;',
  'ALTER TABLE investments ADD COLUMN IF NOT EXISTS updated_at BIGINT DEFAULT 0;',
  'ALTER TABLE investments ADD COLUMN IF NOT EXISTS last_updated_by VARCHAR(100);',

  'ALTER TABLE category_budgets ADD COLUMN IF NOT EXISTS deleted INTEGER DEFAULT 0;',
  'ALTER TABLE category_budgets ADD COLUMN IF NOT EXISTS updated_at BIGINT DEFAULT 0;',
  'ALTER TABLE category_budgets ADD COLUMN IF NOT EXISTS last_updated_by VARCHAR(100);',

  'ALTER TABLE od_accounts ADD COLUMN IF NOT EXISTS deleted INTEGER DEFAULT 0;',
  'ALTER TABLE od_accounts ADD COLUMN IF NOT EXISTS updated_at BIGINT DEFAULT 0;',
  'ALTER TABLE od_accounts ADD COLUMN IF NOT EXISTS last_updated_by VARCHAR(100);',

  'ALTER TABLE od_transactions ADD COLUMN IF NOT EXISTS deleted INTEGER DEFAULT 0;',
  'ALTER TABLE od_transactions ADD COLUMN IF NOT EXISTS updated_at BIGINT DEFAULT 0;',
  'ALTER TABLE od_transactions ADD COLUMN IF NOT EXISTS last_updated_by VARCHAR(100);',

  'ALTER TABLE fuel_logs ADD COLUMN IF NOT EXISTS deleted INTEGER DEFAULT 0;',
  'ALTER TABLE fuel_logs ADD COLUMN IF NOT EXISTS updated_at BIGINT DEFAULT 0;',
  'ALTER TABLE fuel_logs ADD COLUMN IF NOT EXISTS last_updated_by VARCHAR(100);',

  'ALTER TABLE vehicle_configs ADD COLUMN IF NOT EXISTS deleted INTEGER DEFAULT 0;',
  'ALTER TABLE vehicle_configs ADD COLUMN IF NOT EXISTS updated_at BIGINT DEFAULT 0;',
  'ALTER TABLE vehicle_configs ADD COLUMN IF NOT EXISTS last_updated_by VARCHAR(100);',

  'ALTER TABLE car_trips ADD COLUMN IF NOT EXISTS deleted INTEGER DEFAULT 0;',
  'ALTER TABLE car_trips ADD COLUMN IF NOT EXISTS updated_at BIGINT DEFAULT 0;',
  'ALTER TABLE car_trips ADD COLUMN IF NOT EXISTS last_updated_by VARCHAR(100);',

  'ALTER TABLE wallet_contacts ADD COLUMN IF NOT EXISTS deleted INTEGER DEFAULT 0;',
  'ALTER TABLE wallet_contacts ADD COLUMN IF NOT EXISTS updated_at BIGINT DEFAULT 0;',
  'ALTER TABLE wallet_contacts ADD COLUMN IF NOT EXISTS last_updated_by VARCHAR(100);',

  'ALTER TABLE wallet_products ADD COLUMN IF NOT EXISTS deleted INTEGER DEFAULT 0;',
  'ALTER TABLE wallet_products ADD COLUMN IF NOT EXISTS updated_at BIGINT DEFAULT 0;',
  'ALTER TABLE wallet_products ADD COLUMN IF NOT EXISTS last_updated_by VARCHAR(100);',
];

Future<void> main() async {
  print('Starting DB migration for mWallet tables...\n');

  if (SyncConfig.useApiGateway) {
    print('Routing migration queries via API Gateway at ${SyncConfig.apiGatewayUrl}...');
    for (int i = 0; i < alterQueries.length; i++) {
      try {
        final resp = await http.post(
          Uri.parse(SyncConfig.apiGatewayUrl),
          headers: {
            'Content-Type': 'application/json',
            'x-api-key': SyncConfig.apiKey,
          },
          body: jsonEncode({
            'query': alterQueries[i],
            'params': [],
          }),
        );
        if (resp.statusCode == 200) {
          print('  [✓] Query ${i + 1}/${alterQueries.length} executed successfully via API.');
        } else {
          print('  [✗] Query ${i + 1} failed: ${resp.body}');
        }
      } catch (e) {
        print('  [✗] Query ${i + 1} error: $e');
      }
    }
  } else {
    print('Connecting directly to PostgreSQL DB at ${SyncConfig.host}:${SyncConfig.port}...');
    try {
      final connection = await Connection.open(
        Endpoint(
          host: SyncConfig.host,
          port: SyncConfig.port,
          database: SyncConfig.database,
          username: SyncConfig.username,
          password: SyncConfig.password,
        ),
        settings: const ConnectionSettings(sslMode: SslMode.disable),
      );

      for (int i = 0; i < alterQueries.length; i++) {
        await connection.execute(alterQueries[i]);
        print('  [✓] Query ${i + 1}/${alterQueries.length} executed.');
      }

      await connection.close();
      print('\nPostgreSQL migration completed successfully.');
    } catch (e) {
      print('\nDirect Database Connection Failed: $e');
      print('Please check your PostgreSQL connection settings or run the SQL script manually.');
      exit(1);
    }
  }
}

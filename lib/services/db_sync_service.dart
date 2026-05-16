import 'dart:convert';
import 'package:postgres/postgres.dart';
import '../providers/finance_provider.dart';

class DbSyncService {
  static Future<Connection> _connect() async {
    return await Connection.open(
      Endpoint(
        host: '192.168.50.109',
        database: 'my_wallet',
        username: 'walletintegrationuser',
        password: 'wallet@0909090909@',
        port: 5432,
      ),
      settings: ConnectionSettings(sslMode: SslMode.disable),
    );
  }

  static Future<void> _createTablesIfNotExist(Connection conn) async {
    await conn.execute('''
      CREATE TABLE IF NOT EXISTS app_sync_data (
        collection VARCHAR(50) NOT NULL,
        doc_id VARCHAR(50) NOT NULL,
        data JSONB NOT NULL,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        PRIMARY KEY (collection, doc_id)
      );
    ''');
  }

  static Future<void> pushToDb(FinanceProvider provider) async {
    final conn = await _connect();
    try {
      await _createTablesIfNotExist(conn);

      // We will batch UPSERT all items.
      final statement = await conn.prepare('''
        INSERT INTO app_sync_data (collection, doc_id, data, updated_at) 
        VALUES (\$1, \$2, \$3, NOW()) 
        ON CONFLICT (collection, doc_id) 
        DO UPDATE SET data = EXCLUDED.data, updated_at = NOW();
      ''');

      Future<void> syncList(String collection, List<dynamic> items) async {
        for (final item in items) {
          final map = item.toMap();
          final id = map['id'].toString();
          await statement.run([collection, id, jsonEncode(map)]);
        }
      }

      await syncList('categories', provider.categories);
      await syncList('transactions', provider.transactions);
      await syncList('loans', provider.loans);
      await syncList('income_config', provider.incomeConfigs);
      await syncList('lend_borrows', provider.lendBorrows);
      await syncList('repayments', provider.repayments);
      await syncList('investments', provider.investments);

    } finally {
      await conn.close();
    }
  }

  static Future<void> pullFromDb(FinanceProvider provider) async {
    final conn = await _connect();
    try {
      await _createTablesIfNotExist(conn);

      final result = await conn.execute('SELECT collection, data FROM app_sync_data;');
      
      Map<String, List<Map<String, dynamic>>> parsedData = {
        'categories': [],
        'transactions': [],
        'loans': [],
        'income_config': [],
        'lend_borrows': [],
        'repayments': [],
        'investments': [],
      };

      for (final row in result) {
        final collection = row[0] as String;
        final rawData = row[1];
        final dataMap = rawData is String ? jsonDecode(rawData) as Map<String, dynamic> : rawData as Map<String, dynamic>;
        
        if (parsedData.containsKey(collection)) {
          parsedData[collection]!.add(dataMap);
        }
      }

      // Sync back to FinanceProvider, which will overwrite SharedPreferences
      await provider.overwriteFromSync(parsedData);

    } finally {
      await conn.close();
    }
  }
}

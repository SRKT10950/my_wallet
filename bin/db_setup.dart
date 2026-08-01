// ignore_for_file: avoid_print
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:postgres/postgres.dart';
import 'package:my_wallet/services/sync_config.dart';

// Manual database schema setup script.
// To run: dart bin/db_setup.dart

final List<String> schemaQueries = [
  '''
  CREATE TABLE IF NOT EXISTS users (
    mobile_number VARCHAR(20) PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    pin VARCHAR(20) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
  );
  ''',
  '''
  CREATE TABLE IF NOT EXISTS categories (
    id VARCHAR(50) NOT NULL,
    user_id VARCHAR(20) NOT NULL,
    name VARCHAR(100) NOT NULL,
    "plannedAmount" DOUBLE PRECISION NOT NULL,
    deleted INTEGER DEFAULT 0,
    PRIMARY KEY (user_id, id),
    FOREIGN KEY (user_id) REFERENCES users(mobile_number) ON DELETE CASCADE
  );
  ''',
  '''
  CREATE TABLE IF NOT EXISTS transactions (
    id VARCHAR(50) NOT NULL,
    user_id VARCHAR(20) NOT NULL,
    "categoryId" VARCHAR(50) NOT NULL,
    "itemService" TEXT NOT NULL,
    cost DOUBLE PRECISION NOT NULL,
    "paidAmount" DOUBLE PRECISION NOT NULL,
    cleared INTEGER NOT NULL,
    date VARCHAR(50) NOT NULL,
    deleted INTEGER DEFAULT 0,
    PRIMARY KEY (user_id, id),
    FOREIGN KEY (user_id) REFERENCES users(mobile_number) ON DELETE CASCADE
  );
  ''',
  '''
  CREATE TABLE IF NOT EXISTS loans (
    id VARCHAR(50) NOT NULL,
    user_id VARCHAR(20) NOT NULL,
    lender VARCHAR(100) NOT NULL,
    "startDate" VARCHAR(50) NOT NULL,
    "endDate" VARCHAR(50) NOT NULL,
    tenure INTEGER NOT NULL,
    roi DOUBLE PRECISION NOT NULL,
    principal DOUBLE PRECISION NOT NULL,
    interest DOUBLE PRECISION NOT NULL,
    total DOUBLE PRECISION NOT NULL,
    paid DOUBLE PRECISION NOT NULL,
    balance DOUBLE PRECISION NOT NULL,
    emi DOUBLE PRECISION NOT NULL,
    "tenurePending" INTEGER NOT NULL,
    status VARCHAR(20) NOT NULL,
    deleted INTEGER DEFAULT 0,
    PRIMARY KEY (user_id, id),
    FOREIGN KEY (user_id) REFERENCES users(mobile_number) ON DELETE CASCADE
  );
  ''',
  '''
  CREATE TABLE IF NOT EXISTS income_configs (
    id VARCHAR(50) NOT NULL,
    user_id VARCHAR(20) NOT NULL,
    month INTEGER NOT NULL,
    year INTEGER NOT NULL,
    amount DOUBLE PRECISION NOT NULL,
    "isDefault" INTEGER NOT NULL,
    deleted INTEGER DEFAULT 0,
    PRIMARY KEY (user_id, id),
    FOREIGN KEY (user_id) REFERENCES users(mobile_number) ON DELETE CASCADE
  );
  ''',
  '''
  CREATE TABLE IF NOT EXISTS lend_borrows (
    id VARCHAR(50) NOT NULL,
    user_id VARCHAR(20) NOT NULL,
    name VARCHAR(100) NOT NULL,
    type VARCHAR(20) NOT NULL,
    date VARCHAR(50) NOT NULL,
    tenure INTEGER NOT NULL,
    principal DOUBLE PRECISION NOT NULL,
    "returnDate" VARCHAR(50),
    settled DOUBLE PRECISION,
    diff DOUBLE PRECISION,
    status VARCHAR(20) NOT NULL,
    deleted INTEGER DEFAULT 0,
    PRIMARY KEY (user_id, id),
    FOREIGN KEY (user_id) REFERENCES users(mobile_number) ON DELETE CASCADE
  );
  ''',
  '''
  CREATE TABLE IF NOT EXISTS repayments (
    id VARCHAR(50) NOT NULL,
    user_id VARCHAR(20) NOT NULL,
    "lendBorrowId" VARCHAR(50) NOT NULL,
    name VARCHAR(100) NOT NULL,
    "paymentDate" VARCHAR(50) NOT NULL,
    amount DOUBLE PRECISION NOT NULL,
    method VARCHAR(50) NOT NULL,
    deleted INTEGER DEFAULT 0,
    PRIMARY KEY (user_id, id),
    FOREIGN KEY (user_id) REFERENCES users(mobile_number) ON DELETE CASCADE
  );
  ''',
  '''
  CREATE TABLE IF NOT EXISTS investments (
    id VARCHAR(50) NOT NULL,
    user_id VARCHAR(20) NOT NULL,
    name VARCHAR(100) NOT NULL,
    type VARCHAR(20) NOT NULL,
    amount DOUBLE PRECISION NOT NULL,
    "expectedRoi" DOUBLE PRECISION NOT NULL,
    "tenureMonths" INTEGER NOT NULL,
    "startDate" VARCHAR(50) NOT NULL,
    deleted INTEGER DEFAULT 0,
    PRIMARY KEY (user_id, id),
    FOREIGN KEY (user_id) REFERENCES users(mobile_number) ON DELETE CASCADE
  );
  ''',
  '''
  CREATE TABLE IF NOT EXISTS category_budgets (
    id VARCHAR(50) NOT NULL,
    user_id VARCHAR(20) NOT NULL,
    "categoryId" VARCHAR(50) NOT NULL,
    month INTEGER NOT NULL,
    year INTEGER NOT NULL,
    amount DOUBLE PRECISION NOT NULL,
    deleted INTEGER DEFAULT 0,
    PRIMARY KEY (user_id, "categoryId", month, year),
    FOREIGN KEY (user_id) REFERENCES users(mobile_number) ON DELETE CASCADE
  );
  ''',
  '''
  CREATE TABLE IF NOT EXISTS od_accounts (
    id VARCHAR(50) NOT NULL,
    user_id VARCHAR(20) NOT NULL,
    name VARCHAR(100) NOT NULL,
    "limit" DOUBLE PRECISION NOT NULL,
    "interestRate" DOUBLE PRECISION NOT NULL,
    "billingDay" INTEGER NOT NULL,
    deleted INTEGER DEFAULT 0,
    PRIMARY KEY (user_id, id),
    FOREIGN KEY (user_id) REFERENCES users(mobile_number) ON DELETE CASCADE
  );
  ''',
  '''
  CREATE TABLE IF NOT EXISTS od_transactions (
    id VARCHAR(50) NOT NULL,
    user_id VARCHAR(20) NOT NULL,
    "odAccountId" VARCHAR(50) NOT NULL,
    amount DOUBLE PRECISION NOT NULL,
    type VARCHAR(20) NOT NULL,
    date VARCHAR(50) NOT NULL,
    deleted INTEGER DEFAULT 0,
    PRIMARY KEY (user_id, id),
    FOREIGN KEY (user_id) REFERENCES users(mobile_number) ON DELETE CASCADE
  );
  ''',
  '''
  CREATE TABLE IF NOT EXISTS fuel_logs (
    id VARCHAR(50) NOT NULL,
    user_id VARCHAR(20) NOT NULL,
    date VARCHAR(50) NOT NULL,
    odometer DOUBLE PRECISION NOT NULL,
    "fuelAmount" DOUBLE PRECISION NOT NULL,
    "pricePerUnit" DOUBLE PRECISION NOT NULL,
    "totalCost" DOUBLE PRECISION NOT NULL,
    "isFullTank" INTEGER NOT NULL,
    notes TEXT NOT NULL,
    deleted INTEGER DEFAULT 0,
    PRIMARY KEY (user_id, id),
    FOREIGN KEY (user_id) REFERENCES users(mobile_number) ON DELETE CASCADE
  );
  ''',
  '''
  CREATE TABLE IF NOT EXISTS vehicle_configs (
    id VARCHAR(50) NOT NULL,
    user_id VARCHAR(20) NOT NULL,
    "initialOdometer" DOUBLE PRECISION NOT NULL,
    "currentOdometer" DOUBLE PRECISION NOT NULL,
    "vehicleName" VARCHAR(100) NOT NULL,
    "lastSyncTime" VARCHAR(50) NOT NULL,
    "autoStartOnBoot" INTEGER NOT NULL DEFAULT 1,
    deleted INTEGER DEFAULT 0,
    PRIMARY KEY (user_id, id),
    FOREIGN KEY (user_id) REFERENCES users(mobile_number) ON DELETE CASCADE
  );
  ''',
  '''
  CREATE TABLE IF NOT EXISTS car_trips (
    id VARCHAR(50) NOT NULL,
    user_id VARCHAR(20) NOT NULL,
    date VARCHAR(50) NOT NULL,
    "distanceTravelled" DOUBLE PRECISION NOT NULL,
    "startOdometer" DOUBLE PRECISION NOT NULL,
    "endOdometer" DOUBLE PRECISION NOT NULL,
    "gpsPath" TEXT NOT NULL,
    "durationSeconds" INTEGER NOT NULL,
    status VARCHAR(20) NOT NULL,
    deleted INTEGER DEFAULT 0,
    PRIMARY KEY (user_id, id),
    FOREIGN KEY (user_id) REFERENCES users(mobile_number) ON DELETE CASCADE
  );
  ''',
  '''
  CREATE TABLE IF NOT EXISTS wallet_contacts (
    id VARCHAR(50) NOT NULL,
    user_id VARCHAR(20) NOT NULL,
    name VARCHAR(150) NOT NULL,
    mobile VARCHAR(20),
    place VARCHAR(150),
    occupation VARCHAR(150),
    "businessName" VARCHAR(150),
    "transactionNotification" INTEGER DEFAULT 1,
    "notificationMethod" VARCHAR(20) DEFAULT 'WhatsApp',
    active INTEGER NOT NULL DEFAULT 1,
    deleted INTEGER DEFAULT 0,
    PRIMARY KEY (user_id, id),
    FOREIGN KEY (user_id) REFERENCES users(mobile_number) ON DELETE CASCADE
  );
  '''
];

Future<void> main() async {
  print('==================================================');
  print('          MY WALLET - DATABASE SCHEMA SETUP       ');
  print('==================================================');
  print('Connecting using configuration from sync_config.dart...');

  if (SyncConfig.useApiGateway) {
    print('Mode: API Gateway (${SyncConfig.apiGatewayUrl})');
    await runViaApiGateway();
  } else {
    print('Mode: Direct PostgreSQL (${SyncConfig.host}:${SyncConfig.port})');
    await runDirectPostgres();
  }
}

Future<void> runViaApiGateway() async {
  for (int i = 0; i < schemaQueries.length; i++) {
    final sql = schemaQueries[i];
    final tableName = _extractTableName(sql);
    print('Creating table $tableName ($i/${schemaQueries.length})...');
    
    try {
      final res = await http.post(
        Uri.parse(SyncConfig.apiGatewayUrl),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': SyncConfig.apiKey,
        },
        body: jsonEncode({
          'query': sql,
        }),
      );

      if (res.statusCode != 200) {
        throw Exception('Status code: ${res.statusCode}\nBody: ${res.body}');
      }

      final data = jsonDecode(res.body);
      if (data['success'] != true) {
        throw Exception('API error: ${data['error']}');
      }
      print('  -> Table $tableName created successfully.');
    } catch (e) {
      print('  [ERROR] Failed to create table $tableName: $e');
      exit(1);
    }
  }
  print('\n[SUCCESS] All tables created successfully via API Gateway!');
}

Future<void> runDirectPostgres() async {
  Connection conn;
  try {
    conn = await Connection.open(
      Endpoint(
        host: SyncConfig.host,
        database: SyncConfig.database,
        username: SyncConfig.username,
        password: SyncConfig.password,
        port: SyncConfig.port,
      ),
      settings: ConnectionSettings(
        sslMode: SslMode.disable,
        connectTimeout: const Duration(seconds: 15),
      ),
    );
  } catch (e) {
    print('[ERROR] Failed to connect directly to PostgreSQL: $e');
    exit(1);
  }

  try {
    for (int i = 0; i < schemaQueries.length; i++) {
      final sql = schemaQueries[i];
      final tableName = _extractTableName(sql);
      print('Creating table $tableName ($i/${schemaQueries.length})...');
      
      await conn.execute(sql);
      print('  -> Table $tableName created successfully.');
    }
    print('\n[SUCCESS] All tables created successfully via direct PostgreSQL connection!');
  } catch (e) {
    print('  [ERROR] Execution failed: $e');
    exit(1);
  } finally {
    await conn.close();
  }
}

String _extractTableName(String sql) {
  final match = RegExp(r'CREATE\s+TABLE\s+(?:IF\s+NOT\s+EXISTS\s+)?(\w+)', caseSensitive: false).firstMatch(sql);
  return match?.group(1) ?? 'unknown';
}

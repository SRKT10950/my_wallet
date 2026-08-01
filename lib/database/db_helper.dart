import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();

  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDB('my_wallet.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 10,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const realType = 'REAL NOT NULL';
    const boolType = 'INTEGER NOT NULL';

    await db.execute('''
CREATE TABLE categories (
  id $idType,
  name $textType,
  plannedAmount $realType,
  deleted INTEGER NOT NULL DEFAULT 0
  )
''');

    await db.execute('''
CREATE TABLE transactions (
  id $idType,
  date $textType,
  categoryId INTEGER NOT NULL,
  itemService $textType,
  cost $realType,
  paidAmount $realType,
  cleared $boolType,
  accountId INTEGER,
  toAccountId INTEGER,
  transactionType TEXT,
  tags TEXT,
  note TEXT,
  merchantName TEXT,
  deleted INTEGER NOT NULL DEFAULT 0,
  FOREIGN KEY (categoryId) REFERENCES categories (id)
  )
''');

    await db.execute('''
CREATE TABLE loans (
  id $idType,
  lender $textType,
  startDate $textType,
  endDate $textType,
  tenure INTEGER NOT NULL,
  roi $realType,
  principal $realType,
  interest $realType,
  total $realType,
  paid $realType,
  balance $realType,
  emi $realType,
  tenurePending INTEGER NOT NULL,
  status $textType,
  deleted INTEGER NOT NULL DEFAULT 0
  )
''');

    await db.execute('''
CREATE TABLE income_config (
  id $idType,
  month INTEGER NOT NULL,
  year INTEGER NOT NULL,
  amount $realType,
  isDefault $boolType,
  deleted INTEGER NOT NULL DEFAULT 0
  )
''');

    await _createRemainingTables(db);
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createRemainingTables(db);
    }
    if (oldVersion < 3) {
      try {
        await db.execute('ALTER TABLE transactions ADD COLUMN accountId INTEGER');
      } catch (_) {}
      try {
        await db.execute('ALTER TABLE transactions ADD COLUMN toAccountId INTEGER');
      } catch (_) {}
      try {
        await db.execute('ALTER TABLE transactions ADD COLUMN transactionType TEXT');
      } catch (_) {}
      try {
        await db.execute('ALTER TABLE transactions ADD COLUMN tags TEXT');
      } catch (_) {}
      try {
        await db.execute('ALTER TABLE transactions ADD COLUMN note TEXT');
      } catch (_) {}
    }
    if (oldVersion < 4) {
      try {
        await db.execute('ALTER TABLE transactions ADD COLUMN merchantName TEXT');
      } catch (_) {}
    }
    if (oldVersion < 5) {
      final tables = [
        'categories', 'transactions', 'loans', 'income_config',
        'lend_borrows', 'repayments', 'investments', 'category_budgets',
        'od_accounts', 'od_transactions', 'fuel_logs', 'vehicle_configs',
        'car_trips', 'wallet_accounts', 'scheduled_payments', 'goals',
        'wallet_assets_portfolio', 'wallet_split_bills'
      ];
      for (final t in tables) {
        try {
          await db.execute('ALTER TABLE $t ADD COLUMN deleted INTEGER NOT NULL DEFAULT 0');
        } catch (_) {}
      }
    }
    if (oldVersion < 6) {
      try {
        await db.execute('''
CREATE TABLE IF NOT EXISTS wallet_contacts (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  mobile TEXT,
  place TEXT,
  occupation TEXT,
  businessName TEXT,
  active INTEGER NOT NULL DEFAULT 1,
  deleted INTEGER NOT NULL DEFAULT 0
  )
''');
      } catch (_) {}
    }
    if (oldVersion < 7) {
      try {
        await db.execute('ALTER TABLE wallet_contacts ADD COLUMN businessName TEXT');
      } catch (_) {}
    }
    if (oldVersion < 8) {
      try {
        await db.execute('ALTER TABLE wallet_contacts ADD COLUMN transactionNotification INTEGER NOT NULL DEFAULT 1');
      } catch (_) {}
      try {
        await db.execute("ALTER TABLE wallet_contacts ADD COLUMN notificationMethod TEXT DEFAULT 'WhatsApp'");
      } catch (_) {}
    }
    if (oldVersion < 9) {
      try {
        await db.execute('''
CREATE TABLE IF NOT EXISTS wallet_products (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id TEXT DEFAULT 'user_1',
  productName TEXT NOT NULL,
  localName TEXT,
  category TEXT DEFAULT 'General',
  referenceLink TEXT,
  appName TEXT,
  priceDate TEXT,
  currentPrice REAL NOT NULL DEFAULT 0,
  oldPrice REAL NOT NULL DEFAULT 0,
  unit TEXT DEFAULT 'Pcs',
  quantity REAL NOT NULL DEFAULT 1,
  barcode TEXT DEFAULT '',
  qrCode TEXT DEFAULT '',
  imageUrl TEXT DEFAULT '',
  description TEXT DEFAULT '',
  active INTEGER NOT NULL DEFAULT 1,
  deleted INTEGER NOT NULL DEFAULT 0
  )
''');
      } catch (_) {}
    }
    if (oldVersion < 10) {
      try {
        await db.execute("ALTER TABLE wallet_products ADD COLUMN category TEXT DEFAULT 'General'");
      } catch (_) {}
    }
    try {
      await db.execute("ALTER TABLE wallet_products ADD COLUMN barcode TEXT DEFAULT ''");
      await db.execute("ALTER TABLE wallet_products ADD COLUMN qrCode TEXT DEFAULT ''");
      await db.execute("ALTER TABLE wallet_products ADD COLUMN imageUrl TEXT DEFAULT ''");
      await db.execute("ALTER TABLE wallet_products ADD COLUMN description TEXT DEFAULT ''");
    } catch (_) {}
  }

  Future _createRemainingTables(Database db) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const realType = 'REAL NOT NULL';
    const boolType = 'INTEGER NOT NULL';

    await db.execute('''
CREATE TABLE IF NOT EXISTS lend_borrows (
  id $idType,
  name $textType,
  type $textType,
  date $textType,
  tenure INTEGER NOT NULL,
  principal $realType,
  returnDate TEXT,
  settled $realType,
  diff $realType,
  status $textType,
  deleted INTEGER NOT NULL DEFAULT 0
  )
''');

    await db.execute('''
CREATE TABLE IF NOT EXISTS repayments (
  id $idType,
  lendBorrowId INTEGER NOT NULL,
  name $textType,
  paymentDate $textType,
  amount $realType,
  method $textType,
  deleted INTEGER NOT NULL DEFAULT 0,
  FOREIGN KEY (lendBorrowId) REFERENCES lend_borrows (id) ON DELETE CASCADE
  )
''');

    await db.execute('''
CREATE TABLE IF NOT EXISTS investments (
  id $idType,
  name $textType,
  type $textType,
  amount $realType,
  expectedRoi $realType,
  tenureMonths INTEGER NOT NULL,
  startDate $textType,
  deleted INTEGER NOT NULL DEFAULT 0
  )
''');

    await db.execute('''
CREATE TABLE IF NOT EXISTS category_budgets (
  id $idType,
  categoryId INTEGER NOT NULL,
  month INTEGER NOT NULL,
  year INTEGER NOT NULL,
  amount $realType,
  deleted INTEGER NOT NULL DEFAULT 0
  )
''');

    await db.execute('''
CREATE TABLE IF NOT EXISTS od_accounts (
  id $idType,
  name $textType,
  "limit" $realType,
  interestRate $realType,
  billingDay INTEGER NOT NULL,
  deleted INTEGER NOT NULL DEFAULT 0
  )
''');

    await db.execute('''
CREATE TABLE IF NOT EXISTS od_transactions (
  id $idType,
  odAccountId INTEGER NOT NULL,
  amount $realType,
  type $textType,
  date $textType,
  deleted INTEGER NOT NULL DEFAULT 0
  )
''');

    await db.execute('''
CREATE TABLE IF NOT EXISTS fuel_logs (
  id $idType,
  date $textType,
  odometer $realType,
  fuelAmount $realType,
  pricePerUnit $realType,
  totalCost $realType,
  isFullTank $boolType,
  notes $textType,
  deleted INTEGER NOT NULL DEFAULT 0
  )
''');

    await db.execute('''
CREATE TABLE IF NOT EXISTS vehicle_configs (
  id TEXT PRIMARY KEY,
  initialOdometer $realType,
  currentOdometer $realType,
  vehicleName $textType,
  lastSyncTime $textType,
  autoStartOnBoot $boolType,
  deleted INTEGER NOT NULL DEFAULT 0
  )
''');

    await db.execute('''
CREATE TABLE IF NOT EXISTS car_trips (
  id $idType,
  date $textType,
  distanceTravelled $realType,
  startOdometer $realType,
  endOdometer $realType,
  gpsPath $textType,
  durationSeconds INTEGER NOT NULL,
  status $textType,
  deleted INTEGER NOT NULL DEFAULT 0
  )
''');

    await db.execute('''
CREATE TABLE IF NOT EXISTS wallet_accounts (
  id $idType,
  name $textType,
  type $textType,
  initialBalance $realType,
  currencySymbol $textType,
  color $textType,
  deleted INTEGER NOT NULL DEFAULT 0
  )
''');

    await db.execute('''
CREATE TABLE IF NOT EXISTS scheduled_payments (
  id $idType,
  name $textType,
  amount $realType,
  type $textType,
  categoryId INTEGER NOT NULL,
  accountId INTEGER NOT NULL,
  frequency $textType,
  nextDueDate $textType,
  active $boolType,
  deleted INTEGER NOT NULL DEFAULT 0
  )
''');

    await db.execute('''
CREATE TABLE IF NOT EXISTS goals (
  id $idType,
  name $textType,
  targetAmount $realType,
  savedAmount $realType,
  targetDate TEXT,
  accountId INTEGER,
  color $textType,
  deleted INTEGER NOT NULL DEFAULT 0
  )
''');

    await db.execute('''
CREATE TABLE IF NOT EXISTS wallet_assets_portfolio (
  id $idType,
  name $textType,
  category $textType,
  quantity $realType,
  buyPrice $realType,
  currentPrice $realType,
  symbol $textType,
  dateAdded $textType,
  deleted INTEGER NOT NULL DEFAULT 0
  )
''');

    await db.execute('''
CREATE TABLE IF NOT EXISTS wallet_friends (
  name TEXT PRIMARY KEY
  )
''');

    await db.execute('''
CREATE TABLE IF NOT EXISTS wallet_contacts (
  id $idType,
  name $textType,
  mobile TEXT,
  place TEXT,
  occupation TEXT,
  businessName TEXT,
  transactionNotification INTEGER NOT NULL DEFAULT 1,
  notificationMethod TEXT DEFAULT 'WhatsApp',
  active INTEGER NOT NULL DEFAULT 1,
  deleted INTEGER NOT NULL DEFAULT 0
  )
''');

    await db.execute('''
CREATE TABLE IF NOT EXISTS wallet_split_bills (
  id $idType,
  title $textType,
  totalAmount $realType,
  paidBy $textType,
  participants $textType,
  shares $textType,
  date $textType,
  deleted INTEGER NOT NULL DEFAULT 0
  )
''');
  }

  Future<void> saveList(String table, List<Map<String, dynamic>> maps) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      final stringList = maps.map((map) {
        final mutableMap = Map<String, dynamic>.from(map);
        if (mutableMap['participants'] is List) {
          mutableMap['participants'] = (mutableMap['participants'] as List).join(',');
        }
        if (mutableMap['tags'] is List) {
          mutableMap['tags'] = (mutableMap['tags'] as List).join(',');
        }
        return jsonEncode(mutableMap);
      }).toList();
      await prefs.setStringList('web_db_$table', stringList);
      return;
    }

    final db = await database;
    await db.transaction((txn) async {
      await txn.delete(table);
      for (var map in maps) {
        final mutableMap = Map<String, dynamic>.from(map);
        if (mutableMap['participants'] is List) {
          mutableMap['participants'] = (mutableMap['participants'] as List).join(',');
        }
        if (mutableMap['tags'] is List) {
          mutableMap['tags'] = (mutableMap['tags'] as List).join(',');
        }
        if (table == 'wallet_products') {
          mutableMap.remove('Description');
        }
        await txn.insert(table, mutableMap, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }

  Future<List<Map<String, dynamic>>> loadList(String table) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      final stringList = prefs.getStringList('web_db_$table');
      if (stringList == null) return [];
      return stringList.map((str) {
        final decoded = jsonDecode(str) as Map<String, dynamic>;
        final mutable = Map<String, dynamic>.from(decoded);
        if (table == 'wallet_split_bills' && mutable['participants'] is String) {
          if (mutable['participants'].toString().trim().isEmpty) {
            mutable['participants'] = <String>[];
          } else {
            mutable['participants'] = mutable['participants'].toString().split(',');
          }
        }
        return mutable;
      }).toList();
    }

    final db = await database;
    final results = await db.query(table);
    
    return results.map((row) {
      final mutable = Map<String, dynamic>.from(row);
      if (table == 'wallet_split_bills' && mutable['participants'] is String) {
        if (mutable['participants'].toString().trim().isEmpty) {
          mutable['participants'] = <String>[];
        } else {
          mutable['participants'] = mutable['participants'].toString().split(',');
        }
      }
      return mutable;
    }).toList();
  }

  Future close() async {
    if (kIsWeb) return;
    final db = await instance.database;
    db.close();
  }
}

import 'package:postgres/postgres.dart';
import 'package:flutter/foundation.dart' hide Category;
import '../providers/finance_provider.dart';
import '../models/category.dart';
import '../models/transaction.dart';
import '../models/loan.dart';
import '../models/income_config.dart';
import '../models/lend_borrow.dart';
import '../models/investment.dart';
import '../models/category_budget.dart';
import '../models/od_account.dart';
import '../models/fuel_log.dart';
import '../models/vehicle_config.dart';
import '../models/car_trip.dart';
import 'sync_config.dart';
import 'db_sync_service_api.dart';

class DbSyncService {

  static Future<Connection> _connect() async {
    return await Connection.open(
      Endpoint(
        host: SyncConfig.host,
        database: SyncConfig.database,
        username: SyncConfig.username,
        password: SyncConfig.password,
        port: SyncConfig.port,
      ),
      settings: ConnectionSettings(
        sslMode: SslMode.disable,
        connectTimeout: const Duration(seconds: 10),
      ),
    );
  }



  static Future<Map<String, dynamic>?> loginUser(String mobile, String pin) async {
    if (SyncConfig.useApiGateway) {
      return DbSyncServiceApi.loginUser(mobile, pin);
    }
    final conn = await _connect();
    try {
      final result = await conn.execute(
        r'SELECT mobile_number, name FROM users WHERE mobile_number = $1 AND pin = $2',
        parameters: [mobile, pin],
      );
      if (result.isEmpty) return null;
      return {
        'mobile_number': result.first[0],
        'name': result.first[1],
      };
    } finally {
      await conn.close();
    }
  }

  static Future<bool> registerUser(String name, String mobile, String pin) async {
    if (SyncConfig.useApiGateway) {
      return DbSyncServiceApi.registerUser(name, mobile, pin);
    }
    final conn = await _connect();
    try {
      final check = await conn.execute(r'SELECT 1 FROM users WHERE mobile_number = $1', parameters: [mobile]);
      if (check.isNotEmpty) return false;

      await conn.execute(
        r'INSERT INTO users (name, mobile_number, pin) VALUES ($1, $2, $3)',
        parameters: [name, mobile, pin],
      );
      return true;
    } finally {
      await conn.close();
    }
  }

  static Future<void> pushToDb(FinanceProvider provider, {String? targetTable, dynamic targetItem}) async {
    if (SyncConfig.useApiGateway) {
      await DbSyncServiceApi.pushToDb(provider, targetTable: targetTable, targetItem: targetItem);
      return;
    }
    final userId = provider.currentUserId;
    if (userId == null) return;

    final conn = await _connect();
    try {
      // Categories
      if (targetTable == null || targetTable == 'categories') {
        final catStmt = await conn.prepare('''
          INSERT INTO categories (id, user_id, name, "plannedAmount", deleted) VALUES (\$1, \$2, \$3, \$4, \$5) 
          ON CONFLICT (user_id, id) DO UPDATE SET name = EXCLUDED.name, "plannedAmount" = EXCLUDED."plannedAmount", deleted = EXCLUDED.deleted;
        ''');
        final itemsToPush = targetItem != null && targetItem is Category
            ? [targetItem]
            : provider.allCategories;
        for (final item in itemsToPush) {
          await catStmt.run([item.id.toString(), userId, item.name, item.plannedAmount, item.deleted ? 1 : 0]);
        }
      }

      // Transactions
      if (targetTable == null || targetTable == 'transactions') {
        final txStmt = await conn.prepare('''
          INSERT INTO transactions (id, user_id, "categoryId", "itemService", cost, "paidAmount", cleared, date, "merchantName", deleted) VALUES (\$1, \$2, \$3, \$4, \$5, \$6, \$7, \$8, \$9, \$10) 
          ON CONFLICT (user_id, id) DO UPDATE SET "categoryId" = EXCLUDED."categoryId", "itemService" = EXCLUDED."itemService", cost = EXCLUDED.cost, "paidAmount" = EXCLUDED."paidAmount", cleared = EXCLUDED.cleared, date = EXCLUDED.date, "merchantName" = EXCLUDED."merchantName", deleted = EXCLUDED.deleted;
        ''');
        final itemsToPush = targetItem != null && targetItem is DailyTransaction
            ? [targetItem]
            : provider.allTransactions;
        for (final item in itemsToPush) {
          await txStmt.run([item.id.toString(), userId, item.categoryId.toString(), item.itemService, item.cost, item.paidAmount, item.cleared ? 1 : 0, item.date, item.merchantName, item.deleted ? 1 : 0]);
        }
      }

      // Loans
      if (targetTable == null || targetTable == 'loans') {
        final loanStmt = await conn.prepare('''
          INSERT INTO loans (id, user_id, lender, "startDate", "endDate", tenure, roi, principal, interest, total, paid, balance, emi, "tenurePending", status, deleted) 
          VALUES (\$1, \$2, \$3, \$4, \$5, \$6, \$7, \$8, \$9, \$10, \$11, \$12, \$13, \$14, \$15, \$16) 
          ON CONFLICT (user_id, id) DO UPDATE SET lender = EXCLUDED.lender, "startDate" = EXCLUDED."startDate", "endDate" = EXCLUDED."endDate", tenure = EXCLUDED.tenure, roi = EXCLUDED.roi, principal = EXCLUDED.principal, interest = EXCLUDED.interest, total = EXCLUDED.total, paid = EXCLUDED.paid, balance = EXCLUDED.balance, emi = EXCLUDED.emi, "tenurePending" = EXCLUDED."tenurePending", status = EXCLUDED.status, deleted = EXCLUDED.deleted;
        ''');
        final itemsToPush = targetItem != null && targetItem is Loan
            ? [targetItem]
            : provider.allLoans;
        for (final item in itemsToPush) {
          await loanStmt.run([item.id.toString(), userId, item.lender, item.startDate, item.endDate, item.tenure, item.roi, item.principal, item.interest, item.total, item.paid, item.balance, item.emi, item.tenurePending, item.status, item.deleted ? 1 : 0]);
        }
      }

      // Income Configs
      if (targetTable == null || targetTable == 'income_configs') {
        final incStmt = await conn.prepare('''
          INSERT INTO income_configs (id, user_id, month, year, amount, "isDefault", deleted) VALUES (\$1, \$2, \$3, \$4, \$5, \$6, \$7) 
          ON CONFLICT (user_id, id) DO UPDATE SET month = EXCLUDED.month, year = EXCLUDED.year, amount = EXCLUDED.amount, "isDefault" = EXCLUDED."isDefault", deleted = EXCLUDED.deleted;
        ''');
        final itemsToPush = targetItem != null && targetItem is IncomeConfig
            ? [targetItem]
            : provider.allIncomeConfigs;
        for (final item in itemsToPush) {
          await incStmt.run([item.id.toString(), userId, item.month, item.year, item.amount, item.isDefault ? 1 : 0, item.deleted ? 1 : 0]);
        }
      }

      // Lend Borrows
      if (targetTable == null || targetTable == 'lend_borrows') {
        final lbStmt = await conn.prepare('''
          INSERT INTO lend_borrows (id, user_id, name, type, date, tenure, principal, "returnDate", settled, diff, status, deleted) 
          VALUES (\$1, \$2, \$3, \$4, \$5, \$6, \$7, \$8, \$9, \$10, \$11, \$12) 
          ON CONFLICT (user_id, id) DO UPDATE SET name = EXCLUDED.name, type = EXCLUDED.type, date = EXCLUDED.date, tenure = EXCLUDED.tenure, principal = EXCLUDED.principal, "returnDate" = EXCLUDED."returnDate", settled = EXCLUDED.settled, diff = EXCLUDED.diff, status = EXCLUDED.status, deleted = EXCLUDED.deleted;
        ''');
        final itemsToPush = targetItem != null && targetItem is LendBorrow
            ? [targetItem]
            : provider.allLendBorrows;
        for (final item in itemsToPush) {
          await lbStmt.run([item.id.toString(), userId, item.name, item.type, item.date, item.tenure, item.principal, item.returnDate, item.settled, item.diff, item.status, item.deleted ? 1 : 0]);
        }
      }

      // Repayments
      if (targetTable == null || targetTable == 'repayments') {
        final repStmt = await conn.prepare('''
          INSERT INTO repayments (id, user_id, "lendBorrowId", name, "paymentDate", amount, method, deleted) VALUES (\$1, \$2, \$3, \$4, \$5, \$6, \$7, \$8) 
          ON CONFLICT (user_id, id) DO UPDATE SET "lendBorrowId" = EXCLUDED."lendBorrowId", name = EXCLUDED.name, "paymentDate" = EXCLUDED."paymentDate", amount = EXCLUDED.amount, method = EXCLUDED.method, deleted = EXCLUDED.deleted;
        ''');
        final itemsToPush = targetItem != null && targetItem is Repayment
            ? [targetItem]
            : provider.allRepayments;
        for (final item in itemsToPush) {
          await repStmt.run([item.id.toString(), userId, item.lendBorrowId.toString(), item.name, item.paymentDate, item.amount, item.method, item.deleted ? 1 : 0]);
        }
      }

      // Investments
      if (targetTable == null || targetTable == 'investments') {
        final invStmt = await conn.prepare('''
          INSERT INTO investments (id, user_id, name, type, amount, "expectedRoi", "tenureMonths", "startDate", deleted) VALUES (\$1, \$2, \$3, \$4, \$5, \$6, \$7, \$8, \$9) 
          ON CONFLICT (user_id, id) DO UPDATE SET name = EXCLUDED.name, type = EXCLUDED.type, amount = EXCLUDED.amount, "expectedRoi" = EXCLUDED."expectedRoi", "tenureMonths" = EXCLUDED."tenureMonths", "startDate" = EXCLUDED."startDate", deleted = EXCLUDED.deleted;
        ''');
        final itemsToPush = targetItem != null && targetItem is Investment
            ? [targetItem]
            : provider.allInvestments;
        for (final item in itemsToPush) {
          await invStmt.run([item.id.toString(), userId, item.name, item.type, item.amount, item.expectedRoi, item.tenureMonths, item.startDate, item.deleted ? 1 : 0]);
        }
      }

      // Category Budgets
      if (targetTable == null || targetTable == 'category_budgets') {
        final cbStmt = await conn.prepare('''
          INSERT INTO category_budgets (id, user_id, "categoryId", month, year, amount, deleted) 
          VALUES (\$1, \$2, \$3, \$4, \$5, \$6, \$7) 
          ON CONFLICT (user_id, "categoryId", month, year) DO UPDATE SET id = EXCLUDED.id, amount = EXCLUDED.amount, deleted = EXCLUDED.deleted;
        ''');
        final itemsToPush = targetItem != null && targetItem is CategoryBudget
            ? [targetItem]
            : provider.allCategoryBudgets;
        for (final item in itemsToPush) {
          await cbStmt.run([item.id.toString(), userId, item.categoryId.toString(), item.month, item.year, item.amount, item.deleted ? 1 : 0]);
        }
      }

      // OD Accounts
      if (targetTable == null || targetTable == 'od_accounts') {
        final odStmt = await conn.prepare('''
          INSERT INTO od_accounts (id, user_id, name, "limit", "interestRate", "billingDay", deleted) 
          VALUES (\$1, \$2, \$3, \$4, \$5, \$6, \$7) 
          ON CONFLICT (user_id, id) DO UPDATE SET name = EXCLUDED.name, "limit" = EXCLUDED."limit", "interestRate" = EXCLUDED."interestRate", "billingDay" = EXCLUDED."billingDay", deleted = EXCLUDED.deleted;
        ''');
        final itemsToPush = targetItem != null && targetItem is OdAccount
            ? [targetItem]
            : provider.allOdAccounts;
        for (final item in itemsToPush) {
          await odStmt.run([item.id.toString(), userId, item.name, item.limit, item.interestRate, item.billingDay, item.deleted ? 1 : 0]);
        }
      }

      // OD Transactions
      if (targetTable == null || targetTable == 'od_transactions') {
        final odtxStmt = await conn.prepare('''
          INSERT INTO od_transactions (id, user_id, "odAccountId", amount, type, date, deleted) 
          VALUES (\$1, \$2, \$3, \$4, \$5, \$6, \$7) 
          ON CONFLICT (user_id, id) DO UPDATE SET "odAccountId" = EXCLUDED."odAccountId", amount = EXCLUDED.amount, type = EXCLUDED.type, date = EXCLUDED.date, deleted = EXCLUDED.deleted;
        ''');
        final itemsToPush = targetItem != null && targetItem is OdTransaction
            ? [targetItem]
            : provider.allOdTransactions;
        for (final item in itemsToPush) {
          await odtxStmt.run([item.id.toString(), userId, item.odAccountId.toString(), item.amount, item.type, item.date, item.deleted ? 1 : 0]);
        }
      }

      // Fuel Logs
      if (targetTable == null || targetTable == 'fuel_logs') {
        final fuelStmt = await conn.prepare('''
          INSERT INTO fuel_logs (id, user_id, date, odometer, "fuelAmount", "pricePerUnit", "totalCost", "isFullTank", notes, deleted) 
          VALUES (\$1, \$2, \$3, \$4, \$5, \$6, \$7, \$8, \$9, \$10) 
          ON CONFLICT (user_id, id) DO UPDATE SET date = EXCLUDED.date, odometer = EXCLUDED.odometer, "fuelAmount" = EXCLUDED."fuelAmount", "pricePerUnit" = EXCLUDED."pricePerUnit", "totalCost" = EXCLUDED."totalCost", "isFullTank" = EXCLUDED."isFullTank", notes = EXCLUDED.notes, deleted = EXCLUDED.deleted;
        ''');
        final itemsToPush = targetItem != null && targetItem is FuelLog
            ? [targetItem]
            : provider.allFuelLogs;
        for (final item in itemsToPush) {
          await fuelStmt.run([item.id.toString(), userId, item.date, item.odometer, item.fuelAmount, item.pricePerUnit, item.totalCost, item.isFullTank ? 1 : 0, item.notes, item.deleted ? 1 : 0]);
        }
      }

      // Vehicle Config
      if (targetTable == null || targetTable == 'vehicle_configs') {
        final config = targetItem != null && targetItem is VehicleConfig
            ? targetItem
            : provider.vehicleConfig;
        if (config != null) {
          await conn.execute('''
            INSERT INTO vehicle_configs (id, user_id, "initialOdometer", "currentOdometer", "vehicleName", "lastSyncTime", "autoStartOnBoot", deleted) 
            VALUES (\$1, \$2, \$3, \$4, \$5, \$6, \$7, \$8) 
            ON CONFLICT (user_id, id) DO UPDATE SET "initialOdometer" = EXCLUDED."initialOdometer", "currentOdometer" = EXCLUDED."currentOdometer", "vehicleName" = EXCLUDED."vehicleName", "lastSyncTime" = EXCLUDED."lastSyncTime", "autoStartOnBoot" = EXCLUDED."autoStartOnBoot", deleted = EXCLUDED.deleted;
          ''', parameters: [
            'default_vehicle',
            userId,
            config.initialOdometer,
            config.currentOdometer,
            config.vehicleName,
            config.lastSyncTime,
            config.autoStartOnBoot ? 1 : 0,
            config.deleted ? 1 : 0,
          ]);
        }
      }

      // Car Trips
      if (targetTable == null || targetTable == 'car_trips') {
        final tripStmt = await conn.prepare('''
          INSERT INTO car_trips (id, user_id, date, "distanceTravelled", "startOdometer", "endOdometer", "gpsPath", "durationSeconds", status, deleted) 
          VALUES (\$1, \$2, \$3, \$4, \$5, \$6, \$7, \$8, \$9, \$10) 
          ON CONFLICT (user_id, id) DO UPDATE SET date = EXCLUDED.date, "distanceTravelled" = EXCLUDED."distanceTravelled", "startOdometer" = EXCLUDED."startOdometer", "endOdometer" = EXCLUDED."endOdometer", "gpsPath" = EXCLUDED."gpsPath", "durationSeconds" = EXCLUDED."durationSeconds", status = EXCLUDED.status, deleted = EXCLUDED.deleted;
        ''');
        final itemsToPush = targetItem != null && targetItem is CarTrip
            ? [targetItem]
            : provider.allCarTrips;
        for (final item in itemsToPush) {
          await tripStmt.run([
            item.id.toString(),
            userId,
            item.date,
            item.distanceTravelled,
            item.startOdometer,
            item.endOdometer,
            item.gpsPath,
            item.durationSeconds,
            item.status,
            item.deleted ? 1 : 0,
          ]);
        }
      }

    } finally {
      await conn.close();
    }
  }

  static Future<void> pullFromDb(FinanceProvider provider) async {
    if (SyncConfig.useApiGateway) {
      await DbSyncServiceApi.pullFromDb(provider);
      return;
    }
    final userId = provider.currentUserId;
    if (userId == null) return;

    final conn = await _connect();
    try {
      Map<String, List<Map<String, dynamic>>> parsedData = {};

      Future<List<Map<String, dynamic>>> fetch(String table) async {
        final rows = await conn.execute(
          'SELECT * FROM $table WHERE user_id = \$1',
          parameters: [userId],
        );
        return rows.map((r) {
          final m = r.toColumnMap();
          m.remove('user_id');
          m['id'] = int.tryParse(m['id'].toString());
          if (m.containsKey('categoryId')) m['categoryId'] = int.tryParse(m['categoryId'].toString());
          if (m.containsKey('lendBorrowId')) m['lendBorrowId'] = int.tryParse(int.tryParse(m['lendBorrowId'].toString())?.toString() ?? '0');
          return m;
        }).toList();
      }

      parsedData['categories'] = await fetch('categories');
      parsedData['transactions'] = await fetch('transactions');
      parsedData['loans'] = await fetch('loans');
      parsedData['income_config'] = await fetch('income_configs');
      parsedData['lend_borrows'] = await fetch('lend_borrows');
      parsedData['repayments'] = await fetch('repayments');
      parsedData['investments'] = await fetch('investments');
      parsedData['category_budgets'] = await fetch('category_budgets');
      parsedData['od_accounts'] = await fetch('od_accounts');
      parsedData['od_transactions'] = await fetch('od_transactions');
      parsedData['fuel_logs'] = await fetch('fuel_logs');
      parsedData['vehicle_configs'] = await fetch('vehicle_configs');
      parsedData['car_trips'] = await fetch('car_trips');

      await provider.overwriteFromSync(parsedData);

    } finally {
      await conn.close();
    }
  }

  static Future<void> deleteRecord(String table, String keyColumn, String keyValue, String userId) async {
    if (SyncConfig.useApiGateway) {
      await DbSyncServiceApi.deleteRecord(table, keyColumn, keyValue, userId);
      return;
    }
    final conn = await _connect();
    try {
      await conn.execute(
        'UPDATE $table SET deleted = 1 WHERE user_id = \$1 AND $keyColumn = \$2',
        parameters: [userId, keyValue],
      );
      debugPrint('Sync: Soft delete completed for $table where $keyColumn = $keyValue');
    } catch (e) {
      debugPrint('Sync Direct Delete Error: $e');
      rethrow;
    } finally {
      await conn.close();
    }
  }

  static Future<void> clearTable(String table, [String userId = 'user_1']) async {
    if (SyncConfig.useApiGateway) {
      await DbSyncServiceApi.clearTable(table, userId);
      return;
    }
    final conn = await _connect();
    try {
      await conn.execute('DELETE FROM $table WHERE user_id = \$1', parameters: [userId]);
      debugPrint('Sync: Cleared table $table for user $userId');
    } catch (e) {
      debugPrint('Sync Direct Clear Error: $e');
    } finally {
      await conn.close();
    }
  }
}

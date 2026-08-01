import 'dart:convert';
import 'package:http/http.dart' as http;
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
import '../models/contact.dart';
import '../models/product.dart';
import 'sync_config.dart';
import 'device_info_service.dart';

class DbSyncServiceApi {
  static Future<Map<String, dynamic>> _apiQuery(String sql, [List<dynamic>? params]) async {
    final deviceId = await DeviceInfoService.getDeviceId();
    final res = await http.post(
      Uri.parse(SyncConfig.apiGatewayUrl),
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': SyncConfig.apiKey,
        'x-app-name': kIsWeb ? 'web app' : 'mobile app',
        'x-device-id': deviceId,
      },
      body: jsonEncode({
        'query': sql,
        'params': params ?? [],
      }),
    );
    if (res.statusCode != 200) {
      throw Exception('API Gateway status: ${res.statusCode} ${res.body}');
    }
    final data = jsonDecode(res.body);
    if (data['success'] != true) {
      throw Exception('API Gateway query error: ${data['error']}');
    }
    return data;
  }

  static Future<Map<String, dynamic>?> loginUser(String mobile, String pin) async {
    try {
      final data = await _apiQuery(
        'SELECT mobile_number, name FROM users WHERE mobile_number = \$1 AND pin = \$2',
        [mobile, pin],
      );
      final rows = data['rows'] as List;
      if (rows.isEmpty) return null;
      final first = rows.first as Map<String, dynamic>;
      return {
        'mobile_number': first['mobile_number'],
        'name': first['name'],
      };
    } catch (e) {
      debugPrint('Sync API Login Error: $e');
      rethrow;
    }
  }

  static Future<bool> registerUser(String name, String mobile, String pin) async {
    try {
      final data = await _apiQuery(
        'SELECT 1 FROM users WHERE mobile_number = \$1',
        [mobile],
      );
      final rows = data['rows'] as List;
      if (rows.isNotEmpty) return false;

      final now = DateTime.now().millisecondsSinceEpoch;
      final deviceId = await DeviceInfoService.getDeviceId();

      await _apiQuery(
        'INSERT INTO users (name, mobile_number, pin, updated_at, last_updated_by) VALUES (\$1, \$2, \$3, \$4, \$5)',
        [name, mobile, pin, now, deviceId],
      );
      return true;
    } catch (e) {
      debugPrint('Sync API Register Error: $e');
      rethrow;
    }
  }

  static Future<void> pushToDb(FinanceProvider provider, {String? targetTable, dynamic targetItem}) async {
    debugPrint('Sync: Routing Push to API Gateway for targetTable: $targetTable...');
    final userId = provider.currentUserId;
    if (userId == null) return;

    final deviceId = await DeviceInfoService.getDeviceId();
    final now = DateTime.now().millisecondsSinceEpoch;
    
    try {
      final List<Future> futures = [];

      // Categories
      if (targetTable == null || targetTable == 'categories') {
        final itemsToPush = targetItem != null && targetItem is Category
            ? [targetItem]
            : provider.allCategories;
        for (final item in itemsToPush) {
          futures.add(_apiQuery('''
            INSERT INTO categories (id, user_id, name, "plannedAmount", deleted, updated_at, last_updated_by) 
            VALUES (\$1, \$2, \$3, \$4, \$5, \$6, \$7) 
            ON CONFLICT (user_id, id) DO UPDATE SET 
              name = EXCLUDED.name, 
              "plannedAmount" = EXCLUDED."plannedAmount", 
              deleted = EXCLUDED.deleted,
              updated_at = EXCLUDED.updated_at,
              last_updated_by = EXCLUDED.last_updated_by;
          ''', [item.id.toString(), userId, item.name, item.plannedAmount, item.deleted ? 1 : 0, now, deviceId]));
        }
      }

      // Transactions
      if (targetTable == null || targetTable == 'transactions') {
        final itemsToPush = targetItem != null && targetItem is DailyTransaction
            ? [targetItem]
            : provider.allTransactions;
        for (final item in itemsToPush) {
          futures.add(_apiQuery('''
            INSERT INTO transactions (id, user_id, "categoryId", "itemService", cost, "paidAmount", cleared, date, "merchantName", deleted, updated_at, last_updated_by) 
            VALUES (\$1, \$2, \$3, \$4, \$5, \$6, \$7, \$8, \$9, \$10, \$11, \$12) 
            ON CONFLICT (user_id, id) DO UPDATE SET 
              "categoryId" = EXCLUDED."categoryId", 
              "itemService" = EXCLUDED."itemService", 
              cost = EXCLUDED.cost, 
              "paidAmount" = EXCLUDED."paidAmount", 
              cleared = EXCLUDED.cleared, 
              date = EXCLUDED.date, 
              "merchantName" = EXCLUDED."merchantName", 
              deleted = EXCLUDED.deleted,
              updated_at = EXCLUDED.updated_at,
              last_updated_by = EXCLUDED.last_updated_by;
          ''', [item.id.toString(), userId, item.categoryId.toString(), item.itemService, item.cost, item.paidAmount, item.cleared ? 1 : 0, item.date, item.merchantName, item.deleted ? 1 : 0, now, deviceId]));
        }
      }

      // Loans
      if (targetTable == null || targetTable == 'loans') {
        final itemsToPush = targetItem != null && targetItem is Loan
            ? [targetItem]
            : provider.allLoans;
        for (final item in itemsToPush) {
          futures.add(_apiQuery('''
            INSERT INTO loans (id, user_id, lender, "startDate", "endDate", tenure, roi, principal, interest, total, paid, balance, emi, "tenurePending", status, deleted, updated_at, last_updated_by) 
            VALUES (\$1, \$2, \$3, \$4, \$5, \$6, \$7, \$8, \$9, \$10, \$11, \$12, \$13, \$14, \$15, \$16, \$17, \$18) 
            ON CONFLICT (user_id, id) DO UPDATE SET 
              lender = EXCLUDED.lender, 
              "startDate" = EXCLUDED."startDate", 
              "endDate" = EXCLUDED."endDate", 
              tenure = EXCLUDED.tenure, 
              roi = EXCLUDED.roi, 
              principal = EXCLUDED.principal, 
              interest = EXCLUDED.interest, 
              total = EXCLUDED.total, 
              paid = EXCLUDED.paid, 
              balance = EXCLUDED.balance, 
              emi = EXCLUDED.emi, 
              "tenurePending" = EXCLUDED."tenurePending", 
              status = EXCLUDED.status, 
              deleted = EXCLUDED.deleted,
              updated_at = EXCLUDED.updated_at,
              last_updated_by = EXCLUDED.last_updated_by;
          ''', [item.id.toString(), userId, item.lender, item.startDate, item.endDate, item.tenure, item.roi, item.principal, item.interest, item.total, item.paid, item.balance, item.emi, item.tenurePending, item.status, item.deleted ? 1 : 0, now, deviceId]));
        }
      }

      // Income Configs
      if (targetTable == null || targetTable == 'income_configs') {
        final itemsToPush = targetItem != null && targetItem is IncomeConfig
            ? [targetItem]
            : provider.allIncomeConfigs;
        for (final item in itemsToPush) {
          futures.add(_apiQuery('''
            INSERT INTO income_configs (id, user_id, month, year, amount, "isDefault", deleted, updated_at, last_updated_by) 
            VALUES (\$1, \$2, \$3, \$4, \$5, \$6, \$7, \$8, \$9) 
            ON CONFLICT (user_id, id) DO UPDATE SET 
              month = EXCLUDED.month, 
              year = EXCLUDED.year, 
              amount = EXCLUDED.amount, 
              "isDefault" = EXCLUDED."isDefault", 
              deleted = EXCLUDED.deleted,
              updated_at = EXCLUDED.updated_at,
              last_updated_by = EXCLUDED.last_updated_by;
          ''', [item.id.toString(), userId, item.month, item.year, item.amount, item.isDefault ? 1 : 0, item.deleted ? 1 : 0, now, deviceId]));
        }
      }

      // Lend Borrows
      if (targetTable == null || targetTable == 'lend_borrows') {
        final itemsToPush = targetItem != null && targetItem is LendBorrow
            ? [targetItem]
            : provider.allLendBorrows;
        for (final item in itemsToPush) {
          futures.add(_apiQuery('''
            INSERT INTO lend_borrows (id, user_id, name, type, date, tenure, principal, "returnDate", settled, diff, status, deleted, updated_at, last_updated_by) 
            VALUES (\$1, \$2, \$3, \$4, \$5, \$6, \$7, \$8, \$9, \$10, \$11, \$12, \$13, \$14) 
            ON CONFLICT (user_id, id) DO UPDATE SET 
              name = EXCLUDED.name, 
              type = EXCLUDED.type, 
              date = EXCLUDED.date, 
              tenure = EXCLUDED.tenure, 
              principal = EXCLUDED.principal, 
              "returnDate" = EXCLUDED."returnDate", 
              settled = EXCLUDED.settled, 
              diff = EXCLUDED.diff, 
              status = EXCLUDED.status, 
              deleted = EXCLUDED.deleted,
              updated_at = EXCLUDED.updated_at,
              last_updated_by = EXCLUDED.last_updated_by;
          ''', [item.id.toString(), userId, item.name, item.type, item.date, item.tenure, item.principal, item.returnDate, item.settled, item.diff, item.status, item.deleted ? 1 : 0, now, deviceId]));
        }
      }

      // Repayments
      if (targetTable == null || targetTable == 'repayments') {
        final itemsToPush = targetItem != null && targetItem is Repayment
            ? [targetItem]
            : provider.allRepayments;
        for (final item in itemsToPush) {
          futures.add(_apiQuery('''
            INSERT INTO repayments (id, user_id, "lendBorrowId", name, "paymentDate", amount, method, deleted, updated_at, last_updated_by) 
            VALUES (\$1, \$2, \$3, \$4, \$5, \$6, \$7, \$8, \$9, \$10) 
            ON CONFLICT (user_id, id) DO UPDATE SET 
              "lendBorrowId" = EXCLUDED."lendBorrowId", 
              name = EXCLUDED.name, 
              "paymentDate" = EXCLUDED."paymentDate", 
              amount = EXCLUDED.amount, 
              method = EXCLUDED.method, 
              deleted = EXCLUDED.deleted,
              updated_at = EXCLUDED.updated_at,
              last_updated_by = EXCLUDED.last_updated_by;
          ''', [item.id.toString(), userId, item.lendBorrowId.toString(), item.name, item.paymentDate, item.amount, item.method, item.deleted ? 1 : 0, now, deviceId]));
        }
      }

      // Investments
      if (targetTable == null || targetTable == 'investments') {
        final itemsToPush = targetItem != null && targetItem is Investment
            ? [targetItem]
            : provider.allInvestments;
        for (final item in itemsToPush) {
          futures.add(_apiQuery('''
            INSERT INTO investments (id, user_id, name, type, amount, "expectedRoi", "tenureMonths", "startDate", deleted, updated_at, last_updated_by) 
            VALUES (\$1, \$2, \$3, \$4, \$5, \$6, \$7, \$8, \$9, \$10, \$11) 
            ON CONFLICT (user_id, id) DO UPDATE SET 
              name = EXCLUDED.name, 
              type = EXCLUDED.type, 
              amount = EXCLUDED.amount, 
              "expectedRoi" = EXCLUDED."expectedRoi", 
              "tenureMonths" = EXCLUDED."tenureMonths", 
              "startDate" = EXCLUDED."startDate", 
              deleted = EXCLUDED.deleted,
              updated_at = EXCLUDED.updated_at,
              last_updated_by = EXCLUDED.last_updated_by;
          ''', [item.id.toString(), userId, item.name, item.type, item.amount, item.expectedRoi, item.tenureMonths, item.startDate, item.deleted ? 1 : 0, now, deviceId]));
        }
      }

      // Category Budgets
      if (targetTable == null || targetTable == 'category_budgets') {
        final itemsToPush = targetItem != null && targetItem is CategoryBudget
            ? [targetItem]
            : provider.allCategoryBudgets;
        for (final item in itemsToPush) {
          futures.add(_apiQuery('''
            INSERT INTO category_budgets (id, user_id, "categoryId", month, year, amount, deleted, updated_at, last_updated_by) 
            VALUES (\$1, \$2, \$3, \$4, \$5, \$6, \$7, \$8, \$9) 
            ON CONFLICT (user_id, "categoryId", month, year) DO UPDATE SET 
              id = EXCLUDED.id, 
              amount = EXCLUDED.amount, 
              deleted = EXCLUDED.deleted,
              updated_at = EXCLUDED.updated_at,
              last_updated_by = EXCLUDED.last_updated_by;
          ''', [item.id.toString(), userId, item.categoryId.toString(), item.month, item.year, item.amount, item.deleted ? 1 : 0, now, deviceId]));
        }
      }

      // OD Accounts
      if (targetTable == null || targetTable == 'od_accounts') {
        final itemsToPush = targetItem != null && targetItem is OdAccount
            ? [targetItem]
            : provider.allOdAccounts;
        for (final item in itemsToPush) {
          futures.add(_apiQuery('''
            INSERT INTO od_accounts (id, user_id, name, "limit", "interestRate", "billingDay", deleted, updated_at, last_updated_by) 
            VALUES (\$1, \$2, \$3, \$4, \$5, \$6, \$7, \$8, \$9) 
            ON CONFLICT (user_id, id) DO UPDATE SET 
              name = EXCLUDED.name, 
              "limit" = EXCLUDED."limit", 
              "interestRate" = EXCLUDED."interestRate", 
              "billingDay" = EXCLUDED."billingDay", 
              deleted = EXCLUDED.deleted,
              updated_at = EXCLUDED.updated_at,
              last_updated_by = EXCLUDED.last_updated_by;
          ''', [item.id.toString(), userId, item.name, item.limit, item.interestRate, item.billingDay, item.deleted ? 1 : 0, now, deviceId]));
        }
      }

      // OD Transactions
      if (targetTable == null || targetTable == 'od_transactions') {
        final itemsToPush = targetItem != null && targetItem is OdTransaction
            ? [targetItem]
            : provider.allOdTransactions;
        for (final item in itemsToPush) {
          futures.add(_apiQuery('''
            INSERT INTO od_transactions (id, user_id, "odAccountId", amount, type, date, deleted, updated_at, last_updated_by) 
            VALUES (\$1, \$2, \$3, \$4, \$5, \$6, \$7, \$8, \$9) 
            ON CONFLICT (user_id, id) DO UPDATE SET 
              "odAccountId" = EXCLUDED."odAccountId", 
              amount = EXCLUDED.amount, 
              type = EXCLUDED.type, 
              date = EXCLUDED.date, 
              deleted = EXCLUDED.deleted,
              updated_at = EXCLUDED.updated_at,
              last_updated_by = EXCLUDED.last_updated_by;
          ''', [item.id.toString(), userId, item.odAccountId.toString(), item.amount, item.type, item.date, item.deleted ? 1 : 0, now, deviceId]));
        }
      }

      // Fuel Logs
      if (targetTable == null || targetTable == 'fuel_logs') {
        final itemsToPush = targetItem != null && targetItem is FuelLog
            ? [targetItem]
            : provider.allFuelLogs;
        for (final item in itemsToPush) {
          futures.add(_apiQuery('''
            INSERT INTO fuel_logs (id, user_id, date, odometer, "fuelAmount", "pricePerUnit", "totalCost", "isFullTank", notes, deleted, updated_at, last_updated_by) 
            VALUES (\$1, \$2, \$3, \$4, \$5, \$6, \$7, \$8, \$9, \$10, \$11, \$12) 
            ON CONFLICT (user_id, id) DO UPDATE SET 
              date = EXCLUDED.date, 
              odometer = EXCLUDED.odometer, 
              "fuelAmount" = EXCLUDED."fuelAmount", 
              "pricePerUnit" = EXCLUDED."pricePerUnit", 
              "totalCost" = EXCLUDED."totalCost", 
              "isFullTank" = EXCLUDED."isFullTank", 
              notes = EXCLUDED.notes, 
              deleted = EXCLUDED.deleted,
              updated_at = EXCLUDED.updated_at,
              last_updated_by = EXCLUDED.last_updated_by;
          ''', [item.id.toString(), userId, item.date, item.odometer, item.fuelAmount, item.pricePerUnit, item.totalCost, item.isFullTank ? 1 : 0, item.notes, item.deleted ? 1 : 0, now, deviceId]));
        }
      }

      // Vehicle Config
      if (targetTable == null || targetTable == 'vehicle_configs') {
        final config = targetItem != null && targetItem is VehicleConfig
            ? targetItem
            : provider.vehicleConfig;
        if (config != null) {
          futures.add(_apiQuery('''
            INSERT INTO vehicle_configs (id, user_id, "initialOdometer", "currentOdometer", "vehicleName", "lastSyncTime", "autoStartOnBoot", deleted, updated_at, last_updated_by) 
            VALUES (\$1, \$2, \$3, \$4, \$5, \$6, \$7, \$8, \$9, \$10) 
            ON CONFLICT (user_id, id) DO UPDATE SET 
              "initialOdometer" = EXCLUDED."initialOdometer", 
              "currentOdometer" = EXCLUDED."currentOdometer", 
              "vehicleName" = EXCLUDED."vehicleName", 
              "lastSyncTime" = EXCLUDED."lastSyncTime", 
              "autoStartOnBoot" = EXCLUDED."autoStartOnBoot", 
              deleted = EXCLUDED.deleted,
              updated_at = EXCLUDED.updated_at,
              last_updated_by = EXCLUDED.last_updated_by;
          ''', ['default_vehicle', userId, config.initialOdometer, config.currentOdometer, config.vehicleName, config.lastSyncTime, config.autoStartOnBoot ? 1 : 0, config.deleted ? 1 : 0, now, deviceId]));
        }
      }

      // Car Trips
      if (targetTable == null || targetTable == 'car_trips') {
        final itemsToPush = targetItem != null && targetItem is CarTrip
            ? [targetItem]
            : provider.allCarTrips;
        for (final item in itemsToPush) {
          futures.add(_apiQuery('''
            INSERT INTO car_trips (id, user_id, date, "distanceTravelled", "startOdometer", "endOdometer", "gpsPath", "durationSeconds", status, deleted, updated_at, last_updated_by) 
            VALUES (\$1, \$2, \$3, \$4, \$5, \$6, \$7, \$8, \$9, \$10, \$11, \$12) 
            ON CONFLICT (user_id, id) DO UPDATE SET 
              date = EXCLUDED.date, 
              "distanceTravelled" = EXCLUDED."distanceTravelled", 
              "startOdometer" = EXCLUDED."startOdometer", 
              "endOdometer" = EXCLUDED."endOdometer", 
              "gpsPath" = EXCLUDED."gpsPath", 
              "durationSeconds" = EXCLUDED."durationSeconds", 
              status = EXCLUDED.status, 
              deleted = EXCLUDED.deleted,
              updated_at = EXCLUDED.updated_at,
              last_updated_by = EXCLUDED.last_updated_by;
          ''', [item.id.toString(), userId, item.date, item.distanceTravelled, item.startOdometer, item.endOdometer, item.gpsPath, item.durationSeconds, item.status, item.deleted ? 1 : 0, now, deviceId]));
        }
      }

      // Wallet Contacts
      if (targetTable == null || targetTable == 'wallet_contacts') {
        final itemsToPush = targetItem != null && targetItem is Contact
            ? [targetItem]
            : provider.contacts;
        for (final item in itemsToPush) {
          futures.add(_apiQuery('''
            INSERT INTO wallet_contacts (id, user_id, name, mobile, place, occupation, "businessName", "transactionNotification", "notificationMethod", active, deleted, updated_at, last_updated_by) 
            VALUES (\$1, \$2, \$3, \$4, \$5, \$6, \$7, \$8, \$9, \$10, \$11, \$12, \$13) 
            ON CONFLICT (user_id, id) DO UPDATE SET 
              name = EXCLUDED.name, 
              mobile = EXCLUDED.mobile, 
              place = EXCLUDED.place, 
              occupation = EXCLUDED.occupation, 
              "businessName" = EXCLUDED."businessName", 
              "transactionNotification" = EXCLUDED."transactionNotification", 
              "notificationMethod" = EXCLUDED."notificationMethod", 
              active = EXCLUDED.active, 
              deleted = EXCLUDED.deleted,
              updated_at = EXCLUDED.updated_at,
              last_updated_by = EXCLUDED.last_updated_by;
          ''', [item.id.toString(), userId, item.name, item.mobile, item.place, item.occupation, item.businessName, item.transactionNotification ? 1 : 0, item.notificationMethod, item.active ? 1 : 0, item.deleted ? 1 : 0, now, deviceId]));
        }
      }

      // Wallet Products
      if (targetTable == null || targetTable == 'wallet_products') {
        final itemsToPush = targetItem != null && targetItem is Product
            ? [targetItem]
            : provider.products;
        for (final item in itemsToPush) {
          futures.add(_apiQuery('''
            INSERT INTO wallet_products (id, user_id, "productName", "localName", category, "referenceLink", "appName", "priceDate", "currentPrice", "oldPrice", unit, quantity, "description", active, deleted, updated_at, last_updated_by) 
            VALUES (\$1, \$2, \$3, \$4, \$5, \$6, \$7, \$8, \$9, \$10, \$11, \$12, \$13, \$14, \$15, \$16, \$17) 
            ON CONFLICT (user_id, id) DO UPDATE SET 
              "productName" = EXCLUDED."productName", 
              "localName" = EXCLUDED."localName", 
              category = EXCLUDED.category, 
              "referenceLink" = EXCLUDED."referenceLink", 
              "appName" = EXCLUDED."appName", 
              "priceDate" = EXCLUDED."priceDate", 
              "currentPrice" = EXCLUDED."currentPrice", 
              "oldPrice" = EXCLUDED."oldPrice", 
              unit = EXCLUDED.unit, 
              quantity = EXCLUDED.quantity, 
              "description" = EXCLUDED."description",
              active = EXCLUDED.active, 
              deleted = EXCLUDED.deleted,
              updated_at = EXCLUDED.updated_at,
              last_updated_by = EXCLUDED.last_updated_by;
          ''', [item.id.toString(), userId, item.productName, item.localName, item.category, item.referenceLink, item.appName, item.priceDate, item.currentPrice, item.oldPrice, item.unit, item.quantity, item.description, item.active ? 1 : 0, item.deleted ? 1 : 0, now, deviceId]));
        }
      }

      await Future.wait(futures);
      debugPrint('Sync: Push to mWallet completed successfully.');
    } catch (e) {
      debugPrint('Sync API Push Error: $e');
    }
  }

  static Future<void> pullFromDb(FinanceProvider provider) async {
    debugPrint('Sync: Routing Pull from mWallet API Gateway...');
    final userId = provider.currentUserId;
    if (userId == null) return;

    try {
      Map<String, List<Map<String, dynamic>>> parsedData = {};

      Future<List<Map<String, dynamic>>> fetch(String table) async {
        final data = await _apiQuery(
          'SELECT * FROM $table WHERE user_id = \$1',
          [userId],
        );
        final rows = data['rows'] as List;
        return rows.map((r) {
          final m = Map<String, dynamic>.from(r);
          m.remove('user_id');
          if (m.containsKey('id') && m['id'] != null) {
            final rawId = m['id'].toString();
            m['id'] = int.tryParse(rawId) ?? rawId.hashCode.abs();
          }
          if (m.containsKey('categoryId') && m['categoryId'] != null) {
            final rawCatId = m['categoryId'].toString();
            m['categoryId'] = int.tryParse(rawCatId) ?? rawCatId.hashCode.abs();
          }
          if (m.containsKey('lendBorrowId') && m['lendBorrowId'] != null) {
            final rawLbId = m['lendBorrowId'].toString();
            m['lendBorrowId'] = int.tryParse(rawLbId) ?? rawLbId.hashCode.abs();
          }
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
      parsedData['wallet_contacts'] = await fetch('wallet_contacts');
      parsedData['wallet_products'] = await fetch('wallet_products');

      await provider.overwriteFromSync(parsedData);
      debugPrint('Sync: Pull from mWallet completed successfully.');
    } catch (e) {
      debugPrint('Sync API Pull Error: $e');
    }
  }

  static Future<void> deleteRecord(String table, String keyColumn, String keyValue, String userId) async {
    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      final deviceId = await DeviceInfoService.getDeviceId();
      await _apiQuery(
        'UPDATE $table SET deleted = 1, updated_at = \$3, last_updated_by = \$4 WHERE user_id = \$1 AND $keyColumn = \$2',
        [userId, keyValue, now, deviceId],
      );
      debugPrint('Sync: Soft delete completed for $table where $keyColumn = $keyValue via mWallet API.');
    } catch (e) {
      debugPrint('Sync API Delete Error: $e');
      rethrow;
    }
  }
}

import '../providers/finance_provider.dart';
import 'db_sync_service_api.dart';

class DbSyncService {
  static Future<Map<String, dynamic>?> loginUser(String mobile, String pin) async {
    return DbSyncServiceApi.loginUser(mobile, pin);
  }

  static Future<bool> registerUser(String name, String mobile, String pin) async {
    return DbSyncServiceApi.registerUser(name, mobile, pin);
  }

  static Future<void> pushToDb(FinanceProvider provider, {String? targetTable, dynamic targetItem}) async {
    await DbSyncServiceApi.pushToDb(provider, targetTable: targetTable, targetItem: targetItem);
  }

  static Future<void> pullFromDb(FinanceProvider provider) async {
    await DbSyncServiceApi.pullFromDb(provider);
  }

  static Future<void> deleteRecord(String table, String keyColumn, String keyValue, String userId) async {
    await DbSyncServiceApi.deleteRecord(table, keyColumn, keyValue, userId);
  }

  static Future<void> clearTable(String table) async {
    await DbSyncServiceApi.clearTable(table);
  }
}

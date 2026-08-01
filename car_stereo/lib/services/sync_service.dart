import 'dart:convert';
import 'package:http/http.dart' as http;
import '../database/database_helper.dart';

class SyncService {
  static const String apiGatewayUrl = 'https://db.mhservice.co.in/api/db/my_wallet/query';
  static const String apiKey = 'hs_live_U74MhX82o5lOUmzAmXxKsbX3fxNKImkl';

  static Future<Map<String, dynamic>> _apiQuery(String sql, [List<dynamic>? params]) async {
    try {
      final res = await http.post(
        Uri.parse(apiGatewayUrl),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': apiKey,
          'x-app-name': 'car stereo app',
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
    } catch (e) {
      throw Exception('Network / Gateway connection failed: $e');
    }
  }

  static Future<Map<String, String>?> loginUser(String mobile, String pin) async {
    try {
      final data = await _apiQuery(
        'SELECT mobile_number, name FROM users WHERE mobile_number = \$1 AND pin = \$2',
        [mobile, pin],
      );
      final rows = data['rows'] as List;
      if (rows.isEmpty) return null;
      
      final first = rows.first as Map<String, dynamic>;
      return {
        'mobile_number': first['mobile_number'].toString(),
        'name': first['name'].toString(),
      };
    } catch (e) {
      throw Exception('Login API Error: $e');
    }
  }

  static Future<int> syncTripsToServer() async {
    final dbHelper = DatabaseHelper.instance;
    final userId = await dbHelper.getConfig('user_id');
    if (userId.isEmpty) return 0;

    final trips = await dbHelper.getCompletedTrips();
    if (trips.isEmpty) return 0;

    int syncedCount = 0;
    for (final trip in trips) {
      try {
        final id = trip['id'];
        final date = trip['date'];
        final distance = (trip['distanceTravelled'] as num?)?.toDouble() ?? 0.0;
        final startOdo = (trip['startOdometer'] as num?)?.toDouble() ?? 0.0;
        final endOdo = (trip['endOdometer'] as num?)?.toDouble() ?? 0.0;
        final gpsPath = trip['gpsPath'] ?? '[]';
        final duration = (trip['durationSeconds'] as num?)?.toInt() ?? 0;
        final status = trip['status'] ?? 'Completed';

        // Upsert to remote database
        await _apiQuery('''
          INSERT INTO car_trips (id, user_id, date, "distanceTravelled", "startOdometer", "endOdometer", "gpsPath", "durationSeconds", status) 
          VALUES (\$1, \$2, \$3, \$4, \$5, \$6, \$7, \$8, \$9) 
          ON CONFLICT (user_id, id) DO UPDATE SET 
            date = EXCLUDED.date, 
            "distanceTravelled" = EXCLUDED."distanceTravelled", 
            "startOdometer" = EXCLUDED."startOdometer", 
            "endOdometer" = EXCLUDED."endOdometer", 
            "gpsPath" = EXCLUDED."gpsPath", 
            "durationSeconds" = EXCLUDED."durationSeconds", 
            status = EXCLUDED.status;
        ''', [
          id,
          userId,
          date,
          distance,
          startOdo,
          endOdo,
          gpsPath,
          duration,
          status
        ]);

        syncedCount++;
      } catch (e) {
        // Log individual trip sync error and continue
        print('Error syncing trip ${trip['id']}: $e');
      }
    }
    return syncedCount;
  }

  static Future<void> syncOdometerToServer() async {
    final dbHelper = DatabaseHelper.instance;
    final userId = await dbHelper.getConfig('user_id');
    if (userId.isEmpty) return;

    final currentOdoStr = await dbHelper.getConfig('currentOdometer', defaultValue: '0.0');
    final currentOdo = double.tryParse(currentOdoStr) ?? 0.0;

    try {
      // Upsert vehicle config on server
      await _apiQuery('''
        INSERT INTO vehicle_configs (id, user_id, "initialOdometer", "currentOdometer", "vehicleName", "lastSyncTime", "autoStartOnBoot")
        VALUES (\$1, \$2, \$3, \$4, \$5, \$6, \$7)
        ON CONFLICT (user_id, id) DO UPDATE SET 
          "currentOdometer" = EXCLUDED."currentOdometer",
          "lastSyncTime" = EXCLUDED."lastSyncTime";
      ''', [
        'car_stereo_vehicle',
        userId,
        0.0,
        currentOdo,
        'Car Stereo Head Unit',
        DateTime.now().toIso8601String(),
        1
      ]);
    } catch (e) {
      print('Error syncing odometer: $e');
    }
  }
}

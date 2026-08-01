import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('car_stereo.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS car_trips (
        id TEXT PRIMARY KEY,
        user_id TEXT,
        date TEXT,
        distanceTravelled REAL,
        startOdometer REAL,
        endOdometer REAL,
        gpsPath TEXT,
        durationSeconds INTEGER,
        status TEXT,
        startLocation TEXT,
        endLocation TEXT,
        startTime TEXT,
        endTime TEXT,
        fuelUsed REAL,
        mileage REAL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS config (
        key TEXT PRIMARY KEY,
        value TEXT
      )
    ''');

    await db.insert('config', {'key': 'currentOdometer', 'value': '0.0'}, conflictAlgorithm: ConflictAlgorithm.ignore);
    await db.insert('config', {'key': 'mileage', 'value': '15.0'}, conflictAlgorithm: ConflictAlgorithm.ignore);
    await db.insert('config', {'key': 'user_id', 'value': ''}, conflictAlgorithm: ConflictAlgorithm.ignore);
    await db.insert('config', {'key': 'user_name', 'value': ''}, conflictAlgorithm: ConflictAlgorithm.ignore);
    await db.insert('config', {'key': 'is_authenticated', 'value': '0'}, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  // Config Methods
  Future<String> getConfig(String key, {String defaultValue = ''}) async {
    final db = await instance.database;
    final maps = await db.query(
      'config',
      columns: ['value'],
      where: 'key = ?',
      whereArgs: [key],
    );

    if (maps.isNotEmpty) {
      return maps.first['value'] as String? ?? defaultValue;
    }
    return defaultValue;
  }

  Future<void> setConfig(String key, String value) async {
    final db = await instance.database;
    await db.insert(
      'config',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Trip Methods
  Future<List<Map<String, dynamic>>> getCompletedTrips() async {
    final db = await instance.database;
    return await db.query(
      'car_trips',
      where: "status = 'Completed'",
      orderBy: 'date DESC',
    );
  }

  Future<Map<String, dynamic>?> getActiveTrip() async {
    final db = await instance.database;
    final maps = await db.query(
      'car_trips',
      where: "status = 'Active'",
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return maps.first;
    }
    return null;
  }

  Future<void> deleteTrip(String id) async {
    final db = await instance.database;
    await db.delete(
      'car_trips',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> clearAllTrips() async {
    final db = await instance.database;
    await db.delete('car_trips');
  }
}

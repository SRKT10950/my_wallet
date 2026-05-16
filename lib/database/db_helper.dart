import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

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
      version: 1,
      onCreate: _createDB,
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
  plannedAmount $realType
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
  status $textType
  )
''');

    await db.execute('''
CREATE TABLE income_config (
  id $idType,
  month INTEGER NOT NULL,
  year INTEGER NOT NULL,
  amount $realType,
  isDefault $boolType
  )
''');
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}

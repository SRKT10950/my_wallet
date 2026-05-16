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
      settings: ConnectionSettings(
        sslMode: SslMode.disable,
        connectTimeout: const Duration(seconds: 10),
      ),
    );
  }

  static Future<void> _createTablesIfNotExist(Connection conn) async {
    await conn.execute('''
      CREATE TABLE IF NOT EXISTS users (
        mobile_number VARCHAR(20) PRIMARY KEY,
        name VARCHAR(100) NOT NULL,
        pin VARCHAR(20) NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    ''');

    await conn.execute('''
      CREATE TABLE IF NOT EXISTS categories (
        id VARCHAR(50) NOT NULL,
        user_id VARCHAR(20) NOT NULL,
        name VARCHAR(100) NOT NULL,
        "plannedAmount" DOUBLE PRECISION NOT NULL,
        PRIMARY KEY (user_id, id)
      );
    ''');

    await conn.execute('''
      CREATE TABLE IF NOT EXISTS transactions (
        id VARCHAR(50) NOT NULL,
        user_id VARCHAR(20) NOT NULL,
        "categoryId" VARCHAR(50) NOT NULL,
        "itemService" TEXT NOT NULL,
        cost DOUBLE PRECISION NOT NULL,
        "paidAmount" DOUBLE PRECISION NOT NULL,
        cleared INTEGER NOT NULL,
        date VARCHAR(50) NOT NULL,
        PRIMARY KEY (user_id, id)
      );
    ''');

    await conn.execute('''
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
        PRIMARY KEY (user_id, id)
      );
    ''');

    await conn.execute('''
      CREATE TABLE IF NOT EXISTS income_configs (
        id VARCHAR(50) NOT NULL,
        user_id VARCHAR(20) NOT NULL,
        month INTEGER NOT NULL,
        year INTEGER NOT NULL,
        amount DOUBLE PRECISION NOT NULL,
        "isDefault" INTEGER NOT NULL,
        PRIMARY KEY (user_id, id)
      );
    ''');

    await conn.execute('''
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
        PRIMARY KEY (user_id, id)
      );
    ''');

    await conn.execute('''
      CREATE TABLE IF NOT EXISTS repayments (
        id VARCHAR(50) NOT NULL,
        user_id VARCHAR(20) NOT NULL,
        "lendBorrowId" VARCHAR(50) NOT NULL,
        name VARCHAR(100) NOT NULL,
        "paymentDate" VARCHAR(50) NOT NULL,
        amount DOUBLE PRECISION NOT NULL,
        method VARCHAR(50) NOT NULL,
        PRIMARY KEY (user_id, id)
      );
    ''');

    await conn.execute('''
      CREATE TABLE IF NOT EXISTS investments (
        id VARCHAR(50) NOT NULL,
        user_id VARCHAR(20) NOT NULL,
        name VARCHAR(100) NOT NULL,
        type VARCHAR(20) NOT NULL,
        amount DOUBLE PRECISION NOT NULL,
        "expectedRoi" DOUBLE PRECISION NOT NULL,
        "tenureMonths" INTEGER NOT NULL,
        "startDate" VARCHAR(50) NOT NULL,
        PRIMARY KEY (user_id, id)
      );
    ''');

    await conn.execute('''
      CREATE TABLE IF NOT EXISTS category_budgets (
        id VARCHAR(50) NOT NULL,
        user_id VARCHAR(20) NOT NULL,
        "categoryId" VARCHAR(50) NOT NULL,
        month INTEGER NOT NULL,
        year INTEGER NOT NULL,
        amount DOUBLE PRECISION NOT NULL,
        PRIMARY KEY (user_id, "categoryId", month, year)
      );
    ''');

    await conn.execute('''
      CREATE TABLE IF NOT EXISTS od_accounts (
        id VARCHAR(50) NOT NULL,
        user_id VARCHAR(20) NOT NULL,
        name VARCHAR(100) NOT NULL,
        "limit" DOUBLE PRECISION NOT NULL,
        "interestRate" DOUBLE PRECISION NOT NULL,
        "billingDay" INTEGER NOT NULL,
        PRIMARY KEY (user_id, id)
      );
    ''');

    await conn.execute('''
      CREATE TABLE IF NOT EXISTS od_transactions (
        id VARCHAR(50) NOT NULL,
        user_id VARCHAR(20) NOT NULL,
        "odAccountId" VARCHAR(50) NOT NULL,
        amount DOUBLE PRECISION NOT NULL,
        type VARCHAR(20) NOT NULL,
        date VARCHAR(50) NOT NULL,
        PRIMARY KEY (user_id, id)
      );
    ''');
  }

  static Future<Map<String, dynamic>?> loginUser(String mobile, String pin) async {
    final conn = await _connect();
    try {
      await _createTablesIfNotExist(conn);
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
    final conn = await _connect();
    try {
      await _createTablesIfNotExist(conn);
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

  static Future<void> pushToDb(FinanceProvider provider) async {
    final userId = provider.currentUserId;
    if (userId == null) return;

    final conn = await _connect();
    try {
      await _createTablesIfNotExist(conn);

      // Categories
      final catStmt = await conn.prepare('''
        INSERT INTO categories (id, user_id, name, "plannedAmount") VALUES (\$1, \$2, \$3, \$4) 
        ON CONFLICT (user_id, id) DO UPDATE SET name = EXCLUDED.name, "plannedAmount" = EXCLUDED."plannedAmount";
      ''');
      for (final item in provider.categories) {
        await catStmt.run([item.id.toString(), userId, item.name, item.plannedAmount]);
      }

      // Transactions
      final txStmt = await conn.prepare('''
        INSERT INTO transactions (id, user_id, "categoryId", "itemService", cost, "paidAmount", cleared, date) VALUES (\$1, \$2, \$3, \$4, \$5, \$6, \$7, \$8) 
        ON CONFLICT (user_id, id) DO UPDATE SET cost = EXCLUDED.cost, "paidAmount" = EXCLUDED."paidAmount", cleared = EXCLUDED.cleared;
      ''');
      for (final item in provider.transactions) {
        await txStmt.run([item.id.toString(), userId, item.categoryId.toString(), item.itemService, item.cost, item.paidAmount, item.cleared ? 1 : 0, item.date]);
      }

      // Loans
      final loanStmt = await conn.prepare('''
        INSERT INTO loans (id, user_id, lender, "startDate", "endDate", tenure, roi, principal, interest, total, paid, balance, emi, "tenurePending", status) 
        VALUES (\$1, \$2, \$3, \$4, \$5, \$6, \$7, \$8, \$9, \$10, \$11, \$12, \$13, \$14, \$15) 
        ON CONFLICT (user_id, id) DO UPDATE SET paid = EXCLUDED.paid, balance = EXCLUDED.balance, status = EXCLUDED.status;
      ''');
      for (final item in provider.loans) {
        await loanStmt.run([item.id.toString(), userId, item.lender, item.startDate, item.endDate, item.tenure, item.roi, item.principal, item.interest, item.total, item.paid, item.balance, item.emi, item.tenurePending, item.status]);
      }

      // Income Configs
      final incStmt = await conn.prepare('''
        INSERT INTO income_configs (id, user_id, month, year, amount, "isDefault") VALUES (\$1, \$2, \$3, \$4, \$5, \$6) 
        ON CONFLICT (user_id, id) DO UPDATE SET amount = EXCLUDED.amount, "isDefault" = EXCLUDED."isDefault";
      ''');
      for (final item in provider.incomeConfigs) {
        await incStmt.run([item.id.toString(), userId, item.month, item.year, item.amount, item.isDefault ? 1 : 0]);
      }

      // Lend Borrows
      final lbStmt = await conn.prepare('''
        INSERT INTO lend_borrows (id, user_id, name, type, date, tenure, principal, "returnDate", settled, diff, status) 
        VALUES (\$1, \$2, \$3, \$4, \$5, \$6, \$7, \$8, \$9, \$10, \$11) 
        ON CONFLICT (user_id, id) DO UPDATE SET settled = EXCLUDED.settled, status = EXCLUDED.status;
      ''');
      for (final item in provider.lendBorrows) {
        await lbStmt.run([item.id.toString(), userId, item.name, item.type, item.date, item.tenure, item.principal, item.returnDate, item.settled, item.diff, item.status]);
      }

      // Repayments
      final repStmt = await conn.prepare('''
        INSERT INTO repayments (id, user_id, "lendBorrowId", name, "paymentDate", amount, method) VALUES (\$1, \$2, \$3, \$4, \$5, \$6, \$7) 
        ON CONFLICT (user_id, id) DO UPDATE SET amount = EXCLUDED.amount, "paymentDate" = EXCLUDED."paymentDate";
      ''');
      for (final item in provider.repayments) {
        await repStmt.run([item.id.toString(), userId, item.lendBorrowId.toString(), item.name, item.paymentDate, item.amount, item.method]);
      }

      // Investments
      final invStmt = await conn.prepare('''
        INSERT INTO investments (id, user_id, name, type, amount, "expectedRoi", "tenureMonths", "startDate") VALUES (\$1, \$2, \$3, \$4, \$5, \$6, \$7, \$8) 
        ON CONFLICT (user_id, id) DO UPDATE SET amount = EXCLUDED.amount, "expectedRoi" = EXCLUDED."expectedRoi";
      ''');
      for (final item in provider.investments) {
        await invStmt.run([item.id.toString(), userId, item.name, item.type, item.amount, item.expectedRoi, item.tenureMonths, item.startDate]);
      }

      // Category Budgets
      final cbStmt = await conn.prepare('''
        INSERT INTO category_budgets (id, user_id, "categoryId", month, year, amount) 
        VALUES (\$1, \$2, \$3, \$4, \$5, \$6) 
        ON CONFLICT (user_id, "categoryId", month, year) DO UPDATE SET amount = EXCLUDED.amount;
      ''');
      for (final item in provider.categoryBudgets) {
        await cbStmt.run([item.id.toString(), userId, item.categoryId.toString(), item.month, item.year, item.amount]);
      }

      // OD Accounts
      final odStmt = await conn.prepare('''
        INSERT INTO od_accounts (id, user_id, name, "limit", "interestRate", "billingDay") 
        VALUES (\$1, \$2, \$3, \$4, \$5, \$6) 
        ON CONFLICT (user_id, id) DO UPDATE SET name = EXCLUDED.name, "limit" = EXCLUDED."limit", "interestRate" = EXCLUDED."interestRate";
      ''');
      for (final item in provider.odAccounts) {
        await odStmt.run([item.id.toString(), userId, item.name, item.limit, item.interestRate, item.billingDay]);
      }

      // OD Transactions
      final odtxStmt = await conn.prepare('''
        INSERT INTO od_transactions (id, user_id, "odAccountId", amount, type, date) 
        VALUES (\$1, \$2, \$3, \$4, \$5, \$6) 
        ON CONFLICT (user_id, id) DO UPDATE SET amount = EXCLUDED.amount, type = EXCLUDED.type, date = EXCLUDED.date;
      ''');
      for (final item in provider.odTransactions) {
        await odtxStmt.run([item.id.toString(), userId, item.odAccountId.toString(), item.amount, item.type, item.date]);
      }

    } finally {
      await conn.close();
    }
  }

  static Future<void> pullFromDb(FinanceProvider provider) async {
    final userId = provider.currentUserId;
    if (userId == null) return;

    final conn = await _connect();
    try {
      await _createTablesIfNotExist(conn);

      Map<String, List<Map<String, dynamic>>> parsedData = {};

      Future<List<Map<String, dynamic>>> fetch(String table) async {
        final rows = await conn.execute(
          'SELECT * FROM ' + table + ' WHERE user_id = \$1',
          parameters: [userId],
        );
        return rows.map((r) {
          final m = r.toColumnMap();
          m.remove('user_id');
          m['id'] = int.tryParse(m['id'].toString());
          if (m.containsKey('categoryId')) m['categoryId'] = int.tryParse(m['categoryId'].toString());
          if (m.containsKey('lendBorrowId')) m['lendBorrowId'] = int.tryParse(int.tryParse(m['lendBorrowId'].toString())?.toString() ?? '0');
          // No special parsing for dates as they are stored as Strings in models
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

      await provider.overwriteFromSync(parsedData);

    } finally {
      await conn.close();
    }
  }
}

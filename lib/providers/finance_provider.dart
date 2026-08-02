import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' hide Category;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/category.dart';
import '../models/transaction.dart';
import '../models/transaction_item.dart';
import '../models/loan.dart';
import '../models/income_config.dart';
import '../models/lend_borrow.dart';
import '../models/investment.dart';
import '../models/category_budget.dart';
import '../models/od_account.dart';
import '../models/wallet_account.dart';
import '../models/scheduled_payment.dart';
import '../models/goal.dart';
import '../models/asset.dart';
import '../models/split_bill.dart';
import '../models/fuel_log.dart';
import '../models/vehicle_config.dart';
import '../models/car_trip.dart';
import '../models/contact.dart';
import '../models/product.dart';
import '../services/product_price_sync_service.dart';
import '../utils/string_utils.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import '../services/db_sync_service.dart';
import '../services/sync_config.dart';
import '../database/db_helper.dart';
import 'dart:math';

class FinanceProvider with ChangeNotifier {
  String? _currentUserId;
  String? _currentUserName;
  String? get currentUserId => _currentUserId;
  String? get currentUserName => _currentUserName;
  bool get isAuthenticated => _currentUserId != null;
  bool _isOfflineLogin = false;
  bool get isOfflineLogin => _isOfflineLogin;

  List<Category> _categories = [];
  List<DailyTransaction> _transactions = [];
  List<TransactionItem> _transactionItems = [];
  List<Loan> _loans = [];
  List<IncomeConfig> _incomeConfigs = [];
  List<LendBorrow> _lendBorrows = [];
  List<Repayment> _repayments = [];
  List<Investment> _investments = [];
  List<CategoryBudget> _categoryBudgets = [];
  List<OdAccount> _odAccounts = [];
  List<OdTransaction> _odTransactions = [];
  List<WalletAccount> _accounts = [];
  List<ScheduledPayment> _scheduledPayments = [];
  List<Goal> _goals = [];
  List<Asset> _assets = [];
  List<SplitBill> _splitBills = [];
  List<String> _friends = [];
  List<FuelLog> _fuelLogs = [];
  VehicleConfig? _vehicleConfig;
  List<CarTrip> _carTrips = [];
  List<Contact> _contacts = [];
  List<Product> _products = [];
  bool _isTrackingTrip = false;
  double _liveTripDistance = 0.0;
  double _liveSpeed = 0.0;
  StreamSubscription<Position>? _gpsSubscription;
  List<List<double>> _liveTripPath = [];
  DateTime? _tripStartTime;
  double _tripStartOdometer = 0.0;
  bool _isTripActive = false;
  DateTime? _lastMovementTime;
  Timer? _inactivityTimer;
  double _monitoringDistanceAccumulated = 0.0;
  dynamic _wifiSyncServer; // dynamic to avoid dart:io imports breaking kIsWeb compiling if web is built, though we only build apk, dynamic is safer
  String? _localIpAddress;
  String _defaultCurrency = '₹';

  List<Category> get categories => _categories.where((c) => !c.deleted).toList();
  List<DailyTransaction> get transactions => _transactions.where((t) => !t.deleted).toList();
  List<Loan> get loans => _loans.where((l) => !l.deleted).toList();
  List<IncomeConfig> get incomeConfigs => _incomeConfigs.where((i) => !i.deleted).toList();
  List<LendBorrow> get lendBorrows => _lendBorrows.where((lb) => !lb.deleted).toList();
  List<Repayment> get repayments => _repayments.where((r) => !r.deleted).toList();
  List<Investment> get investments => _investments.where((i) => !i.deleted).toList();
  List<CategoryBudget> get categoryBudgets => _categoryBudgets.where((cb) => !cb.deleted).toList();
  List<OdAccount> get odAccounts => _odAccounts.where((od) => !od.deleted).toList();
  List<OdTransaction> get odTransactions => _odTransactions.where((odtx) => !odtx.deleted).toList();
  List<WalletAccount> get accounts => _accounts.where((a) => !a.deleted).toList();
  List<ScheduledPayment> get scheduledPayments => _scheduledPayments.where((sp) => !sp.deleted).toList();
  List<Goal> get goals => _goals.where((g) => !g.deleted).toList();
  List<Asset> get assets => _assets.where((a) => !a.deleted).toList();
  List<SplitBill> get splitBills => _splitBills.where((sb) => !sb.deleted).toList();
  List<String> get friends => _friends;
  List<FuelLog> get fuelLogs => _fuelLogs.where((fl) => !fl.deleted).toList();
  VehicleConfig? get vehicleConfig => _vehicleConfig;
  List<CarTrip> get carTrips => _carTrips.where((ct) => !ct.deleted).toList();
  List<Contact> get contacts => _contacts.where((c) => !c.deleted).toList();
  List<Contact> get activeContacts => contacts.where((c) => c.active).toList();
  List<Contact> get allContacts => _contacts;

  List<Product> get products => _products.where((p) => !p.deleted).toList();
  List<Product> get activeProducts => _products.where((p) => p.active && !p.deleted).toList();
  List<Product> get allProducts => _products;

  List<Category> get allCategories => _categories;
  List<DailyTransaction> get allTransactions => _transactions;
  List<Loan> get allLoans => _loans;
  List<IncomeConfig> get allIncomeConfigs => _incomeConfigs;
  List<LendBorrow> get allLendBorrows => _lendBorrows;
  List<Repayment> get allRepayments => _repayments;
  List<Investment> get allInvestments => _investments;
  List<CategoryBudget> get allCategoryBudgets => _categoryBudgets;
  List<OdAccount> get allOdAccounts => _odAccounts;
  List<OdTransaction> get allOdTransactions => _odTransactions;
  List<WalletAccount> get allAccounts => _accounts;
  List<ScheduledPayment> get allScheduledPayments => _scheduledPayments;
  List<Goal> get allGoals => _goals;
  List<Asset> get allAssets => _assets;
  List<SplitBill> get allSplitBills => _splitBills;
  List<FuelLog> get allFuelLogs => _fuelLogs;
  List<CarTrip> get allCarTrips => _carTrips;

  List<Category> get deletedCategories => _categories.where((c) => c.deleted).toList();
  List<DailyTransaction> get deletedTransactions => _transactions.where((t) => t.deleted).toList();
  List<Loan> get deletedLoans => _loans.where((l) => l.deleted).toList();
  List<IncomeConfig> get deletedIncomeConfigs => _incomeConfigs.where((i) => i.deleted).toList();
  List<LendBorrow> get deletedLendBorrows => _lendBorrows.where((lb) => lb.deleted).toList();
  List<Repayment> get deletedRepayments => _repayments.where((r) => r.deleted).toList();
  List<Investment> get deletedInvestments => _investments.where((i) => i.deleted).toList();
  List<CategoryBudget> get deletedCategoryBudgets => _categoryBudgets.where((cb) => cb.deleted).toList();
  List<OdAccount> get deletedOdAccounts => _odAccounts.where((od) => od.deleted).toList();
  List<OdTransaction> get deletedOdTransactions => _odTransactions.where((odtx) => odtx.deleted).toList();
  List<WalletAccount> get deletedAccounts => _accounts.where((a) => a.deleted).toList();
  List<ScheduledPayment> get deletedScheduledPayments => _scheduledPayments.where((sp) => sp.deleted).toList();
  List<Goal> get deletedGoals => _goals.where((g) => g.deleted).toList();
  List<Asset> get deletedAssets => _assets.where((a) => a.deleted).toList();
  List<SplitBill> get deletedSplitBills => _splitBills.where((sb) => sb.deleted).toList();
  List<FuelLog> get deletedFuelLogs => _fuelLogs.where((fl) => fl.deleted).toList();
  List<CarTrip> get deletedCarTrips => _carTrips.where((ct) => ct.deleted).toList();

  bool get isTrackingTrip => _isTrackingTrip;
  double get liveTripDistance => _liveTripDistance;
  double get liveSpeed => _liveSpeed;
  List<List<double>> get liveTripPath => _liveTripPath;
  bool get isTripActive => _isTripActive;
  dynamic get wifiSyncServer => _wifiSyncServer;
  String? get localIpAddress => _localIpAddress;
  String get defaultCurrency => _defaultCurrency;


  FinanceProvider() {
    _initAuthAndLoad();
  }

  Future<void> _initAuthAndLoad() async {
    final prefs = await SharedPreferences.getInstance();
    _currentUserId = prefs.getString('user_id');
    _currentUserName = prefs.getString('user_name');
    
    if (isAuthenticated) {
      await loadAllData();
      
      // Auto-start car trip if configured and autoStartOnBoot is enabled
      if (_vehicleConfig != null && _vehicleConfig!.autoStartOnBoot && !_isTrackingTrip) {
        Future.delayed(const Duration(seconds: 1), () {
          startCarTrip();
        });
      }
    }
    notifyListeners();
  }

  Future<void> loadAllData() async {
    if (!isAuthenticated) return;
    final prefs = await SharedPreferences.getInstance();
    
    // Check if the SQLite V2 migration has been done
    final sqliteMigrated = prefs.getBool('sqlite_migrated_v2') ?? false;

    if (!sqliteMigrated) {
      // 1. Migration path: Load legacy lists from SharedPreferences
      final catsStr = prefs.getString('categories') ?? '[]';
      _categories = (jsonDecode(catsStr) as List).map((c) => Category.fromMap(c)).toList();

      final transStr = prefs.getString('transactions') ?? '[]';
      _transactions = (jsonDecode(transStr) as List).map((t) => DailyTransaction.fromMap(t)).toList();

      final loansStr = prefs.getString('loans') ?? '[]';
      _loans = (jsonDecode(loansStr) as List).map((l) => Loan.fromMap(l)).toList();

      final incStr = prefs.getString('income_config') ?? '[]';
      _incomeConfigs = (jsonDecode(incStr) as List).map((i) => IncomeConfig.fromMap(i)).toList();

      final lbStr = prefs.getString('lend_borrows') ?? '[]';
      _lendBorrows = (jsonDecode(lbStr) as List).map((l) => LendBorrow.fromMap(l)).toList();

      final repStr = prefs.getString('repayments') ?? '[]';
      _repayments = (jsonDecode(repStr) as List).map((r) => Repayment.fromMap(r)).toList();
      
      final invStr = prefs.getString('investments') ?? '[]';
      _investments = (jsonDecode(invStr) as List).map((i) => Investment.fromMap(i)).toList();

      final cbStr = prefs.getString('category_budgets') ?? '[]';
      _categoryBudgets = (jsonDecode(cbStr) as List).map((i) => CategoryBudget.fromMap(i)).toList();

      final odAccStr = prefs.getString('od_accounts') ?? '[]';
      _odAccounts = (jsonDecode(odAccStr) as List).map((i) => OdAccount.fromMap(i)).toList();

      final odTxStr = prefs.getString('od_transactions') ?? '[]';
      _odTransactions = (jsonDecode(odTxStr) as List).map((i) => OdTransaction.fromMap(i)).toList();

      final accountsStr = prefs.getString('wallet_accounts') ?? '[]';
      _accounts = (jsonDecode(accountsStr) as List).map((a) => WalletAccount.fromMap(a)).toList();

      final schedStr = prefs.getString('scheduled_payments') ?? '[]';
      _scheduledPayments = (jsonDecode(schedStr) as List).map((s) => ScheduledPayment.fromMap(s)).toList();

      final goalsStr = prefs.getString('goals') ?? '[]';
      _goals = (jsonDecode(goalsStr) as List).map((g) => Goal.fromMap(g)).toList();

      final assetsStr = prefs.getString('wallet_assets_portfolio') ?? '[]';
      _assets = (jsonDecode(assetsStr) as List).map((a) => Asset.fromMap(a)).toList();

      final friendsStr = prefs.getString('wallet_friends') ?? '[]';
      _friends = List<String>.from(jsonDecode(friendsStr) as List? ?? []);

      final splitsStr = prefs.getString('wallet_split_bills') ?? '[]';
      _splitBills = (jsonDecode(splitsStr) as List).map((s) => SplitBill.fromMap(s)).toList();

      final fuelStr = prefs.getString('wallet_fuel_logs') ?? '[]';
      _fuelLogs = (jsonDecode(fuelStr) as List).map((f) => FuelLog.fromMap(f)).toList();

      final configStr = prefs.getString('vehicle_config');
      if (configStr != null) {
        _vehicleConfig = VehicleConfig.fromMap(jsonDecode(configStr));
      }

      final tripsStr = prefs.getString('car_trips') ?? '[]';
      _carTrips = (jsonDecode(tripsStr) as List).map((t) => CarTrip.fromMap(t)).toList();

      // If defaults are empty, populate them
      if (_accounts.isEmpty) {
        _accounts = [
          WalletAccount(id: 1, name: 'Cash', type: 'Cash', initialBalance: 0.0, currencySymbol: '₹', color: '#10B981'),
          WalletAccount(id: 2, name: 'Main Bank', type: 'Bank Account', initialBalance: 0.0, currencySymbol: '₹', color: '#6366F1'),
        ];
      }
      if (_friends.isEmpty) {
        _friends = ['Rahul', 'Priya', 'Amit'];
      }

      // Save to SQLite
      final db = DatabaseHelper.instance;
      await db.saveList('categories', _categories.map((e) => e.toMap()).toList());
      await db.saveList('transactions', _transactions.map((e) => e.toMap()).toList());
      await db.saveList('loans', _loans.map((e) => e.toMap()).toList());
      await db.saveList('income_config', _incomeConfigs.map((e) => e.toMap()).toList());
      await db.saveList('lend_borrows', _lendBorrows.map((e) => e.toMap()).toList());
      await db.saveList('repayments', _repayments.map((e) => e.toMap()).toList());
      await db.saveList('investments', _investments.map((e) => e.toMap()).toList());
      await db.saveList('category_budgets', _categoryBudgets.map((e) => e.toMap()).toList());
      await db.saveList('od_accounts', _odAccounts.map((e) => e.toMap()).toList());
      await db.saveList('od_transactions', _odTransactions.map((e) => e.toMap()).toList());
      await db.saveList('wallet_accounts', _accounts.map((e) => e.toMap()).toList());
      await db.saveList('scheduled_payments', _scheduledPayments.map((e) => e.toMap()).toList());
      await db.saveList('goals', _goals.map((e) => e.toMap()).toList());
      await db.saveList('wallet_assets_portfolio', _assets.map((e) => e.toMap()).toList());
      await db.saveList('wallet_friends', _friends.map((friend) => {'name': friend}).toList());
      await db.saveList('wallet_split_bills', _splitBills.map((e) => e.toMap()).toList());
      await db.saveList('fuel_logs', _fuelLogs.map((e) => e.toMap()).toList());
      if (_vehicleConfig != null) {
        final configMap = _vehicleConfig!.toMap();
        configMap['id'] = 'default_vehicle';
        await db.saveList('vehicle_configs', [configMap]);
      }
      await db.saveList('car_trips', _carTrips.map((e) => e.toMap()).toList());
      await db.saveList('wallet_products', _products.map((e) => e.toMap()).toList());

      await prefs.setBool('sqlite_migrated_v2', true);
    } else {
      // 2. Already migrated: Load directly from SQLite!
      final db = DatabaseHelper.instance;
      
      final catsData = await db.loadList('categories');
      _categories = catsData.map((c) => Category.fromMap(c)).toList();

      final transData = await db.loadList('transactions');
      _transactions = transData.map((t) => DailyTransaction.fromMap(t)).toList();

      final itemsData = await db.loadList('transaction_items');
      _transactionItems = itemsData.map((i) => TransactionItem.fromMap(i)).toList();

      _transactions = _transactions.map((t) {
        final childItems = _transactionItems.where((i) => i.transactionId == t.id && !i.deleted).toList();
        return t.copyWith(items: childItems);
      }).toList();

      final loansData = await db.loadList('loans');
      _loans = loansData.map((l) => Loan.fromMap(l)).toList();

      final incData = await db.loadList('income_config');
      _incomeConfigs = incData.map((i) => IncomeConfig.fromMap(i)).toList();

      final lbData = await db.loadList('lend_borrows');
      _lendBorrows = lbData.map((l) => LendBorrow.fromMap(l)).toList();

      final repData = await db.loadList('repayments');
      _repayments = repData.map((r) => Repayment.fromMap(r)).toList();

      final invData = await db.loadList('investments');
      _investments = invData.map((i) => Investment.fromMap(i)).toList();

      final cbData = await db.loadList('category_budgets');
      _categoryBudgets = cbData.map((i) => CategoryBudget.fromMap(i)).toList();

      final odAccData = await db.loadList('od_accounts');
      _odAccounts = odAccData.map((i) => OdAccount.fromMap(i)).toList();

      final odTxData = await db.loadList('od_transactions');
      _odTransactions = odTxData.map((i) => OdTransaction.fromMap(i)).toList();

      final accountsData = await db.loadList('wallet_accounts');
      _accounts = accountsData.map((a) => WalletAccount.fromMap(a)).toList();
      if (_accounts.isEmpty) {
        _accounts = [
          WalletAccount(id: 1, name: 'Cash', type: 'Cash', initialBalance: 0.0, currencySymbol: '₹', color: '#10B981'),
          WalletAccount(id: 2, name: 'Main Bank', type: 'Bank Account', initialBalance: 0.0, currencySymbol: '₹', color: '#6366F1'),
        ];
        await db.saveList('wallet_accounts', _accounts.map((e) => e.toMap()).toList());
      }

      final schedData = await db.loadList('scheduled_payments');
      _scheduledPayments = schedData.map((s) => ScheduledPayment.fromMap(s)).toList();

      final goalsData = await db.loadList('goals');
      _goals = goalsData.map((g) => Goal.fromMap(g)).toList();

      final assetsData = await db.loadList('wallet_assets_portfolio');
      _assets = assetsData.map((a) => Asset.fromMap(a)).toList();

      final friendsData = await db.loadList('wallet_friends');
      _friends = friendsData.map((m) => m['name'] as String).toList();
      if (_friends.isEmpty) {
        _friends = ['Rahul', 'Priya', 'Amit'];
        await db.saveList('wallet_friends', _friends.map((friend) => {'name': friend}).toList());
      }

      final splitsData = await db.loadList('wallet_split_bills');
      _splitBills = splitsData.map((s) => SplitBill.fromMap(s)).toList();

      final fuelData = await db.loadList('fuel_logs');
      _fuelLogs = fuelData.map((f) => FuelLog.fromMap(f)).toList();

      final configData = await db.loadList('vehicle_configs');
      if (configData.isNotEmpty) {
        _vehicleConfig = VehicleConfig.fromMap(configData.first);
      }

      final tripsData = await db.loadList('car_trips');
      _carTrips = tripsData.map((t) => CarTrip.fromMap(t)).toList();

      final contactsData = await db.loadList('wallet_contacts');
      _contacts = contactsData.map((c) => Contact.fromMap(c)).toList();

      final bool hasPurgedProducts = prefs.getBool('products_purged_v2') ?? false;
      if (!hasPurgedProducts) {
        _products = [];
        await db.saveList('wallet_products', []);
        await prefs.setBool('products_purged_v2', true);
      } else {
        final productsData = await db.loadList('wallet_products');
        _products = productsData.map((p) => Product.fromMap(p)).toList();
      }
    }

    _calculateDynamicLoanStats();
    _applyOfflineEstimates();

    // Load Currency Symbol
    _defaultCurrency = prefs.getString('default_currency') ?? '₹';

    _calculateLendBorrowStats();

    // Daily asset price update check
    final lastUpdateStr = prefs.getString('last_asset_price_update_date') ?? '';
    final todayStr = DateTime.now().toIso8601String().substring(0, 10);
    if (lastUpdateStr != todayStr && _assets.isNotEmpty) {
      updateAssetPrices().then((_) {
        prefs.setString('last_asset_price_update_date', todayStr);
      });
    }

    notifyListeners();

    // Auto-Sync Pull in background
    if (SyncConfig.useApiGateway || !kIsWeb) {
      try {
        await DbSyncService.pullFromDb(this);
      } catch (e) {
        debugPrint('Auto-sync failed: $e');
      }
    } else {
      debugPrint('Cloud Sync: Direct PostgreSQL connection is not supported on Web. Please use Mobile or Desktop.');
    }
  }

  Future<void> _saveData(String key, List<dynamic> items, {bool triggerSync = true, dynamic targetItem}) async {
    final db = DatabaseHelper.instance;
    String table = key;
    List<Map<String, dynamic>> maps;

    if (key == 'wallet_friends') {
      table = 'wallet_friends';
      maps = items.map((friend) => {'name': friend as String}).cast<Map<String, dynamic>>().toList();
    } else if (key == 'wallet_fuel_logs') {
      table = 'fuel_logs';
      maps = items.map((e) => e.toMap()).cast<Map<String, dynamic>>().toList();
    } else if (key == 'vehicle_config') {
      table = 'vehicle_configs';
      maps = items.map((e) {
        final m = e.toMap() as Map<String, dynamic>;
        final mutable = Map<String, dynamic>.from(m);
        mutable['id'] = 'default_vehicle';
        return mutable;
      }).cast<Map<String, dynamic>>().toList();
    } else if (key == 'income_config') {
      table = 'income_configs';
      maps = items.map((e) => e.toMap()).cast<Map<String, dynamic>>().toList();
    } else {
      maps = items.map((e) => e.toMap()).cast<Map<String, dynamic>>().toList();
    }

    await db.saveList(table, maps);
    notifyListeners();

    // Auto-Sync Trigger: Instantly sync after each entry or update if connection is OK
    if (triggerSync && (SyncConfig.useApiGateway || !kIsWeb) && isAuthenticated) {
      _triggerAutoSync(table: table, targetItem: targetItem);
    }
  }

  // Fire-and-forget background sync
  void _triggerAutoSync({String? table, dynamic targetItem}) {
    const syncableTables = {
      'categories',
      'transactions',
      'loans',
      'income_configs',
      'lend_borrows',
      'repayments',
      'investments',
      'category_budgets',
      'od_accounts',
      'od_transactions',
      'fuel_logs',
      'vehicle_configs',
      'car_trips',
      'wallet_contacts',
      'wallet_products'
    };
    if (table != null && !syncableTables.contains(table)) return;

    DbSyncService.pushToDb(this, targetTable: table, targetItem: targetItem).then((_) {
      debugPrint('Auto-sync successful for ${table ?? "all tables"}');
    }).catchError((e) {
      debugPrint('Auto-sync skipped for ${table ?? "all tables"} (Offline or Connection Error): $e');
    });
  }

  Future<void> overwriteFromSync(Map<String, List<Map<String, dynamic>>> syncData) async {
    final db = DatabaseHelper.instance;

    if (syncData['categories'] != null) {
      final remote = syncData['categories']!.map((c) => Category.fromMap(c)).toList();
      for (final rItem in remote) {
        final idx = _categories.indexWhere((item) => item.id == rItem.id);
        if (idx == -1) {
          _categories.add(rItem);
        } else {
          _categories[idx] = rItem;
        }
      }
      await db.saveList('categories', _categories.map((e) => e.toMap()).toList());
    }
    if (syncData['transactions'] != null) {
      final remote = syncData['transactions']!.map((t) => DailyTransaction.fromMap(t)).toList();
      for (final rItem in remote) {
        final idx = _transactions.indexWhere((item) => item.id == rItem.id);
        if (idx == -1) {
          _transactions.add(rItem);
        } else {
          _transactions[idx] = rItem;
        }
      }
      await db.saveList('transactions', _transactions.map((e) => e.toMap()).toList());
    }
    if (syncData['loans'] != null) {
      final remote = syncData['loans']!.map((l) => Loan.fromMap(l)).toList();
      for (final rItem in remote) {
        final idx = _loans.indexWhere((item) => item.id == rItem.id);
        if (idx == -1) {
          _loans.add(rItem);
        } else {
          _loans[idx] = rItem;
        }
      }
      await db.saveList('loans', _loans.map((e) => e.toMap()).toList());
    }
    if (syncData['income_config'] != null) {
      final remote = syncData['income_config']!.map((i) => IncomeConfig.fromMap(i)).toList();
      for (final rItem in remote) {
        final idx = _incomeConfigs.indexWhere((item) => item.id == rItem.id);
        if (idx == -1) {
          _incomeConfigs.add(rItem);
        } else {
          _incomeConfigs[idx] = rItem;
        }
      }
      await db.saveList('income_config', _incomeConfigs.map((e) => e.toMap()).toList());
    }
    if (syncData['lend_borrows'] != null) {
      final remote = syncData['lend_borrows']!.map((lb) => LendBorrow.fromMap(lb)).toList();
      for (final rItem in remote) {
        final idx = _lendBorrows.indexWhere((item) => item.id == rItem.id);
        if (idx == -1) {
          _lendBorrows.add(rItem);
        } else {
          _lendBorrows[idx] = rItem;
        }
      }
      await db.saveList('lend_borrows', _lendBorrows.map((e) => e.toMap()).toList());
    }
    if (syncData['repayments'] != null) {
      final remote = syncData['repayments']!.map((r) => Repayment.fromMap(r)).toList();
      for (final rItem in remote) {
        final idx = _repayments.indexWhere((item) => item.id == rItem.id);
        if (idx == -1) {
          _repayments.add(rItem);
        } else {
          _repayments[idx] = rItem;
        }
      }
      await db.saveList('repayments', _repayments.map((e) => e.toMap()).toList());
    }
    if (syncData['investments'] != null) {
      final remote = syncData['investments']!.map((i) => Investment.fromMap(i)).toList();
      for (final rItem in remote) {
        final idx = _investments.indexWhere((item) => item.id == rItem.id);
        if (idx == -1) {
          _investments.add(rItem);
        } else {
          _investments[idx] = rItem;
        }
      }
      await db.saveList('investments', _investments.map((e) => e.toMap()).toList());
    }
    if (syncData['category_budgets'] != null) {
      final remote = syncData['category_budgets']!.map((i) => CategoryBudget.fromMap(i)).toList();
      for (final rItem in remote) {
        final idx = _categoryBudgets.indexWhere((item) => item.id == rItem.id);
        if (idx == -1) {
          _categoryBudgets.add(rItem);
        } else {
          _categoryBudgets[idx] = rItem;
        }
      }
      await db.saveList('category_budgets', _categoryBudgets.map((e) => e.toMap()).toList());
    }
    if (syncData['od_accounts'] != null) {
      final remote = syncData['od_accounts']!.map((i) => OdAccount.fromMap(i)).toList();
      for (final rItem in remote) {
        final idx = _odAccounts.indexWhere((item) => item.id == rItem.id);
        if (idx == -1) {
          _odAccounts.add(rItem);
        } else {
          _odAccounts[idx] = rItem;
        }
      }
      await db.saveList('od_accounts', _odAccounts.map((e) => e.toMap()).toList());
    }
    if (syncData['od_transactions'] != null) {
      final remote = syncData['od_transactions']!.map((i) => OdTransaction.fromMap(i)).toList();
      for (final rItem in remote) {
        final idx = _odTransactions.indexWhere((item) => item.id == rItem.id);
        if (idx == -1) {
          _odTransactions.add(rItem);
        } else {
          _odTransactions[idx] = rItem;
        }
      }
      await db.saveList('od_transactions', _odTransactions.map((e) => e.toMap()).toList());
    }
    if (syncData['wallet_accounts'] != null) {
      final remote = syncData['wallet_accounts']!.map((i) => WalletAccount.fromMap(i)).toList();
      for (final rItem in remote) {
        final idx = _accounts.indexWhere((item) => item.id == rItem.id);
        if (idx == -1) {
          _accounts.add(rItem);
        } else {
          _accounts[idx] = rItem;
        }
      }
      await db.saveList('wallet_accounts', _accounts.map((e) => e.toMap()).toList());
    }
    if (syncData['scheduled_payments'] != null) {
      final remote = syncData['scheduled_payments']!.map((i) => ScheduledPayment.fromMap(i)).toList();
      for (final rItem in remote) {
        final idx = _scheduledPayments.indexWhere((item) => item.id == rItem.id);
        if (idx == -1) {
          _scheduledPayments.add(rItem);
        } else {
          _scheduledPayments[idx] = rItem;
        }
      }
      await db.saveList('scheduled_payments', _scheduledPayments.map((e) => e.toMap()).toList());
    }
    if (syncData['goals'] != null) {
      final remote = syncData['goals']!.map((i) => Goal.fromMap(i)).toList();
      for (final rItem in remote) {
        final idx = _goals.indexWhere((item) => item.id == rItem.id);
        if (idx == -1) {
          _goals.add(rItem);
        } else {
          _goals[idx] = rItem;
        }
      }
      await db.saveList('goals', _goals.map((e) => e.toMap()).toList());
    }
    if (syncData['wallet_assets_portfolio'] != null) {
      final remote = syncData['wallet_assets_portfolio']!.map((i) => Asset.fromMap(i)).toList();
      for (final rItem in remote) {
        final idx = _assets.indexWhere((item) => item.id == rItem.id);
        if (idx == -1) {
          _assets.add(rItem);
        } else {
          _assets[idx] = rItem;
        }
      }
      await db.saveList('wallet_assets_portfolio', _assets.map((e) => e.toMap()).toList());
    }
    if (syncData['wallet_friends'] != null) {
      final remote = List<String>.from(syncData['wallet_friends']!);
      for (final friend in remote) {
        if (!_friends.contains(friend)) {
          _friends.add(friend);
        }
      }
      await db.saveList('wallet_friends', _friends.map((friend) => {'name': friend}).toList());
    }
    if (syncData['wallet_contacts'] != null) {
      final remote = syncData['wallet_contacts']!.map((i) => Contact.fromMap(i)).toList();
      for (final rItem in remote) {
        final idx = _contacts.indexWhere((item) => item.id == rItem.id);
        if (idx == -1) {
          _contacts.add(rItem);
        } else {
          _contacts[idx] = rItem;
        }
      }
      await db.saveList('wallet_contacts', _contacts.map((e) => e.toMap()).toList());
    }
    if (syncData['wallet_products'] != null) {
      final remote = syncData['wallet_products']!.map((i) => Product.fromMap(i)).toList();
      for (final rItem in remote) {
        final idx = _products.indexWhere((item) => item.id == rItem.id);
        if (idx == -1) {
          _products.add(rItem);
        } else {
          _products[idx] = rItem;
        }
      }
      await db.saveList('wallet_products', _products.map((e) => e.toMap()).toList());
    }
    if (syncData['wallet_split_bills'] != null) {
      final remote = syncData['wallet_split_bills']!.map((i) => SplitBill.fromMap(i)).toList();
      for (final rItem in remote) {
        final idx = _splitBills.indexWhere((item) => item.id == rItem.id);
        if (idx == -1) {
          _splitBills.add(rItem);
        } else {
          _splitBills[idx] = rItem;
        }
      }
      await db.saveList('wallet_split_bills', _splitBills.map((e) => e.toMap()).toList());
    }
    if (syncData['fuel_logs'] != null) {
      final remote = syncData['fuel_logs']!.map((i) => FuelLog.fromMap(i)).toList();
      for (final rItem in remote) {
        final idx = _fuelLogs.indexWhere((item) => item.id == rItem.id);
        if (idx == -1) {
          _fuelLogs.add(rItem);
        } else {
          _fuelLogs[idx] = rItem;
        }
      }
      await db.saveList('fuel_logs', _fuelLogs.map((e) => e.toMap()).toList());
    }
    if (syncData['vehicle_configs'] != null) {
      if (syncData['vehicle_configs']!.isNotEmpty) {
        _vehicleConfig = VehicleConfig.fromMap(syncData['vehicle_configs']!.first);
        final configMap = _vehicleConfig!.toMap();
        configMap['id'] = 'default_vehicle';
        await db.saveList('vehicle_configs', [configMap]);
      }
    }
    if (syncData['car_trips'] != null) {
      final remote = syncData['car_trips']!.map((i) => CarTrip.fromMap(i)).toList();
      for (final rItem in remote) {
        final idx = _carTrips.indexWhere((item) => item.id == rItem.id);
        if (idx == -1) {
          _carTrips.add(rItem);
        } else {
          _carTrips[idx] = rItem;
        }
      }
      await db.saveList('car_trips', _carTrips.map((e) => e.toMap()).toList());
    }

    _calculateDynamicLoanStats();
    _calculateLendBorrowStats();
    notifyListeners();
  }

  String _hashPin(String pin) {
    final bytes = utf8.encode('my_wallet_salt_$pin');
    return sha256.convert(bytes).toString();
  }

  Future<void> login(String mobile, String pin) async {
    final prefs = await SharedPreferences.getInstance();
    Map<String, dynamic>? userData;
    bool isOfflineMode = false;
    final hashedPin = _hashPin(pin);

    try {
      userData = await DbSyncService.loginUser(mobile, pin);
      if (userData != null) {
        await prefs.setString('offline_mobile', userData['mobile_number']);
        await prefs.setString('offline_pin_hash', hashedPin);
        await prefs.remove('offline_pin'); // Remove unencrypted legacy PIN if present
        await prefs.setString('offline_name', userData['name']);
      } else {
        final cachedMobile = prefs.getString('offline_mobile');
        final cachedHash = prefs.getString('offline_pin_hash');
        final cachedLegacyPin = prefs.getString('offline_pin');
        final cachedName = prefs.getString('offline_name');
        
        final isMatch = cachedMobile == mobile && 
            cachedName != null && 
            ((cachedHash != null && cachedHash == hashedPin) || (cachedLegacyPin != null && cachedLegacyPin == pin));

        if (isMatch) {
          userData = {
            'mobile_number': cachedMobile,
            'name': cachedName,
          };
          isOfflineMode = true;
          // Upgrade legacy stored pin to hash
          await prefs.setString('offline_pin_hash', hashedPin);
          await prefs.remove('offline_pin');
        }
      }
    } catch (e) {
      final cachedMobile = prefs.getString('offline_mobile');
      final cachedHash = prefs.getString('offline_pin_hash');
      final cachedLegacyPin = prefs.getString('offline_pin');
      final cachedName = prefs.getString('offline_name');

      final isMatch = cachedMobile == mobile && 
          cachedName != null && 
          ((cachedHash != null && cachedHash == hashedPin) || (cachedLegacyPin != null && cachedLegacyPin == pin));

      if (isMatch) {
        userData = {
          'mobile_number': cachedMobile,
          'name': cachedName,
        };
        isOfflineMode = true;
        await prefs.setString('offline_pin_hash', hashedPin);
        await prefs.remove('offline_pin');
      } else {
        throw Exception('Server is offline and no matching local credentials found.');
      }
    }

    if (userData != null) {
      _currentUserId = userData['mobile_number'];
      _currentUserName = userData['name'];
      
      await prefs.setString('user_id', _currentUserId!);
      await prefs.setString('user_name', _currentUserName!);
      _isOfflineLogin = isOfflineMode;
      
      await loadAllData();
      notifyListeners();
    } else {
      throw Exception('Invalid Mobile Number or PIN');
    }
  }

  Future<void> register(String name, String mobile, String pin) async {
    final success = await DbSyncService.registerUser(name, mobile, pin);
    if (success) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('offline_mobile', mobile);
      await prefs.setString('offline_pin_hash', _hashPin(pin));
      await prefs.remove('offline_pin');
      await prefs.setString('offline_name', name);
      
      await login(mobile, pin);
    } else {
      throw Exception('Mobile Number already registered');
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_id');
    await prefs.remove('user_name');
    
    // Clear local data to prevent leakage to next user
    await prefs.remove('categories');
    await prefs.remove('transactions');
    await prefs.remove('loans');
    await prefs.remove('income_config');
    await prefs.remove('lend_borrows');
    await prefs.remove('repayments');
    await prefs.remove('investments');
    await prefs.remove('category_budgets');
    await prefs.remove('od_accounts');
    await prefs.remove('od_transactions');
    await prefs.remove('wallet_accounts');
    await prefs.remove('scheduled_payments');
    await prefs.remove('goals');
    await prefs.remove('wallet_assets_portfolio');
    await prefs.remove('wallet_friends');
    await prefs.remove('wallet_split_bills');
    await prefs.remove('default_currency');
    await prefs.remove('wallet_fuel_logs');
    await prefs.remove('offline_mobile');
    await prefs.remove('offline_pin');
    await prefs.remove('offline_name');

    _currentUserId = null;
    _currentUserName = null;
    _categories = [];
    _transactions = [];
    _loans = [];
    _incomeConfigs = [];
    _lendBorrows = [];
    _repayments = [];
    _investments = [];
    _categoryBudgets = [];
    _odAccounts = [];
    _odTransactions = [];
    _accounts = [];
    _scheduledPayments = [];
    _goals = [];
    _assets = [];
    _friends = [];
    _splitBills = [];
    _fuelLogs = [];
    _defaultCurrency = '₹';

    notifyListeners();
  }

  int _generateId() => DateTime.now().millisecondsSinceEpoch;

  void _calculateDynamicLoanStats() {
    bool changed = false;
    
    for (int i = 0; i < _loans.length; i++) {
      final l = _loans[i];
      final paid = l.paid;
      final balance = (l.total - paid) <= 0 ? 0.0 : (l.total - paid);
      int tenurePending = l.emi > 0 ? (balance / l.emi).ceil() : (balance <= 0 ? 0 : l.tenure);
      if (tenurePending > l.tenure) tenurePending = l.tenure;
      if (tenurePending < 0) tenurePending = 0;
      final status = balance <= 0 ? 'Closed' : 'Active';

      if (l.balance != balance || l.tenurePending != tenurePending || l.status != status) {
        _loans[i] = Loan(
          id: l.id, lender: l.lender, startDate: l.startDate, endDate: l.endDate,
          tenure: l.tenure, roi: l.roi, principal: l.principal, interest: l.interest,
          total: l.total, paid: paid, balance: balance, emi: l.emi,
          tenurePending: tenurePending, status: status,
        );
        changed = true;
      }
    }
    
    if (changed) _saveData('loans', _loans);
  }

  void _calculateLendBorrowStats() {
    bool changed = false;
    for (int i = 0; i < _lendBorrows.length; i++) {
      final lb = _lendBorrows[i];
      final relatedRepayments = _repayments.where((r) => r.lendBorrowId == lb.id).toList();
      relatedRepayments.sort((a, b) => _safeParseDate(a.paymentDate).compareTo(_safeParseDate(b.paymentDate)));

      final settled = relatedRepayments.fold(0.0, (sum, r) => sum + r.amount);
      final diff = lb.principal - settled;
      final status = diff <= 0 ? 'Settled' : 'Active';
      final returnDate = lb.returnDate.isNotEmpty
          ? lb.returnDate
          : (relatedRepayments.isNotEmpty ? relatedRepayments.last.paymentDate : '');

      final endDate = returnDate.isNotEmpty ? _safeParseDate(returnDate) : DateTime.now();
      final start = _safeParseDate(lb.date);
      int tenure = lb.tenure > 0
          ? lb.tenure
          : ((endDate.year - start.year) * 12 + endDate.month - start.month);
      if (tenure < 0) tenure = 0;

      if (lb.settled != settled || lb.diff != diff || lb.status != status || lb.returnDate != returnDate || lb.tenure != tenure) {
        _lendBorrows[i] = LendBorrow(
          id: lb.id,
          name: lb.name,
          type: lb.type,
          date: lb.date,
          tenure: tenure,
          principal: lb.principal,
          returnDate: returnDate,
          settled: settled,
          diff: diff,
          status: status,
        );
        changed = true;
      }
    }
    if (changed) _saveData('lend_borrows', _lendBorrows);
  }

  // --- Category Methods ---
  Future<void> addCategory(Category category) async {
    final newCat = Category(
      id: category.id ?? _generateId(),
      name: category.name,
      plannedAmount: category.plannedAmount,
    );
    _categories.add(newCat);
    await _saveData('categories', _categories, targetItem: newCat);
  }

  Future<void> updateCategory(Category category) async {
    final index = _categories.indexWhere((c) => c.id == category.id);
    if (index != -1) {
      _categories[index] = category;
      await _saveData('categories', _categories, targetItem: category);
    }
  }

  Future<void> deleteCategory(int id) async {
    final index = _categories.indexWhere((c) => c.id == id);
    if (index != -1) {
      final updated = _categories[index].copyWith(deleted: true);
      _categories[index] = updated;
      await _saveData('categories', _categories, targetItem: updated);
    }
  }

  Future<void> recoverCategory(int id) async {
    final index = _categories.indexWhere((c) => c.id == id);
    if (index != -1) {
      final updated = _categories[index].copyWith(deleted: false);
      _categories[index] = updated;
      await _saveData('categories', _categories, targetItem: updated);
    }
  }

  // --- Transaction Methods ---
  Future<void> addTransaction(DailyTransaction tx) async {
    final newTx = DailyTransaction(
      id: tx.id ?? _generateId(),
      date: tx.date,
      categoryId: tx.categoryId,
      itemService: tx.itemService,
      cost: tx.cost,
      paidAmount: tx.paidAmount,
      cleared: tx.cleared,
      accountId: tx.accountId,
      toAccountId: tx.toAccountId,
      transactionType: tx.transactionType,
      tags: tx.tags,
      note: tx.note,
      merchantName: tx.merchantName,
      items: tx.items,
    );
    _transactions.add(newTx);
    await _saveData('transactions', _transactions, targetItem: newTx);

    if (tx.items.isNotEmpty) {
      for (var item in tx.items) {
        final childItem = item.copyWith(transactionId: newTx.id);
        _transactionItems.add(childItem);
      }
      await _saveData('transaction_items', _transactionItems);
    }
  }

  Future<void> updateTransaction(DailyTransaction tx) async {
    final index = _transactions.indexWhere((t) => t.id == tx.id);
    if (index != -1) {
      _transactions[index] = tx;
      await _saveData('transactions', _transactions, targetItem: tx);

      if (tx.items.isNotEmpty) {
        _transactionItems.removeWhere((i) => i.transactionId == tx.id);
        for (var item in tx.items) {
          final childItem = item.copyWith(transactionId: tx.id);
          _transactionItems.add(childItem);
        }
        await _saveData('transaction_items', _transactionItems);
      }
    }
  }

  Future<void> deleteTransaction(int id) async {
    final index = _transactions.indexWhere((t) => t.id == id);
    if (index != -1) {
      final updated = _transactions[index].copyWith(deleted: true);
      _transactions[index] = updated;
      await _saveData('transactions', _transactions, targetItem: updated);

      for (int i = 0; i < _transactionItems.length; i++) {
        if (_transactionItems[i].transactionId == id) {
          _transactionItems[i] = _transactionItems[i].copyWith(deleted: true);
        }
      }
      await _saveData('transaction_items', _transactionItems);
    }
  }

  Future<void> recoverTransaction(int id) async {
    final index = _transactions.indexWhere((t) => t.id == id);
    if (index != -1) {
      final updated = _transactions[index].copyWith(deleted: false);
      _transactions[index] = updated;
      await _saveData('transactions', _transactions, targetItem: updated);
    }
  }

  // --- Loan Methods ---
  Future<void> addLoan(Loan loan) async {
    final newLoan = Loan(
      id: loan.id ?? _generateId(),
      lender: loan.lender,
      startDate: loan.startDate,
      endDate: loan.endDate,
      tenure: loan.tenure,
      roi: loan.roi,
      principal: loan.principal,
      interest: loan.interest,
      total: loan.total,
      paid: loan.paid,
      balance: loan.balance,
      emi: loan.emi,
      tenurePending: loan.tenurePending,
      status: loan.status,
    );
    _loans.add(newLoan);
    _calculateDynamicLoanStats(); // Also updates the just-added loan
    await _saveData('loans', _loans, targetItem: newLoan);
  }

  Future<void> updateLoan(Loan loan) async {
    final index = _loans.indexWhere((l) => l.id == loan.id);
    if (index != -1) {
      _loans[index] = loan;
      _calculateDynamicLoanStats();
      await _saveData('loans', _loans, targetItem: loan);
    }
  }

  Future<void> deleteLoan(int id) async {
    final index = _loans.indexWhere((l) => l.id == id);
    if (index != -1) {
      final updated = _loans[index].copyWith(deleted: true);
      _loans[index] = updated;
      await _saveData('loans', _loans, targetItem: updated);
    }
  }

  Future<void> recoverLoan(int id) async {
    final index = _loans.indexWhere((l) => l.id == id);
    if (index != -1) {
      final updated = _loans[index].copyWith(deleted: false);
      _loans[index] = updated;
      await _saveData('loans', _loans, targetItem: updated);
    }
  }

  // --- Income Config Methods ---
  Future<void> addOrUpdateIncomeConfig(IncomeConfig config) async {
    final index = _incomeConfigs.indexWhere((c) => c.month == config.month && c.year == config.year);
    IncomeConfig target;
    if (index != -1) {
      target = IncomeConfig(
        id: _incomeConfigs[index].id,
        month: config.month,
        year: config.year,
        amount: config.amount,
        isDefault: config.isDefault,
      );
      _incomeConfigs[index] = target;
    } else {
      target = IncomeConfig(
        id: config.id ?? _generateId(),
        month: config.month,
        year: config.year,
        amount: config.amount,
        isDefault: config.isDefault,
      );
      _incomeConfigs.add(target);
    }
    await _saveData('income_config', _incomeConfigs, targetItem: target);
  }

  Future<void> deleteIncomeConfig(int id) async {
    final index = _incomeConfigs.indexWhere((i) => i.id == id);
    if (index != -1) {
      final updated = _incomeConfigs[index].copyWith(deleted: true);
      _incomeConfigs[index] = updated;
      await _saveData('income_config', _incomeConfigs, targetItem: updated);
    }
  }

  Future<void> recoverIncomeConfig(int id) async {
    final index = _incomeConfigs.indexWhere((i) => i.id == id);
    if (index != -1) {
      final updated = _incomeConfigs[index].copyWith(deleted: false);
      _incomeConfigs[index] = updated;
      await _saveData('income_config', _incomeConfigs, targetItem: updated);
    }
  }

  double getMonthlyIncome(int month, int year) {
    final targetDate = DateTime(year, month);
    IncomeConfig? bestMatch;
    DateTime? bestDate;

    for (var config in _incomeConfigs) {
      if (config.isDefault) continue;
      final configDate = DateTime(config.year, config.month);
      if (!configDate.isAfter(targetDate)) {
        if (bestDate == null || configDate.isAfter(bestDate)) {
          bestMatch = config;
          bestDate = configDate;
        }
      }
    }
    
    if (bestMatch != null) {
      return bestMatch.amount;
    }

    for (var config in _incomeConfigs) {
      if (config.isDefault) {
        return config.amount;
      }
    }

    return 0.0;
  }

  double getCategoryBudget(int categoryId, int month, int year) {
    final targetDate = DateTime(year, month);
    CategoryBudget? bestMatch;
    DateTime? bestDate;

    // Filter budgets for this specific category
    final relevantBudgets = _categoryBudgets.where((b) => b.categoryId == categoryId);

    for (var budget in relevantBudgets) {
      final budgetDate = DateTime(budget.year, budget.month);
      if (!budgetDate.isAfter(targetDate)) {
        if (bestDate == null || budgetDate.isAfter(bestDate)) {
          bestMatch = budget;
          bestDate = budgetDate;
        }
      }
    }

    if (bestMatch != null) return bestMatch.amount;

    // Fallback: If no budget history exists, use the "plannedAmount" from the Category object itself
    try {
      return _categories.firstWhere((c) => c.id == categoryId).plannedAmount;
    } catch (e) {
      return 0.0;
    }
  }

  Future<void> updateCategoryBudget(int categoryId, int month, int year, double amount) async {
    final index = _categoryBudgets.indexWhere((b) => b.categoryId == categoryId && b.month == month && b.year == year);
    CategoryBudget target;
    if (index != -1) {
      target = CategoryBudget(
        id: _categoryBudgets[index].id,
        categoryId: categoryId,
        month: month,
        year: year,
        amount: amount,
      );
      _categoryBudgets[index] = target;
    } else {
      target = CategoryBudget(
        id: _generateId(),
        categoryId: categoryId,
        month: month,
        year: year,
        amount: amount,
      );
      _categoryBudgets.add(target);
    }
    await _saveData('category_budgets', _categoryBudgets, targetItem: target);
  }

  Future<void> deleteCategoryBudget(int id) async {
    final index = _categoryBudgets.indexWhere((cb) => cb.id == id);
    if (index != -1) {
      final updated = _categoryBudgets[index].copyWith(deleted: true);
      _categoryBudgets[index] = updated;
      await _saveData('category_budgets', _categoryBudgets, targetItem: updated);
    }
  }

  Future<void> recoverCategoryBudget(int id) async {
    final index = _categoryBudgets.indexWhere((cb) => cb.id == id);
    if (index != -1) {
      final updated = _categoryBudgets[index].copyWith(deleted: false);
      _categoryBudgets[index] = updated;
      await _saveData('category_budgets', _categoryBudgets, targetItem: updated);
    }
  }

  double getMonthlyExpenditure(int month, int year) {
    return _transactions.where((t) {
      final d = _safeParseDate(t.date);
      return d.month == month && d.year == year;
    }).fold(0.0, (sum, item) => sum + item.cost);
  }

  double getTotalEMI() {
    return _loans.where((l) => l.status == 'Active').fold(0.0, (sum, item) => sum + item.emi);
  }

  // --- Lend & Borrow Methods ---
  Future<void> addLendBorrow(LendBorrow lb) async {
    final newLb = LendBorrow(
      id: lb.id ?? _generateId(),
      name: lb.name,
      type: lb.type,
      date: lb.date,
      tenure: lb.tenure,
      principal: lb.principal,
    );
    _lendBorrows.add(newLb);
    _calculateLendBorrowStats();
    await _saveData('lend_borrows', _lendBorrows, targetItem: newLb);
  }

  Future<void> updateLendBorrow(LendBorrow lb) async {
    final index = _lendBorrows.indexWhere((item) => item.id == lb.id);
    if (index != -1) {
      _lendBorrows[index] = lb;
      _calculateLendBorrowStats();
      await _saveData('lend_borrows', _lendBorrows, targetItem: lb);
    }
  }

  Future<void> deleteLendBorrow(int id) async {
    final index = _lendBorrows.indexWhere((item) => item.id == id);
    if (index != -1) {
      final updated = _lendBorrows[index].copyWith(deleted: true);
      _lendBorrows[index] = updated;
      for (int i = 0; i < _repayments.length; i++) {
        if (_repayments[i].lendBorrowId == id) {
          _repayments[i] = _repayments[i].copyWith(deleted: true);
        }
      }
      await _saveData('repayments', _repayments);
      await _saveData('lend_borrows', _lendBorrows, targetItem: updated);
    }
  }

  Future<void> recoverLendBorrow(int id) async {
    final index = _lendBorrows.indexWhere((item) => item.id == id);
    if (index != -1) {
      final updated = _lendBorrows[index].copyWith(deleted: false);
      _lendBorrows[index] = updated;
      for (int i = 0; i < _repayments.length; i++) {
        if (_repayments[i].lendBorrowId == id) {
          _repayments[i] = _repayments[i].copyWith(deleted: false);
        }
      }
      await _saveData('repayments', _repayments);
      await _saveData('lend_borrows', _lendBorrows, targetItem: updated);
    }
  }

  Future<void> addRepayment(Repayment r) async {
    final newRep = Repayment(
      id: r.id ?? _generateId(),
      lendBorrowId: r.lendBorrowId,
      name: r.name,
      paymentDate: r.paymentDate,
      amount: r.amount,
      method: r.method,
    );
    _repayments.add(newRep);
    _calculateLendBorrowStats();
    await _saveData('repayments', _repayments, targetItem: newRep);
  }

  Future<void> updateRepayment(Repayment r) async {
    final index = _repayments.indexWhere((item) => item.id == r.id);
    if (index != -1) {
      _repayments[index] = r;
      _calculateLendBorrowStats();
      await _saveData('repayments', _repayments, targetItem: r);
    }
  }

  Future<void> deleteRepayment(int id) async {
    final index = _repayments.indexWhere((item) => item.id == id);
    if (index != -1) {
      final updated = _repayments[index].copyWith(deleted: true);
      _repayments[index] = updated;
      _calculateLendBorrowStats();
      await _saveData('repayments', _repayments, targetItem: updated);
    }
  }

  Future<void> recoverRepayment(int id) async {
    final index = _repayments.indexWhere((item) => item.id == id);
    if (index != -1) {
      final updated = _repayments[index].copyWith(deleted: false);
      _repayments[index] = updated;
      _calculateLendBorrowStats();
      await _saveData('repayments', _repayments, targetItem: updated);
    }
  }

  Future<void> addContactRepayment({
    required String name,
    required String type,
    required double amount,
    required String method,
    required String date,
  }) async {
    final contactEntries = _lendBorrows.where((lb) => lb.name == name && lb.type == type).toList();
    if (contactEntries.isEmpty) return;

    final activeEntries = contactEntries.where((lb) => lb.status == 'Active').toList();
    activeEntries.sort((a, b) => _safeParseDate(a.date).compareTo(_safeParseDate(b.date)));

    double remaining = amount;
    List<Repayment> newRepayments = [];
    final baseId = DateTime.now().millisecondsSinceEpoch;

    for (var entry in activeEntries) {
      if (remaining <= 0) break;
      double pending = entry.diff;
      if (pending <= 0) continue;

      double repayForThis = remaining >= pending ? pending : remaining;
      newRepayments.add(Repayment(
        id: baseId + newRepayments.length,
        lendBorrowId: entry.id!,
        name: name,
        paymentDate: date,
        amount: repayForThis,
        method: method,
      ));
      remaining -= repayForThis;
    }

    if (remaining > 0) {
      contactEntries.sort((a, b) => _safeParseDate(b.date).compareTo(_safeParseDate(a.date)));
      final newestEntry = contactEntries.first;

      final existingIndex = newRepayments.indexWhere((r) => r.lendBorrowId == newestEntry.id);
      if (existingIndex != -1) {
        final oldRep = newRepayments[existingIndex];
        newRepayments[existingIndex] = Repayment(
          id: oldRep.id,
          lendBorrowId: oldRep.lendBorrowId,
          name: oldRep.name,
          paymentDate: oldRep.paymentDate,
          amount: oldRep.amount + remaining,
          method: oldRep.method,
        );
      } else {
        newRepayments.add(Repayment(
          id: baseId + newRepayments.length,
          lendBorrowId: newestEntry.id!,
          name: name,
          paymentDate: date,
          amount: remaining,
          method: method,
        ));
      }
    }

    if (newRepayments.isNotEmpty) {
      _repayments.addAll(newRepayments);
      _calculateLendBorrowStats();
      await _saveData('repayments', _repayments);
    }
  }

  // --- Investment Methods ---
  Future<void> addInvestment(Investment inv) async {
    final newInv = Investment(
      id: inv.id ?? _generateId(),
      name: inv.name,
      type: inv.type,
      amount: inv.amount,
      expectedRoi: inv.expectedRoi,
      tenureMonths: inv.tenureMonths,
      startDate: inv.startDate,
    );
    _investments.add(newInv);
    await _saveData('investments', _investments, targetItem: newInv);
  }

  Future<void> updateInvestment(Investment inv) async {
    final index = _investments.indexWhere((item) => item.id == inv.id);
    if (index != -1) {
      _investments[index] = inv;
      await _saveData('investments', _investments, targetItem: inv);
    }
  }

  Future<void> deleteInvestment(int id) async {
    final index = _investments.indexWhere((item) => item.id == id);
    if (index != -1) {
      final updated = _investments[index].copyWith(deleted: true);
      _investments[index] = updated;
      await _saveData('investments', _investments, targetItem: updated);
    }
  }

  Future<void> recoverInvestment(int id) async {
    final index = _investments.indexWhere((item) => item.id == id);
    if (index != -1) {
      final updated = _investments[index].copyWith(deleted: false);
      _investments[index] = updated;
      await _saveData('investments', _investments, targetItem: updated);
    }
  }

  int getElapsedMonths(Investment inv) {
    final start = _safeParseDate(inv.startDate);
    final now = DateTime.now();
    int months = (now.year - start.year) * 12 + now.month - start.month;
    if (now.day < start.day) months--;
    if (months < 0) return 0;
    if (months > inv.tenureMonths) return inv.tenureMonths;
    return months;
  }

  bool isInvestmentActive(Investment inv) {
    return getElapsedMonths(inv) < inv.tenureMonths;
  }

  double calculateMaturity(Investment inv, int months) {
    if (months == 0) return inv.amount;

    final r = (inv.expectedRoi / 100) / 12; // Monthly interest rate
    
    if (['FD', 'Mutual Fund', 'Stock'].contains(inv.type)) {
      // Lump sum compound interest
      return inv.amount * pow((1 + r), months);
    } else {
      // Recurring monthly deposit compound interest (Annuity)
      if (r == 0) return inv.amount * months;
      return inv.amount * ((pow(1 + r, months) - 1) / r) * (1 + r);
    }
  }

  double getCurrentMaturity(Investment inv) => calculateMaturity(inv, getElapsedMonths(inv));
  double getFinalMaturity(Investment inv) => calculateMaturity(inv, inv.tenureMonths);

  double getTotalInvested(Investment inv) {
    if (['FD', 'Mutual Fund', 'Stock'].contains(inv.type)) {
      return inv.amount;
    } else {
      return inv.amount * getElapsedMonths(inv);
    }
  }

  double get totalCurrentInvestments {
    return _investments.fold(0.0, (sum, inv) => sum + getCurrentMaturity(inv));
  }

  double get currentMonthlySavings {
    return _investments
        .where((inv) => ['RD', 'SIP', 'PPF'].contains(inv.type) && isInvestmentActive(inv))
        .fold(0.0, (sum, inv) => sum + inv.amount);
  }

  // --- OD Account Methods ---
  Future<void> addOdAccount(OdAccount account) async {
    final newAcc = OdAccount(
      id: account.id ?? _generateId(),
      name: account.name,
      limit: account.limit,
      interestRate: account.interestRate,
      billingDay: account.billingDay,
    );
    _odAccounts.add(newAcc);
    await _saveData('od_accounts', _odAccounts, targetItem: newAcc);
  }

  Future<void> updateOdAccount(OdAccount account) async {
    final index = _odAccounts.indexWhere((item) => item.id == account.id);
    if (index != -1) {
      _odAccounts[index] = account;
      await _saveData('od_accounts', _odAccounts, targetItem: account);
    }
  }

  Future<void> deleteOdAccount(int id) async {
    final index = _odAccounts.indexWhere((item) => item.id == id);
    if (index != -1) {
      final updated = _odAccounts[index].copyWith(deleted: true);
      _odAccounts[index] = updated;
      for (int i = 0; i < _odTransactions.length; i++) {
        if (_odTransactions[i].odAccountId == id) {
          _odTransactions[i] = _odTransactions[i].copyWith(deleted: true);
        }
      }
      await _saveData('od_transactions', _odTransactions);
      await _saveData('od_accounts', _odAccounts, targetItem: updated);
    }
  }

  Future<void> recoverOdAccount(int id) async {
    final index = _odAccounts.indexWhere((item) => item.id == id);
    if (index != -1) {
      final updated = _odAccounts[index].copyWith(deleted: false);
      _odAccounts[index] = updated;
      for (int i = 0; i < _odTransactions.length; i++) {
        if (_odTransactions[i].odAccountId == id) {
          _odTransactions[i] = _odTransactions[i].copyWith(deleted: false);
        }
      }
      await _saveData('od_transactions', _odTransactions);
      await _saveData('od_accounts', _odAccounts, targetItem: updated);
    }
  }

  Future<void> addOdTransaction(OdTransaction tx) async {
    final newTx = OdTransaction(
      id: tx.id ?? _generateId(),
      odAccountId: tx.odAccountId,
      amount: tx.amount,
      type: tx.type,
      date: tx.date,
    );
    _odTransactions.add(newTx);
    await _saveData('od_transactions', _odTransactions, targetItem: newTx);
  }

  Future<void> updateOdTransaction(OdTransaction tx) async {
    final index = _odTransactions.indexWhere((item) => item.id == tx.id);
    if (index != -1) {
      _odTransactions[index] = tx;
      await _saveData('od_transactions', _odTransactions, targetItem: tx);
    }
  }

  Future<void> deleteOdTransaction(int id) async {
    final index = _odTransactions.indexWhere((item) => item.id == id);
    if (index != -1) {
      final updated = _odTransactions[index].copyWith(deleted: true);
      _odTransactions[index] = updated;
      await _saveData('od_transactions', _odTransactions, targetItem: updated);
    }
  }

  Future<void> recoverOdTransaction(int id) async {
    final index = _odTransactions.indexWhere((item) => item.id == id);
    if (index != -1) {
      final updated = _odTransactions[index].copyWith(deleted: false);
      _odTransactions[index] = updated;
      await _saveData('od_transactions', _odTransactions, targetItem: updated);
    }
  }

  double getOdUsedAmount(int accountId) {
    final txs = _odTransactions.where((t) => t.odAccountId == accountId);
    double used = 0.0;
    for (var tx in txs) {
      if (tx.type == 'Debit') {
        used += tx.amount;
      } else {
        used -= tx.amount;
      }
    }
    return used;
  }

  // Calculate Interest based on Daily Reducing Balance (ICICI Process)
  double calculateOdInterest(OdAccount account, {bool upToBillingDate = false}) {
    final now = DateTime.now();
    DateTime lastBillingDate;
    
    // Determine the start of current billing cycle
    if (now.day >= account.billingDay) {
      int maxDay = DateTime(now.year, now.month + 1, 0).day;
      int clampedDay = account.billingDay > maxDay ? maxDay : account.billingDay;
      lastBillingDate = DateTime(now.year, now.month, clampedDay);
    } else {
      int maxDay = DateTime(now.year, now.month, 0).day;
      int clampedDay = account.billingDay > maxDay ? maxDay : account.billingDay;
      lastBillingDate = DateTime(now.year, now.month - 1, clampedDay);
    }

    DateTime targetEndDate;
    if (upToBillingDate) {
      int nextMonth = lastBillingDate.month + 1;
      int maxDay = DateTime(lastBillingDate.year, nextMonth + 1, 0).day;
      int clampedDay = account.billingDay > maxDay ? maxDay : account.billingDay;
      targetEndDate = DateTime(lastBillingDate.year, nextMonth, clampedDay);
    } else {
      targetEndDate = now;
    }

    double totalInterest = 0.0;
    
    // Sort transactions by date
    final sortedTxs = _odTransactions
        .where((t) => t.odAccountId == account.id)
        .toList()
      ..sort((a, b) => _safeParseDate(a.date).compareTo(_safeParseDate(b.date)));

    // For each day from last billing date to target end date
    for (int i = 0; i <= targetEndDate.difference(lastBillingDate).inDays; i++) {
      DateTime day = lastBillingDate.add(Duration(days: i));
      
      // Calculate balance on this specific day
      double dayBalance = 0.0;
      for (var tx in sortedTxs) {
        if (_safeParseDate(tx.date).isAfter(day)) break;
        if (tx.type == 'Debit') {
          dayBalance += tx.amount;
        } else {
          dayBalance -= tx.amount;
        }
      }

      if (dayBalance > 0) {
        // Daily Interest = (Principal * Rate * Time) / (365 * 100)
        // Time = 1 day
        totalInterest += (dayBalance * account.interestRate) / (365 * 100);
      }
    }

    return totalInterest;
  }

  // --- Wallet Account Methods ---
  double getAccountBalance(WalletAccount account, {DateTime? upToDate}) {
    double bal = account.initialBalance;
    for (var tx in _transactions) {
      if (upToDate != null && DateTime.tryParse(tx.date)?.isAfter(upToDate) == true) {
        continue;
      }
      final txAccId = tx.accountId ?? 1; // Fallback to Cash
      if (tx.transactionType == 'Income' && txAccId == account.id) {
        bal += tx.cost;
      } else if (tx.transactionType == 'Expense' && txAccId == account.id) {
        bal -= tx.cost;
      } else if (tx.transactionType == 'Transfer') {
        if (txAccId == account.id) {
          bal -= tx.cost; // Outflow
        }
        if (tx.toAccountId == account.id) {
          bal += tx.cost; // Inflow
        }
      }
    }
    return bal;
  }

  double getTotalWalletBalance({DateTime? upToDate}) {
    double total = 0.0;
    for (var acc in _accounts) {
      total += getAccountBalance(acc, upToDate: upToDate);
    }
    return total;
  }

  double get totalWalletBalance => getTotalWalletBalance();

  Future<void> addWalletAccount(WalletAccount acc) async {
    final newAcc = WalletAccount(
      id: acc.id ?? _generateId(),
      name: acc.name,
      type: acc.type,
      initialBalance: acc.initialBalance,
      currencySymbol: acc.currencySymbol,
      color: acc.color,
    );
    _accounts.add(newAcc);
    await _saveData('wallet_accounts', _accounts);
  }

  Future<void> updateWalletAccount(WalletAccount acc) async {
    final index = _accounts.indexWhere((a) => a.id == acc.id);
    if (index != -1) {
      _accounts[index] = acc;
      await _saveData('wallet_accounts', _accounts);
    }
  }

  Future<void> deleteWalletAccount(int id) async {
    final index = _accounts.indexWhere((a) => a.id == id);
    if (index != -1) {
      final updated = _accounts[index].copyWith(deleted: true);
      _accounts[index] = updated;
      await _saveData('wallet_accounts', _accounts, targetItem: updated);
    }
  }

  Future<void> recoverWalletAccount(int id) async {
    final index = _accounts.indexWhere((a) => a.id == id);
    if (index != -1) {
      final updated = _accounts[index].copyWith(deleted: false);
      _accounts[index] = updated;
      await _saveData('wallet_accounts', _accounts, targetItem: updated);
    }
  }

  // --- Scheduled Payment Methods ---
  Future<void> addScheduledPayment(ScheduledPayment payment) async {
    final newPayment = ScheduledPayment(
      id: payment.id ?? _generateId(),
      name: payment.name,
      amount: payment.amount,
      type: payment.type,
      categoryId: payment.categoryId,
      accountId: payment.accountId,
      frequency: payment.frequency,
      nextDueDate: payment.nextDueDate,
      active: payment.active,
    );
    _scheduledPayments.add(newPayment);
    await _saveData('scheduled_payments', _scheduledPayments);
  }

  Future<void> updateScheduledPayment(ScheduledPayment payment) async {
    final index = _scheduledPayments.indexWhere((s) => s.id == payment.id);
    if (index != -1) {
      _scheduledPayments[index] = payment;
      await _saveData('scheduled_payments', _scheduledPayments);
    }
  }

  Future<void> deleteScheduledPayment(int id) async {
    final index = _scheduledPayments.indexWhere((s) => s.id == id);
    if (index != -1) {
      final updated = _scheduledPayments[index].copyWith(deleted: true);
      _scheduledPayments[index] = updated;
      await _saveData('scheduled_payments', _scheduledPayments, targetItem: updated);
    }
  }

  Future<void> recoverScheduledPayment(int id) async {
    final index = _scheduledPayments.indexWhere((s) => s.id == id);
    if (index != -1) {
      final updated = _scheduledPayments[index].copyWith(deleted: false);
      _scheduledPayments[index] = updated;
      await _saveData('scheduled_payments', _scheduledPayments, targetItem: updated);
    }
  }

  Future<void> payScheduledPayment(int id) async {
    final index = _scheduledPayments.indexWhere((s) => s.id == id);
    if (index != -1) {
      final payment = _scheduledPayments[index];
      
      final tx = DailyTransaction(
        date: DateTime.now().toIso8601String(),
        categoryId: payment.categoryId,
        itemService: payment.name,
        cost: payment.amount,
        paidAmount: payment.amount,
        cleared: true,
        accountId: payment.accountId,
        transactionType: payment.type,
        note: 'Paid scheduled: ${payment.name}',
      );
      await addTransaction(tx);

      final currentDue = _safeParseDate(payment.nextDueDate);
      DateTime nextDue;
      switch (payment.frequency) {
        case 'Daily':
          nextDue = currentDue.add(const Duration(days: 1));
          break;
        case 'Weekly':
          nextDue = currentDue.add(const Duration(days: 7));
          break;
        case 'Monthly':
          nextDue = DateTime(currentDue.year, currentDue.month + 1, currentDue.day);
          break;
        case 'Yearly':
          nextDue = DateTime(currentDue.year + 1, currentDue.month, currentDue.day);
          break;
        default:
          nextDue = DateTime(currentDue.year, currentDue.month + 1, currentDue.day);
      }

      _scheduledPayments[index] = ScheduledPayment(
        id: payment.id,
        name: payment.name,
        amount: payment.amount,
        type: payment.type,
        categoryId: payment.categoryId,
        accountId: payment.accountId,
        frequency: payment.frequency,
        nextDueDate: nextDue.toIso8601String(),
        active: payment.active,
      );

      await _saveData('scheduled_payments', _scheduledPayments);
    }
  }

  // --- Goal Methods ---
  Future<void> addGoal(Goal goal) async {
    final newGoal = Goal(
      id: goal.id ?? _generateId(),
      name: goal.name,
      targetAmount: goal.targetAmount,
      savedAmount: goal.savedAmount,
      targetDate: goal.targetDate,
      accountId: goal.accountId,
      color: goal.color,
    );
    _goals.add(newGoal);
    await _saveData('goals', _goals);
  }

  Future<void> updateGoal(Goal goal) async {
    final index = _goals.indexWhere((g) => g.id == goal.id);
    if (index != -1) {
      _goals[index] = goal;
      await _saveData('goals', _goals);
    }
  }

  Future<void> deleteGoal(int id) async {
    final index = _goals.indexWhere((g) => g.id == id);
    if (index != -1) {
      final updated = _goals[index].copyWith(deleted: true);
      _goals[index] = updated;
      await _saveData('goals', _goals, targetItem: updated);
    }
  }

  int _generateContactId() {
    int maxId = 0;
    for (var c in _contacts) {
      if (c.id != null && c.id! > maxId) {
        maxId = c.id!;
      }
    }
    return maxId + 1;
  }

  // --- Contact Methods ---
  Future<bool> addContact(Contact contact) async {
    final cleanMobile = contact.mobile.trim();
    if (cleanMobile.isNotEmpty) {
      final exists = _contacts.any((c) => !c.deleted && c.mobile.trim() == cleanMobile);
      if (exists) {
        return false; // Duplicate mobile number
      }
    }

    final newId = contact.id ?? _generateContactId();
    final newContact = Contact(
      id: newId,
      name: toTitleCase(contact.name),
      mobile: cleanMobile,
      place: toTitleCase(contact.place),
      occupation: toTitleCase(contact.occupation),
      active: contact.active,
      deleted: false,
    );
    _contacts.add(newContact);
    await _saveData('wallet_contacts', _contacts, targetItem: newContact);
    return true;
  }

  Future<bool> updateContact(Contact contact) async {
    final cleanMobile = contact.mobile.trim();
    if (cleanMobile.isNotEmpty) {
      final exists = _contacts.any((c) => !c.deleted && c.id != contact.id && c.mobile.trim() == cleanMobile);
      if (exists) {
        return false; // Duplicate mobile number
      }
    }

    final index = _contacts.indexWhere((c) => c.id == contact.id);
    if (index != -1) {
      final updated = contact.copyWith(
        name: toTitleCase(contact.name),
        mobile: cleanMobile,
        place: toTitleCase(contact.place),
        occupation: toTitleCase(contact.occupation),
      );
      _contacts[index] = updated;
      await _saveData('wallet_contacts', _contacts, targetItem: updated);
      return true;
    }
    return false;
  }

  Future<void> deleteContact(int id) async {
    final index = _contacts.indexWhere((c) => c.id == id);
    if (index != -1) {
      final updated = _contacts[index].copyWith(deleted: true);
      _contacts[index] = updated;
      await _saveData('wallet_contacts', _contacts, targetItem: updated);
    }
  }

  Future<void> toggleContactStatus(int id) async {
    final index = _contacts.indexWhere((c) => c.id == id);
    if (index != -1) {
      final updated = _contacts[index].copyWith(active: !_contacts[index].active);
      _contacts[index] = updated;
      await _saveData('wallet_contacts', _contacts, targetItem: updated);
    }
  }

  int _generateProductId() {
    int maxId = 0;
    for (var p in _products) {
      if (p.id != null && p.id! > maxId) {
        maxId = p.id!;
      }
    }
    return maxId + 1;
  }

  static List<Product> get defaultVegetablesList => [
    Product(id: 1, productName: 'Potato', localName: 'आलू (Aloo)', category: 'Vegetable', unit: 'Kg', quantity: 1, currentPrice: 30, priceDate: '2026-07-25'),
    Product(id: 2, productName: 'Tomato', localName: 'टमाटर (Tamatar)', category: 'Vegetable', unit: 'Kg', quantity: 1, currentPrice: 40, priceDate: '2026-07-25'),
    Product(id: 3, productName: 'Onion', localName: 'प्याज (Pyaz)', category: 'Vegetable', unit: 'Kg', quantity: 1, currentPrice: 35, priceDate: '2026-07-25'),
    Product(id: 4, productName: 'Garlic', localName: 'लहसुन (Lahsun)', category: 'Vegetable', unit: 'Gram', quantity: 250, currentPrice: 50, priceDate: '2026-07-25'),
    Product(id: 5, productName: 'Ginger', localName: 'अदरक (Adrak)', category: 'Vegetable', unit: 'Gram', quantity: 250, currentPrice: 30, priceDate: '2026-07-25'),
    Product(id: 6, productName: 'Spinach', localName: 'पालक (Palak)', category: 'Vegetable', unit: 'Pack', quantity: 1, currentPrice: 25, priceDate: '2026-07-25'),
    Product(id: 7, productName: 'Cauliflower', localName: 'फूलगोभी (Phool Gobi)', category: 'Vegetable', unit: 'Pcs', quantity: 1, currentPrice: 30, priceDate: '2026-07-25'),
    Product(id: 8, productName: 'Cabbage', localName: 'पत्तागोभी (Patta Gobi)', category: 'Vegetable', unit: 'Pcs', quantity: 1, currentPrice: 25, priceDate: '2026-07-25'),
    Product(id: 9, productName: 'Brinjal / Eggplant', localName: 'बैंगन (Baingan)', category: 'Vegetable', unit: 'Kg', quantity: 1, currentPrice: 40, priceDate: '2026-07-25'),
    Product(id: 10, productName: 'Lady Finger / Okra', localName: 'भिंडी (Bhindi)', category: 'Vegetable', unit: 'Kg', quantity: 1, currentPrice: 45, priceDate: '2026-07-25'),
    Product(id: 11, productName: 'Green Peas', localName: 'हरी मटर (Hari Matar)', category: 'Vegetable', unit: 'Kg', quantity: 1, currentPrice: 60, priceDate: '2026-07-25'),
    Product(id: 12, productName: 'Cucumber', localName: 'खीरा (Kheera)', category: 'Vegetable', unit: 'Kg', quantity: 1, currentPrice: 30, priceDate: '2026-07-25'),
    Product(id: 13, productName: 'Carrot', localName: 'गाजर (Gajar)', category: 'Vegetable', unit: 'Kg', quantity: 1, currentPrice: 40, priceDate: '2026-07-25'),
    Product(id: 14, productName: 'Radish', localName: 'मूली (Mooli)', category: 'Vegetable', unit: 'Kg', quantity: 1, currentPrice: 25, priceDate: '2026-07-25'),
    Product(id: 15, productName: 'Bottle Gourd', localName: 'लौकी (Lauki)', category: 'Vegetable', unit: 'Pcs', quantity: 1, currentPrice: 30, priceDate: '2026-07-25'),
    Product(id: 16, productName: 'Bitter Gourd', localName: 'करेला (Karela)', category: 'Vegetable', unit: 'Kg', quantity: 1, currentPrice: 50, priceDate: '2026-07-25'),
    Product(id: 17, productName: 'Ridge Gourd', localName: 'तरोई (Taroi)', category: 'Vegetable', unit: 'Kg', quantity: 1, currentPrice: 40, priceDate: '2026-07-25'),
    Product(id: 18, productName: 'Capsicum', localName: 'शिमला मिर्च (Shimla Mirch)', category: 'Vegetable', unit: 'Kg', quantity: 1, currentPrice: 60, priceDate: '2026-07-25'),
    Product(id: 19, productName: 'Green Chilli', localName: 'हरी मिर्च (Hari Mirch)', category: 'Vegetable', unit: 'Gram', quantity: 250, currentPrice: 20, priceDate: '2026-07-25'),
    Product(id: 20, productName: 'Lemon', localName: 'नींबू (Nimbu)', category: 'Vegetable', unit: 'Pcs', quantity: 4, currentPrice: 20, priceDate: '2026-07-25'),
    Product(id: 21, productName: 'Coriander Leaves', localName: 'हरा धनिया (Hara Dhaniya)', category: 'Vegetable', unit: 'Pack', quantity: 1, currentPrice: 15, priceDate: '2026-07-25'),
    Product(id: 22, productName: 'Mint Leaves', localName: 'पुदीना (Pudina)', category: 'Vegetable', unit: 'Pack', quantity: 1, currentPrice: 15, priceDate: '2026-07-25'),
    Product(id: 23, productName: 'Pumpkin', localName: 'कद्दू (Kaddu)', category: 'Vegetable', unit: 'Kg', quantity: 1, currentPrice: 30, priceDate: '2026-07-25'),
    Product(id: 24, productName: 'Sweet Potato', localName: 'शकरकंद (Shakarkand)', category: 'Vegetable', unit: 'Kg', quantity: 1, currentPrice: 40, priceDate: '2026-07-25'),
    Product(id: 25, productName: 'Beetroot', localName: 'चुकंदर (Chukandar)', category: 'Vegetable', unit: 'Kg', quantity: 1, currentPrice: 35, priceDate: '2026-07-25'),
    Product(id: 26, productName: 'Broccoli', localName: 'ब्रोकोली (Broccoli)', category: 'Vegetable', unit: 'Pcs', quantity: 1, currentPrice: 70, priceDate: '2026-07-25'),
    Product(id: 27, productName: 'Mushroom', localName: 'मशरूम (Mushroom)', category: 'Vegetable', unit: 'Box', quantity: 1, currentPrice: 50, priceDate: '2026-07-25'),
    Product(id: 28, productName: 'Cluster Beans', localName: 'ग्वार फली (Gwar Phali)', category: 'Vegetable', unit: 'Kg', quantity: 1, currentPrice: 45, priceDate: '2026-07-25'),
    Product(id: 29, productName: 'French Beans', localName: 'बीन्स (Beans)', category: 'Vegetable', unit: 'Kg', quantity: 1, currentPrice: 50, priceDate: '2026-07-25'),
    Product(id: 30, productName: 'Drumstick', localName: 'सहजन (Sahjan)', category: 'Vegetable', unit: 'Pcs', quantity: 1, currentPrice: 30, priceDate: '2026-07-25'),
    Product(id: 31, productName: 'Red Onion', localName: 'लाल प्याज (Lal Pyaz)', category: 'Vegetable', unit: 'Kg', quantity: 1, currentPrice: 35, priceDate: '2026-07-25'),
    Product(id: 32, productName: 'White Onion', localName: 'सफेद प्याज (Safed Pyaz)', category: 'Vegetable', unit: 'Kg', quantity: 1, currentPrice: 40, priceDate: '2026-07-25'),
    Product(id: 33, productName: 'Raw Banana', localName: 'कच्चा केला (Katcha Kela)', category: 'Vegetable', unit: 'Pcs', quantity: 4, currentPrice: 20, priceDate: '2026-07-25'),
    Product(id: 34, productName: 'Raw Papaya', localName: 'कच्चा पपीता (Katcha Papita)', category: 'Vegetable', unit: 'Kg', quantity: 1, currentPrice: 30, priceDate: '2026-07-25'),
    Product(id: 35, productName: 'Raw Mango', localName: 'कच्चा आम (Katcha Aam)', category: 'Vegetable', unit: 'Kg', quantity: 1, currentPrice: 50, priceDate: '2026-07-25'),
    Product(id: 36, productName: 'Elephant Foot Yam', localName: 'जिमीकंद / सूरन (Jimikand / Suran)', category: 'Vegetable', unit: 'Kg', quantity: 1, currentPrice: 60, priceDate: '2026-07-25'),
    Product(id: 37, productName: 'Colocasia Root', localName: 'अरबी (Arbi)', category: 'Vegetable', unit: 'Kg', quantity: 1, currentPrice: 40, priceDate: '2026-07-25'),
    Product(id: 38, productName: 'Colocasia Leaves', localName: 'अरबी के पत्ते (Arbi ke Patte)', category: 'Vegetable', unit: 'Pack', quantity: 1, currentPrice: 20, priceDate: '2026-07-25'),
    Product(id: 39, productName: 'Pointed Gourd', localName: 'परवल (Parwal)', category: 'Vegetable', unit: 'Kg', quantity: 1, currentPrice: 50, priceDate: '2026-07-25'),
    Product(id: 40, productName: 'Snake Gourd', localName: 'चिचिंडा (Chichinda)', category: 'Vegetable', unit: 'Kg', quantity: 1, currentPrice: 35, priceDate: '2026-07-25'),
    Product(id: 41, productName: 'Ivy Gourd', localName: 'कुंदरू (Kundru)', category: 'Vegetable', unit: 'Kg', quantity: 1, currentPrice: 35, priceDate: '2026-07-25'),
    Product(id: 42, productName: 'Sponge Gourd', localName: 'नेनुआ (Nenua)', category: 'Vegetable', unit: 'Kg', quantity: 1, currentPrice: 30, priceDate: '2026-07-25'),
    Product(id: 43, productName: 'Apple Gourd', localName: 'टिंडा (Tinda)', category: 'Vegetable', unit: 'Kg', quantity: 1, currentPrice: 40, priceDate: '2026-07-25'),
    Product(id: 44, productName: 'Ash Gourd', localName: 'पेठा / सफेद कद्दू (Safed Kaddu)', category: 'Vegetable', unit: 'Kg', quantity: 1, currentPrice: 25, priceDate: '2026-07-25'),
    Product(id: 45, productName: 'Flat Beans', localName: 'सेम फली (Sem Phali)', category: 'Vegetable', unit: 'Kg', quantity: 1, currentPrice: 45, priceDate: '2026-07-25'),
    Product(id: 46, productName: 'Cowpea Beans', localName: 'लोबिया फली (Lobiya Phali)', category: 'Vegetable', unit: 'Kg', quantity: 1, currentPrice: 40, priceDate: '2026-07-25'),
    Product(id: 47, productName: 'Fenugreek Leaves', localName: 'मेथी (Methi)', category: 'Vegetable', unit: 'Pack', quantity: 1, currentPrice: 20, priceDate: '2026-07-25'),
    Product(id: 48, productName: 'Mustard Leaves', localName: 'सरसों का साग (Sarson ka Saag)', category: 'Vegetable', unit: 'Pack', quantity: 1, currentPrice: 25, priceDate: '2026-07-25'),
    Product(id: 49, productName: 'Amaranth Leaves', localName: 'चौलाई (Chawli)', category: 'Vegetable', unit: 'Pack', quantity: 1, currentPrice: 20, priceDate: '2026-07-25'),
    Product(id: 50, productName: 'Curry Leaves', localName: 'कढ़ी पत्ता (Kadi Patta)', category: 'Vegetable', unit: 'Pack', quantity: 1, currentPrice: 10, priceDate: '2026-07-25'),
    Product(id: 51, productName: 'Spring Onion', localName: 'हरा प्याज (Hara Pyaz)', category: 'Vegetable', unit: 'Pack', quantity: 1, currentPrice: 30, priceDate: '2026-07-25'),
    Product(id: 52, productName: 'Red Chilli', localName: 'लाल मिर्च (Lal Mirch)', category: 'Vegetable', unit: 'Gram', quantity: 250, currentPrice: 30, priceDate: '2026-07-25'),
    Product(id: 53, productName: 'Yellow Capsicum', localName: 'पीली शिमला मिर्च (Peeli Shimla Mirch)', category: 'Vegetable', unit: 'Kg', quantity: 1, currentPrice: 120, priceDate: '2026-07-25'),
    Product(id: 54, productName: 'Red Capsicum', localName: 'लाल शिमला मिर्च (Lal Shimla Mirch)', category: 'Vegetable', unit: 'Kg', quantity: 1, currentPrice: 120, priceDate: '2026-07-25'),
    Product(id: 55, productName: 'Turnip', localName: 'शलगम (Shalgam)', category: 'Vegetable', unit: 'Kg', quantity: 1, currentPrice: 30, priceDate: '2026-07-25'),
    Product(id: 56, productName: 'Yam', localName: 'रतालू (Ratalu)', category: 'Vegetable', unit: 'Kg', quantity: 1, currentPrice: 50, priceDate: '2026-07-25'),
    Product(id: 57, productName: 'Raw Jackfruit', localName: 'कटहल (Kathal)', category: 'Vegetable', unit: 'Kg', quantity: 1, currentPrice: 60, priceDate: '2026-07-25'),
    Product(id: 58, productName: 'Baby Corn', localName: 'बेबी कॉर्न (Baby Corn)', category: 'Vegetable', unit: 'Pack', quantity: 1, currentPrice: 40, priceDate: '2026-07-25'),
    Product(id: 59, productName: 'Sweet Corn', localName: 'स्वीट कॉर्न (Sweet Corn)', category: 'Vegetable', unit: 'Pcs', quantity: 2, currentPrice: 30, priceDate: '2026-07-25'),
    Product(id: 60, productName: 'Lettuce', localName: 'सलाद पत्ता (Salad Patta)', category: 'Vegetable', unit: 'Pack', quantity: 1, currentPrice: 40, priceDate: '2026-07-25'),
    Product(id: 61, productName: 'Zucchini', localName: 'ज़ुकीनी (Zucchini)', category: 'Vegetable', unit: 'Kg', quantity: 1, currentPrice: 80, priceDate: '2026-07-25'),
    Product(id: 62, productName: 'Celery', localName: 'अजवाइन के पत्ते (Ajwain Patte)', category: 'Vegetable', unit: 'Pack', quantity: 1, currentPrice: 35, priceDate: '2026-07-25'),
    Product(id: 63, productName: 'Asparagus', localName: 'शताब्दी (Shatavari)', category: 'Vegetable', unit: 'Pack', quantity: 1, currentPrice: 150, priceDate: '2026-07-25'),
    Product(id: 64, productName: 'Red Cabbage', localName: 'लाल पत्तागोभी (Lal Patta Gobi)', category: 'Vegetable', unit: 'Pcs', quantity: 1, currentPrice: 50, priceDate: '2026-07-25'),
    Product(id: 65, productName: 'Chinese Cabbage', localName: 'चीनी पत्तागोभी (Chinese Cabbage)', category: 'Vegetable', unit: 'Pcs', quantity: 1, currentPrice: 60, priceDate: '2026-07-25'),
    Product(id: 66, productName: 'Bok Choy', localName: 'बोक चॉय (Bok Choy)', category: 'Vegetable', unit: 'Pack', quantity: 1, currentPrice: 60, priceDate: '2026-07-25'),
    Product(id: 67, productName: 'Leek', localName: 'लीक (Leek)', category: 'Vegetable', unit: 'Pack', quantity: 1, currentPrice: 50, priceDate: '2026-07-25'),
    Product(id: 68, productName: 'Shallots', localName: 'सांभर प्याज (Sambhar Pyaz)', category: 'Vegetable', unit: 'Kg', quantity: 1, currentPrice: 60, priceDate: '2026-07-25'),
    Product(id: 69, productName: 'Raw Turmeric', localName: 'कच्ची हल्दी (Katchi Haldi)', category: 'Vegetable', unit: 'Gram', quantity: 250, currentPrice: 30, priceDate: '2026-07-25'),
    Product(id: 70, productName: 'Bamboo Shoot', localName: 'बांस के करील (Kareel)', category: 'Vegetable', unit: 'Pack', quantity: 1, currentPrice: 80, priceDate: '2026-07-25'),
    Product(id: 71, productName: 'Water Chestnut', localName: 'सिंघाड़ा (Singhara)', category: 'Vegetable', unit: 'Kg', quantity: 1, currentPrice: 50, priceDate: '2026-07-25'),
    Product(id: 72, productName: 'Lotus Stem', localName: 'कमल ककड़ी (Kamal Kakdi)', category: 'Vegetable', unit: 'Kg', quantity: 1, currentPrice: 80, priceDate: '2026-07-25'),
    Product(id: 73, productName: 'Gooseberry', localName: 'आंवला (Amla)', category: 'Vegetable', unit: 'Kg', quantity: 1, currentPrice: 60, priceDate: '2026-07-25'),
    Product(id: 74, productName: 'Tamarind', localName: 'इमली (Imli)', category: 'Vegetable', unit: 'Gram', quantity: 250, currentPrice: 40, priceDate: '2026-07-25'),
    Product(id: 75, productName: 'Dill Leaves', localName: 'सोया साग (Soya Saag)', category: 'Vegetable', unit: 'Pack', quantity: 1, currentPrice: 20, priceDate: '2026-07-25'),
    Product(id: 76, productName: 'Bathua Leaves', localName: 'बथुआ (Bathua)', category: 'Vegetable', unit: 'Pack', quantity: 1, currentPrice: 20, priceDate: '2026-07-25'),
    Product(id: 77, productName: 'Knol Khol', localName: 'गांठ गोभी (Ganth Gobi)', category: 'Vegetable', unit: 'Kg', quantity: 1, currentPrice: 40, priceDate: '2026-07-25'),
    Product(id: 78, productName: 'Watercress', localName: 'जलकुंभी (Jalkumbhi)', category: 'Vegetable', unit: 'Pack', quantity: 1, currentPrice: 30, priceDate: '2026-07-25'),
    Product(id: 79, productName: 'Red Amaranth', localName: 'लाल चौलाई (Lal Chawli)', category: 'Vegetable', unit: 'Pack', quantity: 1, currentPrice: 20, priceDate: '2026-07-25'),
    Product(id: 80, productName: 'Button Mushroom', localName: 'बटन मशरूम (Button Mushroom)', category: 'Vegetable', unit: 'Box', quantity: 1, currentPrice: 50, priceDate: '2026-07-25'),
    Product(id: 81, productName: 'Oyster Mushroom', localName: 'ऑयस्टर मशरूम (Oyster Mushroom)', category: 'Vegetable', unit: 'Box', quantity: 1, currentPrice: 80, priceDate: '2026-07-25'),
    Product(id: 82, productName: 'Cherry Tomato', localName: 'चेरी टमाटर (Cherry Tamatar)', category: 'Vegetable', unit: 'Pack', quantity: 1, currentPrice: 60, priceDate: '2026-07-25'),
    Product(id: 83, productName: 'Purple Brinjal', localName: 'गोल बैंगन (Gol Baingan)', category: 'Vegetable', unit: 'Kg', quantity: 1, currentPrice: 40, priceDate: '2026-07-25'),
    Product(id: 84, productName: 'Green Brinjal', localName: 'हरा बैंगन (Hara Baingan)', category: 'Vegetable', unit: 'Kg', quantity: 1, currentPrice: 40, priceDate: '2026-07-25'),
    Product(id: 85, productName: 'Baby Potato', localName: 'छोटा आलू (Chota Aloo)', category: 'Vegetable', unit: 'Kg', quantity: 1, currentPrice: 35, priceDate: '2026-07-25'),
  ];

  static final List<Product> defaultFruitsList = [
    Product(id: 101, productName: 'Apple', localName: 'सेब (Seb)', category: 'Fruits', unit: 'Kg', quantity: 1, currentPrice: 120, priceDate: '2026-07-26'),
    Product(id: 102, productName: 'Banana', localName: 'केला (Kela)', category: 'Fruits', unit: 'Dozen', quantity: 1, currentPrice: 60, priceDate: '2026-07-26'),
    Product(id: 103, productName: 'Mango', localName: 'आम (Aam)', category: 'Fruits', unit: 'Kg', quantity: 1, currentPrice: 100, priceDate: '2026-07-26'),
    Product(id: 104, productName: 'Orange', localName: 'संतरा (Santra)', category: 'Fruits', unit: 'Kg', quantity: 1, currentPrice: 80, priceDate: '2026-07-26'),
    Product(id: 105, productName: 'Grapes', localName: 'अंगूर (Angoor)', category: 'Fruits', unit: 'Kg', quantity: 1, currentPrice: 90, priceDate: '2026-07-26'),
    Product(id: 106, productName: 'Papaya', localName: 'पपीता (Papita)', category: 'Fruits', unit: 'Kg', quantity: 1, currentPrice: 50, priceDate: '2026-07-26'),
    Product(id: 107, productName: 'Guava', localName: 'अमरूद (Amrood)', category: 'Fruits', unit: 'Kg', quantity: 1, currentPrice: 60, priceDate: '2026-07-26'),
    Product(id: 108, productName: 'Pomegranate', localName: 'अनार (Anar)', category: 'Fruits', unit: 'Kg', quantity: 1, currentPrice: 140, priceDate: '2026-07-26'),
    Product(id: 109, productName: 'Watermelon', localName: 'तरबूज (Tarbooz)', category: 'Fruits', unit: 'Pcs', quantity: 1, currentPrice: 60, priceDate: '2026-07-26'),
    Product(id: 110, productName: 'Muskmelon', localName: 'खरबूजा (Kharbooza)', category: 'Fruits', unit: 'Pcs', quantity: 1, currentPrice: 50, priceDate: '2026-07-26'),
    Product(id: 111, productName: 'Pineapple', localName: 'अनानास (Ananas)', category: 'Fruits', unit: 'Pcs', quantity: 1, currentPrice: 80, priceDate: '2026-07-26'),
    Product(id: 112, productName: 'Sweet Lime / Mosambi', localName: 'मौसमी (Mosambi)', category: 'Fruits', unit: 'Kg', quantity: 1, currentPrice: 70, priceDate: '2026-07-26'),
    Product(id: 113, productName: 'Custard Apple', localName: 'शरीफा / सीताफल (Sitafal)', category: 'Fruits', unit: 'Kg', quantity: 1, currentPrice: 100, priceDate: '2026-07-26'),
    Product(id: 114, productName: 'Sapota / Chikoo', localName: 'चीकू (Chikoo)', category: 'Fruits', unit: 'Kg', quantity: 1, currentPrice: 60, priceDate: '2026-07-26'),
    Product(id: 115, productName: 'Pear', localName: 'नाशपाती (Nashpati)', category: 'Fruits', unit: 'Kg', quantity: 1, currentPrice: 90, priceDate: '2026-07-26'),
    Product(id: 116, productName: 'Peach', localName: 'आडू (Aadoo)', category: 'Fruits', unit: 'Kg', quantity: 1, currentPrice: 120, priceDate: '2026-07-26'),
    Product(id: 117, productName: 'Plum', localName: 'आलूबुखारा (Aloo Bukhara)', category: 'Fruits', unit: 'Kg', quantity: 1, currentPrice: 140, priceDate: '2026-07-26'),
    Product(id: 118, productName: 'Kiwi', localName: 'कीवी (Kiwi)', category: 'Fruits', unit: 'Pcs', quantity: 3, currentPrice: 90, priceDate: '2026-07-26'),
    Product(id: 119, productName: 'Dragon Fruit', localName: 'ड्रैगन फ्रूट (Dragon Fruit)', category: 'Fruits', unit: 'Pcs', quantity: 1, currentPrice: 100, priceDate: '2026-07-26'),
    Product(id: 120, productName: 'Strawberry', localName: 'स्ट्रॉबेरी (Strawberry)', category: 'Fruits', unit: 'Box', quantity: 1, currentPrice: 80, priceDate: '2026-07-26'),
    Product(id: 121, productName: 'Blueberry', localName: 'ब्लूबेरी (Blueberry)', category: 'Fruits', unit: 'Box', quantity: 1, currentPrice: 150, priceDate: '2026-07-26'),
    Product(id: 122, productName: 'Blackberry', localName: 'जामुन (Jamun)', category: 'Fruits', unit: 'Kg', quantity: 1, currentPrice: 120, priceDate: '2026-07-26'),
    Product(id: 123, productName: 'Raspberry', localName: 'रसभरी (Rasbhari)', category: 'Fruits', unit: 'Box', quantity: 1, currentPrice: 100, priceDate: '2026-07-26'),
    Product(id: 124, productName: 'Lychee', localName: 'लीची (Lychee)', category: 'Fruits', unit: 'Kg', quantity: 1, currentPrice: 150, priceDate: '2026-07-26'),
    Product(id: 125, productName: 'Jackfruit (Ripe)', localName: 'पका कटहल (Paka Kathal)', category: 'Fruits', unit: 'Kg', quantity: 1, currentPrice: 80, priceDate: '2026-07-26'),
    Product(id: 126, productName: 'Wood Apple', localName: 'बेल (Bel)', category: 'Fruits', unit: 'Pcs', quantity: 1, currentPrice: 40, priceDate: '2026-07-26'),
    Product(id: 127, productName: 'Dates', localName: 'खजूर (Khajoor)', category: 'Fruits', unit: 'Kg', quantity: 1, currentPrice: 200, priceDate: '2026-07-26'),
    Product(id: 128, productName: 'Fig', localName: 'अंजीर (Anjeer)', category: 'Fruits', unit: 'Kg', quantity: 1, currentPrice: 250, priceDate: '2026-07-26'),
    Product(id: 129, productName: 'Coconut (Water)', localName: 'नारियल पानी (Nariyal Paani)', category: 'Fruits', unit: 'Pcs', quantity: 1, currentPrice: 50, priceDate: '2026-07-26'),
    Product(id: 130, productName: 'Raw Coconut', localName: 'सूखा नारियल (Sookha Nariyal)', category: 'Fruits', unit: 'Pcs', quantity: 1, currentPrice: 30, priceDate: '2026-07-26'),
    Product(id: 131, productName: 'Apricot', localName: 'खुबानी (Khubani)', category: 'Fruits', unit: 'Kg', quantity: 1, currentPrice: 180, priceDate: '2026-07-26'),
    Product(id: 132, productName: 'Cherry', localName: 'चेरी (Cherry)', category: 'Fruits', unit: 'Box', quantity: 1, currentPrice: 150, priceDate: '2026-07-26'),
    Product(id: 133, productName: 'Avocado', localName: 'एवोकैडो (Avocado)', category: 'Fruits', unit: 'Pcs', quantity: 1, currentPrice: 100, priceDate: '2026-07-26'),
    Product(id: 134, productName: 'Passion Fruit', localName: 'पैशन फ्रूट (Passion Fruit)', category: 'Fruits', unit: 'Pcs', quantity: 1, currentPrice: 60, priceDate: '2026-07-26'),
    Product(id: 135, productName: 'Star Fruit', localName: 'कम्रख (Kamrakh)', category: 'Fruits', unit: 'Kg', quantity: 1, currentPrice: 80, priceDate: '2026-07-26'),
    Product(id: 136, productName: 'Mulberry', localName: 'शहतूत (Shahtoot)', category: 'Fruits', unit: 'Box', quantity: 1, currentPrice: 60, priceDate: '2026-07-26'),
    Product(id: 137, productName: 'Green Apple', localName: 'हरा सेब (Hara Seb)', category: 'Fruits', unit: 'Kg', quantity: 1, currentPrice: 160, priceDate: '2026-07-26'),
    Product(id: 138, productName: 'Black Grapes', localName: 'काला अंगूर (Kala Angoor)', category: 'Fruits', unit: 'Kg', quantity: 1, currentPrice: 110, priceDate: '2026-07-26'),
    Product(id: 139, productName: 'Seedless Grapes', localName: 'बिना बीज के अंगूर (Seedless Angoor)', category: 'Fruits', unit: 'Kg', quantity: 1, currentPrice: 100, priceDate: '2026-07-26'),
    Product(id: 140, productName: 'Alphonso Mango', localName: 'हापुस आम (Hapus Aam)', category: 'Fruits', unit: 'Kg', quantity: 1, currentPrice: 250, priceDate: '2026-07-26'),
    Product(id: 141, productName: 'Dasheri Mango', localName: 'दशहरी आम (Dasheri Aam)', category: 'Fruits', unit: 'Kg', quantity: 1, currentPrice: 80, priceDate: '2026-07-26'),
    Product(id: 142, productName: 'Langra Mango', localName: 'लंगड़ा आम (Langra Aam)', category: 'Fruits', unit: 'Kg', quantity: 1, currentPrice: 90, priceDate: '2026-07-26'),
    Product(id: 143, productName: 'Kesar Mango', localName: 'केसर आम (Kesar Aam)', category: 'Fruits', unit: 'Kg', quantity: 1, currentPrice: 120, priceDate: '2026-07-26'),
    Product(id: 144, productName: 'Chausa Mango', localName: 'चौसा आम (Chausa Aam)', category: 'Fruits', unit: 'Kg', quantity: 1, currentPrice: 90, priceDate: '2026-07-26'),
    Product(id: 145, productName: 'Red Banana', localName: 'लाल केला (Lal Kela)', category: 'Fruits', unit: 'Dozen', quantity: 1, currentPrice: 100, priceDate: '2026-07-26'),
    Product(id: 146, productName: 'Robusta Banana', localName: 'केला (Kela)', category: 'Fruits', unit: 'Dozen', quantity: 1, currentPrice: 50, priceDate: '2026-07-26'),
    Product(id: 147, productName: 'Sweet Tamarind', localName: 'मीठी इमली (Meethi Imli)', category: 'Fruits', unit: 'Box', quantity: 1, currentPrice: 80, priceDate: '2026-07-26'),
    Product(id: 148, productName: 'Persimmon', localName: 'जापानी फल (Japani Phal)', category: 'Fruits', unit: 'Kg', quantity: 1, currentPrice: 150, priceDate: '2026-07-26'),
    Product(id: 149, productName: 'Pomelo', localName: 'चकोतरा (Chakotra)', category: 'Fruits', unit: 'Pcs', quantity: 1, currentPrice: 80, priceDate: '2026-07-26'),
    Product(id: 150, productName: 'Kinnu / Mandarin', localName: 'किन्नू (Kinnu)', category: 'Fruits', unit: 'Kg', quantity: 1, currentPrice: 60, priceDate: '2026-07-26'),
  ];

  static List<Product> get freshMasterProductList => [
    // --- Vegetables ---
    Product(id: 1, productName: 'Potato', localName: 'आलू (Aloo)', category: 'Vegetable', unit: 'Kg', quantity: 1, currentPrice: 30, oldPrice: 35, barcode: '8901030000018', qrCode: 'QR-VEG-POTATO-001', imageUrl: 'https://images.unsplash.com/photo-1518977676601-b53f82aba655?w=300', priceDate: '2026-07-30'),
    Product(id: 2, productName: 'Tomato', localName: 'टमाटर (Tamatar)', category: 'Vegetable', unit: 'Kg', quantity: 1, currentPrice: 40, oldPrice: 50, barcode: '8901030000025', qrCode: 'QR-VEG-TOMATO-002', imageUrl: 'https://images.unsplash.com/photo-1592924357228-91a4daadcfea?w=300', priceDate: '2026-07-30'),
    Product(id: 3, productName: 'Onion', localName: 'प्याज (Pyaz)', category: 'Vegetable', unit: 'Kg', quantity: 1, currentPrice: 35, oldPrice: 40, barcode: '8901030000032', qrCode: 'QR-VEG-ONION-003', imageUrl: 'https://images.unsplash.com/photo-1618512496248-a07fe83aa8cb?w=300', priceDate: '2026-07-30'),
    Product(id: 4, productName: 'Garlic', localName: 'लहसुन (Lahsun)', category: 'Vegetable', unit: 'Gram', quantity: 250, currentPrice: 50, oldPrice: 60, barcode: '8901030000049', qrCode: 'QR-VEG-GARLIC-004', imageUrl: 'https://images.unsplash.com/photo-1540148426945-6cf22a6b2383?w=300', priceDate: '2026-07-30'),
    Product(id: 5, productName: 'Ginger', localName: 'अदरक (Adrak)', category: 'Vegetable', unit: 'Gram', quantity: 250, currentPrice: 30, oldPrice: 35, barcode: '8901030000056', qrCode: 'QR-VEG-GINGER-005', imageUrl: 'https://images.unsplash.com/photo-1615485290382-441e4d049cb5?w=300', priceDate: '2026-07-30'),
    Product(id: 6, productName: 'Spinach', localName: 'पालक (Palak)', category: 'Vegetable', unit: 'Pack', quantity: 1, currentPrice: 25, oldPrice: 30, barcode: '8901030000063', qrCode: 'QR-VEG-SPINACH-006', imageUrl: 'https://images.unsplash.com/photo-1576045057995-568f588f82fb?w=300', priceDate: '2026-07-30'),
    Product(id: 7, productName: 'Cauliflower', localName: 'फूलगोभी (Phool Gobi)', category: 'Vegetable', unit: 'Pcs', quantity: 1, currentPrice: 30, oldPrice: 40, barcode: '8901030000070', qrCode: 'QR-VEG-CAULI-007', imageUrl: 'https://images.unsplash.com/photo-1568584711075-3d021a7c3ca3?w=300', priceDate: '2026-07-30'),
    Product(id: 8, productName: 'Cabbage', localName: 'पत्तागोभी (Patta Gobi)', category: 'Vegetable', unit: 'Pcs', quantity: 1, currentPrice: 25, oldPrice: 30, barcode: '8901030000087', qrCode: 'QR-VEG-CABBAGE-008', imageUrl: 'https://images.unsplash.com/photo-1603048588665-791ca8aea617?w=300', priceDate: '2026-07-30'),
    Product(id: 9, productName: 'Brinjal', localName: 'बैंगन (Baingan)', category: 'Vegetable', unit: 'Kg', quantity: 1, currentPrice: 40, oldPrice: 45, barcode: '8901030000094', qrCode: 'QR-VEG-BRINJAL-009', imageUrl: 'https://images.unsplash.com/photo-1615485290382-441e4d049cb5?w=300', priceDate: '2026-07-30'),
    Product(id: 10, productName: 'Lady Finger / Okra', localName: 'भिंडी (Bhindi)', category: 'Vegetable', unit: 'Kg', quantity: 1, currentPrice: 45, oldPrice: 50, barcode: '8901030000100', qrCode: 'QR-VEG-OKRA-010', imageUrl: 'https://images.unsplash.com/photo-1425543103986-22abb7d7e8d2?w=300', priceDate: '2026-07-30'),

    // --- Fruits ---
    Product(id: 101, productName: 'Apple', localName: 'सेब (Seb)', category: 'Fruits', unit: 'Kg', quantity: 1, currentPrice: 120, oldPrice: 140, barcode: '8901030000117', qrCode: 'QR-FRUIT-APPLE-101', imageUrl: 'https://images.unsplash.com/photo-1560806887-1e4cd0b6cbd6?w=300', priceDate: '2026-07-30'),
    Product(id: 102, productName: 'Banana', localName: 'केला (Kela)', category: 'Fruits', unit: 'Dozen', quantity: 1, currentPrice: 60, oldPrice: 70, barcode: '8901030000124', qrCode: 'QR-FRUIT-BANANA-102', imageUrl: 'https://images.unsplash.com/photo-1571771894821-ce9b6c11b08e?w=300', priceDate: '2026-07-30'),
    Product(id: 103, productName: 'Mango', localName: 'आम (Aam)', category: 'Fruits', unit: 'Kg', quantity: 1, currentPrice: 100, oldPrice: 120, barcode: '8901030000131', qrCode: 'QR-FRUIT-MANGO-103', imageUrl: 'https://images.unsplash.com/photo-1553279768-865429fa0078?w=300', priceDate: '2026-07-30'),
    Product(id: 104, productName: 'Orange', localName: 'संतरा (Santra)', category: 'Fruits', unit: 'Kg', quantity: 1, currentPrice: 80, oldPrice: 90, barcode: '8901030000148', qrCode: 'QR-FRUIT-ORANGE-104', imageUrl: 'https://images.unsplash.com/photo-1547514701-42782101795e?w=300', priceDate: '2026-07-30'),
    Product(id: 105, productName: 'Grapes', localName: 'अंगूर (Angoor)', category: 'Fruits', unit: 'Kg', quantity: 1, currentPrice: 90, oldPrice: 100, barcode: '8901030000155', qrCode: 'QR-FRUIT-GRAPES-105', imageUrl: 'https://images.unsplash.com/photo-1537640538966-79f369143f8f?w=300', priceDate: '2026-07-30'),
    Product(id: 106, productName: 'Watermelon', localName: 'तरबूज (Tarbooz)', category: 'Fruits', unit: 'Pcs', quantity: 1, currentPrice: 60, oldPrice: 75, barcode: '8901030000162', qrCode: 'QR-FRUIT-WATERMELON-106', imageUrl: 'https://images.unsplash.com/photo-1563288443-690226487e41?w=300', priceDate: '2026-07-30'),

    // --- Dairy & Bakery ---
    Product(id: 201, productName: 'Amul Taaza Milk 1L', localName: 'अमुल दूध (Amul Doodh)', category: 'Dairy & Bakery', unit: 'Pcs', quantity: 1, currentPrice: 56, oldPrice: 58, barcode: '8901262010057', qrCode: 'QR-DAIRY-AMULMILK-201', imageUrl: 'https://images.unsplash.com/photo-1550583724-b2692b85b150?w=300', priceDate: '2026-07-30'),
    Product(id: 202, productName: 'Amul Butter 100g', localName: 'अमुल मक्खन (Amul Makkhan)', category: 'Dairy & Bakery', unit: 'Pack', quantity: 1, currentPrice: 58, oldPrice: 60, barcode: '8901262020018', qrCode: 'QR-DAIRY-AMULBUTTER-202', imageUrl: 'https://images.unsplash.com/photo-1589985270826-4b7bb135bc9d?w=300', priceDate: '2026-07-30'),
    Product(id: 203, productName: 'Fresh Paneer 200g', localName: 'पनीर (Paneer)', category: 'Dairy & Bakery', unit: 'Pack', quantity: 1, currentPrice: 90, oldPrice: 95, barcode: '8901262030024', qrCode: 'QR-DAIRY-PANEER-203', imageUrl: 'https://images.unsplash.com/photo-1631452180519-c014fe946bc7?w=300', priceDate: '2026-07-30'),
    Product(id: 204, productName: 'Brown Bread', localName: 'ब्राउन ब्रेड (Brown Bread)', category: 'Dairy & Bakery', unit: 'Pack', quantity: 1, currentPrice: 45, oldPrice: 50, barcode: '8901262040030', qrCode: 'QR-DAIRY-BREAD-204', imageUrl: 'https://images.unsplash.com/photo-1509440159596-0249088772ff?w=300', priceDate: '2026-07-30'),
    Product(id: 205, productName: 'Farm Fresh Eggs (6 pcs)', localName: 'अंडे (Ande)', category: 'Dairy & Bakery', unit: 'Pack', quantity: 1, currentPrice: 42, oldPrice: 48, barcode: '8901262050046', qrCode: 'QR-DAIRY-EGGS-205', imageUrl: 'https://images.unsplash.com/photo-1516448620398-c5f44bf9f441?w=300', priceDate: '2026-07-30'),

    // --- Groceries & Staples ---
    Product(id: 301, productName: 'Fortune Basmati Rice 5kg', localName: 'बासमती चावल (Basmati Chawal)', category: 'Groceries', unit: 'Pack', quantity: 1, currentPrice: 450, oldPrice: 490, barcode: '8906007281023', qrCode: 'QR-GROC-RICE-301', imageUrl: 'https://images.unsplash.com/photo-1586201375761-83865001e31c?w=300', priceDate: '2026-07-30'),
    Product(id: 302, productName: 'Aashirvaad Atta 5kg', localName: 'गेहूं का आटा (Gehun Atta)', category: 'Groceries', unit: 'Pack', quantity: 1, currentPrice: 245, oldPrice: 260, barcode: '8901058000456', qrCode: 'QR-GROC-ATTA-302', imageUrl: 'https://images.unsplash.com/photo-1574323347407-f5e1ad6d020b?w=300', priceDate: '2026-07-30'),
    Product(id: 303, productName: 'Toor Dal 1kg', localName: 'तूर दाल / अरहर दाल (Toor Dal)', category: 'Groceries', unit: 'Kg', quantity: 1, currentPrice: 160, oldPrice: 175, barcode: '8906007281030', qrCode: 'QR-GROC-TOORDAL-303', imageUrl: 'https://images.unsplash.com/photo-1515543237350-b3eea1ec8082?w=300', priceDate: '2026-07-30'),
    Product(id: 304, productName: 'Tata Salt 1kg', localName: 'टाटा नमक (Tata Namak)', category: 'Groceries', unit: 'Pack', quantity: 1, currentPrice: 28, oldPrice: 30, barcode: '8901058000789', qrCode: 'QR-GROC-SALT-304', imageUrl: 'https://images.unsplash.com/photo-1608039829572-78524f79c4c7?w=300', priceDate: '2026-07-30'),
    Product(id: 305, productName: 'Fortune Sunflower Oil 1L', localName: 'सूरजमुखी तेल (Oil)', category: 'Groceries', unit: 'Pcs', quantity: 1, currentPrice: 140, oldPrice: 155, barcode: '8906007281047', qrCode: 'QR-GROC-OIL-305', imageUrl: 'https://images.unsplash.com/photo-1474979266404-7eaacbcd87c5?w=300', priceDate: '2026-07-30'),
  ];

  Future<void> deleteAllProducts() async {
    _products.clear();
    final db = DatabaseHelper.instance;
    await db.saveList('wallet_products', []);
    if (SyncConfig.useApiGateway || !kIsWeb) {
      try {
        await DbSyncService.clearTable('wallet_products');
      } catch (e) {
        debugPrint('Failed to clear remote wallet_products: $e');
      }
    }
    notifyListeners();
  }

  Future<void> addProductsFromCatalog(List<Product> catalogProducts) async {
    for (final prod in catalogProducts) {
      final exists = _products.any((p) => p.productName.toLowerCase() == prod.productName.toLowerCase());
      if (!exists) {
        final newId = _generateProductId();
        _products.insert(0, prod.copyWith(id: newId));
      }
    }
    await _saveData('wallet_products', _products);
  }

  // --- Product Master Methods ---
  Future<void> addProduct(Product product) async {
    final newId = product.id ?? _generateProductId();
    final newProduct = product.copyWith(
      id: newId,
      productName: toTitleCase(product.productName),
      localName: product.localName.trim(),
      appName: toTitleCase(product.appName),
    );
    _products.removeWhere((p) => p.id == newId);
    _products.insert(0, newProduct);
    await _saveData('wallet_products', _products, targetItem: newProduct);
  }

  Future<void> updateProduct(Product product) async {
    final index = _products.indexWhere((p) => p.id == product.id);
    if (index != -1) {
      final updated = product.copyWith(
        productName: toTitleCase(product.productName),
        localName: product.localName.trim(),
        appName: toTitleCase(product.appName),
      );
      _products[index] = updated;
      await _saveData('wallet_products', _products, targetItem: updated);
    }
  }

  /// Searches web for lowest price across stores (Blinkit, Zepto, Instamart, BigBasket)
  /// and updates product's minimum price, link, appName, and priceDate
  Future<bool> syncProductBestPrice(Product product) async {
    final quote = await ProductPriceSyncService.findMinimumPriceQuote(
      product.productName,
      targetQuantity: product.quantity,
      targetUnit: product.unit,
    );
    if (quote == null) return false;

    final today = DateTime.now().toIso8601String().substring(0, 10);
    final oldP = product.currentPrice > 0 ? product.currentPrice : product.oldPrice;

    final updated = product.copyWith(
      currentPrice: quote.normalizedPrice,
      oldPrice: oldP != quote.normalizedPrice ? oldP : product.oldPrice,
      appName: quote.appName,
      referenceLink: quote.link,
      priceDate: today,
    );

    await updateProduct(updated);
    return true;
  }

  /// Batch syncs best prices for all active products in catalog
  Future<int> batchSyncAllProductsBestPrices() async {
    int syncedCount = 0;
    final activeProds = _products.where((p) => p.active && !p.deleted).toList();
    for (final p in activeProds) {
      final success = await syncProductBestPrice(p);
      if (success) syncedCount++;
    }
    return syncedCount;
  }

  Future<void> toggleProductStatus(int id) async {
    final index = _products.indexWhere((p) => p.id == id);
    if (index != -1) {
      final updated = _products[index].copyWith(active: !_products[index].active);
      _products[index] = updated;
      await _saveData('wallet_products', _products, targetItem: updated);
    }
  }

  Future<void> deleteProduct(int id) async {
    final index = _products.indexWhere((p) => p.id == id);
    if (index != -1) {
      final updated = _products[index].copyWith(deleted: true);
      _products[index] = updated;
      await _saveData('wallet_products', _products, targetItem: updated);
    }
  }

  Future<void> recoverProduct(int id) async {
    final index = _products.indexWhere((p) => p.id == id);
    if (index != -1) {
      final updated = _products[index].copyWith(deleted: false);
      _products[index] = updated;
      await _saveData('wallet_products', _products, targetItem: updated);
    }
  }

  Future<void> recoverGoal(int id) async {
    final index = _goals.indexWhere((g) => g.id == id);
    if (index != -1) {
      final updated = _goals[index].copyWith(deleted: false);
      _goals[index] = updated;
      await _saveData('goals', _goals, targetItem: updated);
    }
  }

  // --- Settings Methods ---
  Future<void> setDefaultCurrency(String currency) async {
    _defaultCurrency = currency;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('default_currency', currency);
    notifyListeners();
  }

  // --- CSV Import/Export Methods ---
  String exportTransactionsToCsv() {
    final buffer = StringBuffer();
    buffer.writeln('ID,Date,Category,Type,Item/Service,Cost,Paid Amount,Cleared,Account,To Account,Tags,Note');
    for (var tx in _transactions) {
      final cat = _categories.firstWhere((c) => c.id == tx.categoryId, orElse: () => Category(name: 'Unknown', plannedAmount: 0));
      final acc = _accounts.firstWhere((a) => a.id == (tx.accountId ?? 1), orElse: () => WalletAccount(name: 'Cash', type: 'Cash', initialBalance: 0, currencySymbol: '₹', color: ''));
      final toAcc = tx.toAccountId != null 
          ? _accounts.firstWhere((a) => a.id == tx.toAccountId, orElse: () => WalletAccount(name: 'Unknown', type: 'Cash', initialBalance: 0, currencySymbol: '₹', color: ''))
          : null;
      
      final escapedItem = '"${tx.itemService.replaceAll('"', '""')}"';
      final escapedNote = '"${tx.note.replaceAll('"', '""')}"';
      final escapedTags = '"${tx.tags.join(', ').replaceAll('"', '""')}"';
      
      buffer.writeln('${tx.id},'
          '${tx.date},'
          '${cat.name},'
          '${tx.transactionType},'
          '$escapedItem,'
          '${tx.cost},'
          '${tx.paidAmount},'
          '${tx.cleared ? 1 : 0},'
          '${acc.name},'
          '${toAcc?.name ?? ""},'
          '$escapedTags,'
          '$escapedNote');
    }
    return buffer.toString();
  }

  Future<void> importTransactionsFromCsv(String csvContent) async {
    final lines = csvContent.split('\n');
    if (lines.isEmpty) return;
    
    bool headerSkipped = false;
    for (var line in lines) {
      if (line.trim().isEmpty) continue;
      if (!headerSkipped) {
        headerSkipped = true;
        continue;
      }
      
      final List<String> parts = [];
      bool inQuotes = false;
      StringBuffer currentField = StringBuffer();
      
      for (int i = 0; i < line.length; i++) {
        final char = line[i];
        if (char == '"') {
          inQuotes = !inQuotes;
        } else if (char == ',' && !inQuotes) {
          parts.add(currentField.toString().trim());
          currentField.clear();
        } else {
          currentField.write(char);
        }
      }
      parts.add(currentField.toString().trim());
      
      if (parts.length < 6) continue;
      
      try {
        final dateStr = parts[1];
        final catName = parts[2];
        final typeStr = parts[3];
        final itemStr = parts[4];
        final costVal = double.tryParse(parts[5]) ?? 0.0;
        final paidVal = parts.length > 6 ? (double.tryParse(parts[6]) ?? costVal) : costVal;
        final clearedVal = parts.length > 7 ? (parts[7] == '1' || parts[7].toLowerCase() == 'true') : true;
        final accName = parts.length > 8 ? parts[8] : 'Cash';
        final toAccName = parts.length > 9 ? parts[9] : '';
        final tagsStr = parts.length > 10 ? parts[10] : '';
        final noteStr = parts.length > 11 ? parts[11] : '';

        int catId = 1;
        final catIndex = _categories.indexWhere((c) => c.name.toLowerCase() == catName.toLowerCase());
        if (catIndex != -1) {
          catId = _categories[catIndex].id!;
        } else {
          final newCatId = _generateId();
          _categories.add(Category(id: newCatId, name: catName, plannedAmount: 0));
          await _saveData('categories', _categories);
          catId = newCatId;
        }

        int accId = 1;
        final accIndex = _accounts.indexWhere((a) => a.name.toLowerCase() == accName.toLowerCase());
        if (accIndex != -1) {
          accId = _accounts[accIndex].id!;
        } else {
          final newAccId = _generateId();
          _accounts.add(WalletAccount(id: newAccId, name: accName, type: 'Cash', initialBalance: 0.0, currencySymbol: _defaultCurrency, color: '#6366F1'));
          await _saveData('wallet_accounts', _accounts);
          accId = newAccId;
        }

        int? toAccId;
        if (toAccName.isNotEmpty) {
          final toAccIndex = _accounts.indexWhere((a) => a.name.toLowerCase() == toAccName.toLowerCase());
          if (toAccIndex != -1) {
            toAccId = _accounts[toAccIndex].id!;
          } else {
            toAccId = _generateId();
            _accounts.add(WalletAccount(id: toAccId, name: toAccName, type: 'Cash', initialBalance: 0.0, currencySymbol: _defaultCurrency, color: '#3B82F6'));
            await _saveData('wallet_accounts', _accounts);
          }
        }

        final List<String> tags = tagsStr.split(',').map((t) => t.trim()).where((t) => t.isNotEmpty).toList();

        final tx = DailyTransaction(
          id: _generateId(),
          date: dateStr.isNotEmpty ? dateStr : DateTime.now().toIso8601String(),
          categoryId: catId,
          itemService: itemStr,
          cost: costVal,
          paidAmount: paidVal,
          cleared: clearedVal,
          accountId: accId,
          toAccountId: toAccId,
          transactionType: typeStr.isNotEmpty ? typeStr : 'Expense',
          tags: tags,
          note: noteStr,
        );
        _transactions.add(tx);
      } catch (e) {
        debugPrint('Failed parsing line: $line, error: $e');
      }
    }
    await _saveData('transactions', _transactions);
  }

  // --- Assets Methods ---
  Future<void> addAsset(Asset asset) async {
    final newAsset = Asset(
      id: asset.id ?? _generateId(),
      name: asset.name,
      category: asset.category,
      quantity: asset.quantity,
      buyPrice: asset.buyPrice,
      currentPrice: asset.currentPrice,
      symbol: asset.symbol,
      dateAdded: asset.dateAdded,
    );
    _assets.add(newAsset);
    await _saveData('wallet_assets_portfolio', _assets);
    updateAssetPrices();
  }

  Future<void> updateAsset(Asset asset) async {
    final index = _assets.indexWhere((a) => a.id == asset.id);
    if (index != -1) {
      _assets[index] = asset;
      await _saveData('wallet_assets_portfolio', _assets);
      updateAssetPrices();
    }
  }

  Future<void> deleteAsset(int id) async {
    final index = _assets.indexWhere((a) => a.id == id);
    if (index != -1) {
      final updated = _assets[index].copyWith(deleted: true);
      _assets[index] = updated;
      await _saveData('wallet_assets_portfolio', _assets, targetItem: updated);
    }
  }

  Future<void> recoverAsset(int id) async {
    final index = _assets.indexWhere((a) => a.id == id);
    if (index != -1) {
      final updated = _assets[index].copyWith(deleted: false);
      _assets[index] = updated;
      await _saveData('wallet_assets_portfolio', _assets, targetItem: updated);
    }
  }

  double _estimatePriceChange(String symbol, double currentVal) {
    final rand = Random();
    final double percent = (rand.nextDouble() * 3.0) - 1.5; // -1.5% to +1.5% offline drift
    final double nextVal = currentVal * (1.0 + (percent / 100.0));
    return double.parse(nextVal.toStringAsFixed(2));
  }

  void _applyOfflineEstimates() {
    bool changed = false;
    for (int i = 0; i < _assets.length; i++) {
      final a = _assets[i];
      double nextCMP = a.currentPrice == 0.0 ? a.buyPrice : a.currentPrice;
      final estimatedPrice = _estimatePriceChange(a.symbol, nextCMP);
      if (estimatedPrice != a.currentPrice) {
        _assets[i] = Asset(
          id: a.id,
          name: a.name,
          category: a.category,
          quantity: a.quantity,
          buyPrice: a.buyPrice,
          currentPrice: estimatedPrice,
          symbol: a.symbol,
          dateAdded: a.dateAdded,
        );
        changed = true;
      }
    }
    if (changed) {
      _saveData('wallet_assets_portfolio', _assets);
    }
  }

  String mapSymbol(String symbol) {
    final sym = symbol.trim().toUpperCase();
    if (sym == 'GOLD') return 'GC=F';
    if (sym == 'SILVER') return 'SI=F';
    if (sym == 'BTC') return 'BTC-USD';
    if (sym == 'ETH') return 'ETH-USD';
    if (sym == 'SOL') return 'SOL-USD';
    
    // Automatically default standard Indian stock symbols to NSE (.NS) if currency is ₹
    if (_defaultCurrency == '₹' && RegExp(r'^[A-Z]+$').hasMatch(sym)) {
      return '$sym.NS';
    }
    return sym;
  }

  String getCurrencyIsoCode(String symbol) {
    if (symbol == '₹') return 'INR';
    if (symbol == '\$') return 'USD';
    if (symbol == '€') return 'EUR';
    if (symbol == '£') return 'GBP';
    return 'USD';
  }

  Future<double?> _fetchYahooPrice(String symbol) async {
    try {
      final cleanSymbol = symbol.trim().toUpperCase();
      final url = Uri.parse('https://query1.finance.yahoo.com/v8/finance/chart/$cleanSymbol?interval=1d&range=1d');
      final response = await http.get(
        url,
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        },
      ).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final result = json['chart']?['result']?[0];
        final price = result?['meta']?['regularMarketPrice'];
        if (price != null) {
          return (price as num).toDouble();
        }
      }
    } catch (e) {
      debugPrint('Error fetching price for $symbol: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>?> _fetchYahooPriceAndCurrency(String symbol) async {
    try {
      final cleanSymbol = symbol.trim().toUpperCase();
      final url = Uri.parse('https://query1.finance.yahoo.com/v8/finance/chart/$cleanSymbol?interval=1d&range=1d');
      final response = await http.get(
        url,
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        },
      ).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final result = json['chart']?['result']?[0];
        final price = result?['meta']?['regularMarketPrice'];
        final currency = result?['meta']?['currency'];
        if (price != null) {
          return {
            'price': (price as num).toDouble(),
            'currency': (currency ?? 'USD').toString().toUpperCase(),
          };
        }
      }
    } catch (e) {
      debugPrint('Error fetching price & currency for $symbol: $e');
    }
    return null;
  }

  Future<void> updateLiveAssetPrices() async {
    bool changed = false;
    final userCurrencyCode = getCurrencyIsoCode(_defaultCurrency);
    final Map<String, double> exchangeRates = {};

    for (int i = 0; i < _assets.length; i++) {
      final a = _assets[i];
      final mappedSym = mapSymbol(a.symbol);
      final data = await _fetchYahooPriceAndCurrency(mappedSym);
      if (data != null) {
        double rawPrice = data['price'];
        String assetCurrency = data['currency'];
        double convertedPrice = rawPrice;

        if (assetCurrency != userCurrencyCode) {
          final rateKey = '${assetCurrency}_$userCurrencyCode';
          double? rate = exchangeRates[rateKey];
          if (rate == null) {
            final rateSymbol = '$assetCurrency$userCurrencyCode=X';
            rate = await _fetchYahooPrice(rateSymbol);
            if (rate != null) {
              exchangeRates[rateKey] = rate;
            }
          }
          if (rate != null) {
            convertedPrice = rawPrice * rate;
          }
        }

        _assets[i] = Asset(
          id: a.id,
          name: a.name,
          category: a.category,
          quantity: a.quantity,
          buyPrice: a.buyPrice,
          currentPrice: double.parse(convertedPrice.toStringAsFixed(2)),
          symbol: a.symbol,
          dateAdded: a.dateAdded,
        );
        changed = true;
      }
    }

    if (changed) {
      await _saveData('wallet_assets_portfolio', _assets);
    }
  }

  /// Fetches live prices from Yahoo Finance. Falls back to offline drift estimate if network unavailable.
  Future<void> updateAssetPrices() async {
    try {
      await updateLiveAssetPrices();
    } catch (e) {
      debugPrint('Live price fetch failed (offline?). Applying drift estimate: $e');
      _applyOfflineEstimates();
    }
    notifyListeners();
  }

  double get totalPortfolioValue {
    return _assets.fold(0.0, (sum, a) => sum + a.totalCurrentValue);
  }

  double get totalPortfolioInvested {
    return _assets.fold(0.0, (sum, a) => sum + a.totalInvested);
  }

  double get totalNetWorth {
    final walletBal = totalWalletBalance;
    final portfolioVal = totalPortfolioValue;
    final loanLiabilities = loans.where((l) => l.status == 'Active').fold(0.0, (sum, l) => sum + l.balance);
    return walletBal + portfolioVal - loanLiabilities;
  }

  // --- Split Bills & Friends Methods ---
  Future<void> addFriend(String name) async {
    final trimmed = name.trim();
    if (trimmed.isNotEmpty && !_friends.contains(trimmed)) {
      _friends.add(trimmed);
      await _saveData('wallet_friends', _friends);
    }
  }

  Future<void> deleteFriend(String name) async {
    _friends.remove(name);
    _splitBills.removeWhere((b) => b.paidBy == name || b.participants.contains(name));
    
    await _saveData('wallet_friends', _friends, triggerSync: false);
    await _saveData('wallet_split_bills', _splitBills, triggerSync: false);
  }

  Future<void> addSplitBill(SplitBill bill) async {
    final newBill = SplitBill(
      id: bill.id ?? _generateId(),
      title: bill.title,
      totalAmount: bill.totalAmount,
      paidBy: bill.paidBy,
      participants: bill.participants,
      shares: bill.shares,
      date: bill.date,
    );
    _splitBills.add(newBill);
    await _saveData('wallet_split_bills', _splitBills);
  }

  Future<void> deleteSplitBill(int id) async {
    final index = _splitBills.indexWhere((b) => b.id == id);
    if (index != -1) {
      final updated = _splitBills[index].copyWith(deleted: true);
      _splitBills[index] = updated;
      await _saveData('wallet_split_bills', _splitBills, targetItem: updated);
    }
  }

  Future<void> recoverSplitBill(int id) async {
    final index = _splitBills.indexWhere((b) => b.id == id);
    if (index != -1) {
      final updated = _splitBills[index].copyWith(deleted: false);
      _splitBills[index] = updated;
      await _saveData('wallet_split_bills', _splitBills, targetItem: updated);
    }
  }

  Future<void> settleFriendDues(String friendName, double amount, int walletAccountId) async {
    final isIncome = amount > 0;
    final txCost = amount.abs();
    
    final tx = DailyTransaction(
      date: DateTime.now().toIso8601String(),
      categoryId: 1,
      itemService: isIncome ? 'Settlement from $friendName' : 'Settlement to $friendName',
      cost: txCost,
      paidAmount: txCost,
      cleared: true,
      accountId: walletAccountId,
      transactionType: isIncome ? 'Income' : 'Expense',
      tags: ['settlement', 'split'],
      note: 'Settled group balance with $friendName',
    );
    await addTransaction(tx);

    _splitBills.removeWhere((b) => 
        (b.paidBy == 'You' && b.participants.contains(friendName)) ||
        (b.paidBy == friendName && b.participants.contains('You'))
    );
    await _saveData('wallet_split_bills', _splitBills);
  }

  Map<String, double> get friendsNetBalances {
    final Map<String, double> balances = {};
    for (var f in _friends) {
      if (f == 'You') continue;
      balances[f] = 0.0;
    }

    for (var bill in _splitBills) {
      final String payer = bill.paidBy;
      
      if (payer == 'You') {
        bill.shares.forEach((person, share) {
          if (person != 'You' && balances.containsKey(person)) {
            balances[person] = (balances[person] ?? 0.0) + share;
          }
        });
      } else {
        if (bill.participants.contains('You')) {
          final yourShare = bill.shares['You'] ?? 0.0;
          if (balances.containsKey(payer)) {
            balances[payer] = (balances[payer] ?? 0.0) - yourShare;
          }
        }
      }
    }
    return balances;
  }

  // --- Dashboard Period Calculation Methods ---

  double getTotalPortfolioValue({DateTime? upToDate}) {
    return _assets
        .where((a) => upToDate == null || DateTime.tryParse(a.dateAdded)?.isAfter(upToDate) != true)
        .fold(0.0, (sum, a) => sum + a.totalCurrentValue);
  }

  double getNetWorthForPeriod(int month, int year) {
    final upTo = DateTime(year, month + 1, 0, 23, 59, 59);
    final walletBal = getTotalWalletBalance(upToDate: upTo);
    final portfolioVal = getTotalPortfolioValue(upToDate: upTo);
    final loanLiabilities = getActiveLoansForPeriod(month, year).fold(0.0, (sum, l) => sum + l.balance);
    return walletBal + portfolioVal - loanLiabilities;
  }

  List<Loan> getActiveLoansForPeriod(int month, int year) {
    final periodStart = DateTime(year, month, 1);
    final periodEnd = DateTime(year, month + 1, 0, 23, 59, 59);
    
    return _loans.where((l) {
      final start = DateTime.tryParse(l.startDate) ?? DateTime(2000);
      final end = DateTime.tryParse(l.endDate) ?? DateTime(2100);
      
      final startedBeforeOrDuring = start.isBefore(periodEnd);
      final endedAfterOrDuring = end.isAfter(periodStart) || l.status == 'Active';
      
      return startedBeforeOrDuring && endedAfterOrDuring;
    }).toList();
  }

  double getTotalEMIForPeriod(int month, int year) {
    return getActiveLoansForPeriod(month, year).fold(0.0, (sum, l) => sum + l.emi);
  }

  int getElapsedMonthsForPeriod(Investment inv, int month, int year) {
    final start = _safeParseDate(inv.startDate);
    final periodEnd = DateTime(year, month + 1, 0); 
    
    int months = (periodEnd.year - start.year) * 12 + periodEnd.month - start.month;
    if (months < 0) return 0;
    if (months > inv.tenureMonths) return inv.tenureMonths;
    return months;
  }

  bool isInvestmentActiveForPeriod(Investment inv, int month, int year) {
    final start = _safeParseDate(inv.startDate);
    final periodStart = DateTime(year, month, 1);
    final periodEnd = DateTime(year, month + 1, 0, 23, 59, 59);
    
    if (start.isAfter(periodEnd)) return false;
    
    final elapsedAtStartOfPeriod = (periodStart.year - start.year) * 12 + periodStart.month - start.month;
    if (elapsedAtStartOfPeriod >= inv.tenureMonths) return false;
    
    return true;
  }

  double getCurrentMaturityForPeriod(Investment inv, int month, int year) {
    final elapsed = getElapsedMonthsForPeriod(inv, month, year);
    final start = _safeParseDate(inv.startDate);
    final periodEnd = DateTime(year, month + 1, 0);
    if (start.isAfter(periodEnd)) return 0.0;
    return calculateMaturity(inv, elapsed);
  }

  double getTotalCurrentInvestmentsForPeriod(int month, int year) {
    return _investments
        .where((inv) => _safeParseDate(inv.startDate).isAfter(DateTime(year, month + 1, 0)) == false)
        .fold(0.0, (sum, inv) => sum + getCurrentMaturityForPeriod(inv, month, year));
  }

  double getMonthlySavingsForPeriod(int month, int year) {
    return _investments
        .where((inv) => ['RD', 'SIP', 'PPF'].contains(inv.type) && isInvestmentActiveForPeriod(inv, month, year))
        .fold(0.0, (sum, inv) => sum + inv.amount);
  }

  double calculateOdInterestForPeriod(OdAccount account, int month, int year) {
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 0, 23, 59, 59);
    
    double totalInterest = 0.0;
    
    final sortedTxs = _odTransactions
        .where((t) => t.odAccountId == account.id)
        .toList()
      ..sort((a, b) => _safeParseDate(a.date).compareTo(_safeParseDate(b.date)));
      
    for (int i = 0; i <= end.difference(start).inDays; i++) {
      DateTime day = start.add(Duration(days: i));
      
      double dayBalance = 0.0;
      for (var tx in sortedTxs) {
        if (_safeParseDate(tx.date).isAfter(day)) break;
        if (tx.type == 'Debit') {
          dayBalance += tx.amount;
        } else {
          dayBalance -= tx.amount;
        }
      }
      
      if (dayBalance > 0) {
        totalInterest += (dayBalance * account.interestRate) / (365 * 100);
      }
    }
    return totalInterest;
  }

  double getTotalOdInterestForPeriod(int month, int year) {
    return _odAccounts.fold(0.0, (sum, acc) => sum + calculateOdInterestForPeriod(acc, month, year));
  }

  List<LendBorrow> getActiveLendBorrowsForPeriod(int month, int year) {
    final periodEnd = DateTime(year, month + 1, 0, 23, 59, 59);
    return _lendBorrows.where((lb) {
      final lbDate = DateTime.tryParse(lb.date) ?? DateTime(2000);
      return !lbDate.isAfter(periodEnd);
    }).toList();
  }

  double getLendBorrowDiffForPeriod(LendBorrow lb, int month, int year) {
    final periodEnd = DateTime(year, month + 1, 0, 23, 59, 59);
    
    final lbDate = DateTime.tryParse(lb.date) ?? DateTime(2000);
    if (lbDate.isAfter(periodEnd)) return 0.0;
    
    final repaymentsSum = _repayments
        .where((r) => r.lendBorrowId == lb.id && (DateTime.tryParse(r.paymentDate)?.isAfter(periodEnd) != true))
        .fold(0.0, (sum, r) => sum + r.amount);
        
    final remaining = lb.principal - repaymentsSum;
    return remaining > 0 ? remaining : 0.0;
  }

  // --- Fuel Log Methods ---
  Future<void> addFuelLog(FuelLog log) async {
    final newLog = FuelLog(
      id: log.id ?? _generateId(),
      date: log.date,
      odometer: log.odometer,
      fuelAmount: log.fuelAmount,
      pricePerUnit: log.pricePerUnit,
      totalCost: log.totalCost,
      isFullTank: log.isFullTank,
      notes: log.notes,
    );
    _fuelLogs.add(newLog);
    await _saveData('wallet_fuel_logs', _fuelLogs, targetItem: newLog);
  }

  Future<void> updateFuelLog(FuelLog log) async {
    final index = _fuelLogs.indexWhere((item) => item.id == log.id);
    if (index != -1) {
      _fuelLogs[index] = log;
      await _saveData('wallet_fuel_logs', _fuelLogs, targetItem: log);
    }
  }

  Future<void> deleteFuelLog(int id) async {
    final index = _fuelLogs.indexWhere((item) => item.id == id);
    if (index != -1) {
      final updated = _fuelLogs[index].copyWith(deleted: true);
      _fuelLogs[index] = updated;
      await _saveData('wallet_fuel_logs', _fuelLogs, targetItem: updated);
    }
  }

  Future<void> recoverFuelLog(int id) async {
    final index = _fuelLogs.indexWhere((item) => item.id == id);
    if (index != -1) {
      final updated = _fuelLogs[index].copyWith(deleted: false);
      _fuelLogs[index] = updated;
      await _saveData('wallet_fuel_logs', _fuelLogs, targetItem: updated);
    }
  }

  // --- Vehicle Config & Car Trips Methods ---
  Future<void> saveVehicleConfig(double odometer, {bool? autoStartOnBoot}) async {
    _vehicleConfig = VehicleConfig(
      initialOdometer: odometer,
      currentOdometer: odometer,
      vehicleName: _vehicleConfig?.vehicleName ?? 'My Car',
      lastSyncTime: DateTime.now().toIso8601String(),
      autoStartOnBoot: autoStartOnBoot ?? _vehicleConfig?.autoStartOnBoot ?? true,
    );
    await _saveData('vehicle_config', [_vehicleConfig!], targetItem: _vehicleConfig);
  }

  Future<void> toggleAutoStartOnBoot(bool enabled) async {
    if (_vehicleConfig == null) return;
    _vehicleConfig = _vehicleConfig!.copyWith(autoStartOnBoot: enabled);
    await _saveData('vehicle_config', [_vehicleConfig!], targetItem: _vehicleConfig);
  }

  Future<bool> startCarTrip() async {
    if (_isTrackingTrip) return true;

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    _isTrackingTrip = true;
    _isTripActive = false;
    _liveTripDistance = 0.0;
    _liveSpeed = 0.0;
    _liveTripPath = [];
    _monitoringDistanceAccumulated = 0.0;
    _lastMovementTime = DateTime.now();
    notifyListeners();

    // Inactivity check timer (checks every 10 seconds)
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (_isTrackingTrip) {
        final lastMove = _lastMovementTime ?? DateTime.now();
        final elapsed = DateTime.now().difference(lastMove);
        if (elapsed >= const Duration(minutes: 20)) {
          stopCarTrip();
        }
      }
    });

    _gpsSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5, // update every 5 meters for better tracking resolution
      ),
    ).listen((Position position) {
      _liveSpeed = (position.speed * 3.6); // Convert m/s to km/h

      if (!_isTripActive) {
        // Standby/Monitoring mode - waiting for >50m movement
        if (_liveTripPath.isEmpty) {
          _liveTripPath.add([position.latitude, position.longitude]);
          _lastMovementTime = DateTime.now();
        } else {
          final startCoords = _liveTripPath.first;
          final distFromStart = Geolocator.distanceBetween(
            startCoords[0],
            startCoords[1],
            position.latitude,
            position.longitude,
          );

          final lastCoords = _liveTripPath.last;
          final segmentDist = Geolocator.distanceBetween(
            lastCoords[0],
            lastCoords[1],
            position.latitude,
            position.longitude,
          );

          // If segment movement is observed (greater than 2.0 meters to filter GPS noise)
          if (segmentDist > 2.0) {
            _lastMovementTime = DateTime.now();
            _monitoringDistanceAccumulated += segmentDist;
            _liveTripPath.add([position.latitude, position.longitude]);
          }

          // If cumulative or straight-line distance exceeds 50 meters
          if (_monitoringDistanceAccumulated >= 50.0 || distFromStart >= 50.0) {
            _isTripActive = true;
            _tripStartTime = DateTime.now();
            _tripStartOdometer = _vehicleConfig?.currentOdometer ?? 0.0;
            // Trip starts with the accumulated distance traveled so far
            _liveTripDistance = _monitoringDistanceAccumulated / 1000.0;
            _lastMovementTime = DateTime.now();
          }
        }
      } else {
        // Active Recording mode
        if (_liveTripPath.isNotEmpty) {
          final lastCoords = _liveTripPath.last;
          final distanceInMeters = Geolocator.distanceBetween(
            lastCoords[0],
            lastCoords[1],
            position.latitude,
            position.longitude,
          );

          // Filter noise: only count if segment distance is > 2.0m or speed > 0.5 m/s
          if (distanceInMeters > 2.0 || position.speed > 0.5) {
            _lastMovementTime = DateTime.now();
            final distanceInKm = distanceInMeters / 1000.0;
            _liveTripDistance += distanceInKm;

            if (_vehicleConfig != null) {
              _vehicleConfig = _vehicleConfig!.copyWith(
                currentOdometer: _vehicleConfig!.currentOdometer + distanceInKm,
              );
              _saveData('vehicle_config', [_vehicleConfig!]);
            }
            _liveTripPath.add([position.latitude, position.longitude]);
          }
        } else {
          _liveTripPath.add([position.latitude, position.longitude]);
        }
      }
      notifyListeners();
    });

    return true;
  }

  Future<void> stopCarTrip() async {
    if (!_isTrackingTrip) return;
    _isTrackingTrip = false;
    _inactivityTimer?.cancel();
    _inactivityTimer = null;
    _gpsSubscription?.cancel();
    _gpsSubscription = null;

    final wasActive = _isTripActive;
    _isTripActive = false;

    if (wasActive) {
      final duration = DateTime.now().difference(_tripStartTime ?? DateTime.now()).inSeconds;
      final endOdo = _vehicleConfig?.currentOdometer ?? _tripStartOdometer;

      final trip = CarTrip(
        id: _generateId(),
        date: _tripStartTime?.toIso8601String() ?? DateTime.now().toIso8601String(),
        distanceTravelled: _liveTripDistance,
        startOdometer: _tripStartOdometer,
        endOdometer: endOdo,
        gpsPath: jsonEncode(_liveTripPath),
        durationSeconds: duration,
        status: 'Completed',
      );

      _carTrips.add(trip);
      _liveSpeed = 0.0;
      await _saveData('car_trips', _carTrips, targetItem: trip);

      if (_vehicleConfig != null) {
        _vehicleConfig = _vehicleConfig!.copyWith(
          lastSyncTime: DateTime.now().toIso8601String(),
        );
        await _saveData('vehicle_config', [_vehicleConfig!], targetItem: _vehicleConfig);
      }
    } else {
      _liveSpeed = 0.0;
      notifyListeners();
    }
  }

  Future<void> deleteCarTrip(int id) async {
    final index = _carTrips.indexWhere((t) => t.id == id);
    if (index != -1) {
      final updated = _carTrips[index].copyWith(deleted: true);
      _carTrips[index] = updated;
      await _saveData('car_trips', _carTrips, targetItem: updated);
    }
  }

  Future<void> recoverCarTrip(int id) async {
    final index = _carTrips.indexWhere((t) => t.id == id);
    if (index != -1) {
      final updated = _carTrips[index].copyWith(deleted: false);
      _carTrips[index] = updated;
      await _saveData('car_trips', _carTrips, targetItem: updated);
    }
  }

  // --- P2P Wi-Fi Sync Methods ---
  Future<void> startWifiSyncHost() async {
    if (_wifiSyncServer != null) return;

    try {
      // Find local IP address
      final interfaces = await NetworkInterface.list(type: InternetAddressType.IPv4);
      for (var interface in interfaces) {
        for (var addr in interface.addresses) {
          if (!addr.isLoopback) {
            _localIpAddress = addr.address;
            break;
          }
        }
        if (_localIpAddress != null) break;
      }

      _localIpAddress ??= '127.0.0.1';

      _wifiSyncServer = await HttpServer.bind(InternetAddress.anyIPv4, 8899);
      notifyListeners();

      _wifiSyncServer!.listen((HttpRequest request) async {
        if (request.uri.path == '/sync' && request.method == 'POST') {
          try {
            final content = await utf8.decoder.bind(request).join();
            final data = jsonDecode(content) as Map<String, dynamic>;

            final otherFuelLogs = data['fuel_logs'] as List? ?? [];
            final otherCarTrips = data['car_trips'] as List? ?? [];
            final otherVehicle = data['vehicle_config'] as Map<String, dynamic>?;

            // Merge client data into host
            await mergeOfflineTelemetryData(otherFuelLogs, otherCarTrips, otherVehicle);

            // Respond with host's merged data
            final responseData = {
              'fuel_logs': _fuelLogs.map((e) => e.toMap()).toList(),
              'car_trips': _carTrips.map((e) => e.toMap()).toList(),
              'vehicle_config': _vehicleConfig?.toMap(),
            };

            request.response
              ..statusCode = HttpStatus.ok
              ..headers.contentType = ContentType.json
              ..write(jsonEncode(responseData));
          } catch (e) {
            request.response
              ..statusCode = HttpStatus.internalServerError
              ..write('Sync error: $e');
          } finally {
            await request.response.close();
          }
        } else {
          request.response
            ..statusCode = HttpStatus.notFound
            ..write('Not Found');
          await request.response.close();
        }
      });
    } catch (e) {
      debugPrint('Failed to start sync host: $e');
      _localIpAddress = null;
      _wifiSyncServer = null;
      notifyListeners();
    }
  }

  Future<void> stopWifiSyncHost() async {
    if (_wifiSyncServer == null) return;
    await _wifiSyncServer!.close(force: true);
    _wifiSyncServer = null;
    _localIpAddress = null;
    notifyListeners();
  }

  Future<bool> connectAndSyncWithWifiHost(String hostIp) async {
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 8);
    try {
      final request = await client.postUrl(Uri.parse('http://$hostIp:8899/sync'));
      request.headers.contentType = ContentType.json;

      final payload = {
        'fuel_logs': _fuelLogs.map((e) => e.toMap()).toList(),
        'car_trips': _carTrips.map((e) => e.toMap()).toList(),
        'vehicle_config': _vehicleConfig?.toMap(),
      };

      request.write(jsonEncode(payload));
      final response = await request.close();

      if (response.statusCode == HttpStatus.ok) {
        final content = await response.transform(utf8.decoder).join();
        final data = jsonDecode(content) as Map<String, dynamic>;

        final otherFuelLogs = data['fuel_logs'] as List? ?? [];
        final otherCarTrips = data['car_trips'] as List? ?? [];
        final otherVehicle = data['vehicle_config'] as Map<String, dynamic>?;

        // Merge host data into client
        await mergeOfflineTelemetryData(otherFuelLogs, otherCarTrips, otherVehicle);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Sync connection failed: $e');
      return false;
    } finally {
      client.close();
    }
  }

  Future<void> mergeOfflineTelemetryData(
    List<dynamic> otherFuelLogs,
    List<dynamic> otherCarTrips,
    Map<String, dynamic>? otherVehicleConfig,
  ) async {
    final db = DatabaseHelper.instance;

    // 1. Merge Fuel Logs
    final Map<int, FuelLog> mergedLogsMap = {
      for (var log in _fuelLogs) log.id ?? 0: log
    };
    for (var rawLog in otherFuelLogs) {
      final parsed = FuelLog.fromMap(Map<String, dynamic>.from(rawLog));
      final id = parsed.id ?? 0;
      if (id != 0 && !mergedLogsMap.containsKey(id)) {
        mergedLogsMap[id] = parsed;
      }
    }
    _fuelLogs = mergedLogsMap.values.toList()
      ..sort((a, b) => b.odometer.compareTo(a.odometer));
    await db.saveList('fuel_logs', _fuelLogs.map((e) => e.toMap()).toList());

    // 2. Merge Car Trips
    final Map<int, CarTrip> mergedTripsMap = {
      for (var trip in _carTrips) trip.id ?? 0: trip
    };
    for (var rawTrip in otherCarTrips) {
      final parsed = CarTrip.fromMap(Map<String, dynamic>.from(rawTrip));
      final id = parsed.id ?? 0;
      if (id != 0 && !mergedTripsMap.containsKey(id)) {
        mergedTripsMap[id] = parsed;
      }
    }
    _carTrips = mergedTripsMap.values.toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    await db.saveList('car_trips', _carTrips.map((e) => e.toMap()).toList());

    // 3. Merge Vehicle Odometer
    if (otherVehicleConfig != null) {
      final otherConfig = VehicleConfig.fromMap(otherVehicleConfig);
      if (_vehicleConfig == null) {
        _vehicleConfig = otherConfig;
      } else {
        // Take the highest odometer
        final maxOdo = max(_vehicleConfig!.currentOdometer, otherConfig.currentOdometer);
        _vehicleConfig = _vehicleConfig!.copyWith(
          currentOdometer: maxOdo,
          initialOdometer: min(_vehicleConfig!.initialOdometer, otherConfig.initialOdometer),
          lastSyncTime: DateTime.now().toIso8601String(),
        );
      }
      final configMap = _vehicleConfig!.toMap();
      configMap['id'] = 'default_vehicle';
      await db.saveList('vehicle_configs', [configMap]);
    }

    notifyListeners();

    // Trigger Cloud db sync if user has internet / remote connection
    if ((SyncConfig.useApiGateway || !kIsWeb) && isAuthenticated) {
      _triggerAutoSync();
    }
  }

  @override
  void dispose() {
    _gpsSubscription?.cancel();
    _inactivityTimer?.cancel();
    super.dispose();
  }

  DateTime _safeParseDate(String? dateStr, {DateTime? fallback}) {
    if (dateStr == null || dateStr.trim().isEmpty) return fallback ?? DateTime.fromMillisecondsSinceEpoch(0);
    return DateTime.tryParse(dateStr) ?? fallback ?? DateTime.fromMillisecondsSinceEpoch(0);
  }
}

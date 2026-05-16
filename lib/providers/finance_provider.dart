import 'dart:convert';
import 'package:flutter/foundation.dart' hide Category;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/category.dart';
import '../models/transaction.dart';
import '../models/loan.dart';
import '../models/income_config.dart';
import '../models/lend_borrow.dart';
import '../models/investment.dart';
import '../models/category_budget.dart';
import '../models/od_account.dart';
import '../services/db_sync_service.dart';
import 'dart:math';
class FinanceProvider with ChangeNotifier {
  String? _currentUserId;
  String? _currentUserName;
  String? get currentUserId => _currentUserId;
  String? get currentUserName => _currentUserName;
  bool get isAuthenticated => _currentUserId != null;

  List<Category> _categories = [];
  List<DailyTransaction> _transactions = [];
  List<Loan> _loans = [];
  List<IncomeConfig> _incomeConfigs = [];
  List<LendBorrow> _lendBorrows = [];
  List<Repayment> _repayments = [];
  List<Investment> _investments = [];
  List<CategoryBudget> _categoryBudgets = [];
  List<OdAccount> _odAccounts = [];
  List<OdTransaction> _odTransactions = [];

  List<Category> get categories => _categories;
  List<DailyTransaction> get transactions => _transactions;
  List<Loan> get loans => _loans;
  List<IncomeConfig> get incomeConfigs => _incomeConfigs;
  List<LendBorrow> get lendBorrows => _lendBorrows;
  List<Repayment> get repayments => _repayments;
  List<Investment> get investments => _investments;
  List<CategoryBudget> get categoryBudgets => _categoryBudgets;
  List<OdAccount> get odAccounts => _odAccounts;
  List<OdTransaction> get odTransactions => _odTransactions;

  FinanceProvider() {
    _initAuthAndLoad();
  }

  Future<void> _initAuthAndLoad() async {
    final prefs = await SharedPreferences.getInstance();
    _currentUserId = prefs.getString('user_id');
    _currentUserName = prefs.getString('user_name');
    
    if (isAuthenticated) {
      await loadAllData();
    }
    notifyListeners();
  }

  Future<void> loadAllData() async {
    if (!isAuthenticated) return;
    final prefs = await SharedPreferences.getInstance();

    final catsStr = prefs.getString('categories') ?? '[]';
    _categories = (jsonDecode(catsStr) as List).map((c) => Category.fromMap(c)).toList();

    final transStr = prefs.getString('transactions') ?? '[]';
    _transactions = (jsonDecode(transStr) as List).map((t) => DailyTransaction.fromMap(t)).toList();

    final loansStr = prefs.getString('loans') ?? '[]';
    _loans = (jsonDecode(loansStr) as List).map((l) => Loan.fromMap(l)).toList();
    _calculateDynamicLoanStats(); // Dynamically update loan stats

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

    _calculateLendBorrowStats();

    notifyListeners();

    // Auto-Sync Pull in background (only on non-web platforms)
    if (!kIsWeb) {
      try {
        await DbSyncService.pullFromDb(this);
      } catch (e) {
        debugPrint('Auto-sync failed: $e');
      }
    } else {
      debugPrint('Cloud Sync: Direct PostgreSQL connection is not supported on Web. Please use Mobile or Desktop.');
    }
  }

  Future<void> _saveData(String key, List<dynamic> items) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = jsonEncode(items.map((e) => e.toMap()).toList());
    await prefs.setString(key, jsonStr);
    notifyListeners();

    // Auto-Sync Trigger: Instantly sync after each entry or update if connection is OK
    if (!kIsWeb && isAuthenticated) {
      _triggerAutoSync();
    }
  }

  // Fire-and-forget background sync
  void _triggerAutoSync() {
    DbSyncService.pushToDb(this).then((_) {
      debugPrint('Auto-sync successful');
    }).catchError((e) {
      debugPrint('Auto-sync skipped (Offline or Connection Error): $e');
    });
  }

  Future<void> overwriteFromSync(Map<String, List<Map<String, dynamic>>> syncData) async {
    final prefs = await SharedPreferences.getInstance();

    if (syncData['categories'] != null && syncData['categories']!.isNotEmpty) {
      _categories = syncData['categories']!.map((c) => Category.fromMap(c)).toList();
      await prefs.setString('categories', jsonEncode(_categories.map((e) => e.toMap()).toList()));
    }
    if (syncData['transactions'] != null && syncData['transactions']!.isNotEmpty) {
      _transactions = syncData['transactions']!.map((t) => DailyTransaction.fromMap(t)).toList();
      await prefs.setString('transactions', jsonEncode(_transactions.map((e) => e.toMap()).toList()));
    }
    if (syncData['loans'] != null && syncData['loans']!.isNotEmpty) {
      _loans = syncData['loans']!.map((l) => Loan.fromMap(l)).toList();
      await prefs.setString('loans', jsonEncode(_loans.map((e) => e.toMap()).toList()));
    }
    if (syncData['income_config'] != null && syncData['income_config']!.isNotEmpty) {
      _incomeConfigs = syncData['income_config']!.map((i) => IncomeConfig.fromMap(i)).toList();
      await prefs.setString('income_config', jsonEncode(_incomeConfigs.map((e) => e.toMap()).toList()));
    }
    if (syncData['lend_borrows'] != null && syncData['lend_borrows']!.isNotEmpty) {
      _lendBorrows = syncData['lend_borrows']!.map((lb) => LendBorrow.fromMap(lb)).toList();
      await prefs.setString('lend_borrows', jsonEncode(_lendBorrows.map((e) => e.toMap()).toList()));
    }
    if (syncData['repayments'] != null && syncData['repayments']!.isNotEmpty) {
      _repayments = syncData['repayments']!.map((r) => Repayment.fromMap(r)).toList();
      await prefs.setString('repayments', jsonEncode(_repayments.map((e) => e.toMap()).toList()));
    }
    if (syncData['investments'] != null && syncData['investments']!.isNotEmpty) {
      _investments = syncData['investments']!.map((i) => Investment.fromMap(i)).toList();
      await prefs.setString('investments', jsonEncode(_investments.map((e) => e.toMap()).toList()));
    }
    if (syncData['category_budgets'] != null && syncData['category_budgets']!.isNotEmpty) {
      _categoryBudgets = syncData['category_budgets']!.map((i) => CategoryBudget.fromMap(i)).toList();
      await prefs.setString('category_budgets', jsonEncode(_categoryBudgets.map((e) => e.toMap()).toList()));
    }
    if (syncData['od_accounts'] != null && syncData['od_accounts']!.isNotEmpty) {
      _odAccounts = syncData['od_accounts']!.map((i) => OdAccount.fromMap(i)).toList();
      await prefs.setString('od_accounts', jsonEncode(_odAccounts.map((e) => e.toMap()).toList()));
    }
    if (syncData['od_transactions'] != null && syncData['od_transactions']!.isNotEmpty) {
      _odTransactions = syncData['od_transactions']!.map((i) => OdTransaction.fromMap(i)).toList();
      await prefs.setString('od_transactions', jsonEncode(_odTransactions.map((e) => e.toMap()).toList()));
    }

    _calculateDynamicLoanStats();
    _calculateLendBorrowStats();
    notifyListeners();
  }

  Future<void> login(String mobile, String pin) async {
    final userData = await DbSyncService.loginUser(mobile, pin);
    if (userData != null) {
      _currentUserId = userData['mobile_number'];
      _currentUserName = userData['name'];
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_id', _currentUserId!);
      await prefs.setString('user_name', _currentUserName!);
      
      await loadAllData(); // Load local data and trigger sync
      notifyListeners();
    } else {
      throw Exception('Invalid Mobile Number or PIN');
    }
  }

  Future<void> register(String name, String mobile, String pin) async {
    final success = await DbSyncService.registerUser(name, mobile, pin);
    if (success) {
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

    notifyListeners();
  }

  int _generateId() => DateTime.now().millisecondsSinceEpoch;

  void _calculateDynamicLoanStats() {
    final now = DateTime.now();
    bool changed = false;
    
    for (int i = 0; i < _loans.length; i++) {
      final l = _loans[i];
      final start = DateTime.parse(l.startDate);
      
      int completed = (now.year - start.year) * 12 + now.month - start.month;
      if (now.day < start.day) {
        completed--; // Full month hasn't passed yet
      }
      if (completed < 0) completed = 0;
      if (completed > l.tenure) completed = l.tenure;

      final paid = l.emi * completed;
      final balance = l.total - paid;
      final tenurePending = l.tenure - completed;
      final status = tenurePending <= 0 ? 'Closed' : 'Active';

      if (l.paid != paid || l.balance != balance || l.tenurePending != tenurePending || l.status != status) {
        _loans[i] = Loan(
          id: l.id, lender: l.lender, startDate: l.startDate, endDate: l.endDate,
          tenure: l.tenure, roi: l.roi, principal: l.principal, interest: l.interest,
          total: l.total, paid: paid, balance: balance, emi: l.emi,
          tenurePending: tenurePending, status: status,
        );
        changed = true;
      }
    }
    
    // We don't await because loadAllData is fast and we want to silently sync.
    if (changed) _saveData('loans', _loans);
  }

  void _calculateLendBorrowStats() {
    bool changed = false;
    for (int i = 0; i < _lendBorrows.length; i++) {
      final lb = _lendBorrows[i];
      final relatedRepayments = _repayments.where((r) => r.lendBorrowId == lb.id).toList();
      relatedRepayments.sort((a, b) => DateTime.parse(a.paymentDate).compareTo(DateTime.parse(b.paymentDate)));

      final settled = relatedRepayments.fold(0.0, (sum, r) => sum + r.amount);
      final diff = lb.principal - settled;
      final status = diff <= 0 ? 'Settled' : 'Active';
      final returnDate = relatedRepayments.isNotEmpty ? relatedRepayments.last.paymentDate : '';

      final endDate = returnDate.isNotEmpty ? DateTime.parse(returnDate) : DateTime.now();
      final start = DateTime.parse(lb.date);
      int tenure = (endDate.year - start.year) * 12 + endDate.month - start.month;
      if (endDate.day < start.day) tenure--;
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
    await _saveData('categories', _categories);
  }

  Future<void> updateCategory(Category category) async {
    final index = _categories.indexWhere((c) => c.id == category.id);
    if (index != -1) {
      _categories[index] = category;
      await _saveData('categories', _categories);
    }
  }

  Future<void> deleteCategory(int id) async {
    _categories.removeWhere((c) => c.id == id);
    await _saveData('categories', _categories);
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
    );
    _transactions.add(newTx);
    await _saveData('transactions', _transactions);
  }

  Future<void> updateTransaction(DailyTransaction tx) async {
    final index = _transactions.indexWhere((t) => t.id == tx.id);
    if (index != -1) {
      _transactions[index] = tx;
      await _saveData('transactions', _transactions);
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
    await _saveData('loans', _loans);
  }

  // --- Income Config Methods ---
  Future<void> addOrUpdateIncomeConfig(IncomeConfig config) async {
    final index = _incomeConfigs.indexWhere((c) => c.month == config.month && c.year == config.year);
    if (index != -1) {
      _incomeConfigs[index] = IncomeConfig(
        id: _incomeConfigs[index].id,
        month: config.month,
        year: config.year,
        amount: config.amount,
        isDefault: config.isDefault,
      );
    } else {
      _incomeConfigs.add(IncomeConfig(
        id: config.id ?? _generateId(),
        month: config.month,
        year: config.year,
        amount: config.amount,
        isDefault: config.isDefault,
      ));
    }
    await _saveData('income_config', _incomeConfigs);
  }

  double getMonthlyIncome(int month, int year) {
    final targetDate = DateTime(year, month);
    IncomeConfig? bestMatch;
    DateTime? bestDate;

    for (var config in _incomeConfigs) {
      final configDate = DateTime(config.year, config.month);
      if (!configDate.isAfter(targetDate)) {
        if (bestDate == null || configDate.isAfter(bestDate)) {
          bestMatch = config;
          bestDate = configDate;
        }
      }
    }
    return bestMatch?.amount ?? 0.0;
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
    if (index != -1) {
      _categoryBudgets[index] = CategoryBudget(
        id: _categoryBudgets[index].id,
        categoryId: categoryId,
        month: month,
        year: year,
        amount: amount,
      );
    } else {
      _categoryBudgets.add(CategoryBudget(
        id: _generateId(),
        categoryId: categoryId,
        month: month,
        year: year,
        amount: amount,
      ));
    }
    await _saveData('category_budgets', _categoryBudgets);
  }

  double getMonthlyExpenditure(int month, int year) {
    return _transactions.where((t) {
      final d = DateTime.parse(t.date);
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
    await _saveData('lend_borrows', _lendBorrows);
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
    await _saveData('repayments', _repayments);
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
    await _saveData('investments', _investments);
  }

  int getElapsedMonths(Investment inv) {
    final start = DateTime.parse(inv.startDate);
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
    await _saveData('od_accounts', _odAccounts);
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
    await _saveData('od_transactions', _odTransactions);
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
      lastBillingDate = DateTime(now.year, now.month, account.billingDay);
    } else {
      lastBillingDate = DateTime(now.year, now.month - 1, account.billingDay);
    }

    DateTime targetEndDate = upToBillingDate 
      ? DateTime(lastBillingDate.year, lastBillingDate.month + 1, account.billingDay) 
      : now;

    double totalInterest = 0.0;
    
    // Sort transactions by date
    final sortedTxs = _odTransactions
        .where((t) => t.odAccountId == account.id)
        .toList()
      ..sort((a, b) => DateTime.parse(a.date).compareTo(DateTime.parse(b.date)));

    // For each day from last billing date to target end date
    for (int i = 0; i <= targetEndDate.difference(lastBillingDate).inDays; i++) {
      DateTime day = lastBillingDate.add(Duration(days: i));
      
      // Calculate balance on this specific day
      double dayBalance = 0.0;
      for (var tx in sortedTxs) {
        if (DateTime.parse(tx.date).isAfter(day)) break;
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
}

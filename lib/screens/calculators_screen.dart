import 'package:flutter/material.dart';
import 'dart:math';
import 'package:provider/provider.dart';
import '../providers/finance_provider.dart';

class CalculatorsScreen extends StatefulWidget {
  const CalculatorsScreen({super.key});

  @override
  State<CalculatorsScreen> createState() => _CalculatorsScreenState();
}

class _CalculatorsScreenState extends State<CalculatorsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Financial Calculators',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, letterSpacing: -0.5),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF6366F1),
          labelColor: const Color(0xFF6366F1),
          unselectedLabelColor: Colors.white38,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(text: 'FIRE Planner', icon: Icon(Icons.local_fire_department_rounded, size: 20)),
            Tab(text: 'EMI & Prepay', icon: Icon(Icons.calculate_rounded, size: 20)),
            Tab(text: 'Debt Payoff', icon: Icon(Icons.trending_down_rounded, size: 20)),
          ],
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF080914), Color(0xFF0E111F)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: TabBarView(
          controller: _tabController,
          children: const [
            FirePlannerTab(),
            EmiCalculatorTab(),
            DebtPayoffTab(),
          ],
        ),
      ),
    );
  }
}

// -------------------------------------------------------------
// TAB 1: FIRE RETIREMENT PLANNER
// -------------------------------------------------------------
class FirePlannerTab extends StatefulWidget {
  const FirePlannerTab({super.key});

  @override
  State<FirePlannerTab> createState() => _FirePlannerTabState();
}

class _FirePlannerTabState extends State<FirePlannerTab> {
  double _currentAge = 25.0;
  double _targetAge = 50.0;
  double _currentExpenses = 500000.0; // annual expenses
  double _currentSavings = 100000.0;
  double _monthlyContribution = 20000.0;
  double _inflation = 6.0; // % inflation
  double _roiPre = 12.0; // % ROI pre-retirement
  double _roiPost = 8.0; // % ROI post-retirement

  // Output fields
  double _requiredFIRECorpus = 0.0;
  double _projectedSavingsAtRetirement = 0.0;
  bool _isFireFeasible = false;

  @override
  void initState() {
    super.initState();
    _calculateFIRE();
  }

  void _calculateFIRE() {
    final double preRoiDec = _roiPre / 100.0;
    final double postRoiDec = _roiPost / 100.0;
    final double inflationDec = _inflation / 100.0;

    final int yearsToRetire = (_targetAge - _currentAge).toInt();
    if (yearsToRetire <= 0) return;

    // 1. Calculate future expenses at retirement (adjusted for inflation)
    final double futureExpensesAtRetirement = _currentExpenses * pow(1 + inflationDec, yearsToRetire);

    // 2. Required FIRE Corpus (Safe Withdrawal Rate model)
    // SWR = post-retirement ROI - inflation. Real return = (1 + postRoi) / (1 + inflation) - 1
    final double realReturnPost = ((1 + postRoiDec) / (1 + inflationDec)) - 1;
    final double requiredCorpus = realReturnPost > 0.0001
        ? futureExpensesAtRetirement / realReturnPost 
        : futureExpensesAtRetirement * 25; // 4% SWR fallback

    // 3. Project savings to retirement
    double balance = _currentSavings;
    final double monthlyPreRoi = preRoiDec / 12;

    for (int month = 1; month <= yearsToRetire * 12; month++) {
      balance = (balance * (1 + monthlyPreRoi)) + _monthlyContribution;
    }

    setState(() {
      _requiredFIRECorpus = requiredCorpus;
      _projectedSavingsAtRetirement = balance;
      _isFireFeasible = balance >= requiredCorpus;
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<FinanceProvider>(context, listen: false);
    final curSymbol = provider.defaultCurrency;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Visual Results Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(color: const Color(0xFF6366F1).withValues(alpha: 0.25), blurRadius: 20, offset: const Offset(0, 8))
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'REQUIRED FIRE CORPUS AT RETIREMENT',
                  style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5),
                ),
                const SizedBox(height: 8),
                Text(
                  '$curSymbol${_requiredFIRECorpus.toStringAsFixed(0)}',
                  style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: -1.0),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Projected Savings', style: TextStyle(color: Colors.white70, fontSize: 11)),
                        const SizedBox(height: 2),
                        Text(
                          '$curSymbol${_projectedSavingsAtRetirement.toStringAsFixed(0)}',
                          style: TextStyle(
                            color: _isFireFeasible ? Colors.greenAccent : Colors.amberAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('Status', style: TextStyle(color: Colors.white70, fontSize: 11)),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _isFireFeasible ? Colors.green.withValues(alpha: 0.2) : Colors.amber.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _isFireFeasible ? 'ON TRACK' : 'SAVINGS GAP',
                            style: TextStyle(
                              color: _isFireFeasible ? Colors.greenAccent : Colors.amberAccent,
                              fontWeight: FontWeight.w900,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Inputs Section
          const Text(
            'RETIREMENT VARIABLES & ROI',
            style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5),
          ),
          const SizedBox(height: 10),

          // AGE SLIDERS
          _buildInputSlider(
            label: 'Current Age',
            val: _currentAge,
            min: 18.0,
            max: 70.0,
            div: 52,
            format: '${_currentAge.toInt()} yrs',
            onChanged: (val) {
              setState(() {
                _currentAge = val;
                if (_targetAge <= _currentAge) {
                  _targetAge = _currentAge + 5;
                }
                _calculateFIRE();
              });
            },
          ),
          _buildInputSlider(
            label: 'Target Retirement Age',
            val: _targetAge,
            min: _currentAge + 1,
            max: 85.0,
            div: 60,
            format: '${_targetAge.toInt()} yrs',
            onChanged: (val) {
              setState(() {
                _targetAge = val;
                _calculateFIRE();
              });
            },
          ),
          _buildInputSlider(
            label: 'Current Annual Expenses',
            val: _currentExpenses,
            min: 100000.0,
            max: 5000000.0,
            div: 49,
            format: '$curSymbol${(_currentExpenses / 1000).toStringAsFixed(0)}k',
            onChanged: (val) {
              setState(() {
                _currentExpenses = val;
                _calculateFIRE();
              });
            },
          ),
          _buildInputSlider(
            label: 'Current Retirement Savings',
            val: _currentSavings,
            min: 0.0,
            max: 10000000.0,
            div: 100,
            format: '$curSymbol${(_currentSavings / 1000).toStringAsFixed(0)}k',
            onChanged: (val) {
              setState(() {
                _currentSavings = val;
                _calculateFIRE();
              });
            },
          ),
          _buildInputSlider(
            label: 'Monthly contributions',
            val: _monthlyContribution,
            min: 0.0,
            max: 200000.0,
            div: 100,
            format: '$curSymbol${(_monthlyContribution / 1000).toStringAsFixed(0)}k/mo',
            onChanged: (val) {
              setState(() {
                _monthlyContribution = val;
                _calculateFIRE();
              });
            },
          ),
          _buildInputSlider(
            label: 'Investment Rate of Return (ROI) Pre-Retirement',
            val: _roiPre,
            min: 2.0,
            max: 25.0,
            div: 46,
            format: '${_roiPre.toStringAsFixed(1)}%',
            onChanged: (val) {
              setState(() {
                _roiPre = val;
                _calculateFIRE();
              });
            },
          ),
          _buildInputSlider(
            label: 'Post-Retirement Return',
            val: _roiPost,
            min: 2.0,
            max: 18.0,
            div: 32,
            format: '${_roiPost.toStringAsFixed(1)}%',
            onChanged: (val) {
              setState(() {
                _roiPost = val;
                _calculateFIRE();
              });
            },
          ),
          _buildInputSlider(
            label: 'Annual Inflation Rate',
            val: _inflation,
            min: 1.0,
            max: 15.0,
            div: 28,
            format: '${_inflation.toStringAsFixed(1)}%',
            onChanged: (val) {
              setState(() {
                _inflation = val;
                _calculateFIRE();
              });
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildInputSlider({
    required String label,
    required double val,
    required double min,
    required double max,
    required int div,
    required String format,
    required ValueChanged<double> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF121422),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold)),
              Text(format, style: const TextStyle(color: Color(0xFF6366F1), fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
          Slider(
            value: val,
            min: min,
            max: max,
            divisions: div,
            activeColor: const Color(0xFF6366F1),
            inactiveColor: Colors.white10,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

// -------------------------------------------------------------
// TAB 2: EMI & PREPAYMENT CALCULATOR
// -------------------------------------------------------------
class EmiCalculatorTab extends StatefulWidget {
  const EmiCalculatorTab({super.key});

  @override
  State<EmiCalculatorTab> createState() => _EmiCalculatorTabState();
}

class _EmiCalculatorTabState extends State<EmiCalculatorTab> {
  double _principal = 1000000.0;
  double _rate = 9.0;
  double _tenureMonths = 120.0; // 10 years
  double _extraPayment = 5000.0; // monthly prepayment

  double _emi = 0.0;
  double _totalInterestPayable = 0.0;
  
  double _interestSaved = 0.0;
  int _monthsSaved = 0;

  List<Map<String, dynamic>> _schedule = [];
  bool _showSchedule = false;

  @override
  void initState() {
    super.initState();
    _calculateEmi();
  }

  void _calculateEmi() {
    final double p = _principal;
    final double r = (_rate / 12.0) / 100.0;
    final int n = _tenureMonths.toInt();

    if (r == 0) {
      _emi = p / n;
      _totalInterestPayable = 0;
      return;
    }

    // Standard EMI formula: E = P * r * (1+r)^n / ((1+r)^n - 1)
    final double emiVal = (p * r * pow(1 + r, n)) / (pow(1 + r, n) - 1);
    final double totalAmount = emiVal * n;
    final double totalInterest = totalAmount - p;

    // Simulate with Prepayments
    double balance = p;
    double cumulativeInterestWithPrepay = 0.0;
    int monthsWithPrepay = 0;
    List<Map<String, dynamic>> tempSchedule = [];

    while (balance > 0.01 && monthsWithPrepay < 600) {
      monthsWithPrepay++;
      final double interestForMonth = balance * r;
      double principalForMonth = emiVal - interestForMonth;
      
      if (principalForMonth > balance) {
        principalForMonth = balance;
      }

      double prepayment = _extraPayment;
      if (balance - principalForMonth < prepayment) {
        prepayment = balance - principalForMonth;
      }

      final double startBalance = balance;
      balance = balance - principalForMonth - prepayment;
      if (balance < 0) balance = 0;

      cumulativeInterestWithPrepay += interestForMonth;

      // Save first 12 months for amortization table
      if (tempSchedule.length < 24) {
        tempSchedule.add({
          'month': monthsWithPrepay,
          'start': startBalance,
          'interest': interestForMonth,
          'principal': principalForMonth,
          'prepay': prepayment,
          'end': balance,
        });
      }
    }

    setState(() {
      _emi = emiVal;
      _totalInterestPayable = totalInterest;

      _interestSaved = max(0.0, totalInterest - cumulativeInterestWithPrepay);
      _monthsSaved = max(0, n - monthsWithPrepay);
      _schedule = tempSchedule;
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<FinanceProvider>(context, listen: false);
    final curSymbol = provider.defaultCurrency;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // EMI Result Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF121422),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            ),
            child: Column(
              children: [
                const Text('MONTHLY EMI PAYMENT', style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                const SizedBox(height: 8),
                Text(
                  '$curSymbol${_emi.toStringAsFixed(0)}',
                  style: const TextStyle(color: Color(0xFF6366F1), fontSize: 32, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Divider(color: Colors.white.withValues(alpha: 0.06)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Normal Interest', style: TextStyle(color: Colors.white38, fontSize: 10)),
                        const SizedBox(height: 2),
                        Text('$curSymbol${_totalInterestPayable.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('Interest Saved', style: TextStyle(color: Colors.white38, fontSize: 10)),
                        const SizedBox(height: 2),
                        Text('$curSymbol${_interestSaved.toStringAsFixed(0)}', style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 13)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Original Tenure', style: TextStyle(color: Colors.white38, fontSize: 10)),
                        const SizedBox(height: 2),
                        Text('${_tenureMonths.toInt()} months', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('Months Saved', style: TextStyle(color: Colors.white38, fontSize: 10)),
                        const SizedBox(height: 2),
                        Text('$_monthsSaved months faster', style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 13)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Inputs
          const Text(
            'LOAN PARAMETERS & PREPAYMENTS',
            style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5),
          ),
          const SizedBox(height: 10),

          _buildSlider(
            label: 'Principal Amount',
            val: _principal,
            min: 50000.0,
            max: 20000000.0,
            div: 100,
            format: '$curSymbol${(_principal / 1000).toStringAsFixed(0)}k',
            onChanged: (val) {
              setState(() {
                _principal = val;
                _calculateEmi();
              });
            },
          ),
          _buildSlider(
            label: 'Interest Rate (ROI)',
            val: _rate,
            min: 2.0,
            max: 20.0,
            div: 36,
            format: '${_rate.toStringAsFixed(1)}%',
            onChanged: (val) {
              setState(() {
                _rate = val;
                _calculateEmi();
              });
            },
          ),
          _buildSlider(
            label: 'Tenure (Months)',
            val: _tenureMonths,
            min: 12.0,
            max: 360.0,
            div: 58,
            format: '${_tenureMonths.toInt()} mo (${(_tenureMonths / 12).toStringAsFixed(1)} yrs)',
            onChanged: (val) {
              setState(() {
                _tenureMonths = val;
                _calculateEmi();
              });
            },
          ),
          _buildSlider(
            label: 'Extra Monthly Prepayment',
            val: _extraPayment,
            min: 0.0,
            max: 100000.0,
            div: 100,
            format: '$curSymbol${(_extraPayment / 1000).toStringAsFixed(0)}k/mo',
            onChanged: (val) {
              setState(() {
                _extraPayment = val;
                _calculateEmi();
              });
            },
          ),

          const SizedBox(height: 16),

          // Amortization Schedule Toggle
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              title: const Text('View 2-Year Amortization Schedule', style: TextStyle(color: Color(0xFF6366F1), fontSize: 12, fontWeight: FontWeight.bold)),
              trailing: Icon(_showSchedule ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: const Color(0xFF6366F1)),
              onExpansionChanged: (val) => setState(() => _showSchedule = val),
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columnSpacing: 16,
                    columns: const [
                      DataColumn(label: Text('Mo', style: TextStyle(color: Colors.white70, fontSize: 11))),
                      DataColumn(label: Text('Interest', style: TextStyle(color: Colors.white70, fontSize: 11))),
                      DataColumn(label: Text('Principal', style: TextStyle(color: Colors.white70, fontSize: 11))),
                      DataColumn(label: Text('Prepay', style: TextStyle(color: Colors.white70, fontSize: 11))),
                      DataColumn(label: Text('Bal End', style: TextStyle(color: Colors.white70, fontSize: 11))),
                    ],
                    rows: _schedule.map((row) {
                      return DataRow(cells: [
                        DataCell(Text('#${row['month']}', style: const TextStyle(color: Colors.white54, fontSize: 11))),
                        DataCell(Text('$curSymbol${(row['interest'] as double).toStringAsFixed(0)}', style: const TextStyle(color: Colors.redAccent, fontSize: 11))),
                        DataCell(Text('$curSymbol${(row['principal'] as double).toStringAsFixed(0)}', style: const TextStyle(color: Colors.greenAccent, fontSize: 11))),
                        DataCell(Text('$curSymbol${(row['prepay'] as double).toStringAsFixed(0)}', style: const TextStyle(color: Colors.cyanAccent, fontSize: 11))),
                        DataCell(Text('$curSymbol${(row['end'] as double).toStringAsFixed(0)}', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold))),
                      ]);
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildSlider({
    required String label,
    required double val,
    required double min,
    required double max,
    required int div,
    required String format,
    required ValueChanged<double> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF121422),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold)),
              Text(format, style: const TextStyle(color: Color(0xFF6366F1), fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
          Slider(
            value: val,
            min: min,
            max: max,
            divisions: div,
            activeColor: const Color(0xFF6366F1),
            inactiveColor: Colors.white10,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

// -------------------------------------------------------------
// TAB 3: DEBT PAYOFF PLANNER (SNOWBALL VS AVALANCHE)
// -------------------------------------------------------------
class DebtPayoffTab extends StatefulWidget {
  const DebtPayoffTab({super.key});

  @override
  State<DebtPayoffTab> createState() => _DebtPayoffTabState();
}

class _DebtPayoffTabState extends State<DebtPayoffTab> {
  // Local list of active debts
  final List<Map<String, dynamic>> _debts = [
    {'name': 'Credit Card 1', 'balance': 50000.0, 'rate': 36.0, 'min': 2500.0},
    {'name': 'Personal Loan', 'balance': 200000.0, 'rate': 12.0, 'min': 5000.0},
    {'name': 'Car Loan', 'balance': 400000.0, 'rate': 8.5, 'min': 8000.0},
  ];

  double _extraBudget = 10000.0;
  String _payoffMethod = 'Avalanche'; // 'Avalanche' or 'Snowball'

  // Results
  int _monthsToPayoff = 0;
  double _totalInterestPaid = 0.0;
  @override
  void initState() {
    super.initState();
    _simulatePayoff();
  }

  void _simulatePayoff() {
    // 1. Clone debts
    List<Map<String, dynamic>> simDebts = _debts.map((d) => {
      'name': d['name'],
      'balance': d['balance'] as double,
      'rate': d['rate'] as double,
      'min': d['min'] as double,
    }).toList();

    // Calculate total minimums
    final totalMinimums = simDebts.fold(0.0, (sum, d) => sum + (d['min'] as double));
    final totalMonthlyBudget = _extraBudget + totalMinimums;

    int month = 0;
    double cumulativeInterest = 0.0;

    // Simulate month-by-month
    while (simDebts.any((d) => d['balance'] > 0) && month < 360) {
      month++;
      
      // Calculate monthly interest accrual first
      for (var d in simDebts) {
        if (d['balance'] > 0) {
          final interest = d['balance'] * ((d['rate'] / 12) / 100);
          d['balance'] += interest;
          cumulativeInterest += interest;
        }
      }

      // Sort according to selected strategy
      if (_payoffMethod == 'Snowball') {
        // Snowball: lowest balance first
        simDebts.sort((a, b) {
          if (a['balance'] <= 0) return 1;
          if (b['balance'] <= 0) return -1;
          return (a['balance'] as double).compareTo(b['balance'] as double);
        });
      } else {
        // Avalanche: highest interest rate first
        simDebts.sort((a, b) {
          if (a['balance'] <= 0) return 1;
          if (b['balance'] <= 0) return -1;
          return (b['rate'] as double).compareTo(a['rate'] as double);
        });
      }

      // Distribute minimum payments and extra budget
      double paidMinimums = 0.0;
      
      // 1. Pay minimums
      for (var d in simDebts) {
        if (d['balance'] > 0) {
          final minPayment = min(d['balance'] as double, d['min'] as double);
          d['balance'] -= minPayment;
          paidMinimums += minPayment;
        }
      }

      // Roll over the difference to extra pool
      double extraPool = totalMonthlyBudget - paidMinimums;
      if (extraPool < 0) extraPool = 0.0;

      // 2. Dump extra pool to the targeted debt (first active in list)
      for (var d in simDebts) {
        if (d['balance'] > 0 && extraPool > 0) {
          final extraPayment = min(d['balance'] as double, extraPool);
          d['balance'] -= extraPayment;
          extraPool -= extraPayment;
        }
      }
    }

    setState(() {
      _monthsToPayoff = month;
      _totalInterestPaid = cumulativeInterest;
    });
  }

  void _showAddDebtDialog() {
    String name = '';
    double balance = 0.0;
    double rate = 0.0;
    double minPayment = 0.0;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final monthlyInterest = balance * ((rate / 12) / 100);
            final isNegativeAmortization = balance > 0 && rate > 0 && minPayment > 0 && minPayment <= monthlyInterest;

            return AlertDialog(
              backgroundColor: const Color(0xFF121422),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
              title: const Text('Add Active Debt Account', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: const InputDecoration(labelText: 'Debt Name (e.g. Credit Card)', labelStyle: TextStyle(color: Colors.white54, fontSize: 12)),
                      onChanged: (val) => setDialogState(() => name = val),
                    ),
                    TextField(
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: const InputDecoration(labelText: 'Outstanding Balance', labelStyle: TextStyle(color: Colors.white54, fontSize: 12)),
                      onChanged: (val) => setDialogState(() => balance = double.tryParse(val) ?? 0.0),
                    ),
                    TextField(
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: const InputDecoration(labelText: 'Interest Rate % (APR)', labelStyle: TextStyle(color: Colors.white54, fontSize: 12)),
                      onChanged: (val) => setDialogState(() => rate = double.tryParse(val) ?? 0.0),
                    ),
                    TextField(
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: const InputDecoration(labelText: 'Minimum Monthly Payment', labelStyle: TextStyle(color: Colors.white54, fontSize: 12)),
                      onChanged: (val) => setDialogState(() => minPayment = double.tryParse(val) ?? 0.0),
                    ),
                    if (isNegativeAmortization) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          'Warning: Minimum payment (\$${minPayment.toStringAsFixed(2)}) is less than or equal to monthly accrued interest (\$${monthlyInterest.toStringAsFixed(2)}). This debt will grow indefinitely (negative amortization).',
                          style: const TextStyle(color: Colors.redAccent, fontSize: 11),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: Colors.white38))),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366F1)),
                  onPressed: () {
                    if (name.isNotEmpty && balance > 0) {
                      setState(() {
                        _debts.add({'name': name, 'balance': balance, 'rate': rate, 'min': minPayment});
                        _simulatePayoff();
                      });
                      Navigator.pop(ctx);
                    }
                  },
                  child: const Text('Add', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<FinanceProvider>(context, listen: false);
    final curSymbol = provider.defaultCurrency;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Visual Simulation Outcomes
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF121422),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: _payoffMethod == 'Avalanche' ? Colors.cyanAccent.withValues(alpha: 0.3) : Colors.greenAccent.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('DEBT-FREE TIMELINE', style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                    ToggleButtons(
                      borderRadius: BorderRadius.circular(10),
                      isSelected: [_payoffMethod == 'Avalanche', _payoffMethod == 'Snowball'],
                      fillColor: const Color(0xFF6366F1).withValues(alpha: 0.2),
                      selectedBorderColor: const Color(0xFF6366F1),
                      selectedColor: Colors.white,
                      color: Colors.white38,
                      constraints: const BoxConstraints(minWidth: 80, minHeight: 30),
                      children: const [
                        Text('AVALANCHE', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900)),
                        Text('SNOWBALL', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900)),
                      ],
                      onPressed: (index) {
                        setState(() {
                          _payoffMethod = index == 0 ? 'Avalanche' : 'Snowball';
                          _simulatePayoff();
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Payoff Duration', style: TextStyle(color: Colors.white38, fontSize: 10)),
                        const SizedBox(height: 2),
                        Text('$_monthsToPayoff months', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('Total Interest Paid', style: TextStyle(color: Colors.white38, fontSize: 10)),
                        const SizedBox(height: 2),
                        Text('$curSymbol${_totalInterestPaid.toStringAsFixed(0)}', style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 20)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  _payoffMethod == 'Avalanche' 
                      ? '• Avalanche prioritizes debts with the highest interest rate first, mathematically saving you the most interest.'
                      : '• Snowball prioritizes debts with the smallest balances first, building psychological momentum as accounts close.',
                  style: const TextStyle(color: Colors.white30, fontSize: 10, fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Payoff Accelerator Inputs
          const Text('PAYOFF ACCELERATOR', style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF121422),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Extra Monthly Payment Budget', style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold)),
                    Text('$curSymbol${(_extraBudget / 1000).toStringAsFixed(0)}k/mo', style: const TextStyle(color: Color(0xFF6366F1), fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
                Slider(
                  value: _extraBudget,
                  min: 0.0,
                  max: 100000.0,
                  divisions: 50,
                  activeColor: const Color(0xFF6366F1),
                  inactiveColor: Colors.white10,
                  onChanged: (val) {
                    setState(() {
                      _extraBudget = val;
                      _simulatePayoff();
                    });
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Active Debts List
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('ACTIVE DEBTS', style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('ADD DEBT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900)),
                onPressed: _showAddDebtDialog,
              )
            ],
          ),
          const SizedBox(height: 10),

          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _debts.length,
            itemBuilder: (context, idx) {
              final d = _debts[idx];
              return Dismissible(
                key: ValueKey(d['name']),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (_) {
                  setState(() {
                    _debts.removeAt(idx);
                    _simulatePayoff();
                  });
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF121422),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(d['name']!, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                          const SizedBox(height: 2),
                          Text('Min Payment: $curSymbol${(d['min'] as double).toStringAsFixed(0)}/mo', style: const TextStyle(color: Colors.white30, fontSize: 10)),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('$curSymbol${(d['balance'] as double).toStringAsFixed(0)}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                          const SizedBox(height: 2),
                          Text('Interest: ${d['rate']}% APR', style: const TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}

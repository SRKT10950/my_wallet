import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/finance_provider.dart';
import '../models/fuel_log.dart';

class FuelLogScreen extends StatefulWidget {
  const FuelLogScreen({super.key});

  @override
  State<FuelLogScreen> createState() => _FuelLogScreenState();
}

class _FuelLogScreenState extends State<FuelLogScreen> {
  void _showAddFuelLogModal(BuildContext context, {FuelLog? fuelLog}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AddFuelLogSheet(fuelLog: fuelLog),
    );
  }

  double? _calculateAvgMileage(List<FuelLog> logs) {
    final sorted = List<FuelLog>.from(logs)..sort((a, b) => a.odometer.compareTo(b.odometer));
    if (sorted.length < 2) return null;

    int firstFullIdx = sorted.indexWhere((l) => l.isFullTank);
    int lastFullIdx = sorted.lastIndexWhere((l) => l.isFullTank);
    if (firstFullIdx == -1 || lastFullIdx == -1 || firstFullIdx == lastFullIdx) return null;

    double totalDistance = sorted[lastFullIdx].odometer - sorted[firstFullIdx].odometer;
    double totalFuel = 0.0;
    for (int k = firstFullIdx + 1; k <= lastFullIdx; k++) {
      totalFuel += sorted[k].fuelAmount;
    }

    if (totalFuel <= 0 || totalDistance <= 0) return null;
    return totalDistance / totalFuel;
  }

  double? _calculateCostPerKm(List<FuelLog> logs) {
    if (logs.length < 2) return null;
    final sorted = List<FuelLog>.from(logs)..sort((a, b) => a.odometer.compareTo(b.odometer));
    double span = sorted.last.odometer - sorted.first.odometer;
    if (span <= 0) return null;
    double totalCost = logs.fold(0.0, (sum, l) => sum + l.totalCost);
    return totalCost / span;
  }

  double? _calculateLogMileage(FuelLog log, List<FuelLog> allLogs) {
    if (!log.isFullTank) return null;
    final sorted = List<FuelLog>.from(allLogs)..sort((a, b) => a.odometer.compareTo(b.odometer));
    final index = sorted.indexWhere((l) => l.id == log.id);
    if (index <= 0) return null;

    int prevFullIdx = -1;
    for (int k = index - 1; k >= 0; k--) {
      if (sorted[k].isFullTank) {
        prevFullIdx = k;
        break;
      }
    }
    if (prevFullIdx == -1) return null;

    double dist = log.odometer - sorted[prevFullIdx].odometer;
    double fuel = 0.0;
    for (int k = prevFullIdx + 1; k <= index; k++) {
      fuel += sorted[k].fuelAmount;
    }

    if (fuel <= 0 || dist <= 0) return null;
    return dist / fuel;
  }

  double? _calculateDistanceTraveled(FuelLog log, List<FuelLog> allLogs) {
    final sorted = List<FuelLog>.from(allLogs)..sort((a, b) => a.odometer.compareTo(b.odometer));
    final index = sorted.indexWhere((l) => l.id == log.id);
    if (index <= 0) return null;
    final dist = log.odometer - sorted[index - 1].odometer;
    return dist > 0 ? dist : null;
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<FinanceProvider>(context);
    final logs = provider.fuelLogs;
    final curSymbol = provider.defaultCurrency;

    // Sort logs latest first for list display
    final displayLogs = List<FuelLog>.from(logs)..sort((a, b) => b.odometer.compareTo(a.odometer));

    final avgMileage = _calculateAvgMileage(logs);
    final costPerKm = _calculateCostPerKm(logs);
    final totalCost = logs.fold(0.0, (sum, l) => sum + l.totalCost);
    final totalFuel = logs.fold(0.0, (sum, l) => sum + l.fuelAmount);

    // Group expenses by Month for bar chart
    final Map<String, double> monthlyExpenses = {};
    for (var log in logs) {
      try {
        final date = DateTime.tryParse(log.date) ?? DateTime.now();
        final key = DateFormat('MMM yy').format(date);
        monthlyExpenses[key] = (monthlyExpenses[key] ?? 0.0) + log.totalCost;
      } catch (_) {}
    }
    final sortedMonths = monthlyExpenses.keys.toList()
      ..sort((a, b) {
        // Sort chronologically by parsing back
        final format = DateFormat('MMM yy');
        return format.parse(a).compareTo(format.parse(b));
      });

    final maxMonthlyExpense = monthlyExpenses.values.fold(0.0, (max, val) => val > max ? val : max);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Petrol & Mileage Log'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF080914), Color(0xFF0E111F)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Stats Row
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            title: 'Avg Mileage',
                            value: avgMileage != null ? '${avgMileage.toStringAsFixed(2)} km/L' : 'N/A',
                            sub: 'Full-to-Full',
                            color: const Color(0xFF10B981),
                            icon: Icons.local_gas_station_rounded,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            title: 'Cost per km',
                            value: costPerKm != null ? '$curSymbol${costPerKm.toStringAsFixed(2)}' : 'N/A',
                            sub: 'Odometer Span',
                            color: Colors.orangeAccent,
                            icon: Icons.speed_rounded,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            title: 'Total Spent',
                            value: '$curSymbol${totalCost.toStringAsFixed(0)}',
                            sub: 'Refueling costs',
                            color: Colors.lightBlueAccent,
                            icon: Icons.payments_rounded,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            title: 'Total Fuel',
                            value: '${totalFuel.toStringAsFixed(1)} L',
                            sub: 'Total litres',
                            color: Colors.pinkAccent,
                            icon: Icons.opacity_rounded,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Monthly Expenses Bar Chart
                    if (sortedMonths.isNotEmpty) ...[
                      const Text(
                        'Monthly Fuel Expenses',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 12),
                      Card(
                        color: Colors.white.withValues(alpha: 0.04),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: SizedBox(
                            height: 130,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: sortedMonths.map((month) {
                                final amt = monthlyExpenses[month]!;
                                final ratio = maxMonthlyExpense > 0 ? amt / maxMonthlyExpense : 0.0;
                                return Expanded(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Tooltip(
                                        message: '$curSymbol${amt.toStringAsFixed(0)}',
                                        triggerMode: TooltipTriggerMode.tap,
                                        child: Container(
                                          height: (ratio * 75).clamp(4.0, 75.0),
                                          margin: const EdgeInsets.symmetric(horizontal: 6),
                                          decoration: BoxDecoration(
                                            gradient: const LinearGradient(
                                              colors: [Colors.orangeAccent, Colors.redAccent],
                                              begin: Alignment.topCenter,
                                              end: Alignment.bottomCenter,
                                            ),
                                            borderRadius: BorderRadius.circular(4),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.orangeAccent.withValues(alpha: 0.2),
                                                blurRadius: 4,
                                                offset: const Offset(0, 2),
                                              )
                                            ],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        month,
                                        style: const TextStyle(fontSize: 10, color: Colors.grey),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    const Text(
                      'Refueling History',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 12),

                    if (displayLogs.isEmpty)
                      const Card(
                        color: Colors.transparent,
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 40.0),
                          child: Center(
                            child: Text(
                              'No refuels logged yet.',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: displayLogs.length,
                        itemBuilder: (context, idx) {
                          final log = displayLogs[idx];
                          final logDate = DateTime.tryParse(log.date) ?? DateTime.now();
                          final mileage = _calculateLogMileage(log, logs);
                          final distance = _calculateDistanceTraveled(log, logs);

                          return Card(
                            color: Colors.white.withValues(alpha: 0.03),
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            child: ListTile(
                              onTap: () => _showAddFuelLogModal(context, fuelLog: log),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              title: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    DateFormat('MMM dd, yyyy').format(logDate),
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    '$curSymbol${log.totalCost.toStringAsFixed(0)}',
                                    style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white),
                                  ),
                                ],
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Odo: ${log.odometer.toStringAsFixed(0)} km${distance != null ? " (+${distance.toStringAsFixed(0)} km)" : ""} | Added: ${log.fuelAmount.toStringAsFixed(1)} L',
                                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                                        ),
                                        Text(
                                          '$curSymbol${log.pricePerUnit.toStringAsFixed(2)}/L',
                                          style: const TextStyle(color: Colors.white60, fontSize: 12),
                                        ),
                                      ],
                                    ),
                                    if (log.notes.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        log.notes,
                                        style: const TextStyle(color: Colors.grey, fontSize: 11, fontStyle: FontStyle.italic),
                                      ),
                                    ],
                                    const SizedBox(height: 6),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              log.isFullTank ? Icons.local_gas_station_rounded : Icons.opacity_rounded,
                                              size: 14,
                                              color: log.isFullTank ? const Color(0xFF10B981) : Colors.orangeAccent,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              log.isFullTank ? 'Full Tank' : 'Partial Tank',
                                              style: TextStyle(
                                                color: log.isFullTank ? const Color(0xFF10B981) : Colors.orangeAccent,
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (mileage != null)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF10B981).withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              '${mileage.toStringAsFixed(2)} km/L',
                                              style: const TextStyle(
                                                color: Color(0xFF10B981),
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddFuelLogModal(context),
        backgroundColor: Colors.orangeAccent,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add),
        label: const Text('Add Refuel', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String sub,
    required Color color,
    required IconData icon,
  }) {
    return Card(
      color: Colors.white.withValues(alpha: 0.04),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                Icon(icon, size: 16, color: color),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 4),
            Text(sub, style: const TextStyle(color: Colors.white30, fontSize: 10)),
          ],
        ),
      ),
    );
  }
}

class AddFuelLogSheet extends StatefulWidget {
  final FuelLog? fuelLog;
  const AddFuelLogSheet({super.key, this.fuelLog});

  @override
  State<AddFuelLogSheet> createState() => _AddFuelLogSheetState();
}

class _AddFuelLogSheetState extends State<AddFuelLogSheet> {
  final _formKey = GlobalKey<FormState>();
  final _odoController = TextEditingController();
  final _amountController = TextEditingController();
  final _priceController = TextEditingController();
  final _costController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isFullTank = true;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    if (widget.fuelLog != null) {
      _odoController.text = widget.fuelLog!.odometer.toStringAsFixed(0);
      _amountController.text = widget.fuelLog!.fuelAmount.toStringAsFixed(1);
      _priceController.text = widget.fuelLog!.pricePerUnit.toStringAsFixed(2);
      _costController.text = widget.fuelLog!.totalCost.toStringAsFixed(0);
      _notesController.text = widget.fuelLog!.notes;
      _isFullTank = widget.fuelLog!.isFullTank;
      _selectedDate = DateTime.parse(widget.fuelLog!.date);
    }

    _amountController.addListener(_calculateCost);
    _priceController.addListener(_calculateCost);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _priceController.dispose();
    _odoController.dispose();
    _costController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _calculateCost() {
    final amt = double.tryParse(_amountController.text);
    final prc = double.tryParse(_priceController.text);
    if (amt != null && prc != null) {
      _costController.text = (amt * prc).toStringAsFixed(0);
    }
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final provider = Provider.of<FinanceProvider>(context, listen: false);
      final odo = double.parse(_odoController.text);
      final amt = double.parse(_amountController.text);
      final prc = double.parse(_priceController.text);
      final cost = double.parse(_costController.text);

      final isEdit = widget.fuelLog != null;
      final updated = FuelLog(
        id: isEdit ? widget.fuelLog!.id : null,
        date: _selectedDate.toIso8601String(),
        odometer: odo,
        fuelAmount: amt,
        pricePerUnit: prc,
        totalCost: cost,
        isFullTank: _isFullTank,
        notes: _notesController.text,
      );

      if (isEdit) {
        provider.updateFuelLog(updated);
      } else {
        provider.addFuelLog(updated);
      }
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.fuelLog != null;
    final provider = Provider.of<FinanceProvider>(context);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        top: 24,
        left: 24,
        right: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isEdit ? 'Edit Refueling' : 'New Refueling Log',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _odoController,
                decoration: const InputDecoration(
                  labelText: 'Odometer (km)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Required';
                  final num = double.tryParse(v);
                  if (num == null || num <= 0) return 'Must be positive';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _amountController,
                      decoration: const InputDecoration(
                        labelText: 'Fuel Added (L)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Required';
                        final num = double.tryParse(v);
                        if (num == null || num <= 0) return 'Must be positive';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _priceController,
                      decoration: const InputDecoration(
                        labelText: 'Price / Litre (₹)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Required';
                        final num = double.tryParse(v);
                        if (num == null || num <= 0) return 'Must be positive';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _costController,
                decoration: const InputDecoration(
                  labelText: 'Total Cost (₹)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Required';
                  final num = double.tryParse(v);
                  if (num == null || num <= 0) return 'Must be positive';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes (gas station, location...)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              SwitchListTile(
                title: const Text('Full Tank Refuel'),
                subtitle: const Text('Turn off if partial tank refueling'),
                value: _isFullTank,
                onChanged: (val) => setState(() => _isFullTank = val),
                contentPadding: EdgeInsets.zero,
                activeThumbColor: Colors.orangeAccent,
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Date: ${DateFormat('yyyy-MM-dd').format(_selectedDate)}'),
                trailing: const Icon(Icons.calendar_today, color: Colors.orangeAccent),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2101),
                  );
                  if (picked != null) setState(() => _selectedDate = picked);
                },
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  if (isEdit) ...[
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Colors.redAccent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Delete Log'),
                              content: const Text('Are you sure you want to delete this refueling log?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    provider.deleteFuelLog(widget.fuelLog!.id!);
                                    Navigator.pop(ctx);
                                    Navigator.pop(context);
                                  },
                                  child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
                                ),
                              ],
                            ),
                          );
                        },
                        icon: const Icon(Icons.delete),
                        label: const Text('Delete', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.orangeAccent,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _submit,
                      child: Text(
                        isEdit ? 'Update Log' : 'Save Log',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

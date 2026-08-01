class LendBorrow {
  final int? id;
  final String name;
  final String type; // 'Lend' or 'Borrow'
  final String date;
  final int tenure; // in months
  final double principal;
  final String returnDate; // auto-calculated
  final double settled; // auto-calculated
  final double diff; // auto-calculated
  final String status; // 'Active' or 'Settled'
  final bool deleted;

  LendBorrow({
    this.id,
    required this.name,
    required this.type,
    required this.date,
    required this.tenure,
    required this.principal,
    this.returnDate = '',
    this.settled = 0.0,
    this.diff = 0.0,
    this.status = 'Active',
    this.deleted = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'date': date,
      'tenure': tenure,
      'principal': principal,
      'returnDate': returnDate,
      'settled': settled,
      'diff': diff,
      'status': status,
      'deleted': deleted ? 1 : 0,
    };
  }

  DateTime? get computedDueDate {
    if (returnDate.isNotEmpty) {
      final parsed = DateTime.tryParse(returnDate);
      if (parsed != null) return parsed;
    }
    if (tenure > 0) {
      final start = DateTime.tryParse(date);
      if (start != null) {
        return DateTime(start.year, start.month + tenure, start.day);
      }
    }
    return null;
  }

  bool get isOverdue {
    if (status == 'Settled' || diff <= 0) return false;
    final due = computedDueDate;
    if (due == null) return false;
    final today = DateTime.now();
    final startOfToday = DateTime(today.year, today.month, today.day);
    final startOfDue = DateTime(due.year, due.month, due.day);
    return startOfToday.isAfter(startOfDue);
  }

  bool get isDueSoon {
    if (status == 'Settled' || diff <= 0 || isOverdue) return false;
    final due = computedDueDate;
    if (due == null) return false;
    final today = DateTime.now();
    final startOfToday = DateTime(today.year, today.month, today.day);
    final startOfDue = DateTime(due.year, due.month, due.day);
    final diffDays = startOfDue.difference(startOfToday).inDays;
    return diffDays >= 0 && diffDays <= 7;
  }

  bool get isPartiallyPaid {
    return status == 'Active' && settled > 0 && diff > 0;
  }

  String get displayStatus {
    if (status == 'Settled' || diff <= 0) return 'Settled';
    if (isOverdue) return 'Overdue';
    if (isDueSoon) return 'Due Soon';
    if (isPartiallyPaid) return 'Partially Paid';
    return 'Active';
  }

  factory LendBorrow.fromMap(Map<String, dynamic> map) {
    return LendBorrow(
      id: map['id'] is int ? map['id'] : int.tryParse(map['id']?.toString() ?? ''),
      name: map['name'],
      type: map['type'],
      date: map['date'],
      tenure: (map['tenure'] ?? 0) is int ? map['tenure'] : (int.tryParse(map['tenure']?.toString() ?? '') ?? 0),
      principal: (map['principal'] as num).toDouble(),
      returnDate: map['returnDate'] ?? '',
      settled: (map['settled'] ?? 0.0 as num).toDouble(),
      diff: (map['diff'] ?? 0.0 as num).toDouble(),
      status: map['status'] ?? 'Active',
      deleted: map['deleted'] == 1 || map['deleted'] == true || map['deleted'] == 'true',
    );
  }

  LendBorrow copyWith({
    int? id,
    String? name,
    String? type,
    String? date,
    int? tenure,
    double? principal,
    String? returnDate,
    double? settled,
    double? diff,
    String? status,
    bool? deleted,
  }) {
    return LendBorrow(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      date: date ?? this.date,
      tenure: tenure ?? this.tenure,
      principal: principal ?? this.principal,
      returnDate: returnDate ?? this.returnDate,
      settled: settled ?? this.settled,
      diff: diff ?? this.diff,
      status: status ?? this.status,
      deleted: deleted ?? this.deleted,
    );
  }
}

class Repayment {
  final int? id;
  final int lendBorrowId;
  final String name;
  final String paymentDate;
  final double amount;
  final String method; // 'Cash', 'UPI', 'Bank Transfer'
  final bool deleted;

  Repayment({
    this.id,
    required this.lendBorrowId,
    required this.name,
    required this.paymentDate,
    required this.amount,
    required this.method,
    this.deleted = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'lendBorrowId': lendBorrowId,
      'name': name,
      'paymentDate': paymentDate,
      'amount': amount,
      'method': method,
      'deleted': deleted ? 1 : 0,
    };
  }

  factory Repayment.fromMap(Map<String, dynamic> map) {
    return Repayment(
      id: map['id'] is int ? map['id'] : int.tryParse(map['id']?.toString() ?? ''),
      lendBorrowId: map['lendBorrowId'] is int ? map['lendBorrowId'] : (int.tryParse(map['lendBorrowId']?.toString() ?? '') ?? 0),
      name: map['name'],
      paymentDate: map['paymentDate'],
      amount: (map['amount'] as num).toDouble(),
      method: map['method'],
      deleted: map['deleted'] == 1 || map['deleted'] == true || map['deleted'] == 'true',
    );
  }

  Repayment copyWith({
    int? id,
    int? lendBorrowId,
    String? name,
    String? paymentDate,
    double? amount,
    String? method,
    bool? deleted,
  }) {
    return Repayment(
      id: id ?? this.id,
      lendBorrowId: lendBorrowId ?? this.lendBorrowId,
      name: name ?? this.name,
      paymentDate: paymentDate ?? this.paymentDate,
      amount: amount ?? this.amount,
      method: method ?? this.method,
      deleted: deleted ?? this.deleted,
    );
  }
}


class Loan {
  final int? id;
  final String lender;
  final String startDate;
  final String endDate;
  final int tenure;
  final double roi;
  final double principal;
  final double interest;
  final double total;
  final double paid;
  final double balance;
  final double emi;
  final int tenurePending;
  final String status;
  final bool deleted;

  Loan({
    this.id,
    required this.lender,
    required this.startDate,
    required this.endDate,
    required this.tenure,
    required this.roi,
    required this.principal,
    required this.interest,
    required this.total,
    required this.paid,
    required this.balance,
    required this.emi,
    required this.tenurePending,
    required this.status,
    this.deleted = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'lender': lender,
      'startDate': startDate,
      'endDate': endDate,
      'tenure': tenure,
      'roi': roi,
      'principal': principal,
      'interest': interest,
      'total': total,
      'paid': paid,
      'balance': balance,
      'emi': emi,
      'tenurePending': tenurePending,
      'status': status,
      'deleted': deleted ? 1 : 0,
    };
  }

  factory Loan.fromMap(Map<String, dynamic> map) {
    return Loan(
      id: map['id'] is int ? map['id'] : int.tryParse(map['id']?.toString() ?? ''),
      lender: map['lender'],
      startDate: map['startDate'],
      endDate: map['endDate'],
      tenure: (map['tenure'] ?? 0) is int ? map['tenure'] : (int.tryParse(map['tenure']?.toString() ?? '') ?? 0),
      roi: (map['roi'] ?? 0.0).toDouble(),
      principal: (map['principal'] ?? 0.0).toDouble(),
      interest: (map['interest'] ?? 0.0).toDouble(),
      total: (map['total'] ?? 0.0).toDouble(),
      paid: (map['paid'] ?? 0.0).toDouble(),
      balance: (map['balance'] ?? 0.0).toDouble(),
      emi: (map['emi'] ?? 0.0).toDouble(),
      tenurePending: (map['tenurePending'] ?? 0) is int ? map['tenurePending'] : (int.tryParse(map['tenurePending']?.toString() ?? '') ?? 0),
      status: map['status'],
      deleted: map['deleted'] == 1 || map['deleted'] == true || map['deleted'] == 'true',
    );
  }

  Loan copyWith({
    int? id,
    String? lender,
    String? startDate,
    String? endDate,
    int? tenure,
    double? roi,
    double? principal,
    double? interest,
    double? total,
    double? paid,
    double? balance,
    double? emi,
    int? tenurePending,
    String? status,
    bool? deleted,
  }) {
    return Loan(
      id: id ?? this.id,
      lender: lender ?? this.lender,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      tenure: tenure ?? this.tenure,
      roi: roi ?? this.roi,
      principal: principal ?? this.principal,
      interest: interest ?? this.interest,
      total: total ?? this.total,
      paid: paid ?? this.paid,
      balance: balance ?? this.balance,
      emi: emi ?? this.emi,
      tenurePending: tenurePending ?? this.tenurePending,
      status: status ?? this.status,
      deleted: deleted ?? this.deleted,
    );
  }
}


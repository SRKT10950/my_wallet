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
    };
  }

  factory Loan.fromMap(Map<String, dynamic> map) {
    return Loan(
      id: map['id'],
      lender: map['lender'],
      startDate: map['startDate'],
      endDate: map['endDate'],
      tenure: map['tenure'],
      roi: map['roi'],
      principal: map['principal'],
      interest: map['interest'],
      total: map['total'],
      paid: map['paid'],
      balance: map['balance'],
      emi: map['emi'],
      tenurePending: map['tenurePending'],
      status: map['status'],
    );
  }
}

class FuelLog {
  final int? id;
  final String date;
  final double odometer;
  final double fuelAmount;
  final double pricePerUnit;
  final double totalCost;
  final bool isFullTank;
  final String notes;
  final bool deleted;

  FuelLog({
    this.id,
    required this.date,
    required this.odometer,
    required this.fuelAmount,
    required this.pricePerUnit,
    required this.totalCost,
    this.isFullTank = true,
    this.notes = '',
    this.deleted = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date,
      'odometer': odometer,
      'fuelAmount': fuelAmount,
      'pricePerUnit': pricePerUnit,
      'totalCost': totalCost,
      'isFullTank': isFullTank ? 1 : 0,
      'notes': notes,
      'deleted': deleted ? 1 : 0,
    };
  }

  factory FuelLog.fromMap(Map<String, dynamic> map) {
    return FuelLog(
      id: map['id'] is int ? map['id'] : int.tryParse(map['id']?.toString() ?? ''),
      date: map['date'] ?? '',
      odometer: (map['odometer'] as num?)?.toDouble() ?? 0.0,
      fuelAmount: (map['fuelAmount'] as num?)?.toDouble() ?? 0.0,
      pricePerUnit: (map['pricePerUnit'] as num?)?.toDouble() ?? 0.0,
      totalCost: (map['totalCost'] as num?)?.toDouble() ?? 0.0,
      isFullTank: map['isFullTank'] == 1 || map['isFullTank'] == true,
      notes: map['notes'] ?? '',
      deleted: map['deleted'] == 1 || map['deleted'] == true || map['deleted'] == 'true',
    );
  }

  FuelLog copyWith({
    int? id,
    String? date,
    double? odometer,
    double? fuelAmount,
    double? pricePerUnit,
    double? totalCost,
    bool? isFullTank,
    String? notes,
    bool? deleted,
  }) {
    return FuelLog(
      id: id ?? this.id,
      date: date ?? this.date,
      odometer: odometer ?? this.odometer,
      fuelAmount: fuelAmount ?? this.fuelAmount,
      pricePerUnit: pricePerUnit ?? this.pricePerUnit,
      totalCost: totalCost ?? this.totalCost,
      isFullTank: isFullTank ?? this.isFullTank,
      notes: notes ?? this.notes,
      deleted: deleted ?? this.deleted,
    );
  }
}


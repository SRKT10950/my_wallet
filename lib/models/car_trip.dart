class CarTrip {
  final int? id;
  final String date;
  final double distanceTravelled;
  final double startOdometer;
  final double endOdometer;
  final String gpsPath; // JSON encoded list of [lat, lng]
  final int durationSeconds;
  final String status; // 'Active' or 'Completed'
  final bool deleted;

  CarTrip({
    this.id,
    required this.date,
    required this.distanceTravelled,
    required this.startOdometer,
    required this.endOdometer,
    required this.gpsPath,
    required this.durationSeconds,
    this.status = 'Completed',
    this.deleted = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date,
      'distanceTravelled': distanceTravelled,
      'startOdometer': startOdometer,
      'endOdometer': endOdometer,
      'gpsPath': gpsPath,
      'durationSeconds': durationSeconds,
      'status': status,
      'deleted': deleted ? 1 : 0,
    };
  }

  factory CarTrip.fromMap(Map<String, dynamic> map) {
    return CarTrip(
      id: map['id'] != null ? int.tryParse(map['id'].toString()) : null,
      date: map['date'] ?? '',
      distanceTravelled: (map['distanceTravelled'] as num?)?.toDouble() ?? 0.0,
      startOdometer: (map['startOdometer'] as num?)?.toDouble() ?? 0.0,
      endOdometer: (map['endOdometer'] as num?)?.toDouble() ?? 0.0,
      gpsPath: map['gpsPath'] ?? '[]',
      durationSeconds: (map['durationSeconds'] as num?)?.toInt() ?? 0,
      status: map['status'] ?? 'Completed',
      deleted: map['deleted'] == 1 || map['deleted'] == true || map['deleted'] == 'true',
    );
  }

  CarTrip copyWith({
    int? id,
    String? date,
    double? distanceTravelled,
    double? startOdometer,
    double? endOdometer,
    String? gpsPath,
    int? durationSeconds,
    String? status,
    bool? deleted,
  }) {
    return CarTrip(
      id: id ?? this.id,
      date: date ?? this.date,
      distanceTravelled: distanceTravelled ?? this.distanceTravelled,
      startOdometer: startOdometer ?? this.startOdometer,
      endOdometer: endOdometer ?? this.endOdometer,
      gpsPath: gpsPath ?? this.gpsPath,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      status: status ?? this.status,
      deleted: deleted ?? this.deleted,
    );
  }
}


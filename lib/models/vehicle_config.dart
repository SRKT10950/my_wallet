class VehicleConfig {
  final double initialOdometer;
  final double currentOdometer;
  final String vehicleName;
  final String lastSyncTime;
  final bool autoStartOnBoot;
  final bool deleted;

  VehicleConfig({
    required this.initialOdometer,
    required this.currentOdometer,
    this.vehicleName = 'My Car',
    this.lastSyncTime = '',
    this.autoStartOnBoot = true,
    this.deleted = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'initialOdometer': initialOdometer,
      'currentOdometer': currentOdometer,
      'vehicleName': vehicleName,
      'lastSyncTime': lastSyncTime,
      'autoStartOnBoot': autoStartOnBoot,
      'deleted': deleted ? 1 : 0,
    };
  }

  factory VehicleConfig.fromMap(Map<String, dynamic> map) {
    final rawAutoStart = map['autoStartOnBoot'];
    bool parsedAutoStart = true;
    if (rawAutoStart is bool) {
      parsedAutoStart = rawAutoStart;
    } else if (rawAutoStart is num) {
      parsedAutoStart = rawAutoStart.toInt() != 0;
    } else if (rawAutoStart != null) {
      parsedAutoStart = rawAutoStart.toString().toLowerCase() == 'true' || rawAutoStart.toString() == '1';
    }
    return VehicleConfig(
      initialOdometer: (map['initialOdometer'] as num?)?.toDouble() ?? 0.0,
      currentOdometer: (map['currentOdometer'] as num?)?.toDouble() ?? 0.0,
      vehicleName: map['vehicleName'] ?? 'My Car',
      lastSyncTime: map['lastSyncTime'] ?? '',
      autoStartOnBoot: parsedAutoStart,
      deleted: map['deleted'] == 1 || map['deleted'] == true || map['deleted'] == 'true',
    );
  }

  VehicleConfig copyWith({
    double? initialOdometer,
    double? currentOdometer,
    String? vehicleName,
    String? lastSyncTime,
    bool? autoStartOnBoot,
    bool? deleted,
  }) {
    return VehicleConfig(
      initialOdometer: initialOdometer ?? this.initialOdometer,
      currentOdometer: currentOdometer ?? this.currentOdometer,
      vehicleName: vehicleName ?? this.vehicleName,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      autoStartOnBoot: autoStartOnBoot ?? this.autoStartOnBoot,
      deleted: deleted ?? this.deleted,
    );
  }
}


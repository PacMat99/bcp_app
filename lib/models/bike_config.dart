class BikeConfig {
  final BikeType bikeType;
  final double? forkTravel; // mm
  final double? shockTravel; // mm

  BikeConfig({
    required this.bikeType,
    this.forkTravel,
    this.shockTravel,
  });

  Map<String, dynamic> toJson() {
    return {
      'bike_type': bikeType.name,
      if (forkTravel != null) 'fork_travel': forkTravel,
      if (shockTravel != null) 'shock_travel': shockTravel,
    };
  }

  factory BikeConfig.fromJson(Map<String, dynamic> json) {
    return BikeConfig(
      bikeType: BikeType.values.firstWhere(
        (e) => e.name == json['bike_type'],
        orElse: () => BikeType.rigid,
      ),
      forkTravel: json['fork_travel'],
      shockTravel: json['shock_travel'],
    );
  }

  BikeConfig copyWith({
    BikeType? bikeType,
    double? frontWheelSize,
    double? rearWheelSize,
    double? forkTravel,
    double? shockTravel,
  }) {
    return BikeConfig(
      bikeType: bikeType ?? this.bikeType,
      forkTravel: forkTravel ?? this.forkTravel,
      shockTravel: shockTravel ?? this.shockTravel,
    );
  }
}

enum BikeType {
  rigid,
  hardtail,
  fullSuspension,
}

extension BikeTypeExtension on BikeType {
  String get displayName {
    switch (this) {
      case BikeType.rigid:
        return 'Rigid';
      case BikeType.hardtail:
        return 'Hardtail';
      case BikeType.fullSuspension:
        return 'Full Suspension';
    }
  }
}

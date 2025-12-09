class WheelConfig {
  final String rimModel;
  final RimMaterial rimMaterial;
  final TireConfig frontTire;
  final TireConfig rearTire;

  WheelConfig({
    required this.rimModel,
    required this.rimMaterial,
    required this.frontTire,
    required this.rearTire,
  });

  Map<String, dynamic> toJson() {
    return {
      'rim_model': rimModel,
      'rim_material': rimMaterial.name,
      'front_tire': frontTire.toJson(),
      'rear_tire': rearTire.toJson(),
    };
  }

  factory WheelConfig.fromJson(Map<String, dynamic> json) {
    return WheelConfig(
      rimModel: json['rim_model'] ?? '',
      rimMaterial: RimMaterial.values.firstWhere(
        (e) => e.name == json['rim_material'],
        orElse: () => RimMaterial.aluminum,
      ),
      frontTire: TireConfig.fromJson(json['front_tire'] ?? {}),
      rearTire: TireConfig.fromJson(json['rear_tire'] ?? {}),
    );
  }

  WheelConfig copyWith({
    String? rimModel,
    RimMaterial? rimMaterial,
    TireConfig? frontTire,
    TireConfig? rearTire,
  }) {
    return WheelConfig(
      rimModel: rimModel ?? this.rimModel,
      rimMaterial: rimMaterial ?? this.rimMaterial,
      frontTire: frontTire ?? this.frontTire,
      rearTire: rearTire ?? this.rearTire,
    );
  }
}

class TireConfig {
  final String model;
  final double size; // pollici
  final TireSetup setup;
  final double pressure; // psi
  final PressureUnit pressureUnit;

  TireConfig({
    required this.model,
    required this.size,
    required this.setup,
    this.pressure = 25.0,
    this.pressureUnit = PressureUnit.psi,
  });

  Map<String, dynamic> toJson() {
    return {
      'model': model,
      'size_inches': size,
      'setup': setup.name,
      'pressure': pressure,
      'pressure_unit': pressureUnit.name,
    };
  }

  factory TireConfig.fromJson(Map<String, dynamic> json) {
    return TireConfig(
      model: json['model'] ?? '',
      size: json['size_inches']?.toDouble() ?? 29.0,
      setup: TireSetup.values.firstWhere(
        (e) => e.name == json['setup'],
        orElse: () => TireSetup.tubeless,
      ),
      pressure: json['pressure']?.toDouble() ?? 25.0,
      pressureUnit: PressureUnit.values.firstWhere(
        (e) => e.name == json['pressure_unit'],
        orElse: () => PressureUnit.psi,
      ),
    );
  }

  TireConfig copyWith({
    String? model,
    double? size,
    TireSetup? setup,
    double? pressure,
    PressureUnit? pressureUnit,
  }) {
    return TireConfig(
      model: model ?? this.model,
      size: size ?? this.size,
      setup: setup ?? this.setup,
      pressure: pressure ?? this.pressure,
      pressureUnit: pressureUnit ?? this.pressureUnit,
    );
  }
}

enum RimMaterial {
  aluminum,
  carbon,
}

extension RimMaterialExtension on RimMaterial {
  String get displayName {
    switch (this) {
      case RimMaterial.aluminum:
        return 'Aluminum';
      case RimMaterial.carbon:
        return 'Carbon';
    }
  }
}

enum TireSetup {
  tube,
  tubeless,
  insert,
}

extension TireSetupExtension on TireSetup {
  String get displayName {
    switch (this) {
      case TireSetup.tube:
        return 'Inner Tube';
      case TireSetup.tubeless:
        return 'Tubeless';
      case TireSetup.insert:
        return 'Insert';
    }
  }
}

enum PressureUnit {
  psi,
  bar,
}

extension PressureUnitExtension on PressureUnit {
  String get displayName {
    switch (this) {
      case PressureUnit.psi:
        return 'PSI';
      case PressureUnit.bar:
        return 'Bar';
    }
  }
  
  double convert(double value, PressureUnit to) {
    if (this == to) return value;
    if (this == PressureUnit.psi && to == PressureUnit.bar) {
      return value * 0.0689476;
    } else {
      return value / 0.0689476;
    }
  }
}

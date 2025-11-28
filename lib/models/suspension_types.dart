enum SpringType {
  air,
  coil,
}

extension SpringTypeExtension on SpringType {
  String get displayName {
    switch (this) {
      case SpringType.air:
        return 'Aria';
      case SpringType.coil:
        return 'Molla';
    }
  }
}

// Altri tipi comuni per sospensioni
enum DamperType {
  open,
  closed,
}

extension DamperTypeExtension on DamperType {
  String get displayName {
    switch (this) {
      case DamperType.open:
        return 'Open Bath';
      case DamperType.closed:
        return 'Closed Cartridge';
    }
  }
}

enum AdjustmentType {
  external,
  internal,
}

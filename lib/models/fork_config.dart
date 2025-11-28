import 'suspension_types.dart';

class ForkConfig {
  final String name;
  final int travel; // mm
  final SpringType springType;
  final double sag; // %
  final double pressure; // psi
  final int hsc; // clicks
  final int lsc; // clicks
  final int rebound; // clicks
  final int tokens;

  ForkConfig({
    required this.name,
    required this.travel,
    required this.springType,
    this.sag = 25.0,
    this.pressure = 80.0,
    this.hsc = 2,
    this.lsc = 5,
    this.rebound = 4,
    this.tokens = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'travel_mm': travel,
      'spring_type': springType.name,
      'sag_percent': sag,
      'pressure_psi': pressure,
      'hsc_clicks': hsc,
      'lsc_clicks': lsc,
      'rebound_clicks': rebound,
      'tokens': tokens,
    };
  }

  factory ForkConfig.fromJson(Map<String, dynamic> json) {
    return ForkConfig(
      name: json['name'] ?? '',
      travel: json['travel_mm'] ?? 150,
      springType: SpringType.values.firstWhere(
        (e) => e.name == json['spring_type'],
        orElse: () => SpringType.air,
      ),
      sag: json['sag_percent']?.toDouble() ?? 25.0,
      pressure: json['pressure_psi']?.toDouble() ?? 80.0,
      hsc: json['hsc_clicks'] ?? 2,
      lsc: json['lsc_clicks'] ?? 5,
      rebound: json['rebound_clicks'] ?? 4,
      tokens: json['tokens'] ?? 0,
    );
  }

  ForkConfig copyWith({
    String? name,
    int? travel,
    SpringType? springType,
    double? sag,
    double? pressure,
    int? hsc,
    int? lsc,
    int? rebound,
    int? tokens,
  }) {
    return ForkConfig(
      name: name ?? this.name,
      travel: travel ?? this.travel,
      springType: springType ?? this.springType,
      sag: sag ?? this.sag,
      pressure: pressure ?? this.pressure,
      hsc: hsc ?? this.hsc,
      lsc: lsc ?? this.lsc,
      rebound: rebound ?? this.rebound,
      tokens: tokens ?? this.tokens,
    );
  }
}

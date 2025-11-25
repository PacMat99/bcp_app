class Esp32Config {
  final int sensorCount;

  Esp32Config({
    required this.sensorCount,
  });

  Map<String, dynamic> toJson() {
    return {
      'sensor_count': sensorCount,
    };
  }

  factory Esp32Config.fromJson(Map<String, dynamic> json) {
    return Esp32Config(
      sensorCount: json['sensor_count'] ?? 2,
    );
  }

  Esp32Config copyWith({
    int? sensorCount,
  }) {
    return Esp32Config(
      sensorCount: sensorCount ?? this.sensorCount,
    );
  }
}

class Esp32Config {
  final int sensorCount;
  final int sampleRate;

  Esp32Config({
    required this.sensorCount,
    this.sampleRate = 104, // Default a 104Hz
  });

  Map<String, dynamic> toJson() {
    return {
      'sensor_count': sensorCount,
      'sample_rate': sampleRate,
    };
  }

  factory Esp32Config.fromJson(Map<String, dynamic> json) {
    return Esp32Config(
      sensorCount: json['sensor_count'] ?? 2,
      sampleRate: json['sample_rate'] ?? 104,
    );
  }

  Esp32Config copyWith({
    int? sensorCount,
    int? sampleRate,
  }) {
    return Esp32Config(
      sensorCount: sensorCount ?? this.sensorCount,
      sampleRate: sampleRate ?? this.sampleRate,
    );
  }
}
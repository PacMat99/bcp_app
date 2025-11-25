class SensorData {
  final DateTime timestamp;
  final double accelX;
  final double accelY;
  final double accelZ;
  final double gyroX;
  final double gyroY;
  final double gyroZ;

  SensorData({
    required this.timestamp,
    required this.accelX,
    required this.accelY,
    required this.accelZ,
    required this.gyroX,
    required this.gyroY,
    required this.gyroZ,
  });

  factory SensorData.fromBytes(List<int> bytes) {
    // Parse binary data from ESP32
    // Assumendo formato: timestamp(8) + accel(12) + gyro(12) = 32 bytes
    // Adatta al tuo formato reale
    return SensorData(
      timestamp: DateTime.now(),
      accelX: 0.0,
      accelY: 0.0,
      accelZ: 0.0,
      gyroX: 0.0,
      gyroY: 0.0,
      gyroZ: 0.0,
    );
  }
}

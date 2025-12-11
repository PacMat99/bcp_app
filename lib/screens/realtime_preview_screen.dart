import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/ble_service.dart';
import '../models/sensor_data.dart';
import '../theme/app_theme.dart'; // Import per costanti o coerenza futura

class RealtimePreviewScreen extends StatefulWidget {
  const RealtimePreviewScreen({super.key});

  @override
  State<RealtimePreviewScreen> createState() => _RealtimePreviewScreenState();
}

class _RealtimePreviewScreenState extends State<RealtimePreviewScreen> {
  final List<SensorData> _dataBuffer = [];
  final int _maxDataPoints = 100;
  bool _isStreaming = false;

  // COLORI PROFESSIONALI (Data Viz Palette)
  // Accelerometro (Assi cartesiani standard)
  final Color colAccX = const Color(0xFFE53935); // Rosso Tecnico
  final Color colAccY = const Color(0xFF43A047); // Verde Tecnico
  final Color colAccZ = const Color(0xFF1E88E5); // Blu Tecnico

  // Giroscopio (Palette distinta)
  final Color colGyroX = const Color(0xFFFB8C00); // Arancione
  final Color colGyroY = const Color(0xFF8E24AA); // Viola
  final Color colGyroZ = const Color(0xFF00ACC1); // Ciano scuro

  @override
  void initState() {
    super.initState();
    _startListening();
  }

  void _startListening() {
    final bleService = context.read<BleService>();
    
    bleService.sensorDataStream.listen((data) {
      if (mounted) {
        setState(() {
          _dataBuffer.add(data);
          if (_dataBuffer.length > _maxDataPoints) {
            _dataBuffer.removeAt(0);
          }
        });
      }
    });
  }

  Future<void> _toggleStream() async {
    final bleService = context.read<BleService>();
    
    if (_isStreaming) {
      await bleService.stopDataStream();
      setState(() => _isStreaming = false);
    } else {
      await bleService.startDataStream();
      setState(() => _isStreaming = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Real-time Preview'),
        actions: [
          IconButton(
            // Icona che cambia stato
            icon: Icon(_isStreaming ? Icons.stop_circle_outlined : Icons.play_circle_fill),
            color: _isStreaming ? colorScheme.error : colorScheme.secondary,
            tooltip: _isStreaming ? 'Stop Stream' : 'Start Stream',
            onPressed: _toggleStream,
          ),
        ],
      ),
      body: _dataBuffer.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isStreaming ? Icons.hourglass_empty : Icons.show_chart,
                      size: 64,
                      color: _isStreaming ? colorScheme.primary : colorScheme.outline,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    _isStreaming 
                        ? 'Waiting for data...' 
                        : 'Press Play to start streaming',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Ensure ESP32 is connected',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // HEADER CARD
                  Card(
                    color: colorScheme.primaryContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(
                            Icons.show_chart,
                            size: 48,
                            color: colorScheme.onPrimaryContainer,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Live Telemetry',
                                  style: theme.textTheme.headlineSmall?.copyWith(
                                    color: colorScheme.onPrimaryContainer,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'IMU Sensor Data Stream',
                                  style: TextStyle(
                                    color: colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  _buildChartCard(
                    'Accelerometer',
                    Icons.speed,
                    _buildAccelerometerChart(),
                  ),
                  const SizedBox(height: 16),
                  _buildChartCard(
                    'Gyroscope',
                    Icons.rotate_right,
                    _buildGyroscopeChart(),
                  ),
                  const SizedBox(height: 16),
                  _buildStatsCard(),
                ],
              ),
            ),
    );
  }

  Widget _buildChartCard(String title, IconData icon, Widget chart) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Theme.of(context).colorScheme.secondary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: chart,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccelerometerChart() {
    if (_dataBuffer.isEmpty) return const Center(child: Text('No Data'));

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          getDrawingHorizontalLine: (value) => FlLine(
            color: Colors.grey.withValues(alpha: 0.2),
            strokeWidth: 1,
          ),
          getDrawingVerticalLine: (value) => FlLine(
            color: Colors.grey.withValues(alpha: 0.2),
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toStringAsFixed(1),
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                );
              },
            ),
          ),
          bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: true, border: Border.all(color: Colors.grey.withValues(alpha: 0.2))),
        lineBarsData: [
          _buildLineChartBarData(_dataBuffer.map((d) => d.accelX).toList(), colAccX),
          _buildLineChartBarData(_dataBuffer.map((d) => d.accelY).toList(), colAccY),
          _buildLineChartBarData(_dataBuffer.map((d) => d.accelZ).toList(), colAccZ),
        ],
      ),
    );
  }

  Widget _buildGyroscopeChart() {
    if (_dataBuffer.isEmpty) return const Center(child: Text('No Data'));

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          getDrawingHorizontalLine: (value) => FlLine(
            color: Colors.grey.withValues(alpha: 0.2),
            strokeWidth: 1,
          ),
          getDrawingVerticalLine: (value) => FlLine(
            color: Colors.grey.withValues(alpha: 0.2),
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toStringAsFixed(1),
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                );
              },
            ),
          ),
          bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: true, border: Border.all(color: Colors.grey.withValues(alpha: 0.2))),
        lineBarsData: [
          _buildLineChartBarData(_dataBuffer.map((d) => d.gyroX).toList(), colGyroX),
          _buildLineChartBarData(_dataBuffer.map((d) => d.gyroY).toList(), colGyroY),
          _buildLineChartBarData(_dataBuffer.map((d) => d.gyroZ).toList(), colGyroZ),
        ],
      ),
    );
  }

  LineChartBarData _buildLineChartBarData(List<double> data, Color color) {
    return LineChartBarData(
      spots: data.asMap().entries.map((entry) {
        return FlSpot(entry.key.toDouble(), entry.value);
      }).toList(),
      isCurved: true,
      color: color,
      barWidth: 2,
      isStrokeCapRound: true,
      dotData: const FlDotData(show: false),
      belowBarData: BarAreaData(show: false),
    );
  }

  Widget _buildStatsCard() {
    if (_dataBuffer.isEmpty) return const SizedBox.shrink();

    final latest = _dataBuffer.last;
    final theme = Theme.of(context);

    return Card(
      color: _isStreaming 
          ? theme.colorScheme.secondary.withValues(alpha: 0.05) 
          : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: _isStreaming
            ? BorderSide(color: theme.colorScheme.secondary, width: 1.5)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.analytics, color: theme.colorScheme.tertiary),
                const SizedBox(width: 8),
                Text(
                  'Current Values',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildStatRow('Accel X', latest.accelX, colAccX),
            _buildStatRow('Accel Y', latest.accelY, colAccY),
            _buildStatRow('Accel Z', latest.accelZ, colAccZ),
            const SizedBox(height: 12),
            _buildStatRow('Gyro X', latest.gyroX, colGyroX),
            _buildStatRow('Gyro Y', latest.gyroY, colGyroY),
            _buildStatRow('Gyro Z', latest.gyroZ, colGyroZ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Buffer Size: ${_dataBuffer.length} samples',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, double value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4), // Quadrato stondato invece di cerchio (più tecnico)
                ),
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ],
          ),
          Text(
            value.toStringAsFixed(3),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontFamily: 'Monospace', // Font monospaziato per i numeri
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    if (_isStreaming) {
      context.read<BleService>().stopDataStream();
    }
    super.dispose();
  }
}
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/ble_service.dart';
import '../models/sensor_data.dart';

class RealtimePreviewScreen extends StatefulWidget {
  const RealtimePreviewScreen({super.key});

  @override
  State<RealtimePreviewScreen> createState() => _RealtimePreviewScreenState();
}

class _RealtimePreviewScreenState extends State<RealtimePreviewScreen> {
  final List<SensorData> _dataBuffer = [];
  final int _maxDataPoints = 100;
  bool _isStreaming = false;

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Preview Real-time'),
        actions: [
          IconButton(
            icon: Icon(_isStreaming ? Icons.stop : Icons.play_arrow),
            onPressed: _toggleStream,
          ),
        ],
      ),
      body: _dataBuffer.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _isStreaming ? Icons.hourglass_empty : Icons.play_circle_outline,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _isStreaming 
                        ? 'In attesa di dati...' 
                        : 'Premi play per iniziare',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildChartCard(
                    'Accelerometro',
                    Icons.speed,
                    _buildAccelerometerChart(),
                  ),
                  const SizedBox(height: 16),
                  _buildChartCard(
                    'Giroscopio',
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
                Icon(icon, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
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
    if (_dataBuffer.isEmpty) {
      return const Center(child: Text('Nessun dato'));
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toStringAsFixed(1),
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
          bottomTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          _buildLineChartBarData(
            _dataBuffer.map((d) => d.accelX).toList(),
            Colors.red,
          ),
          _buildLineChartBarData(
            _dataBuffer.map((d) => d.accelY).toList(),
            Colors.green,
          ),
          _buildLineChartBarData(
            _dataBuffer.map((d) => d.accelZ).toList(),
            Colors.blue,
          ),
        ],
      ),
    );
  }

  Widget _buildGyroscopeChart() {
    if (_dataBuffer.isEmpty) {
      return const Center(child: Text('Nessun dato'));
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toStringAsFixed(1),
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
          bottomTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          _buildLineChartBarData(
            _dataBuffer.map((d) => d.gyroX).toList(),
            Colors.orange,
          ),
          _buildLineChartBarData(
            _dataBuffer.map((d) => d.gyroY).toList(),
            Colors.purple,
          ),
          _buildLineChartBarData(
            _dataBuffer.map((d) => d.gyroZ).toList(),
            Colors.cyan,
          ),
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
      dotData: const FlDotData(show: false),
      belowBarData: BarAreaData(show: false),
    );
  }

  Widget _buildStatsCard() {
    if (_dataBuffer.isEmpty) return const SizedBox.shrink();

    final latest = _dataBuffer.last;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Valori Attuali',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const Divider(),
            _buildStatRow('Accel X', latest.accelX, Colors.red),
            _buildStatRow('Accel Y', latest.accelY, Colors.green),
            _buildStatRow('Accel Z', latest.accelZ, Colors.blue),
            const SizedBox(height: 8),
            _buildStatRow('Gyro X', latest.gyroX, Colors.orange),
            _buildStatRow('Gyro Y', latest.gyroY, Colors.purple),
            _buildStatRow('Gyro Z', latest.gyroZ, Colors.cyan),
            const Divider(),
            Text(
              'Campioni: ${_dataBuffer.length}',
              style: Theme.of(context).textTheme.bodySmall,
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
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(label),
            ],
          ),
          Text(
            value.toStringAsFixed(3),
            style: const TextStyle(fontWeight: FontWeight.bold),
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

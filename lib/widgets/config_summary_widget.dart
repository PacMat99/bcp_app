import 'package:flutter/material.dart';
import '../utils/config_helper.dart';
import '../models/bike_config.dart';
import '../models/fork_config.dart';
import '../models/shock_config.dart';
import '../models/wheel_config.dart';
import '../models/esp32_config.dart';

class ConfigSummaryWidget extends StatefulWidget {
  const ConfigSummaryWidget({super.key});

  @override
  State<ConfigSummaryWidget> createState() => _ConfigSummaryWidgetState();
}

class _ConfigSummaryWidgetState extends State<ConfigSummaryWidget> {
  Map<String, dynamic> _config = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAllConfigs();
  }

  Future<void> _loadAllConfigs() async {
    // Usa l'helper invece di caricare manualmente
    final completeConfig = await ConfigHelper.loadCompleteConfig();
    
    setState(() {
      _config = completeConfig;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Riepilogo Configurazione',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          
          if (_config['bike'] != null) _buildConfigCard(
            'Bici',
            Icons.directions_bike,
            BikeConfig.fromJson(_config['bike']),
          ),
          
          if (_config['fork'] != null) _buildConfigCard(
            'Forcella',
            Icons.settings_input_component,
            ForkConfig.fromJson(_config['fork']),
          ),
          
          if (_config['shock'] != null) _buildConfigCard(
            'Ammortizzatore',
            Icons.published_with_changes,
            ShockConfig.fromJson(_config['shock']),
          ),
          
          if (_config['wheels'] != null) _buildConfigCard(
            'Ruote',
            Icons.album,
            WheelConfig.fromJson(_config['wheels']),
          ),
          
          if (_config['esp32'] != null) _buildConfigCard(
            'ESP32',
            Icons.memory,
            Esp32Config.fromJson(_config['esp32']),
          ),
        ],
      ),
    );
  }

  Widget _buildConfigCard(String title, IconData icon, dynamic config) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(title),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              _formatConfig(config),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }

  String _formatConfig(dynamic config) {
    if (config is BikeConfig) {
      return 'Tipo: ${config.bikeType.displayName}\n'
             'Ruote: ${config.frontWheelSize}" / ${config.rearWheelSize}"';
    } else if (config is ForkConfig) {
      return '${config.name}\n'
             'Escursione: ${config.travel}mm\n'
             'Sag: ${config.sag.toStringAsFixed(0)}% | Pressione: ${config.pressure.toStringAsFixed(0)} PSI';
    } else if (config is ShockConfig) {
      return '${config.name}\n'
             'Escursione: ${config.travel}mm\n'
             'Sag: ${config.sag.toStringAsFixed(0)}% | Pressione: ${config.pressure.toStringAsFixed(0)} PSI';
    } else if (config is WheelConfig) {
      return 'Cerchi: ${config.rimModel} (${config.rimMaterial.displayName})\n'
             'Ant: ${config.frontTire.model}\n'
             'Post: ${config.rearTire.model}';
    } else if (config is Esp32Config) {
      return 'Sensori: ${config.sensorCount}';
    }
    return 'N/A';
  }
}

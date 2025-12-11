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
    final completeConfig = await ConfigHelper.loadCompleteConfig();
    
    if (mounted) {
      setState(() {
        _config = completeConfig;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // HEADER CARD (Standard Precision Style)
          Card(
            color: colorScheme.primaryContainer,
            margin: const EdgeInsets.only(bottom: 24),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Icons.summarize_outlined, 
                    size: 48, 
                    color: colorScheme.onPrimaryContainer
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'System Overview',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Complete telemetry setup',
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
          
          if (_config['bike'] != null) 
            _buildConfigCard(
              'Bike Geometry',
              Icons.directions_bike,
              _buildBikeContent(BikeConfig.fromJson(_config['bike'])),
            ),
          
          if (_config['fork'] != null) 
            _buildConfigCard(
              'Fork Setup',
              Icons.compress,
              _buildForkContent(ForkConfig.fromJson(_config['fork'])),
            ),
          
          if (_config['shock'] != null) 
            _buildConfigCard(
              'Shock Setup',
              Icons.height,
              _buildShockContent(ShockConfig.fromJson(_config['shock'])),
            ),
          
          if (_config['wheels'] != null) 
            _buildConfigCard(
              'Wheels & Tires',
              Icons.tire_repair,
              _buildWheelsContent(WheelConfig.fromJson(_config['wheels'])),
            ),
          
          if (_config['esp32'] != null) 
            _buildConfigCard(
              'Hardware',
              Icons.memory,
              _buildEsp32Content(Esp32Config.fromJson(_config['esp32'])),
            ),
        ],
      ),
    );
  }

  Widget _buildConfigCard(String title, IconData icon, Widget content) {
    return Card(
      clipBehavior: Clip.hardEdge,
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: Icon(icon, color: Theme.of(context).colorScheme.secondary),
        title: Text(
          title, 
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        collapsedBackgroundColor: Colors.white,
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Divider(),
          content,
        ],
      ),
    );
  }

  // --- CONTENT BUILDERS ---

  Widget _buildBikeContent(BikeConfig config) {
    return Column(
      children: [
        _buildRow('Frame Type', config.bikeType.displayName),
        if (config.forkTravel != null)
           _buildRow('Fork Travel', '${config.forkTravel?.toStringAsFixed(0)} mm'),
        if (config.shockTravel != null)
           _buildRow('Shock Travel', '${config.shockTravel?.toStringAsFixed(0)} mm'),
      ],
    );
  }

  Widget _buildForkContent(ForkConfig config) {
    return Column(
      children: [
        _buildRow('Model', config.name.isNotEmpty ? config.name : 'Not set'),
        _buildRow('Travel', '${config.travel} mm'),
        _buildRow('Spring', config.springType.name),
        const Divider(height: 16, thickness: 0.5),
        _buildRow('Pressure', '${config.pressure.toStringAsFixed(0)} psi'),
        _buildRow('Sag', '${config.sag.toStringAsFixed(0)} %'),
        _buildRow('HSC / LSC', '${config.hsc} / ${config.lsc} clicks'),
        _buildRow('Rebound', '${config.rebound} clicks'),
        _buildRow('Tokens', '${config.tokens}'),
      ],
    );
  }

  Widget _buildShockContent(ShockConfig config) {
    return Column(
      children: [
        _buildRow('Model', config.name.isNotEmpty ? config.name : 'Not set'),
        _buildRow('Travel', '${config.travel} mm'),
        _buildRow('Spring', config.springType.name),
        const Divider(height: 16, thickness: 0.5),
        _buildRow('Pressure', '${config.pressure.toStringAsFixed(0)} psi'),
        _buildRow('Sag', '${config.sag.toStringAsFixed(0)} %'),
        _buildRow('HSC / LSC', '${config.hsc} / ${config.lsc} clicks'),
        _buildRow('Rebound', '${config.rebound} clicks'),
        _buildRow('Tokens', '${config.tokens}'),
      ],
    );
  }

  Widget _buildWheelsContent(WheelConfig config) {
    return Column(
      children: [
        _buildRow('Rims', config.rimModel.isNotEmpty ? config.rimModel : 'Generic'),
        _buildRow('Material', config.rimMaterial.displayName),
        const Divider(height: 16, thickness: 0.5),
        _buildSectionHeader('Front Tire'),
        _buildRow('Model', config.frontTire.model),
        _buildRow('Setup', config.frontTire.setup.displayName),
        _buildRow('Pressure', '${config.frontTire.pressure.toStringAsFixed(1)} ${config.frontTire.pressureUnit.displayName}'),
        const SizedBox(height: 8),
        _buildSectionHeader('Rear Tire'),
        _buildRow('Model', config.rearTire.model),
        _buildRow('Setup', config.rearTire.setup.displayName),
        _buildRow('Pressure', '${config.rearTire.pressure.toStringAsFixed(1)} ${config.rearTire.pressureUnit.displayName}'),
      ],
    );
  }

  Widget _buildEsp32Content(Esp32Config config) {
    return Column(
      children: [
        _buildRow('Connected Sensors', '${config.sensorCount}'),
        _buildRow('Board Type', 'ESP32-C6'),
      ],
    );
  }

  // --- HELPER WIDGETS ---

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary, // Slate Dark
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4, top: 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title.toUpperCase(),
          style: TextStyle(
            color: Theme.of(context).colorScheme.secondary, // Tech Blue
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}
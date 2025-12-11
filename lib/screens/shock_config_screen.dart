import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/shock_config.dart';
import '../models/suspension_types.dart';
import '../theme/app_theme.dart';

class ShockConfigScreen extends StatefulWidget {
  const ShockConfigScreen({super.key});

  @override
  State<ShockConfigScreen> createState() => _ShockConfigScreenState();
}

class _ShockConfigScreenState extends State<ShockConfigScreen> {
  final _nameController = TextEditingController();
  int _travel = 130;
  SpringType _springType = SpringType.air;
  double _sag = 30.0;
  double _pressure = 200.0;
  int _hsc = 2;
  int _lsc = 5;
  int _rebound = 4;
  int _tokens = 0;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final configJson = prefs.getString('shock_config');
    
    if (configJson != null) {
      final config = ShockConfig.fromJson(jsonDecode(configJson));
      setState(() {
        _nameController.text = config.name;
        _travel = config.travel;
        _springType = config.springType;
        _sag = config.sag;
        _pressure = config.pressure;
        _hsc = config.hsc;
        _lsc = config.lsc;
        _rebound = config.rebound;
        _tokens = config.tokens;
      });
    }
  }

  Future<void> _saveConfig() async {
    final config = ShockConfig(
      name: _nameController.text,
      travel: _travel,
      springType: _springType,
      sag: _sag,
      pressure: _pressure,
      hsc: _hsc,
      lsc: _lsc,
      rebound: _rebound,
      tokens: _tokens,
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('shock_config', jsonEncode(config.toJson()));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Shock configuration saved'),
          backgroundColor: AppTheme.success,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Alias per comodità e pulizia
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shock Configuration'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header - Stile coerente con Bike e Wheel config
            Card(
              color: colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      Icons.height,
                      size: 48,
                      color: colorScheme.onPrimaryContainer,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Shock Setup',
                            style: textTheme.headlineSmall?.copyWith(
                              color: colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Configure shock parameters',
                            style: TextStyle(
                              color: colorScheme.onPrimaryContainer,
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

            // Sezione Info
            Text(
              'General Info',
              style: textTheme.titleLarge?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Shock Model',
                hintText: 'eg. Cane Creek Coil IL',
                prefixIcon: Icon(Icons.label),
              ),
            ),
            const SizedBox(height: 16),

            // Card Travel
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Travel'),
                        Text(
                          '$_travel mm',
                          style: textTheme.headlineSmall?.copyWith(
                            color: colorScheme.secondary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: _travel.toDouble(),
                      min: 100,
                      max: 200,
                      divisions: 20,
                      label: '$_travel mm',
                      onChanged: (value) {
                        setState(() {
                          _travel = value.toInt();
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Tipo Molla
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Spring Type'),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: SegmentedButton<SpringType>(
                        segments: SpringType.values.map((type) {
                          return ButtonSegment(
                            value: type,
                            label: Text(type.displayName),
                            icon: Icon(type == SpringType.air ? Icons.air : Icons.water_drop),
                          );
                        }).toList(),
                        selected: {_springType},
                        onSelectionChanged: (Set<SpringType> newSelection) {
                          setState(() {
                            _springType = newSelection.first;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Setup
            Text(
              'Setup',
              style: textTheme.titleLarge?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            // Sag & Pressure in grid
            Row(
              children: [
                Expanded(
                  child: _buildSettingCard(
                    'Sag',
                    _sag,
                    '%',
                    20,
                    40,
                    (value) => setState(() => _sag = value),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSettingCard(
                    'Pressure',
                    _pressure,
                    'PSI',
                    100,
                    300,
                    (value) => setState(() => _pressure = value),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // HSC & LSC
            Row(
              children: [
                Expanded(
                  child: _buildClickCard(
                    'HSC',
                    _hsc,
                    (value) => setState(() => _hsc = value),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildClickCard(
                    'LSC',
                    _lsc,
                    (value) => setState(() => _lsc = value),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Rebound & Tokens
            Row(
              children: [
                Expanded(
                  child: _buildClickCard(
                    'Rebound',
                    _rebound,
                    (value) => setState(() => _rebound = value),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildClickCard(
                    'Tokens',
                    _tokens,
                    (value) => setState(() => _tokens = value),
                    max: 10,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Bottone Salva
            FilledButton.icon(
              onPressed: _saveConfig,
              icon: const Icon(Icons.save),
              label: const Text('SAVE SETUP'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingCard(
    String label,
    double value,
    String unit,
    double min,
    double max,
    Function(double) onChanged,
  ) {
    // Alias per comodità e pulizia
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(label, style: textTheme.bodyMedium),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  value.toStringAsFixed(0),
                  style: textTheme.headlineMedium?.copyWith(
                    color: colorScheme.secondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 4),
                Text(unit, style: textTheme.bodySmall),
              ],
            ),
            Slider(
              value: value,
              min: min,
              max: max,
              divisions: (max - min).toInt(),
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClickCard(
    String label,
    int value,
    Function(int) onChanged,
    {int max = 20}
  ) {
    // Alias per comodità e pulizia
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(label, style: textTheme.bodyMedium),
            const SizedBox(height: 8),
            Text(
              '$value',
              style: textTheme.headlineMedium?.copyWith(
                color: colorScheme.secondary,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text('Clicks', style: textTheme.bodySmall),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: value > 0 ? () => onChanged(value - 1) : null,
                  icon: const Icon(Icons.remove_circle_outline),
                  color: colorScheme.secondary,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 16),
                IconButton(
                  onPressed: value < max ? () => onChanged(value + 1) : null,
                  icon: const Icon(Icons.add_circle_outline),
                  color: colorScheme.secondary,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }
}
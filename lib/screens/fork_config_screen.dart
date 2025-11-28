import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/fork_config.dart';
import '../models/suspension_types.dart';

class ForkConfigScreen extends StatefulWidget {
  const ForkConfigScreen({super.key});

  @override
  State<ForkConfigScreen> createState() => _ForkConfigScreenState();
}

class _ForkConfigScreenState extends State<ForkConfigScreen> {
  final _nameController = TextEditingController();
  int _travel = 150;
  SpringType _springType = SpringType.air;
  double _sag = 25.0;
  double _pressure = 80.0;
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
    final configJson = prefs.getString('fork_config');
    
    if (configJson != null) {
      final config = ForkConfig.fromJson(jsonDecode(configJson));
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
    final config = ForkConfig(
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
    await prefs.setString('fork_config', jsonEncode(config.toJson()));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Configurazione forcella salvata'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurazione Forcella'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Card(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      Icons.settings_input_component,
                      size: 48,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Setup Forcella',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Configura i parametri della forcella anteriore',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Informazioni Generali
            Text(
              'Informazioni Generali',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),

            // Nome Forcella
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Modello Forcella',
                hintText: 'es. RockShox Pike Ultimate',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.label),
              ),
            ),
            const SizedBox(height: 16),

            // Escursione
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Escursione'),
                        Text(
                          '$_travel mm',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: _travel.toDouble(),
                      min: 80,
                      max: 200,
                      divisions: 24,
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
                    const Text('Tipo di Molla'),
                    const SizedBox(height: 12),
                    SegmentedButton<SpringType>(
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
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Setup
            Text(
              'Setup',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).colorScheme.primary,
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
                    10,
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
                    40,
                    150,
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
              label: const Text('Salva Configurazione'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.all(16),
                backgroundColor: const Color(0xFF9C27B0),
              ),
            ),
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Text(
              value.toStringAsFixed(0),
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              unit,
              style: Theme.of(context).textTheme.bodySmall,
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Text(
              '$value',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: Theme.of(context).colorScheme.secondary,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Clicks',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: value > 0 ? () => onChanged(value - 1) : null,
                  icon: const Icon(Icons.remove_circle_outline),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: value < max ? () => onChanged(value + 1) : null,
                  icon: const Icon(Icons.add_circle_outline),
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

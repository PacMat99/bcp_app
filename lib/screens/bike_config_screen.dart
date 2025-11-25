import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/bike_config.dart';

class BikeConfigScreen extends StatefulWidget {
  const BikeConfigScreen({super.key});

  @override
  State<BikeConfigScreen> createState() => _BikeConfigScreenState();
}

class _BikeConfigScreenState extends State<BikeConfigScreen> {
  BikeType _selectedBikeType = BikeType.hardtail;
  double _frontWheelSize = 29.0;
  double _rearWheelSize = 29.0;
  double _forkTravel = 120.0;
  double _shockTravel = 130.0;

  final List<double> _wheelSizes = [26.0, 27.5, 29.0];

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final configJson = prefs.getString('bike_config');
    
    if (configJson != null) {
      final config = BikeConfig.fromJson(jsonDecode(configJson));
      setState(() {
        _selectedBikeType = config.bikeType;
        _frontWheelSize = config.frontWheelSize;
        _rearWheelSize = config.rearWheelSize;
        _forkTravel = config.forkTravel ?? 120.0;
        _shockTravel = config.shockTravel ?? 130.0;
      });
    }
  }

  Future<void> _saveConfig() async {
    final config = BikeConfig(
      bikeType: _selectedBikeType,
      frontWheelSize: _frontWheelSize,
      rearWheelSize: _rearWheelSize,
      forkTravel: _selectedBikeType != BikeType.rigid ? _forkTravel : null,
      shockTravel: _selectedBikeType == BikeType.fullSuspension ? _shockTravel : null,
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('bike_config', jsonEncode(config.toJson()));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Configurazione salvata'),
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
        title: const Text('Configurazione Bici'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header card
            Card(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      Icons.directions_bike,
                      size: 48,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'Configura la tua MTB',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Tipo Bici
            Text(
              'Tipo di Bici',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: DropdownButtonFormField<BikeType>(
                  value: _selectedBikeType,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    icon: Icon(Icons.bike_scooter),
                  ),
                  items: BikeType.values.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(type.displayName),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedBikeType = value!;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Dimensioni Ruote
            Text(
              'Dimensioni Ruote',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            
            // Ruota Anteriore
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Ruota Anteriore'),
                    const SizedBox(height: 8),
                    SegmentedButton<double>(
                      segments: _wheelSizes.map((size) {
                        return ButtonSegment(
                          value: size,
                          label: Text('${size.toStringAsFixed(1)}"'),
                        );
                      }).toList(),
                      selected: {_frontWheelSize},
                      onSelectionChanged: (Set<double> newSelection) {
                        setState(() {
                          _frontWheelSize = newSelection.first;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Ruota Posteriore
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Ruota Posteriore'),
                    const SizedBox(height: 8),
                    SegmentedButton<double>(
                      segments: _wheelSizes.map((size) {
                        return ButtonSegment(
                          value: size,
                          label: Text('${size.toStringAsFixed(1)}"'),
                        );
                      }).toList(),
                      selected: {_rearWheelSize},
                      onSelectionChanged: (Set<double> newSelection) {
                        setState(() {
                          _rearWheelSize = newSelection.first;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),

            // Escursione Forcella (se non Rigida)
            if (_selectedBikeType != BikeType.rigid) ...[
              const SizedBox(height: 24),
              Text(
                'Escursione Forcella',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${_forkTravel.toStringAsFixed(0)} mm',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const Icon(Icons.settings_input_component),
                        ],
                      ),
                      Slider(
                        value: _forkTravel,
                        min: 80,
                        max: 200,
                        divisions: 24,
                        label: '${_forkTravel.toStringAsFixed(0)} mm',
                        onChanged: (value) {
                          setState(() {
                            _forkTravel = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // Escursione Ammortizzatore (solo Full Suspension)
            if (_selectedBikeType == BikeType.fullSuspension) ...[
              const SizedBox(height: 24),
              Text(
                'Escursione Ammortizzatore',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${_shockTravel.toStringAsFixed(0)} mm',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const Icon(Icons.published_with_changes),
                        ],
                      ),
                      Slider(
                        value: _shockTravel,
                        min: 100,
                        max: 200,
                        divisions: 20,
                        label: '${_shockTravel.toStringAsFixed(0)} mm',
                        onChanged: (value) {
                          setState(() {
                            _shockTravel = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 32),

            // Bottone Salva
            FilledButton.icon(
              onPressed: _saveConfig,
              icon: const Icon(Icons.save),
              label: const Text('Salva Configurazione'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

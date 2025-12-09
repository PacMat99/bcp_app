import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/wheel_config.dart';
import '../theme/app_theme.dart';

class WheelConfigScreen extends StatefulWidget {
  const WheelConfigScreen({super.key});

  @override
  State<WheelConfigScreen> createState() => _WheelConfigScreenState();
}

class _WheelConfigScreenState extends State<WheelConfigScreen> {
  final _rimModelController = TextEditingController();
  RimMaterial _rimMaterial = RimMaterial.aluminum;
  
  // Front tire
  final _frontTireController = TextEditingController();
  double _frontSize = 29.0;
  TireSetup _frontSetup = TireSetup.tubeless;
  double _frontPressure = 25.0;
  
  // Rear tire
  final _rearTireController = TextEditingController();
  double _rearSize = 29.0;
  TireSetup _rearSetup = TireSetup.tubeless;
  double _rearPressure = 27.0;
  
  PressureUnit _pressureUnit = PressureUnit.psi;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final configJson = prefs.getString('wheel_config');
    
    if (configJson != null) {
      final config = WheelConfig.fromJson(jsonDecode(configJson));
      setState(() {
        _rimModelController.text = config.rimModel;
        _rimMaterial = config.rimMaterial;
        
        _frontTireController.text = config.frontTire.model;
        _frontSize = config.frontTire.size;
        _frontSetup = config.frontTire.setup;
        _frontPressure = config.frontTire.pressure;
        
        _rearTireController.text = config.rearTire.model;
        _rearSize = config.rearTire.size;
        _rearSetup = config.rearTire.setup;
        _rearPressure = config.rearTire.pressure;
        
        _pressureUnit = config.frontTire.pressureUnit;
      });
    }
  }

  Future<void> _saveConfig() async {
    final config = WheelConfig(
      rimModel: _rimModelController.text,
      rimMaterial: _rimMaterial,
      frontTire: TireConfig(
        model: _frontTireController.text,
        size: _frontSize,
        setup: _frontSetup,
        pressure: _frontPressure,
        pressureUnit: _pressureUnit,
      ),
      rearTire: TireConfig(
        model: _rearTireController.text,
        size: _rearSize,
        setup: _rearSetup,
        pressure: _rearPressure,
        pressureUnit: _pressureUnit,
      ),
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('wheel_config', jsonEncode(config.toJson()));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Wheels configuration saved'),
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
        title: const Text('Wheels Configuration'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Card(
              color: colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      Icons.album, // Icona Ruote
                      size: 48,
                      color: colorScheme.onPrimaryContainer,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Wheels Setup',
                            style: textTheme.headlineSmall?.copyWith(
                              color: colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Wheels and Tires',
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

            // Cerchi
            Text(
              'Wheels',
              style: textTheme.titleLarge?.copyWith(
                color: colorScheme.primary, // Usa colore tema
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _rimModelController,
              decoration: const InputDecoration( // Stile definito nel tema
                labelText: 'Rims Model',
                hintText: 'eg. DT Swiss XM 1700',
                prefixIcon: Icon(Icons.album_outlined),
              ),
            ),
            const SizedBox(height: 16),

            // Materiale Cerchi - Card standard
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Rims Material', style: textTheme.titleSmall),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: SegmentedButton<RimMaterial>(
                        segments: RimMaterial.values.map((material) {
                          return ButtonSegment(
                            value: material,
                            label: Text(material.displayName),
                            icon: Icon(
                              material == RimMaterial.carbon 
                                  ? Icons.fiber_smart_record 
                                  : Icons.circle_outlined,
                            ),
                          );
                        }).toList(),
                        selected: {_rimMaterial},
                        onSelectionChanged: (Set<RimMaterial> newSelection) {
                          setState(() {
                            _rimMaterial = newSelection.first;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Pneumatico Anteriore
            _buildTireSection(
              'Front', // Titolo più breve
              Icons.arrow_upward,
              _frontTireController,
              _frontSize,
              _frontSetup,
              _frontPressure,
              (size) => setState(() => _frontSize = size),
              (setup) => setState(() => _frontSetup = setup),
              (pressure) => setState(() => _frontPressure = pressure),
            ),
            const SizedBox(height: 16),

            // Pneumatico Posteriore
            _buildTireSection(
              'Rear', // Titolo più breve
              Icons.arrow_downward,
              _rearTireController,
              _rearSize,
              _rearSetup,
              _rearPressure,
              (size) => setState(() => _rearSize = size),
              (setup) => setState(() => _rearSetup = setup),
              (pressure) => setState(() => _rearPressure = pressure),
            ),
            const SizedBox(height: 16),

            // Unità Pressione - Card Standard
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Pressure Unit', style: textTheme.titleSmall),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: SegmentedButton<PressureUnit>(
                        segments: PressureUnit.values.map((unit) {
                          return ButtonSegment(
                            value: unit,
                            label: Text(unit.displayName),
                          );
                        }).toList(),
                        selected: {_pressureUnit},
                        onSelectionChanged: (Set<PressureUnit> newSelection) {
                          setState(() {
                            // Converti le pressioni quando cambi unità
                            final newUnit = newSelection.first;
                            _frontPressure = _pressureUnit.convert(_frontPressure, newUnit);
                            _rearPressure = _pressureUnit.convert(_rearPressure, newUnit);
                            _pressureUnit = newUnit;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Bottone Salva - STILE AGGIORNATO: Usa stile tema
            FilledButton.icon(
              onPressed: _saveConfig,
              icon: const Icon(Icons.save),
              label: const Text('SAVE SETUP'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.all(16),
                // Il colore background è gestito dal tema
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildTireSection(
    String title,
    IconData icon,
    TextEditingController controller,
    double size,
    TireSetup setup,
    double pressure,
    Function(double) onSizeChanged,
    Function(TireSetup) onSetupChanged,
    Function(double) onPressureChanged,
  ) {
    // Alias per comodità e pulizia
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              title,
              style: textTheme.titleLarge?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Modello pneumatico - STILE AGGIORNATO
        TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Tire Model',
            hintText: 'eg. Maxxis Minion',
            prefixIcon: Icon(Icons.tire_repair),
          ),
        ),
        const SizedBox(height: 12),

        // Dimensione e Setup in una singola Card per pulizia visiva
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Dimensione
                Text('Size', style: textTheme.titleSmall),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<double>(
                    segments: const [
                      ButtonSegment(value: 26.0, label: Text('26"')),
                      ButtonSegment(value: 27.5, label: Text('27.5"')),
                      ButtonSegment(value: 29.0, label: Text('29"')),
                    ],
                    selected: {size},
                    onSelectionChanged: (Set<double> newSelection) {
                      onSizeChanged(newSelection.first);
                    },
                  ),
                ),
                
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(), // Divisore sottile tra le opzioni
                ),

                // Setup
                Text('Setup Type', style: textTheme.titleSmall),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<TireSetup>(
                    segments: TireSetup.values.map((setupType) {
                      return ButtonSegment(
                        value: setupType,
                        label: Text(setupType.displayName),
                      );
                    }).toList(),
                    selected: {setup},
                    onSelectionChanged: (Set<TireSetup> newSelection) {
                      onSetupChanged(newSelection.first);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Pressione - Card Separata per importanza
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Pressure'),
                    Text(
                      '${pressure.toStringAsFixed(1)} ${_pressureUnit.displayName}',
                      style: textTheme.titleMedium?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: pressure,
                  min: _pressureUnit == PressureUnit.psi ? 15 : 1.0,
                  max: _pressureUnit == PressureUnit.psi ? 40 : 2.8,
                  divisions: _pressureUnit == PressureUnit.psi ? 50 : 36,
                  label: '${pressure.toStringAsFixed(1)} ${_pressureUnit.displayName}',
                  onChanged: onPressureChanged,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _rimModelController.dispose();
    _frontTireController.dispose();
    _rearTireController.dispose();
    super.dispose();
  }
}
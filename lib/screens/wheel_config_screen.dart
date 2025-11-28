import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/wheel_config.dart';

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
        const SnackBar(
          content: Text('Configurazione ruote salvata'),
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
        title: const Text('Configurazione Ruote'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Card(
              color: Theme.of(context).colorScheme.tertiaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      Icons.album,
                      size: 48,
                      color: Theme.of(context).colorScheme.onTertiaryContainer,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Setup Ruote',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: Theme.of(context).colorScheme.onTertiaryContainer,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Cerchi e pneumatici',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onTertiaryContainer.withValues(alpha: 0.8),
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

            // Cerchi
            Text(
              'Cerchi',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: const Color(0xFF00BCD4),
              ),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _rimModelController,
              decoration: InputDecoration(
                labelText: 'Modello Cerchi',
                hintText: 'es. DT Swiss XM 1700',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.album),
              ),
            ),
            const SizedBox(height: 16),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Materiale Cerchi'),
                    const SizedBox(height: 12),
                    SegmentedButton<RimMaterial>(
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
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Pneumatico Anteriore
            _buildTireSection(
              'Pneumatico Anteriore',
              Icons.arrow_upward,
              _frontTireController,
              _frontSize,
              _frontSetup,
              _frontPressure,
              (size) => setState(() => _frontSize = size),
              (setup) => setState(() => _frontSetup = setup),
              (pressure) => setState(() => _frontPressure = pressure),
            ),
            const SizedBox(height: 24),

            // Pneumatico Posteriore
            _buildTireSection(
              'Pneumatico Posteriore',
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

            // Unità Pressione
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Unità di Misura Pressione'),
                    const SizedBox(height: 12),
                    SegmentedButton<PressureUnit>(
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
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Bottone Salva
            FilledButton.icon(
              onPressed: _saveConfig,
              icon: const Icon(Icons.save),
              label: const Text('Salva Configurazione'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.all(16),
                backgroundColor: const Color(0xFF00BCD4),
              ),
            ),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: const Color(0xFF00BCD4)),
            const SizedBox(width: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: const Color(0xFF00BCD4),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Modello pneumatico
        TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: 'Modello Pneumatico',
            hintText: 'es. Maxxis Minion DHF',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            prefixIcon: const Icon(Icons.tire_repair),
          ),
        ),
        const SizedBox(height: 12),

        // Dimensione
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Dimensione'),
                const SizedBox(height: 12),
                SegmentedButton<double>(
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
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Setup
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Tipo Setup'),
                const SizedBox(height: 12),
                SegmentedButton<TireSetup>(
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
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Pressione
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Pressione'),
                    Text(
                      '${pressure.toStringAsFixed(1)} ${_pressureUnit.displayName}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: const Color(0xFF00BCD4),
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

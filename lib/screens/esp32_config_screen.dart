import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/esp32_config.dart';
import '../services/ble_service.dart';

class Esp32ConfigScreen extends StatefulWidget {
  const Esp32ConfigScreen({super.key});

  @override
  State<Esp32ConfigScreen> createState() => _Esp32ConfigScreenState();
}

class _Esp32ConfigScreenState extends State<Esp32ConfigScreen> {
  int _sensorCount = 2; // Default: 2 sensori
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final configJson = prefs.getString('esp32_config');
    
    if (configJson != null) {
      final config = Esp32Config.fromJson(jsonDecode(configJson));
      setState(() {
        _sensorCount = config.sensorCount;
      });
    }
  }

  Future<void> _saveAndSendConfig() async {
    setState(() => _isSending = true);

    // Salva localmente
    final config = Esp32Config(sensorCount: _sensorCount);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('esp32_config', jsonEncode(config.toJson()));

    // Invia all'ESP32
    final bleService = context.read<BleService>();
    if (!bleService.isConnected) {
      setState(() => _isSending = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ESP32 non connesso'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    final success = await bleService.sendSensorConfig(_sensorCount);

    setState(() => _isSending = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success 
              ? 'Configurazione inviata con successo' 
              : 'Errore invio configurazione'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
      
      if (success) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurazione ESP32'),
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
                      Icons.memory,
                      size: 48,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hardware Setup',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'ESP32-C6 Configuration',
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

            // Info sensori connessi
            Text(
              'Numero Sensori LSM6DSOX',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Specifica quanti sensori IMU sono fisicamente collegati all\'ESP32',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),

            // Selector sensori con card visuali
            ...List.generate(4, (index) {
              final count = index + 1;
              final isSelected = _sensorCount == count;
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: isSelected 
                        ? LinearGradient(
                            colors: [
                              const Color(0xFF9C27B0),
                              const Color(0xFFE040FB),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: isSelected ? null : Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected 
                          ? const Color(0xFFE040FB) 
                          : Colors.transparent,
                      width: 2,
                    ),
                    boxShadow: isSelected ? [
                      BoxShadow(
                        color: const Color(0xFFE040FB).withValues(alpha: 0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ] : null,
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _sensorCount = count;
                        });
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            // Icona sensori
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isSelected 
                                    ? Colors.white.withValues(alpha: 0.2)
                                    : Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.sensors,
                                size: 32,
                                color: isSelected 
                                    ? Colors.white 
                                    : Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: 16),
                            
                            // Info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '$count Sensor${count > 1 ? 'i' : 'e'}',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: isSelected 
                                          ? Colors.white 
                                          : Theme.of(context).colorScheme.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _getSensorDescription(count),
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: isSelected 
                                          ? Colors.white.withValues(alpha: 0.8)
                                          : Theme.of(context).colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            // Checkmark
                            if (isSelected)
                              const Icon(
                                Icons.check_circle,
                                color: Colors.white,
                                size: 28,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),

            const SizedBox(height: 32),

            // Bottone Salva e Invia
            FilledButton.icon(
              onPressed: _isSending ? null : _saveAndSendConfig,
              icon: _isSending 
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send),
              label: Text(_isSending ? 'Invio in corso...' : 'Salva e Invia a ESP32'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.all(16),
                backgroundColor: const Color(0xFF9C27B0),
                elevation: 8,
                shadowColor: const Color(0xFFE040FB).withValues(alpha: 0.5),
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Nota
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF00BCD4).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFF00BCD4).withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 20,
                    color: const Color(0xFF00BCD4),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'La configurazione verrà salvata e inviata all\'ESP32',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getSensorDescription(int count) {
    switch (count) {
      case 1:
        return 'Setup base - forcella anteriore';
      case 2:
        return 'Setup standard - forcella + ammortizzatore';
      case 3:
        return 'Setup avanzato - tripla telemetria';
      case 4:
        return 'Setup completo - massima precisione';
      default:
        return '';
    }
  }
}

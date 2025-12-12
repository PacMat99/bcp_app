import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/esp32_config.dart';
import '../services/ble_service.dart';
import '../theme/app_theme.dart';

class Esp32ConfigScreen extends StatefulWidget {
  const Esp32ConfigScreen({super.key});

  @override
  State<Esp32ConfigScreen> createState() => _Esp32ConfigScreenState();
}

class _Esp32ConfigScreenState extends State<Esp32ConfigScreen> {
  int _sensorCount = 2; 
  int _sampleRate = 104; // Stato per la frequenza
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
      try {
        final config = Esp32Config.fromJson(jsonDecode(configJson));
        setState(() {
          _sensorCount = config.sensorCount;
          _sampleRate = config.sampleRate; // Carica frequenza salvata
        });
      } catch (e) {
        debugPrint("Errore lettura config: $e");
      }
    }
  }

  Future<void> _saveAndSendConfig() async {
    setState(() => _isSending = true);

    // 1. Salva localmente (entrambi i valori)
    final config = Esp32Config(sensorCount: _sensorCount, sampleRate: _sampleRate);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('esp32_config', jsonEncode(config.toJson()));

    // 2. Invia all'ESP32
    final bleService = context.read<BleService>();
    if (!bleService.isConnected) {
      setState(() => _isSending = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('ESP32 not connected'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
      return;
    }

    // Chiama la nuova funzione con 2 parametri
    final success = await bleService.sendSensorConfig(_sensorCount, _sampleRate);

    setState(() => _isSending = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success 
              ? 'Configuration sent successfully' 
              : 'Sending configuration failed'),
          backgroundColor: success ? AppTheme.success : Theme.of(context).colorScheme.error,
        ),
      );
      
      if (success) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ESP32 Configuration'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // HEADER
            Card(
              color: colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      Icons.memory,
                      size: 48,
                      color: colorScheme.onPrimaryContainer,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hardware Setup',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'ESP32-C6 Configuration',
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
            const SizedBox(height: 24),

            // --- SEZIONE SENSORI ---
            Text(
              'Connected Sensors',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Select active IMU sensors.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),

            // Selector sensori [1, 2, 4]
            ...[1, 2, 4].map((count) {
              final isSelected = _sensorCount == count;
              final activeColor = colorScheme.secondary;

              return Card(
                color: isSelected ? activeColor.withValues(alpha: 0.05) : null,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: isSelected 
                      ? BorderSide(color: activeColor, width: 2) 
                      : BorderSide(color: colorScheme.outline.withValues(alpha: 0.3), width: 1),
                ),
                margin: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  onTap: () => setState(() => _sensorCount = count),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isSelected 
                                ? activeColor.withValues(alpha: 0.1) 
                                : colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.sensors,
                            size: 24,
                            color: isSelected ? activeColor : colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$count Sensor${count > 1 ? 's' : ''}',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? activeColor : colorScheme.onSurface,
                                ),
                              ),
                              Text(
                                _getSensorDescription(count),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          Icon(Icons.check_circle, color: activeColor, size: 24),
                      ],
                    ),
                  ),
                ),
              );
            }),

            const SizedBox(height: 24),

            // --- NUOVA SEZIONE: FREQUENZA DI CAMPIONAMENTO ---
            Text(
              'Sample Rate',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Higher frequency = More data precision and higher power consumption.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),

            // Selector Frequenza [104, 208] - LAYOUT ORIZZONTALE
            Row(
              children: [104, 208].map((rate) {
                final isSelected = _sampleRate == rate;
                // Usiamo il colore Terziario (Ciano) per distinguere questa sezione
                final activeColor = colorScheme.tertiary; 

                return Expanded(
                  child: Card(
                    color: isSelected ? activeColor.withValues(alpha: 0.05) : null,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: isSelected 
                          ? BorderSide(color: activeColor, width: 2) 
                          : BorderSide(color: colorScheme.outline.withValues(alpha: 0.3), width: 1),
                    ),
                    // Margine solo tra le due card
                    margin: EdgeInsets.only(
                      right: rate == 104 ? 8 : 0, 
                      left: rate == 208 ? 8 : 0,
                      bottom: 8
                    ),
                    child: InkWell(
                      onTap: () => setState(() => _sampleRate = rate),
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Column(
                          children: [
                            Icon(
                              Icons.speed, // Icona tachimetro
                              color: isSelected ? activeColor : colorScheme.onSurfaceVariant,
                              size: 28,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '$rate Hz',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: isSelected ? activeColor : colorScheme.onSurface,
                              ),
                            ),
                            Text(
                              rate == 104 ? 'Standard' : 'High Perf.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 32),

            // Bottone Salva
            FilledButton.icon(
              onPressed: _isSending ? null : _saveAndSendConfig,
              icon: _isSending 
                  ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    ) 
                  : const Icon(Icons.send),
              label: Text(_isSending ? 'SENDING...' : 'SAVE & SEND'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
            ),

            const SizedBox(height: 16),

            // Nota
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: colorScheme.outlineVariant),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 20, color: colorScheme.secondary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Configuration is saved locally and sent to the connected ESP32.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
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
        return 'Basic setup - Handlebar only';
      case 2:
        return 'Standard setup - Handlebar + BB';
      case 4:
        return 'Advanced setup - Handlebar + BB + F/R wheels';
      default:
        return '';
    }
  }
}
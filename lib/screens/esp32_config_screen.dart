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
          SnackBar(
            content: Text('ESP32 not connected'),
            backgroundColor: Theme.of(context).colorScheme.error,
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
    // Alias per scrivere meno codice e accedere ai colori del tema
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
            // Header card
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

            // Info sensori connessi
            Text(
              'Connected Sensors (LSM6DSOX)',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Select how many IMU sensors should be managed by the system.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),

            // Selector sensori con card visuali
            ...[1, 2, 4].map((count) {
              final isSelected = _sensorCount == count;
              
              // Colore attivo: Tech Blue (Secondary del tema)
              final activeColor = colorScheme.secondary;

              return Card(
                // SFONDO
                color: isSelected ? activeColor.withValues(alpha: 0.05) : null,
                
                // BORDO
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: isSelected 
        // Selezionato: Bordo colorato (Tech Blue) e più spesso (2px)
        ? BorderSide(color: activeColor, width: 2) 
        // Non selezionato: Bordo Grigio sottile (1px)
        : BorderSide(color: colorScheme.outline.withValues(alpha: 0.3), width: 1),
                ),
                margin: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  onTap: () => setState(() => _sensorCount = count),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        // ICONA
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
                            size: 28,
                            color: isSelected ? activeColor : colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 16),
                        
                        // TESTI
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
                              const SizedBox(height: 4),
                              Text(
                                _getSensorDescription(count),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // CHECKMARK
                        if (isSelected)
                          Icon(
                            Icons.check_circle,
                            color: activeColor,
                            size: 24,
                          ),
                      ],
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
                border: Border.all(
                  color: colorScheme.outlineVariant,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 20,
                    color: colorScheme.secondary, // Tech Blue
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'This configuration will be saved locally and sent to the ESP32 immediately.',
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

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/ble_service.dart';
import 'file_manager_screen.dart';
import 'bike_config_screen.dart';
import 'esp32_config_screen.dart';
import 'realtime_preview_screen.dart';
import 'settings_screen.dart';
import 'fork_config_screen.dart';
import 'shock_config_screen.dart';
import 'wheel_config_screen.dart';
import 'config_summary_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();

    final allGranted = statuses.values.every((status) => status.isGranted);
    if (!allGranted && mounted) {
      _showPermissionDialog();
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permessi Necessari'),
        content: const Text(
          'L\'app necessita dei permessi Bluetooth e Posizione per funzionare correttamente.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annulla'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('Apri Impostazioni'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bike Comfort Project'),
        actions: [
          IconButton(
            icon: const Icon(Icons.summarize),
            tooltip: 'Riepilogo Config',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ConfigSummaryScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: Consumer<BleService>(
        builder: (context, bleService, child) {
          if (bleService.isConnected) {
            return _buildConnectedView(bleService);
          } else {
            return _buildScanView(bleService);
          }
        },
      ),
    );
  }

  Widget _buildScanView(BleService bleService) {
    return Column(
      children: [
        // Status card
        Container(
          width: double.infinity,
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Icon(
                bleService.isScanning 
                    ? Icons.bluetooth_searching 
                    : Icons.bluetooth_disabled,
                size: 64,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                bleService.isScanning 
                    ? 'Scansione in corso...' 
                    : 'Cerca il tuo ESP32',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                bleService.isScanning 
                    ? 'Trovati ${bleService.scanResults.length} dispositivi'
                    : 'Premi il pulsante per iniziare',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: bleService.isScanning ? null : _startScan,
                icon: const Icon(Icons.search),
                label: const Text('Avvia Scansione'),
                style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                backgroundColor: const Color(0xFF9C27B0),
                elevation: 8,
                shadowColor: const Color(0xFFE040FB).withValues(alpha: 0.5),
              ),
              ),
            ],
          ),
        ),

        // Lista dispositivi
          Expanded(
            child: bleService.scanResults.isEmpty
                ? Center(
                    child: Text(
                      'Nessun dispositivo trovato',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  )
                : Builder(
                    builder: (context) {
                      // Filtra solo dispositivi ESP32
                      final filteredResults = bleService.scanResults.where((result) {
                        final name = result.device.platformName.toLowerCase();
                        return name.contains('esp');
                      }).toList();

                      // Se dopo il filtro non ci sono dispositivi
                      if (filteredResults.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.search_off,
                                size: 64,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Nessun ESP32 trovato',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Trovati ${bleService.scanResults.length} dispositivi, ma nessuno ESP32',
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      // Mostra solo ESP32 filtrati
                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: filteredResults.length,
                        itemBuilder: (context, index) {
                          final result = filteredResults[index];
                          final device = result.device;
                          final deviceName = device.platformName.isNotEmpty
                              ? device.platformName
                              : 'Dispositivo sconosciuto';

                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: Icon(
                                Icons.sensors,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              title: Text(deviceName),
                              subtitle: Text(
                                'MAC: ${device.remoteId}\nRSSI: ${result.rssi} dBm',
                              ),
                              trailing: CircleAvatar(
                                backgroundColor: result.rssi > -70
                                    ? Colors.green
                                    : result.rssi > -85
                                        ? Colors.orange
                                        : Colors.red,
                                child: Text(
                                  '${result.rssi}',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              onTap: () => _connectToDevice(bleService, device),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),

      ],
    );
  }

  Widget _buildConnectedView(BleService bleService) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Stato connessione
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF6A1B9A),
                  const Color(0xFF9C27B0),
                  const Color(0xFFAB47BC),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF9C27B0).withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white, size: 32),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Connesso',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        Text(
                          bleService.connectedDevice?.platformName ?? 'ESP32',
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => bleService.disconnect(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

// Menu funzioni
Expanded(
  child: GridView.count(
    crossAxisCount: 2,
    mainAxisSpacing: 16,
    crossAxisSpacing: 16,
    childAspectRatio: 0.85, // Regola altezza card
    children: [
      _buildMenuCard(
        icon: Icons.folder_open,
        title: 'Gestione File',
        subtitle: 'SD Card ESP32',
        accentColor: const Color(0xFF9C27B0),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const FileManagerScreen(),
            ),
          );
        },
      ),
      _buildMenuCard(
        icon: Icons.directions_bike,
        title: 'Setup Bici',
        subtitle: 'Tipo e ruote',
        accentColor: const Color(0xFFE040FB),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const BikeConfigScreen(),
            ),
          );
        },
      ),
      _buildMenuCard(
        icon: Icons.settings_input_component,
        title: 'Forcella',
        subtitle: 'Setup anteriore',
        accentColor: const Color(0xFF9C27B0),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ForkConfigScreen(),
            ),
          );
        },
      ),
      _buildMenuCard(
        icon: Icons.published_with_changes,
        title: 'Ammortizzatore',
        subtitle: 'Setup posteriore',
        accentColor: const Color(0xFFE040FB),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ShockConfigScreen(),
            ),
          );
        },
      ),
      _buildMenuCard(
        icon: Icons.album,
        title: 'Ruote',
        subtitle: 'Cerchi e gomme',
        accentColor: const Color(0xFF00BCD4),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const WheelConfigScreen(),
            ),
          );
        },
      ),
      _buildMenuCard(
        icon: Icons.memory,
        title: 'Hardware',
        subtitle: 'Config ESP32',
        accentColor: const Color(0xFF00BCD4),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const Esp32ConfigScreen(),
            ),
          );
        },
      ),
      _buildMenuCard(
        icon: Icons.show_chart,
        title: 'Preview Live',
        subtitle: 'Dati Sensori',
        accentColor: const Color(0xFF9C27B0),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const RealtimePreviewScreen(),
            ),
          );
        },
      ),
      _buildMenuCard(
        icon: Icons.info_outline,
        title: 'Info Sistema',
        subtitle: 'Stato ESP32',
        accentColor: const Color(0xFFAB47BC),
        onTap: () {
          _showSystemInfo();
        },
      ),
    ],
  ),
),

        ],
      ),
    );
  }

  Widget _buildMenuCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? accentColor, // Aggiungi questo parametro
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            accentColor?.withValues(alpha: 0.1) ?? const Color(0xFF2D2538),
            const Color(0xFF2D2538),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: accentColor?.withValues(alpha: 0.3) ?? Colors.transparent,
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 48, color: accentColor ?? const Color(0xFFE040FB)),
                const SizedBox(height: 12),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }


  Future<void> _connectToDevice(BleService bleService, BluetoothDevice device) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Connessione in corso...'),
              ],
            ),
          ),
        ),
      ),
    );

    final success = await bleService.connectToDevice(device);
    
    if (mounted) {
      Navigator.pop(context);
      
      if (!success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Connessione fallita'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showSystemInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Info Sistema'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ESP32-C6 Telemetry System'),
            SizedBox(height: 8),
            Text('Firmware: v1.0.0'),
            Text('Sensori: LSM6DSOX (x2)'),
            Text('Storage: SD Card'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _startScan() async {
    final bleService = context.read<BleService>();
    await bleService.startScan();
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/bike_config.dart';
import '../services/ble_service.dart';
import '../utils/bike_type_prefs.dart';
import 'file_manager_screen.dart';
import 'esp32_config_screen.dart';
import 'realtime_preview_screen.dart';
import 'settings_screen.dart';
import 'fork_config_screen.dart';
import 'shock_config_screen.dart';
import 'wheel_config_screen.dart';
import 'config_summary_screen.dart';
import '../theme/app_theme.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  BikeType _selectedBikeType = BikeType.hardtail; // default

  @override
  void initState() {
    super.initState();
    _checkPermissions();
    _loadBikeType();
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

  Future<void> _loadBikeType() async {
    _selectedBikeType = await BikeTypePrefs.loadBikeType();
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _onBikeTypeChanged(BikeType type) async {
    setState(() {
      _selectedBikeType = type;
    });
    await BikeTypePrefs.saveBikeType(type);
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permissions Required'),
        content: const Text(
          'Bluetooth and Location permissions are required for the app to function.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('Open Settings'),
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
            tooltip: 'Config Summary',
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center, // Centra verticalmente
        children: [
          Card(
            margin: const EdgeInsets.all(32),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    bleService.isScanning
                        ? Icons.radar
                        : Icons.bluetooth_searching,
                    size: 80,
                    // Usa il colore secondario del tema (Tech Blue)
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    bleService.isScanning
                        ? 'Scanning Devices...'
                        : 'Connect to Telemetry',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    bleService.isScanning
                        ? 'Found ${bleService.scanResults.length} devices'
                        : 'Make sure your ESP32 is powered on',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  if (!bleService.isScanning)
                    FilledButton.icon(
                      onPressed: _startScan,
                      icon: const Icon(Icons.search),
                      label: const Text('START SCAN'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(200, 50), // Bottone più grande
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Lista dispositivi
          Expanded(
            child: bleService.scanResults.isEmpty
                ? Center(
                    child: Text(
                      'No devices detected',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  )
                : Builder(
                    builder: (context) {
                      final filteredResults = bleService.scanResults.where((
                        result,
                      ) {
                        final name = result.device.platformName.toLowerCase();
                        return name.contains('esp');
                      }).toList();

                      if (filteredResults.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.search_off,
                                size: 64,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No ESP32 found',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Found ${bleService.scanResults.length} devices, but no ESP32',
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                    ),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: filteredResults.length,
                        itemBuilder: (context, index) {
                          final result = filteredResults[index];
                          final device = result.device;
                          final deviceName = device.platformName.isNotEmpty
                              ? device.platformName
                              : 'Unknown device';

                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            // STILE AGGIORNATO: Card standard gestita dal tema
                            child: ListTile(
                              leading: Icon(
                                Icons.sensors,
                                color: Theme.of(context).colorScheme.secondary,
                              ),
                              title: Text(deviceName),
                              subtitle: Text(
                                'MAC: ${device.remoteId}\nRSSI: ${result.rssi} dBm',
                              ),
                              trailing: CircleAvatar(
                                radius: 14,
                                // Colori semantici mantenuti per utilità
                                backgroundColor: result.rssi > -70
                                    ? Colors.green
                                    : result.rssi > -85
                                    ? Colors.orange
                                    : Theme.of(context).colorScheme.error,
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
      ),
    );
  }

  Widget _buildConnectedView(BleService bleService) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Stato connessione - STILE AGGIORNATO: Rimosso gradiente viola
          Card(
            color: Theme.of(
              context,
            ).colorScheme.primary, // Usa colore scuro del tema
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: Colors.greenAccent,
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'System Connected',
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
          const SizedBox(height: 16),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.pedal_bike,
                        size: 20,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Active Bike Profile',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity, // Occupa tutto lo spazio
                    child: SegmentedButton<BikeType>(
                      segments: const [
                        ButtonSegment(
                          value: BikeType.rigid,
                          label: Text('Rigid'),
                          icon: Icon(Icons.do_not_touch), // Icona simbolica
                        ),
                        ButtonSegment(
                          value: BikeType.hardtail,
                          label: Text('Hardtail'),
                          icon: Icon(Icons.arrow_upward), // Simbolo frontale
                        ),
                        ButtonSegment(
                          value: BikeType.fullSuspension,
                          label: Text('Full'),
                          icon: Icon(
                            Icons.import_export,
                          ), // Simbolo doppia sosp
                        ),
                      ],
                      selected: {_selectedBikeType},
                      onSelectionChanged: (selection) {
                        _onBikeTypeChanged(selection.first);
                      },
                      // Stile compatto per risparmiare spazio verticale
                      style: ButtonStyle(
                        visualDensity: VisualDensity.compact,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Menu funzioni
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 0.9,
              children: [
                // Ho mantenuto gli stessi parametri ma cambiato i colori passati
                // per usare quelli del tema o colori semantici specifici
                _buildMenuCard(
                  icon: Icons.folder_open,
                  title: 'File Manager',
                  subtitle: 'Recording files',
                  accentColor: Theme.of(context).colorScheme.secondary,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const FileManagerScreen(),
                    ),
                  ),
                ),
                if (_selectedBikeType != BikeType.rigid)
                  _buildMenuCard(
                    icon: Icons.settings_input_component,
                    title: 'Fork',
                    subtitle: 'Front setup',
                    accentColor: Theme.of(context).colorScheme.secondary,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ForkConfigScreen(),
                      ),
                    ),
                  ),
                if (_selectedBikeType == BikeType.fullSuspension)
                  _buildMenuCard(
                    icon: Icons.published_with_changes,
                    title: 'Ammortizzatore',
                    subtitle: 'Setup posteriore',
                    accentColor: Theme.of(context).colorScheme.secondary,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ShockConfigScreen(),
                      ),
                    ),
                  ),
                _buildMenuCard(
                  icon: Icons.album,
                  title: 'Ruote',
                  subtitle: 'Cerchi e gomme',
                  accentColor: Theme.of(context).colorScheme.secondary,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const WheelConfigScreen(),
                    ),
                  ),
                ),
                _buildMenuCard(
                  icon: Icons.memory,
                  title: 'Hardware',
                  subtitle: 'Config ESP32',
                  accentColor: Theme.of(
                    context,
                  ).colorScheme.tertiary, // Arancione per hardware
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const Esp32ConfigScreen(),
                    ),
                  ),
                ),
                _buildMenuCard(
                  icon: Icons.show_chart,
                  title: 'Preview Live',
                  subtitle: 'Dati Sensori',
                  accentColor: Theme.of(
                    context,
                  ).colorScheme.tertiary, // Arancione per live
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RealtimePreviewScreen(),
                    ),
                  ),
                ),
                _buildMenuCard(
                  icon: Icons.info_outline,
                  title: 'Info Sistema',
                  subtitle: 'Stato ESP32',
                  accentColor: Colors.grey,
                  onTap: _showSystemInfo,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // STILE AGGIORNATO: Card Flat Tecniche
  Widget _buildMenuCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? accentColor,
  }) {
    final color = accentColor ?? Theme.of(context).colorScheme.secondary;

    return Card(
      // Rimosso Container con gradiente, ora usa lo stile Card del tema (bianco con bordo)
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8), // Match col tema
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icona colorata su sfondo neutro
              Icon(icon, size: 48, color: color),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
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
    );
  }

  Future<void> _connectToDevice(
    BleService bleService,
    BluetoothDevice device,
  ) async {
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
                Text('Connecting...'),
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
          SnackBar(
            content: Text('Connection failed'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _showSystemInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('System Info'),
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

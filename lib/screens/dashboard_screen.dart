import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/bike_config.dart'; // Serve solo per l'enum BikeType
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
  BikeType _selectedBikeType = BikeType.hardtail; // Default safe

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
            icon: const Icon(Icons.summarize_outlined),
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
            icon: const Icon(Icons.settings_outlined),
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

  // --- SCAN VIEW ---
  Widget _buildScanView(BleService bleService) {
    // 1. FILTRO PROFESSIONALE A MONTE
    // Creo una lista contenente SOLO i dispositivi che hanno "esp" nel nome
    final espDevices = bleService.scanResults
        .where((r) => r.device.platformName.toLowerCase().contains('esp'))
        .toList();

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
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
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    bleService.isScanning 
                        ? 'Scanning Devices...' 
                        : 'Connect Telemetry',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  
                  // 2. USO LA LISTA FILTRATA PER IL CONTEGGIO
                  Text(
                    bleService.isScanning 
                        ? 'Found ${espDevices.length} ESP devices' // Conteggio reale
                        : 'Power on your ESP32 unit',
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
                        minimumSize: const Size(200, 50),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // 3. LISTA DISPOSITIVI FILTRATI
          if (espDevices.isNotEmpty)
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: espDevices.length, // Lunghezza della lista filtrata
                itemBuilder: (context, index) {
                  final result = espDevices[index]; // Elemento filtrato
                  
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: Icon(
                        Icons.developer_board,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      title: Text(result.device.platformName),
                      subtitle: Text('ID: ${result.device.remoteId}'),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${result.rssi} dBm', 
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)
                        ),
                      ),
                      onTap: () => _connectToDevice(bleService, result.device),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  // --- CONNECTED VIEW (Dashboard Principale) ---
  Widget _buildConnectedView(BleService bleService) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. STATUS CARD
          Card(
            color: theme.colorScheme.primary,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.wifi_tethering, color: Colors.greenAccent, size: 32),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'System Online',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        Text(
                          bleService.connectedDevice?.platformName ?? 'ESP32 Device',
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.power_settings_new, color: Colors.white70),
                    onPressed: () => bleService.disconnect(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),

          // 2. BIKE SELECTOR CARD (Semplificata)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.pedal_bike, size: 20, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Active Profile',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Selettore a tutta larghezza
                  SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<BikeType>(
                      segments: const [
                        ButtonSegment(
                          value: BikeType.rigid, 
                          label: Text('Rigid'), 
                          icon: Icon(Icons.do_not_touch)
                        ),
                        ButtonSegment(
                          value: BikeType.hardtail, 
                          label: Text('Hardtail'), 
                          icon: Icon(Icons.arrow_upward)
                        ),
                        ButtonSegment(
                          value: BikeType.fullSuspension, 
                          label: Text('Full'), 
                          icon: Icon(Icons.import_export)
                        ),
                      ],
                      selected: {_selectedBikeType},
                      onSelectionChanged: (selection) => _onBikeTypeChanged(selection.first),
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

          const SizedBox(height: 4),

          // 3. MENU GRID
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.0, // Cards quadrate
              children: [
                _buildMenuCard(
                  icon: Icons.sd_storage_outlined,
                  title: 'File Manager',
                  subtitle: 'Logs & Data',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const FileManagerScreen())),
                ),
                
                // --- LOGICA VISIBILITÀ SOSPENSIONI ---
                
                // Card Forcella: Mostra se NON è Rigida (Hardtail o Full)
                if (_selectedBikeType != BikeType.rigid)
                  _buildMenuCard(
                    icon: Icons.compress,
                    title: 'Fork Setup',
                    subtitle: 'Front Susp.',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ForkConfigScreen())),
                  ),
                  
                // Card Ammortizzatore: Mostra SOLO se è Full
                if (_selectedBikeType == BikeType.fullSuspension)
                  _buildMenuCard(
                    icon: Icons.height,
                    title: 'Shock Setup',
                    subtitle: 'Rear Susp.',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ShockConfigScreen())),
                  ),
                  
                _buildMenuCard(
                  icon: Icons.tire_repair,
                  title: 'Wheels',
                  subtitle: 'Tires & Rims',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const WheelConfigScreen())),
                ),
                
                _buildMenuCard(
                  icon: Icons.memory,
                  title: 'Hardware',
                  subtitle: 'ESP32 Config',
                  accentColor: theme.colorScheme.tertiary, // Arancione
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const Esp32ConfigScreen())),
                ),
                
                _buildMenuCard(
                  icon: Icons.show_chart,
                  title: 'Live Data',
                  subtitle: 'Real-time View',
                  accentColor: theme.colorScheme.tertiary, // Arancione
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const RealtimePreviewScreen())),
                ),

                _buildMenuCard(
                  icon: Icons.info_outline,
                  title: 'System Info',
                  subtitle: 'Status',
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

  Widget _buildMenuCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? accentColor,
  }) {
    final theme = Theme.of(context);
    final color = accentColor ?? theme.colorScheme.secondary;
    
    return Card(
      clipBehavior: Clip.hardEdge, // Ripple contenuto
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: color),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- UTILS ---

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
            content: const Text('Connection Failed'),
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
            Text('Sensors: LSM6DSOX'),
            Text('Storage: SD Card'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
        ],
      ),
    );
  }

  Future<void> _startScan() async {
    final bleService = context.read<BleService>();
    await bleService.startScan();
  }
}
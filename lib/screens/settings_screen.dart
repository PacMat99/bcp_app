import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _serverUrlController = TextEditingController();
  bool _isTestingConnection = false;
  bool? _connectionStatus;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final serverUrl = prefs.getString('server_url') ?? 'http://192.168.1.100:5000';
    
    setState(() {
      _serverUrlController.text = serverUrl;
    });

    final apiService = context.read<ApiService>();
    apiService.setBaseUrl(serverUrl);
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('server_url', _serverUrlController.text);

    final apiService = context.read<ApiService>();
    apiService.setBaseUrl(_serverUrlController.text);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impostazioni salvate'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _testConnection() async {
    setState(() {
      _isTestingConnection = true;
      _connectionStatus = null;
    });

    final apiService = context.read<ApiService>();
    apiService.setBaseUrl(_serverUrlController.text);
    
    final success = await apiService.testConnection();

    setState(() {
      _isTestingConnection = false;
      _connectionStatus = success;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Impostazioni'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Server Settings
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.cloud,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Server Backend',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _serverUrlController,
                    decoration: InputDecoration(
                      labelText: 'URL Server Raspberry Pi',
                      hintText: 'http://192.168.1.100:5000',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.link),
                      suffixIcon: _connectionStatus != null
                          ? Icon(
                              _connectionStatus! 
                                  ? Icons.check_circle 
                                  : Icons.error,
                              color: _connectionStatus! 
                                  ? Colors.green 
                                  : Colors.red,
                            )
                          : null,
                    ),
                    keyboardType: TextInputType.url,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isTestingConnection ? null : _testConnection,
                          icon: _isTestingConnection
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.wifi_find),
                          label: const Text('Test Connessione'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _saveSettings,
                          icon: const Icon(Icons.save),
                          label: const Text('Salva'),
                        ),
                      ),
                    ],
                  ),
                  if (_connectionStatus != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        _connectionStatus!
                            ? '✓ Server raggiungibile'
                            : '✗ Server non raggiungibile',
                        style: TextStyle(
                          color: _connectionStatus! ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // App Info
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Informazioni App',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                  const Divider(),
                  _buildInfoRow('Versione', '1.0.0'),
                  _buildInfoRow('Sistema', 'MTB Telemetry'),
                  _buildInfoRow('Hardware', 'ESP32-C6'),
                  _buildInfoRow('Sensori', 'LSM6DSOX x2'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Help
          Card(
            child: ListTile(
              leading: const Icon(Icons.help_outline),
              title: const Text('Guida e Supporto'),
              subtitle: const Text('Come utilizzare l\'app'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Guida Rapida'),
                    content: const SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('1. Connetti l\'ESP32 dalla dashboard'),
                          SizedBox(height: 8),
                          Text('2. Configura la tua bici dal menu'),
                          SizedBox(height: 8),
                          Text('3. Gestisci i file dalla SD Card'),
                          SizedBox(height: 8),
                          Text('4. Visualizza dati in tempo reale'),
                          SizedBox(height: 8),
                          Text('5. Invia i file al server per l\'analisi'),
                        ],
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _serverUrlController.dispose();
    super.dispose();
  }
}

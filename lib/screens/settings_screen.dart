import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart'; // Import necessario per AppTheme.success

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _serverUrlController = TextEditingController();
  bool _isTestingConnection = false;
  bool? _connectionStatus;
  
  // Rimosso late ApiService per evitare problemi di inizializzazione, 
  // lo recuperiamo via context quando serve.

  final _cfClientIdController = TextEditingController();
  final _cfClientSecretController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final serverUrl = prefs.getString('server_url') ?? 'https://api.pacsbrothers.com';
    final cfClientId = prefs.getString('cf_client_id') ?? '';
    final cfClientSecret = prefs.getString('cf_client_secret') ?? '';

    setState(() {
      _serverUrlController.text = serverUrl;
      _cfClientIdController.text = cfClientId;
      _cfClientSecretController.text = cfClientSecret;
    });

    // Aggiorna il servizio se il widget è ancora montato
    if (mounted) {
      final apiService = context.read<ApiService>();
      apiService.setBaseUrl(serverUrl);
      if (cfClientId.isNotEmpty && cfClientSecret.isNotEmpty) {
        apiService.setCloudflareCredentials(cfClientId, cfClientSecret);
      }
    }
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('server_url', _serverUrlController.text);

    if (mounted) {
      final apiService = context.read<ApiService>();
      apiService.setBaseUrl(_serverUrlController.text);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Settings saved'),
          backgroundColor: AppTheme.success, // STILE AGGIORNATO
        ),
      );
    }
  }

  Future<void> _saveCfCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('cf_client_id', _cfClientIdController.text);
    await prefs.setString('cf_client_secret', _cfClientSecretController.text);

    if (mounted) {
      final apiService = context.read<ApiService>();
      apiService.setCloudflareCredentials(
        _cfClientIdController.text,
        _cfClientSecretController.text,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cloudflare credentials saved'),
          backgroundColor: AppTheme.success, // STILE AGGIORNATO
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
    // Assicuriamo di testare l'URL scritto nel campo, anche se non salvato
    apiService.setBaseUrl(_serverUrlController.text);

    final success = await apiService.testConnection();

    if (mounted) {
      setState(() {
        _isTestingConnection = false;
        _connectionStatus = success;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // HEADER CARD (Nuova aggiunta per coerenza)
          Card(
            color: colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Icons.settings_applications,
                    size: 48,
                    color: colorScheme.onPrimaryContainer,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'System Configuration',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Backend & Connectivity',
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
          const SizedBox(height: 24),

          // Server Settings
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.cloud, color: colorScheme.secondary),
                      const SizedBox(width: 8),
                      Text(
                        'Backend Server',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // STILE AGGIORNATO: Input Field pulito (eredita dal tema)
                  TextField(
                    controller: _serverUrlController,
                    decoration: const InputDecoration(
                      labelText: 'Raspberry Pi / Server URL',
                      hintText: 'http://api.domain.com',
                      prefixIcon: Icon(Icons.link),
                    ),
                    keyboardType: TextInputType.url,
                  ),
                  const SizedBox(height: 16),
                  
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
                          label: const Text('Test Connection'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _saveSettings,
                          icon: const Icon(Icons.save),
                          label: const Text('Save'),
                        ),
                      ),
                    ],
                  ),
                  
                  // Visualizzazione Stato Connessione Migliorata
                  if (_connectionStatus != null)
                    Container(
                      margin: const EdgeInsets.only(top: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _connectionStatus! 
                            ? AppTheme.success.withValues(alpha: 0.1) 
                            : colorScheme.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _connectionStatus! 
                              ? AppTheme.success 
                              : colorScheme.error,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _connectionStatus! ? Icons.check_circle : Icons.error,
                            color: _connectionStatus! ? AppTheme.success : colorScheme.error,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            _connectionStatus!
                                ? 'Server Reachable'
                                : 'Connection Failed',
                            style: TextStyle(
                              color: _connectionStatus!
                                ? AppTheme.success
                                : colorScheme.error,
                              fontWeight: FontWeight.bold,
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

          // Credentials settings
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.security, color: colorScheme.secondary),
                      const SizedBox(width: 8),
                      Text(
                        'Cloudflare Access',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _cfClientIdController,
                    decoration: const InputDecoration(
                      labelText: 'CF-Access-Client-Id',
                      prefixIcon: Icon(Icons.vpn_key),
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _cfClientSecretController,
                    decoration: const InputDecoration(
                      labelText: 'CF-Access-Client-Secret',
                      prefixIcon: Icon(Icons.password),
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _saveCfCredentials,
                      icon: const Icon(Icons.lock),
                      label: const Text('Save Secure Credentials'),
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
                      Icon(Icons.info_outline, color: colorScheme.secondary),
                      const SizedBox(width: 8),
                      Text(
                        'App Info',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  _buildInfoRow('Version', '1.0.0'),
                  _buildInfoRow('System', 'MTB Telemetry'),
                  _buildInfoRow('Hardware', 'ESP32-C6'),
                  _buildInfoRow('Sensors', 'LSM6DSOX'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Help
          Card(
            clipBehavior: Clip.hardEdge,
            child: ListTile(
              leading: Icon(Icons.help_outline, color: colorScheme.secondary),
              title: const Text('Help & Support'),
              subtitle: const Text('How to use the app'),
              trailing: Icon(Icons.arrow_forward_ios, size: 16, color: colorScheme.onSurfaceVariant),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Quick Guide'),
                    content: const SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('1. Connect ESP32 via Dashboard'),
                          SizedBox(height: 8),
                          Text('2. Configure Bike & Geometry'),
                          SizedBox(height: 8),
                          Text('3. Manage logs in File Manager'),
                          SizedBox(height: 8),
                          Text('4. View Real-time data stream'),
                          SizedBox(height: 8),
                          Text('5. Upload logs to Server'),
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
          const SizedBox(height: 32),
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
          Text(
            label,
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _serverUrlController.dispose();
    _cfClientIdController.dispose();
    _cfClientSecretController.dispose();
    super.dispose();
  }
}
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
  String _connectionStatus = 'Non testato';
  late ApiService _apiService;


  @override
  void initState() {
    super.initState();
    _apiService = context.read<ApiService>();
    _loadSettings();
  }

  final _cfClientIdController = TextEditingController();
  final _cfClientSecretController = TextEditingController();

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

    final apiService = context.read<ApiService>();
    apiService.setBaseUrl(serverUrl);
    if (cfClientId.isNotEmpty && cfClientSecret.isNotEmpty) {
      apiService.setCloudflareCredentials(cfClientId, cfClientSecret);
    }
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

  Future<void> _saveCfCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('cf_client_id', _cfClientIdController.text);
    await prefs.setString('cf_client_secret', _cfClientSecretController.text);

    final apiService = context.read<ApiService>();
    apiService.setCloudflareCredentials(
      _cfClientIdController.text,
      _cfClientSecretController.text,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Credenziali Cloudflare salvate'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _testConnection() async {
    setState(() {
      _isTestingConnection = true;
      _connectionStatus = 'Testing...';
    });

    final result = await _apiService.testConnection();
    
    setState(() {
      _isTestingConnection = false;
      
      if (result['success'] == true) {
        _connectionStatus = '✅ ${result['message']}';
      } else {
        _connectionStatus = '❌ ${result['message']}';
        _showErrorDialog(result);
      }
    });
  }

  void _showErrorDialog(Map<String, dynamic> error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Errore Connessione'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Errore: ${error['error'] ?? 'Sconosciuto'}'),
              const SizedBox(height: 8),
              Text('Messaggio: ${error['message']}'),
              if (error['statusCode'] != null)
                Text('Status Code: ${error['statusCode']}'),
              if (error['details'] != null) ...[
                const SizedBox(height: 8),
                const Text(
                  'Dettagli:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(error['details'].toString()),
              ],
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
                      hintText: 'http://api.domain.com',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.link),
                      suffixIcon: _connectionStatus != 'Non testato'
                        ? Icon(
                            _connectionStatus.startsWith('✅') 
                                ? Icons.check_circle 
                                : Icons.error,
                            color: _connectionStatus.startsWith('✅') 
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
                  if (_connectionStatus != 'Non testato')
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        _connectionStatus,  // ← Mostra direttamente il messaggio
                        style: TextStyle(
                          color: _connectionStatus.startsWith('✅') 
                              ? Colors.green 
                              : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
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
                      Icon(
                        Icons.security,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Cloudflare Access',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _cfClientIdController,
                    decoration: const InputDecoration(
                      labelText: 'CF-Access-Client-Id',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.vpn_key),
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _cfClientSecretController,
                    decoration: const InputDecoration(
                      labelText: 'CF-Access-Client-Secret',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.password),
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _saveCfCredentials,
                    icon: const Icon(Icons.save),
                    label: const Text('Salva Credenziali'),
                  ),
                ],
              ),
            ),
          ),

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
    _cfClientIdController.dispose();
    _cfClientSecretController.dispose();
    super.dispose();
  }
}

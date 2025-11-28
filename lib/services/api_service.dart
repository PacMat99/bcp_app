import 'dart:io';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../utils/config_helper.dart'; // <-- AGGIUNGI QUESTO

class ApiService {
  late Dio _dio;
  String _baseUrl = 'https://api.pacsbrother.com';
  String? _cfClientId;
  String? _cfClientSecret;

  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 60),
    ));

    _loadCredentials();

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (_cfClientId != null && _cfClientSecret != null) {
            options.headers['CF-Access-Client-Id'] = _cfClientId;
            options.headers['CF-Access-Client-Secret'] = _cfClientSecret;
          }
          return handler.next(options);
        },
        onError: (error, handler) {
          if (error.response?.statusCode == 403) {
            print('Cloudflare Access: autenticazione fallita');
          }
          return handler.next(error);
        },
      ),
    );
  }

  Future<void> _loadCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    _cfClientId = prefs.getString('cf_client_id');
    _cfClientSecret = prefs.getString('cf_client_secret');
  }

  Future<void> setCloudflareCredentials(String clientId, String clientSecret) async {
    _cfClientId = clientId;
    _cfClientSecret = clientSecret;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('cf_client_id', clientId);
    await prefs.setString('cf_client_secret', clientSecret);
  }

  void setBaseUrl(String url) {
    _baseUrl = url;
    _dio.options.baseUrl = _baseUrl;
  }

  String get baseUrl => _baseUrl;

  Future<bool> testConnection() async {
    try {
      final response = await _dio.get('/api/health');
      return response.statusCode == 200;
    } catch (e) {
      print('Test connection error: $e');
      return false;
    }
  }

  // Upload file con TUTTA la configurazione completa
  Future<bool> uploadFile({
    required File file,
    String? sessionName,
  }) async {
    try {
      // Usa l'helper per caricare la configurazione
      final completeConfig = await ConfigHelper.loadCompleteConfig();

      FormData formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          file.path,
          filename: file.path.split('/').last,
        ),
        'session_name': sessionName ?? DateTime.now().toIso8601String(),
        'bike_config': jsonEncode(completeConfig),
      });

      final response = await _dio.post(
        '/api/upload',
        data: formData,
        onSendProgress: (sent, total) {
          print('Upload progress: ${(sent / total * 100).toStringAsFixed(0)}%');
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Errore upload: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> getAnalysis(String sessionId) async {
    try {
      final response = await _dio.get('/api/analysis/$sessionId');
      return response.data;
    } catch (e) {
      print('Errore recupero analisi: $e');
      return null;
    }
  }

  // Metodo helper per ottenere un riepilogo della configurazione
  Future<String> getConfigSummary() async {
    return await ConfigHelper.getConfigSummary();
  }
}

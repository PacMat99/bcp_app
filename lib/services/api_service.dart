import 'dart:io';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/bike_config.dart';

class ApiService {
  late Dio _dio;
  String _baseUrl = 'https://api.pacsbrothers.com';
  String? _cfClientId;
  String? _cfClientSecret;

  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 60),
    ));

    _loadCredentials();

    // Interceptor per aggiungere header dinamicamente
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

  // Metodo per salvare credenziali
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

  // Test connessione server
  Future<bool> testConnection() async {
    try {
      final response = await _dio.get('/health');
      if (response.statusCode == 200) {
        if (response.headers['content-type']?.contains('application/json') ?? false) {
          return true;
        }
      }
      throw("Test connection error");
    } catch (e) {
      print('Test connection error: $e');
      return false;
    }
  }

  

  // Upload file con metadati bici
  Future<bool> uploadFile({
    required File file,
    required BikeConfig bikeConfig,
    String? sessionName,
  }) async {
    try {
      FormData formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          file.path,
          filename: file.path.split('/').last,
        ),
        'bike_config': bikeConfig.toJson().toString(),
        'session_name': sessionName ?? DateTime.now().toIso8601String(),
      });

      final response = await _dio.post(
        '$_baseUrl/api/upload',
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

  // Recupera analisi processata
  Future<Map<String, dynamic>?> getAnalysis(String sessionId) async {
    try {
      final response = await _dio.get('$_baseUrl/api/analysis/$sessionId');
      return response.data;
    } catch (e) {
      print('Errore recupero analisi: $e');
      return null;
    }
  }
}

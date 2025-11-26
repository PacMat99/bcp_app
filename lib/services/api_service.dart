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
            options.headers['CF-Access-Client-Id'] = _cfClientId!.trim();
            options.headers['CF-Access-Client-Secret'] = _cfClientSecret!.trim();
          }
          print('Headers inviati: ${options.headers}');
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
  //Future<bool> testConnection() async {
  //  try {
  //    final response = await _dio.get('/health');
  //    print(response.statusCode);
  //    print(response.headers['content-type']);
  //    return response.statusCode == 200;
  //  } catch (e) {
  //    print('Test connection error: $e');
  //    return false;
  //  }
  //}

  // Test connessione server CON DIAGNOSTICA DETTAGLIATA
  Future<Map<String, dynamic>> testConnection() async {
    try {
      print('=== INIZIO TEST CONNESSIONE ===');
      print('URL: $_baseUrl/api/health');
      print('CF-Client-Id: ${_cfClientId ?? "NON IMPOSTATO"}');
      print('CF-Client-Secret: ${_cfClientSecret != null ? "***PRESENTE***" : "NON IMPOSTATO"}');
      
      final response = await _dio.get('/api/health');
      
      print('\n--- RISPOSTA SERVER ---');
      print('Status Code: ${response.statusCode}');
      print('Content-Type: ${response.headers['content-type']}');
      
      // Controlla se la risposta è HTML (errore Cloudflare)
      final contentType = response.headers['content-type']?.join(', ') ?? '';
      
      if (contentType.contains('html')) {
        print('\n❌ ERRORE: RICEVUTA PAGINA HTML (Cloudflare Access?)');
        print('--- CORPO RISPOSTA ---');
        print(response.data.toString().substring(0, 500)); // Primi 500 caratteri
        
        return {
          'success': false,
          'error': 'Cloudflare Access blocking',
          'statusCode': response.statusCode,
          'contentType': contentType,
          'message': 'Verifica le credenziali CF-Access'
        };
      }
      
      // Risposta JSON valida
      if (response.statusCode == 200) {
        print('\n✅ SUCCESSO: Risposta JSON valida');
        print('--- DATI SERVER ---');
        print(response.data);
        
        return {
          'success': true,
          'statusCode': response.statusCode,
          'data': response.data,
          'message': 'Connessione riuscita'
        };
      }
      
      return {
        'success': false,
        'statusCode': response.statusCode,
        'message': 'Status code inatteso: ${response.statusCode}'
      };
      
    } on DioException catch (e) {
      print('\n❌ ERRORE DIO EXCEPTION');
      print('Type: ${e.type}');
      print('Message: ${e.message}');
      
      if (e.response != null) {
        print('Status Code: ${e.response?.statusCode}');
        print('Response Data: ${e.response?.data}');
        
        return {
          'success': false,
          'error': 'DioException',
          'statusCode': e.response?.statusCode,
          'message': e.message ?? 'Errore di connessione',
          'details': e.response?.data.toString()
        };
      }
      
      return {
        'success': false,
        'error': 'Network Error',
        'message': 'Impossibile raggiungere il server',
        'details': e.message
      };
      
    } catch (e) {
      print('\n❌ ERRORE GENERICO');
      print('Error: $e');
      
      return {
        'success': false,
        'error': 'Generic Error',
        'message': e.toString()
      };
    } finally {
      print('\n=== FINE TEST CONNESSIONE ===\n');
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

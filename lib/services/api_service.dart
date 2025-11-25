import 'dart:io';
import 'package:dio/dio.dart';
import '../models/bike_config.dart';

class ApiService {
  late Dio _dio;
  String _baseUrl = 'http://192.168.1.100:5000'; // Default

  ApiService() {
    _dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 60),
    ));
  }

  void setBaseUrl(String url) {
    _baseUrl = url;
    _dio.options.baseUrl = _baseUrl;
  }

  String get baseUrl => _baseUrl;

  // Test connessione server
  Future<bool> testConnection() async {
    try {
      final response = await _dio.get('$_baseUrl/api/health');
      return response.statusCode == 200;
    } catch (e) {
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

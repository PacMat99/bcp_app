import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../models/sensor_data.dart';
import '../models/file_info.dart';

class BleService extends ChangeNotifier {
  // ===== PLACEHOLDER UUIDs - SOSTITUISCI CON I TUOI =====
  // UUID del tuo ESP32-C6
static const String SERVICE_UUID = "aec37971-05a3-4609-82e4-855be85d0ba2";
static const String CHARACTERISTIC_UUID = "eb75be25-4d72-4f38-bf3a-942e17ef6998";

// Se hai altre characteristic per TX/RX/Stream separate, aggiungile qui
// Altrimenti usa la stessa per tutto:
static const String CHARACTERISTIC_TX_UUID = "eb75be25-4d72-4f38-bf3a-942e17ef6998";
static const String CHARACTERISTIC_RX_UUID = "eb75be25-4d72-4f38-bf3a-942e17ef6998";
static const String CHARACTERISTIC_STREAM_UUID = "eb75be25-4d72-4f38-bf3a-942e17ef6998";
  // =====================================================

  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _txCharacteristic;
  BluetoothCharacteristic? _rxCharacteristic;
  BluetoothCharacteristic? _streamCharacteristic;

  bool _isScanning = false;
  bool _isConnected = false;
  List<ScanResult> _scanResults = [];
  
  final StreamController<SensorData> _sensorDataController = 
      StreamController<SensorData>.broadcast();
  
  StreamSubscription? _connectionSubscription;
  StreamSubscription? _streamSubscription;

  // Getters
  bool get isScanning => _isScanning;
  bool get isConnected => _isConnected;
  List<ScanResult> get scanResults => _scanResults;
  BluetoothDevice? get connectedDevice => _connectedDevice;
  Stream<SensorData> get sensorDataStream => _sensorDataController.stream;

  // Scan dispositivi
  Future<void> startScan() async {
    _isScanning = true;
    _scanResults.clear();
    notifyListeners();

    try {
      FlutterBluePlus.scanResults.listen((results) {
        _scanResults = results;
        notifyListeners();
      });

      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));
      await Future.delayed(const Duration(seconds: 10));
    } catch (e) {
      debugPrint('Errore scan: $e');
    } finally {
      _isScanning = false;
      notifyListeners();
    }
  }

  Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
    _isScanning = false;
    notifyListeners();
  }

  // Connessione
  Future<bool> connectToDevice(BluetoothDevice device) async {
    try {
      await device.connect(
        timeout: const Duration(seconds: 15),
        mtu: 512,
        license: License.free,
      );

      _connectedDevice = device;

      // Monitora stato connessione
      _connectionSubscription = device.connectionState.listen((state) {
        _isConnected = state == BluetoothConnectionState.connected;
        if (!_isConnected) {
          _cleanup();
        }
        notifyListeners();
      });

      // Discover services
      await device.discoverServices();
      
      // Trova le caratteristiche
      for (var service in device.servicesList) {
        if (service.uuid.toString().toLowerCase() == SERVICE_UUID.toLowerCase()) {
          for (var char in service.characteristics) {
            final charUuid = char.uuid.toString().toLowerCase();
            
            if (charUuid == CHARACTERISTIC_TX_UUID.toLowerCase()) {
              _txCharacteristic = char;
            } else if (charUuid == CHARACTERISTIC_RX_UUID.toLowerCase()) {
              _rxCharacteristic = char;
              // Subscribe a notifiche RX
              await char.setNotifyValue(true);
            } else if (charUuid == CHARACTERISTIC_STREAM_UUID.toLowerCase()) {
              _streamCharacteristic = char;
            }
          }
        }
      }

      _isConnected = true;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Errore connessione: $e');
      _isConnected = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> disconnect() async {
    await _connectedDevice?.disconnect();
    _cleanup();
  }

  void _cleanup() {
    _connectedDevice = null;
    _txCharacteristic = null;
    _rxCharacteristic = null;
    _streamCharacteristic = null;
    _isConnected = false;
    _connectionSubscription?.cancel();
    _streamSubscription?.cancel();
    notifyListeners();
  }

  // Comandi ESP32
  Future<void> _sendCommand(String command) async {
    if (_txCharacteristic == null) throw Exception('Non connesso');
    await _txCharacteristic!.write(utf8.encode(command));
  }

  Future<List<int>> _readResponse() async {
    if (_rxCharacteristic == null) throw Exception('Non connesso');
    return await _rxCharacteristic!.read();
  }

  // Lista file su SD
  Future<List<FileInfo>> listFiles() async {
    try {
      await _sendCommand('LIST_FILES');
      await Future.delayed(const Duration(milliseconds: 500));
      
      final response = await _readResponse();
      final jsonString = utf8.decode(response);
      final List<dynamic> filesJson = jsonDecode(jsonString);
      
      return filesJson.map((json) => FileInfo.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Errore lista file: $e');
      return [];
    }
  }

  // Download file
  Future<List<int>?> downloadFile(String filename) async {
    try {
      await _sendCommand('DOWNLOAD:$filename');
      
      // Leggi file in chunks
      List<int> fileData = [];
      bool receiving = true;
      
      while (receiving) {
        await Future.delayed(const Duration(milliseconds: 100));
        final chunk = await _readResponse();
        
        if (chunk.isEmpty || chunk.length < 4) {
          receiving = false;
        } else {
          fileData.addAll(chunk);
        }
      }
      
      return fileData;
    } catch (e) {
      debugPrint('Errore download: $e');
      return null;
    }
  }

  // Elimina file
  Future<bool> deleteFile(String filename) async {
    try {
      await _sendCommand('DELETE:$filename');
      await Future.delayed(const Duration(milliseconds: 200));
      final response = await _readResponse();
      return utf8.decode(response).contains('OK');
    } catch (e) {
      debugPrint('Errore eliminazione: $e');
      return false;
    }
  }

  // Stream dati real-time
  Future<void> startDataStream() async {
    if (_streamCharacteristic == null) return;

    try {
      await _streamCharacteristic!.setNotifyValue(true);
      
      _streamSubscription = _streamCharacteristic!.lastValueStream.listen((data) {
        if (data.isNotEmpty) {
          final sensorData = SensorData.fromBytes(data);
          _sensorDataController.add(sensorData);
        }
      });

      await _sendCommand('START_STREAM');
    } catch (e) {
      debugPrint('Errore avvio stream: $e');
    }
  }

  Future<void> stopDataStream() async {
    try {
      await _sendCommand('STOP_STREAM');
      await _streamCharacteristic?.setNotifyValue(false);
      _streamSubscription?.cancel();
    } catch (e) {
      debugPrint('Errore stop stream: $e');
    }
  }

  // Invia configurazione sensori all'ESP32
  Future<bool> sendSensorConfig(int sensorCount) async {
    try {
      if (_txCharacteristic == null) throw Exception('Non connesso');
      
      // Formato comando: CONFIG:SENSORS:X dove X è il numero di sensori
      final command = 'CONFIG:SENSORS:$sensorCount';
      await _txCharacteristic!.write(utf8.encode(command));
      
      // Attendi risposta
      await Future.delayed(const Duration(milliseconds: 300));
      final response = await _readResponse();
      final responseStr = utf8.decode(response);
      
      debugPrint('Risposta ESP32: $responseStr');
      return responseStr.contains('OK');
    } catch (e) {
      debugPrint('Errore invio config: $e');
      return false;
    }
  }


  @override
  void dispose() {
    _connectionSubscription?.cancel();
    _streamSubscription?.cancel();
    _sensorDataController.close();
    super.dispose();
  }
}

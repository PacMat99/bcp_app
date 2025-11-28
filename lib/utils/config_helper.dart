import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class ConfigHelper {
  // Carica TUTTA la configurazione salvata
  static Future<Map<String, dynamic>> loadCompleteConfig() async {
    final prefs = await SharedPreferences.getInstance();
    
    Map<String, dynamic> config = {
      'timestamp': DateTime.now().toIso8601String(),
    };

    // Bike config base
    final bikeConfigJson = prefs.getString('bike_config');
    if (bikeConfigJson != null && bikeConfigJson.isNotEmpty) {
      try {
        config['bike'] = jsonDecode(bikeConfigJson);
      } catch (e) {
        print('Error parsing bike_config: $e');
      }
    }

    // Fork config
    final forkConfigJson = prefs.getString('fork_config');
    if (forkConfigJson != null && forkConfigJson.isNotEmpty) {
      try {
        config['fork'] = jsonDecode(forkConfigJson);
      } catch (e) {
        print('Error parsing fork_config: $e');
      }
    }

    // Shock config
    final shockConfigJson = prefs.getString('shock_config');
    if (shockConfigJson != null && shockConfigJson.isNotEmpty) {
      try {
        config['shock'] = jsonDecode(shockConfigJson);
      } catch (e) {
        print('Error parsing shock_config: $e');
      }
    }

    // Wheel config
    final wheelConfigJson = prefs.getString('wheel_config');
    if (wheelConfigJson != null && wheelConfigJson.isNotEmpty) {
      try {
        config['wheels'] = jsonDecode(wheelConfigJson);
      } catch (e) {
        print('Error parsing wheel_config: $e');
      }
    }

    // ESP32 config
    final esp32ConfigJson = prefs.getString('esp32_config');
    if (esp32ConfigJson != null && esp32ConfigJson.isNotEmpty) {
      try {
        config['esp32'] = jsonDecode(esp32ConfigJson);
      } catch (e) {
        print('Error parsing esp32_config: $e');
      }
    }

    return config;
  }

  // Helper per ottenere un riepilogo testuale (per debug/UI)
  static Future<String> getConfigSummary() async {
    final config = await loadCompleteConfig();
    return jsonEncode(config);
  }

  // Helper per verificare se una configurazione specifica esiste
  static Future<bool> hasConfig(String configKey) async {
    final prefs = await SharedPreferences.getInstance();
    final configJson = prefs.getString(configKey);
    return configJson != null && configJson.isNotEmpty;
  }

  // Helper per verificare se tutte le configurazioni sono complete
  static Future<bool> isConfigComplete() async {
    return await hasConfig('bike_config') &&
           await hasConfig('fork_config') &&
           await hasConfig('shock_config') &&
           await hasConfig('wheels_config') &&
           await hasConfig('esp32_config');
  }
}

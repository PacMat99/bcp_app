import 'package:shared_preferences/shared_preferences.dart';
import '../models/bike_config.dart'; // o dove sta BikeType

class BikeTypePrefs {
  static const _key = 'bike_type';

  static Future<void> saveBikeType(BikeType type) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, type.name); // 'rigid' | 'hardtail' | 'fullSuspension'
  }

  static Future<BikeType> loadBikeType() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_key);
    if (value == null) return BikeType.fullSuspension; // default
    return BikeType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => BikeType.fullSuspension,
    );
  }
}

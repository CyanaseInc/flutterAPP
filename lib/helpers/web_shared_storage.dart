import 'package:shared_preferences/shared_preferences.dart';

class WebSharedStorage {
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  String getCommon(String key) {
    return _prefs?.getString(key) ?? '';
  }

  Future<void> setCommon(String key, String value) async {
    await _prefs?.setString(key, value);
  }

  Future<void> removeCommon(String key) async {
    await _prefs?.remove(key);
  }

  Future<void> clearAll() async {
    await _prefs?.clear();
  }
}

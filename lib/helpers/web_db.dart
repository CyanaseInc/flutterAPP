import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WebSharedStorage {
  static SharedPreferences? preferences;

  // initialises shared Storage
  static Future<void> init() async {
    preferences ??= await SharedPreferences.getInstance();
    // const androidOptions = AndroidOptions(
    //   encryptedSharedPreferences: true,
    // );
    // _secureStorage ??= const FlutterSecureStorage(aOptions: androidOptions);
  }

  /// Sets the value for the key to common preferences storage
  Future<bool> setCommon<T>(String key, T value) {
    return switch (T) {
      const (String) => preferences!.setString(key, value as String),
      const (List<String>) =>
        preferences!.setStringList(key, value as List<String>),
      const (int) => preferences!.setInt(key, value as int),
      const (bool) => preferences!.setBool(key, value as bool),
      const (double) => preferences!.setDouble(key, value as double),
      _ => preferences!.setString(key, value as String)
    };
  }

  /// Reads the value for the key from common preferences storage
  T? getCommon<T>(String key) {
    try {
      return switch (T) {
        const (String) => preferences!.getString(key) as T?,
        const (List<String>) => preferences!.getStringList(key) as T?,
        const (int) => preferences!.getInt(key) as T?,
        const (bool) => preferences!.getBool(key) as T?,
        const (double) => preferences!.getDouble(key) as T?,
        _ => preferences!.get(key) as T?
      };
    } on PlatformException catch (ex) {
      dynamic appLogger;
      appLogger.debug('$ex');
      return null;
    }
  }
}

import 'package:shared_preferences/shared_preferences.dart';

class UserPreferencesService {
  static const String _keyRememberData = 'remember_data';
  static const String _keySignerName = 'signer_name';
  static const String _keySignerId = 'signer_id';
  static const String _keyLocation = 'location';
  static const String _keyReason = 'reason';
  static const String _keyEnableTimestamp = 'enable_timestamp';
  static const String _keyTsaServer = 'tsa_server';

  static Future<void> setRememberData(bool remember) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyRememberData, remember);
  }

  static Future<bool> getRememberData() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyRememberData) ?? false;
  }

  static Future<void> saveUserData({
    required String signerName,
    required String signerId,
    required String location,
    required String reason,
    String? enableTimestamp,
    String? tsaServer,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keySignerName, signerName);
    await prefs.setString(_keySignerId, signerId);
    await prefs.setString(_keyLocation, location);
    await prefs.setString(_keyReason, reason);
    if (enableTimestamp != null) {
      await prefs.setString(_keyEnableTimestamp, enableTimestamp);
    }
    if (tsaServer != null) {
      await prefs.setString(_keyTsaServer, tsaServer);
    }
  }

  static Future<Map<String, String>> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'signerName': prefs.getString(_keySignerName) ?? '',
      'signerId': prefs.getString(_keySignerId) ?? '',
      'location': prefs.getString(_keyLocation) ?? 'Ecuador',
      'reason': prefs.getString(_keyReason) ?? 'Firma digital',
      'enableTimestamp': prefs.getString(_keyEnableTimestamp) ?? 'false',
      'tsaServer': prefs.getString(_keyTsaServer) ?? 'https://freetsa.org/tsr',
    };
  }

  static Future<void> clearUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keySignerName);
    await prefs.remove(_keySignerId);
    await prefs.remove(_keyLocation);
    await prefs.remove(_keyReason);
    await prefs.remove(_keyEnableTimestamp);
    await prefs.remove(_keyTsaServer);
  }
} 
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// Provider for current user ID
/// Generates and stores a unique user ID for the device
final userIdProvider = FutureProvider<String>((ref) async {
  const storageKey = 'user_id';
  final prefs = await SharedPreferences.getInstance();
  
  // Try to get existing user ID
  String? userId = prefs.getString(storageKey);
  
  // If no user ID exists, generate a new one
  if (userId == null || userId.isEmpty) {
    const uuid = Uuid();
    userId = uuid.v4();
    await prefs.setString(storageKey, userId);
  }
  
  return userId;
});

/// Provider for current user name
/// Can be set by the user
final userNameProvider = StateNotifierProvider<UserNameNotifier, AsyncValue<String>>((ref) {
  return UserNameNotifier();
});

class UserNameNotifier extends StateNotifier<AsyncValue<String>> {
  static const String _storageKey = 'user_name';
  
  UserNameNotifier() : super(const AsyncValue.loading()) {
    _loadUserName();
  }
  
  Future<void> _loadUserName() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userName = prefs.getString(_storageKey) ?? 'Usuario';
      state = AsyncValue.data(userName);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }
  
  Future<void> setUserName(String name) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, name);
      state = AsyncValue.data(name);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }
}


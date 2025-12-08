import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Простий сервіс локального сховища поверх SharedPreferences.
/// Використовується репозиторіями як key-value сховище.
class LocalStorageService {
  // Singleton
  static final LocalStorageService _instance = LocalStorageService._internal();

  factory LocalStorageService() => _instance;

  LocalStorageService._internal();

  SharedPreferences? _prefs;

  Future<SharedPreferences> _getPrefs() async {
    return _prefs ??= await SharedPreferences.getInstance();
  }

  /// Прочитати рядок за ключем.
  Future<String?> read(String key) async {
    final prefs = await _getPrefs();
    return prefs.getString(key);
  }

  /// Записати рядок за ключем.
  Future<void> write(String key, String value) async {
    final prefs = await _getPrefs();
    await prefs.setString(key, value);
  }

  /// Видалити ключ.
  Future<void> delete(String key) async {
    final prefs = await _getPrefs();
    await prefs.remove(key);
  }

  /// ───────────── JSON helpers (об’єкт) ─────────────

  Future<Map<String, dynamic>?> readJson(String key) async {
    final raw = await read(key);
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> writeJson(String key, Map<String, dynamic> value) async {
    final raw = jsonEncode(value);
    await write(key, raw);
  }

  /// ───────────── JSON helpers (список об’єктів) ─────────────

  /// Прочитати список JSON-об’єктів з ключа.
  /// Якщо нічого немає або формат не той — повертає [].
  Future<List<Map<String, dynamic>>> loadJsonList(String key) async {
    final raw = await read(key);
    if (raw == null || raw.isEmpty) return [];

    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded.whereType<Map<String, dynamic>>().toList(
          growable: false,
        );
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  /// Зберегти список JSON-об’єктів у ключ.
  Future<void> saveJsonList(
    String key,
    List<Map<String, dynamic>> jsonList,
  ) async {
    final raw = jsonEncode(jsonList);
    await write(key, raw);
  }

  /// Очистити конкретний ключ (для зручності).
  Future<void> clearKey(String key) async {
    await delete(key);
  }
}

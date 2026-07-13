/// 本地存储服务
/// SharedPreferences 封装，兼容 PC 版 localStorage 语义

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  late final SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // ===== 字符串操作（对应 localStorage.getItem / setItem）=====

  String? getString(String key) => _prefs.getString(key);

  Future<void> setString(String key, String value) => _prefs.setString(key, value);

  Future<void> remove(String key) => _prefs.remove(key);

  // ===== JSON 读写（对应 readJSON / writeJSON）=====

  /// 读取 JSON 值并解析，失败返回 fallback
  T readJSON<T>(String key, T fallback) {
    final raw = _prefs.getString(key);
    if (raw == null) return fallback;
    try {
      return jsonDecode(raw) as T;
    } catch (_) {
      return fallback;
    }
  }

  /// 将值序列化为 JSON 并存储
  Future<void> writeJSON(String key, Object? value) async {
    await _prefs.setString(key, jsonEncode(value));
  }

  // ===== 便捷方法 =====

  int? getInt(String key) {
    final raw = _prefs.getString(key);
    if (raw == null) return null;
    return int.tryParse(raw);
  }

  Future<void> setInt(String key, int value) => _prefs.setString(key, value.toString());
}

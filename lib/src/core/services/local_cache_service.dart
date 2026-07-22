import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalCacheService {
  static const String _tsSuffix = '_ts';

  /// Save raw string or JSON data with optional TTL in minutes (default: 60 mins).
  Future<bool> save(String key, dynamic value, {int ttlMinutes = 60}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String stringValue;
      if (value is String) {
        stringValue = value;
      } else {
        stringValue = json.encode(value);
      }
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      final expiryMs = nowMs + (ttlMinutes * 60 * 1000);

      await prefs.setString(key, stringValue);
      await prefs.setInt('$key$_tsSuffix', expiryMs);
      return true;
    } catch (e) {
      debugPrint('LocalCacheService save error [$key]: $e');
      return false;
    }
  }

  /// Retrieve cached JSON data if it exists and hasn't expired.
  /// Returns null if missing or expired.
  Future<dynamic> get(String key, {bool ignoreExpiry = false}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stringValue = prefs.getString(key);
      if (stringValue == null) return null;

      if (!ignoreExpiry) {
        final expiryMs = prefs.getInt('$key$_tsSuffix');
        if (expiryMs != null) {
          final nowMs = DateTime.now().millisecondsSinceEpoch;
          if (nowMs > expiryMs) {
            debugPrint('LocalCacheService key [$key] expired.');
            return null;
          }
        }
      }

      return json.decode(stringValue);
    } catch (e) {
      debugPrint('LocalCacheService get error [$key]: $e');
      return null;
    }
  }

  /// Check if a cache key exists and is valid.
  Future<bool> isValid(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final stringValue = prefs.getString(key);
    if (stringValue == null) return false;
    final expiryMs = prefs.getInt('$key$_tsSuffix');
    if (expiryMs == null) return true;
    return DateTime.now().millisecondsSinceEpoch <= expiryMs;
  }

  /// Remove a key from cache.
  Future<void> remove(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(key);
      await prefs.remove('$key$_tsSuffix');
    } catch (e) {
      debugPrint('LocalCacheService remove error [$key]: $e');
    }
  }

  /// Clear all cache entries.
  Future<void> clearAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    } catch (e) {
      debugPrint('LocalCacheService clearAll error: $e');
    }
  }
}

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class OfflineSyncService {
  static const String _queueKey = 'offline_attendance_queue';
  final ApiService _api = ApiService();

  Future<void> saveOfflineAttendance({
    required String jenis,
    required double latitude,
    required double longitude,
    required String fotoPath,
    required bool isMocked,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> currentQueue = prefs.getStringList(_queueKey) ?? [];

    final item = {
      'jenis': jenis,
      'latitude': latitude,
      'longitude': longitude,
      'fotoPath': fotoPath,
      'isMocked': isMocked,
      'createdAt': DateTime.now().toIso8601String(),
    };

    currentQueue.add(jsonEncode(item));
    await prefs.setStringList(_queueKey, currentQueue);
    debugPrint('Saved offline attendance item to queue. Total: ${currentQueue.length}');
  }

  Future<int> getPendingQueueCount() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> currentQueue = prefs.getStringList(_queueKey) ?? [];
    return currentQueue.length;
  }

  Future<bool> syncOfflineAttendances() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> currentQueue = prefs.getStringList(_queueKey) ?? [];

    if (currentQueue.isEmpty) return true;

    debugPrint('Attempting to sync ${currentQueue.length} offline attendance items...');
    final List<String> remainingQueue = [];
    int successCount = 0;

    for (String itemStr in currentQueue) {
      try {
        final Map<String, dynamic> item = jsonDecode(itemStr);
        await _api.submitAttendance(
          jenis: item['jenis'],
          latitude: (item['latitude'] as num).toDouble(),
          longitude: (item['longitude'] as num).toDouble(),
          fotoPath: item['fotoPath'],
          isMocked: item['isMocked'] ?? false,
        );
        successCount++;
      } catch (e) {
        debugPrint('Failed to sync item: $e');
        remainingQueue.add(itemStr);
      }
    }

    await prefs.setStringList(_queueKey, remainingQueue);
    debugPrint('Offline sync completed. Success: $successCount, Remaining: ${remainingQueue.length}');
    return remainingQueue.isEmpty;
  }
}

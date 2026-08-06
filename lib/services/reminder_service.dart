import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReminderService {
  static const String _reminderEnabledKey = 'presensi_reminder_enabled';
  static const String _morningTimeKey = 'presensi_morning_time';
  static const String _eveningTimeKey = 'presensi_evening_time';

  Future<bool> isReminderEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_reminderEnabledKey) ?? true;
  }

  Future<void> setReminderEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_reminderEnabledKey, enabled);
    debugPrint('Presensi reminder enabled state set to: $enabled');
  }

  Future<String> getMorningTime() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_morningTimeKey) ?? '07:15';
  }

  Future<String> getEveningTime() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_eveningTimeKey) ?? '15:45';
  }

  Future<void> updateScheduleTimes({required String morning, required String evening}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_morningTimeKey, morning);
    await prefs.setString(_eveningTimeKey, evening);
    debugPrint('Updated reminder schedule times: Morning=$morning, Evening=$evening');
  }

  Future<void> checkAndTriggerAlarm() async {
    final enabled = await isReminderEnabled();
    if (!enabled) return;

    final now = DateTime.now();
    final morning = await getMorningTime();
    final evening = await getEveningTime();

    final nowStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    if (nowStr == morning) {
      debugPrint('⏰ ALARM PRESENSI: Pengingat Presensi Masuk ($morning)');
    } else if (nowStr == evening) {
      debugPrint('⏰ ALARM PRESENSI: Pengingat Presensi Pulang ($evening)');
    }
  }
}

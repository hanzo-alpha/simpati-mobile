class ApiConfig {
  // Using localhost with adb reverse for Laravel Herd (Port 8080 -> 443)
  static const String baseUrl = 'https://localhost:8080/api';

  // Timeout settings
  static const int connectTimeout = 30;
  static const int receiveTimeout = 30;

  // Endpoints
  static const String login = '/login';
  static const String logout = '/logout';
  static const String me = '/me';

  static const String attendanceStore = '/attendance';
  static const String attendanceToday = '/attendance/today';
  static const String attendanceHistory = '/attendance/history';

  static const String leaveRequests = '/leave-requests';
  static const String fcmToken = '/fcm-token';
  static const String attendanceSchedule = '/attendance/schedule';
  static const String ranking = '/ranking';
}

import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  Map<String, dynamic>? _user;
  bool _isLoading = false;
  String? _error;

  Map<String, dynamic>? get user => _user;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _user != null;
  String? get error => _error;

  String get userName => _user?['name'] ?? 'ASN';
  String get userNip => _user?['nip'] ?? '';
  String get userRole => _user?['role']?['display_name'] ?? 'ASN';
  String get userOpdName => _user?['office']?['opd_name'] ?? '-';
  String get userJabatan => _user?['profile']?['jabatan'] ?? '-';
  int get sisaCuti => _user?['profile']?['sisa_cuti_tahunan'] ?? 0;

  bool get isSupervisor {
    if (_user == null) return false;
    final roleName = _user?['role']?['name']?.toString().toLowerCase() ?? '';
    final roleId = _user?['role_id'];
    final isSup = _user?['is_supervisor'] == true ||
        (_user?['subordinates_count'] != null &&
            (_user!['subordinates_count'] as int) > 0);
    return isSup ||
        roleId == 2 ||
        roleId == 3 ||
        roleName == 'super_admin' ||
        roleName == 'admin_opd' ||
        roleName == 'atasan';
  }

  Future<bool> checkAuth() async {
    if (await _api.isLoggedIn()) {
      try {
        final response = await _api.getProfile();
        _user = response.data['user'];
        notifyListeners();
        return true;
      } catch (e) {
        await _api.clearToken();
      }
    }
    return false;
  }

  Future<bool> login(String nip, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _api.login(nip, password);
      _user = response.data['user'];

      // Update FCM Token & Schedule Alarms
      final notificationService = NotificationService();
      await notificationService.updateToken();
      await notificationService.scheduleAttendanceAlarms();

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = _extractError(e);
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _api.logout();
    _user = null;
    notifyListeners();
  }

  String _extractError(dynamic e) {
    if (kDebugMode) {
      debugPrint('Login Error: $e');
    }
    if (e is Exception) {
      try {
        final dioError = e as dynamic;
        final data = dioError.response?.data;
        if (data is Map && data.containsKey('message')) {
          return data['message'];
        }
        if (data is Map && data.containsKey('errors')) {
          final errors = data['errors'] as Map;
          return errors.values.first.first ?? 'Login gagal';
        }
      } catch (_) {}
    }
    return 'Terjadi kesalahan. Periksa koneksi internet.';
  }
}

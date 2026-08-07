import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/api_config.dart';

class ApiService {
  late final Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  static const String _tokenKey = 'auth_token';

  ApiService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: const Duration(seconds: ApiConfig.connectTimeout),
        receiveTimeout: const Duration(seconds: ApiConfig.receiveTimeout),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Bypass SSL certificate validation for development (Herd HTTPS/IP testing)
    (_dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
      final client = HttpClient();
      client.badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
      return client;
    };

    if (kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(
          requestHeader: true,
          requestBody: true,
          responseHeader: true,
          responseBody: true,
          error: true,
        ),
      );
    }

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (error, handler) {
          if (error.response?.statusCode == 401) {
            clearToken();
          }
          return handler.next(error);
        },
      ),
    );
  }

  // ─── Token Management ──────────────────────────
  Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  Future<void> clearToken() async {
    await _storage.delete(key: _tokenKey);
  }

  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  static const String _deviceIdKey = 'device_id';

  Future<String> getDeviceId() async {
    String? deviceId = await _storage.read(key: _deviceIdKey);
    if (deviceId == null || deviceId.isEmpty) {
      deviceId =
          'DEV-${DateTime.now().millisecondsSinceEpoch}-${(1000 + (DateTime.now().microsecondsSinceEpoch % 9000))}';
      await _storage.write(key: _deviceIdKey, value: deviceId);
    }
    return deviceId;
  }

  // ─── Auth ──────────────────────────────────────
  Future<Response> login(String nip, String password) async {
    final deviceId = await getDeviceId();
    final response = await _dio.post(
      ApiConfig.login,
      data: {'nip': nip, 'password': password, 'device_id': deviceId},
    );
    if (response.data['token'] != null) {
      await saveToken(response.data['token']);
    }
    return response;
  }

  Future<Response> requestDeviceReset({
    required String nip,
    required String password,
    required String alasan,
  }) async {
    return await _dio.post(
      '${ApiConfig.baseUrl}/request-device-reset',
      data: {'nip': nip, 'password': password, 'alasan': alasan},
    );
  }

  Future<Response> getProfile() async {
    return await _dio.get(ApiConfig.me);
  }

  Future<void> logout() async {
    try {
      await _dio.post(ApiConfig.logout);
    } finally {
      await clearToken();
    }
  }

  // ─── Attendance ────────────────────────────────
  Future<Response> submitAttendance({
    required String jenis,
    required double latitude,
    required double longitude,
    required String fotoPath,
    bool isMocked = false,
    bool isLivePhoto = true,
  }) async {
    final deviceId = await getDeviceId();
    final formData = FormData.fromMap({
      'jenis': jenis,
      'latitude': latitude,
      'longitude': longitude,
      'is_mocked': isMocked ? 1 : 0,
      'is_live_photo': isLivePhoto ? 1 : 0,
      'device_id': deviceId,
      'foto_selfie': await MultipartFile.fromFile(
        fotoPath,
        filename: 'selfie.jpg',
      ),
    });
    return await _dio.post(ApiConfig.attendanceStore, data: formData);
  }

  Future<Response> getTodayAttendance() async {
    return await _dio.get(ApiConfig.attendanceToday);
  }

  Future<Response> getAttendanceHistory({int? year, int? month}) async {
    return await _dio.get(
      ApiConfig.attendanceHistory,
      queryParameters: {'year': year, 'month': month},
    );
  }

  Future<Response> getSchedule() async {
    return await _dio.get(ApiConfig.attendanceSchedule);
  }

  Future<Response> getStatistics({int? year, int? month}) async {
    return await _dio.get(
      '${ApiConfig.baseUrl}/statistics',
      queryParameters: {'year': year, 'month': month},
    );
  }

  Future<Response> exportAttendancePdf({int? year, int? month}) async {
    return await _dio.get(
      '${ApiConfig.baseUrl}/attendance/export-pdf',
      queryParameters: {'year': year, 'month': month},
    );
  }

  Future<Response> scanQrAttendance({required String qrCode, String? acara}) async {
    return await _dio.post(
      '${ApiConfig.baseUrl}/attendance/scan-qr',
      data: {'qr_code': qrCode, 'acara': acara},
    );
  }

  Future<Response> getSupervisionLiveLocations() async {
    return await _dio.get('${ApiConfig.baseUrl}/supervision/live-locations');
  }

  Future<Response> getAnnouncements() async {
    return await _dio.get('${ApiConfig.baseUrl}/announcements');
  }

  // ─── Shift Swap Requests ────────────────────────────
  Future<Response> getShiftSwaps() async {
    return await _dio.get('${ApiConfig.baseUrl}/shift-swaps');
  }

  Future<Response> getSubordinateShiftSwaps({String? status}) async {
    final Map<String, dynamic> params = {};
    if (status != null && status.isNotEmpty) {
      params['status'] = status;
    }
    return await _dio.get(
      '${ApiConfig.baseUrl}/shift-swaps/subordinates',
      queryParameters: params,
    );
  }

  Future<Response> createShiftSwap({
    required int targetUserId,
    required String tanggalShift,
    required String alasan,
  }) async {
    return await _dio.post(
      '${ApiConfig.baseUrl}/shift-swaps',
      data: {
        'target_user_id': targetUserId,
        'tanggal_shift': tanggalShift,
        'alasan': alasan,
      },
    );
  }

  Future<Response> updateShiftSwapStatus({
    required int id,
    required String status,
  }) async {
    return await _dio.patch(
      '${ApiConfig.baseUrl}/shift-swaps/$id/status',
      data: {'status': status},
    );
  }

  // ─── Attendance Corrections (Lupa Absen) ─────────
  Future<Response> getAttendanceCorrections() async {
    return await _dio.get('${ApiConfig.baseUrl}/attendance-corrections');
  }

  Future<Response> getSubordinateAttendanceCorrections({String? status}) async {
    final Map<String, dynamic> params = {};
    if (status != null && status.isNotEmpty) {
      params['status'] = status;
    }
    return await _dio.get(
      '${ApiConfig.baseUrl}/attendance-corrections/subordinates',
      queryParameters: params,
    );
  }

  Future<Response> submitAttendanceCorrection({
    required String tanggal,
    required String jenis,
    required String jamKoreksi,
    required String alasan,
    String? lampiranPath,
  }) async {
    final formData = FormData.fromMap({
      'tanggal': tanggal,
      'jenis': jenis,
      'jam_koreksi': jamKoreksi,
      'alasan': alasan,
      if (lampiranPath != null)
        'lampiran': await MultipartFile.fromFile(lampiranPath),
    });
    return await _dio.post(
      '${ApiConfig.baseUrl}/attendance-corrections',
      data: formData,
    );
  }

  Future<Response> updateAttendanceCorrectionStatus({
    required int id,
    required String status,
    String? catatanApproval,
  }) async {
    return await _dio.patch(
      '${ApiConfig.baseUrl}/attendance-corrections/$id/status',
      data: {'status': status, 'catatan_approval': catatanApproval},
    );
  }

  // ─── Leave Requests ────────────────────────────
  Future<Response> getLeaveRequests({String? status}) async {
    final Map<String, dynamic> params = {};
    if (status != null && status.isNotEmpty) {
      params['status'] = status;
    }
    return await _dio.get(
      ApiConfig.leaveRequests,
      queryParameters: params,
    );
  }

  Future<Response> getSubordinateLeaveRequests({String? status}) async {
    final Map<String, dynamic> params = {};
    if (status != null && status.isNotEmpty) {
      params['status'] = status;
    }
    return await _dio.get(
      '${ApiConfig.leaveRequests}/subordinates',
      queryParameters: params,
    );
  }

  Future<Response> updateLeaveRequestStatus(
    int id, {
    required String status,
    String? catatanApproval,
  }) async {
    return await _dio.patch(
      '${ApiConfig.leaveRequests}/$id/status',
      data: {'status': status, 'catatan_approval': catatanApproval},
    );
  }

  Future<Response> submitLeaveRequest({
    required String type,
    required String tanggalMulai,
    required String tanggalSelesai,
    required String alasan,
    String? lampiranPath,
  }) async {
    final formData = FormData.fromMap({
      'type': type,
      'tanggal_mulai': tanggalMulai,
      'tanggal_selesai': tanggalSelesai,
      'alasan': alasan,
      if (lampiranPath != null)
        'lampiran': await MultipartFile.fromFile(lampiranPath),
    });
    return await _dio.post(ApiConfig.leaveRequests, data: formData);
  }

  // ─── FCM Token ─────────────────────────────────
  Future<Response> updateFcmToken(String token) async {
    return await _dio.post(ApiConfig.fcmToken, data: {'fcm_token': token});
  }

  // ─── Event Presensi / Apel ────────────────────────────
  Future<Response> getActiveEvents() async {
    return await _dio.get('${ApiConfig.baseUrl}/events/active');
  }

  Future<Response> scanEventQr({
    required String qrToken,
    double? latitude,
    double? longitude,
  }) async {
    return await _dio.post(
      '${ApiConfig.baseUrl}/events/scan',
      data: {
        'qr_token': qrToken,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
      },
    );
  }

  // ─── Ranking ───────────────────────────────────
  Future<Response> getRanking({
    required String scope,
    int? month,
    int? year,
  }) async {
    return await _dio.get(
      ApiConfig.ranking,
      queryParameters: {'scope': scope, 'month': month, 'year': year},
    );
  }
}

import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import '../../config/theme.dart';
import '../../services/api_service.dart';
import '../../services/offline_sync_service.dart';
import '../../config/enums.dart';

class PresensiScreen extends StatefulWidget {
  const PresensiScreen({super.key});

  @override
  State<PresensiScreen> createState() => _PresensiScreenState();
}

class _PresensiScreenState extends State<PresensiScreen> {
  final ApiService _api = ApiService();
  Position? _position;

  double _parseTime(String timeString) {
    // timeString format: "08:00:00" or "08:00"
    final parts = timeString.split(':');
    if (parts.length >= 2) {
      final h = double.tryParse(parts[0]) ?? 0;
      final m = double.tryParse(parts[1]) ?? 0;
      return h + (m / 60.0);
    }
    return 0.0;
  }

  AttendanceType? _getActiveAttendanceType() {
    if (_scheduleData == null) return null;

    final now = DateTime.now();
    final time = now.hour + (now.minute / 60.0);

    final double istirahat = _parseTime(
      _scheduleData!['jam_istirahat'] ?? '12:00',
    );
    final double kembali = _parseTime(_scheduleData!['jam_kembali'] ?? '13:00');
    final double pulang = _parseTime(_scheduleData!['jam_pulang'] ?? '16:00');

    // Define rules logic. Using default start of day as 05:00 for calculation if needed,
    // but the system should lock Masuk when it passes Istirahat
    if (time >= 5.0 && time < istirahat) {
      return AttendanceType.masuk;
    } else if (time >= istirahat && time < kembali) {
      return AttendanceType.istirahat;
    } else if (time >= kembali && time < pulang) {
      return AttendanceType.kembali;
    } else if (time >= pulang && time < 24.0) {
      return AttendanceType.pulang;
    }
    return null;
  }

  String _formatTimeString(String timeString) {
    final parts = timeString.split(':');
    if (parts.length >= 2) {
      return '${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}';
    }
    return timeString;
  }

  String _getActiveSlotTimeRange(AttendanceType type) {
    if (_scheduleData == null) return '-';

    final istirahatStr = _formatTimeString(
      _scheduleData!['jam_istirahat'] ?? '12:00',
    );
    final kembaliStr = _formatTimeString(
      _scheduleData!['jam_kembali'] ?? '13:00',
    );
    final pulangStr = _formatTimeString(
      _scheduleData!['jam_pulang'] ?? '16:00',
    );

    switch (type) {
      case AttendanceType.masuk:
        return '05:00 - $istirahatStr'; // Presensi masuk can usually start early
      case AttendanceType.istirahat:
        return '$istirahatStr - $kembaliStr';
      case AttendanceType.kembali:
        return '$kembaliStr - $pulangStr';
      case AttendanceType.pulang:
        return '$pulangStr - 23:59';
      case AttendanceType.dinasDalam:
        return '05:00 - 23:59 (Dinas Dalam)';
      case AttendanceType.dinasLuar:
        return '05:00 - 23:59 (Dinas Luar)';
      case AttendanceType.wfh:
        return '05:00 - 23:59 (WFH)';
    }
  }

  String _locationStatus = 'loading';
  String _locationText = 'Mendapatkan lokasi...';
  bool _isSubmitting = false;
  XFile? _selfieImage;
  List<dynamic> _todayAttendances = [];
  Map<String, dynamic>? _office;
  Map<String, dynamic>? _scheduleData; // Active schedule for today
  double? _distance;
  bool _allowRearCamera = false;
  bool _allowGalleryUpload = false;

  @override
  void initState() {
    super.initState();
    _retrieveLostData();
    _getLocation();
    _loadTodayStatus();
    _loadSchedule();
  }

  Future<void> _retrieveLostData() async {
    try {
      final picker = ImagePicker();
      final response = await picker.retrieveLostData();
      if (response.isEmpty) return;
      if (response.file != null) {
        setState(() {
          _selfieImage = response.file;
        });
      } else if (response.exception != null) {
        debugPrint('Error retrieving lost camera data: ${response.exception}');
      }
    } catch (e) {
      debugPrint('retrieveLostData error: $e');
    }
  }

  Future<void> _loadSchedule() async {
    try {
      final response = await _api.getSchedule();
      final List schedules = response.data['schedules'] ?? [];

      if (schedules.isNotEmpty) {
        // Find today's schedule
        final now = DateTime.now();
        final daysIndo = [
          'minggu',
          'senin',
          'selasa',
          'rabu',
          'kamis',
          'jumat',
          'sabtu',
        ];
        final currentDayName = daysIndo[now.weekday == 7 ? 0 : now.weekday];

        Map<String, dynamic>? todaySchedule;
        for (var sch in schedules) {
          final reqDays = sch['hari'].toString().toLowerCase().split(',');
          if (reqDays.contains(currentDayName)) {
            todaySchedule = sch;
            break;
          }
        }

        if (mounted && todaySchedule != null) {
          setState(() {
            _scheduleData = todaySchedule;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading schedule: $e');
    }
  }

  Future<void> _loadTodayStatus() async {
    try {
      final response = await _api.getTodayAttendance();
      final camSettings = response.data['camera_settings'];
      setState(() {
        _todayAttendances = response.data['attendances'] ?? [];
        _office = response.data['office'];
        if (camSettings != null) {
          _allowRearCamera = camSettings['allow_rear_camera'] == true;
          _allowGalleryUpload = camSettings['allow_gallery_upload'] == true;
        }
      });
      if (_position != null) _calculateDistance();
    } catch (_) {}
  }

  Future<void> _getLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _locationStatus = 'error';
          _locationText = 'GPS tidak aktif';
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _locationStatus = 'error';
            _locationText = 'Izin lokasi ditolak';
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _locationStatus = 'error';
          _locationText = 'Izin lokasi ditolak permanen';
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      if (position.isMocked) {
        setState(() {
          _position = position;
          _locationStatus = 'error';
          _locationText = 'Terdeteksi Fake GPS / Lokasi Palsu!';
        });
        return;
      }

      setState(() {
        _position = position;
        _locationStatus = 'ok';
        _locationText =
            'Lokasi: ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
      });
      _calculateDistance();
    } catch (e) {
      setState(() {
        _locationStatus = 'error';
        _locationText = 'Gagal mendapatkan lokasi';
      });
    }
  }

  void _calculateDistance() {
    if (_position != null && _office != null) {
      final dist = Geolocator.distanceBetween(
        _position!.latitude,
        _position!.longitude,
        double.parse(_office!['latitude'].toString()),
        double.parse(_office!['longitude'].toString()),
      );
      setState(() => _distance = dist);
    }
  }

  bool get _isInRadius {
    if (_distance == null || _office == null) return false;
    return _distance! <= double.parse(_office!['radius_meters'].toString());
  }

  Future<void> _takeSelfie() async {
    if (!_allowRearCamera && !_allowGalleryUpload) {
      // Direct front camera (selfie live) only
      _pickImage(ImageSource.camera, CameraDevice.front);
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_front),
              title: const Text('Kamera Depan (Selfie)'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.camera, CameraDevice.front);
              },
            ),
            if (_allowRearCamera)
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Kamera Utama (Belakang)'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.camera, CameraDevice.rear);
                },
              ),
            if (_allowGalleryUpload)
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Pilih dari Galeri'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.gallery, CameraDevice.front);
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(
    ImageSource source,
    CameraDevice preferredCamera,
  ) async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(
        source: source,
        preferredCameraDevice: preferredCamera,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );
      if (image != null && mounted) {
        setState(() => _selfieImage = image);
      }
    } catch (e) {
      debugPrint('Error taking selfie: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengambil foto selfie: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  bool _isDone(String type) => _todayAttendances.any((a) => a['jenis'] == type);

  Future<void> _submitPresensi() async {
    final activeType = _getActiveAttendanceType();
    if (activeType == null || _position == null || _selfieImage == null) return;

    if (_position!.isMocked) {
      _showError('Presensi ditolak! Terdeteksi penggunaan Fake GPS / Lokasi Palsu.');
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await _api.submitAttendance(
        jenis: activeType.name,
        latitude: _position!.latitude,
        longitude: _position!.longitude,
        fotoPath: _selfieImage!.path,
        isMocked: _position!.isMocked,
      );
      if (mounted) {
        _showSuccess('Presensi berhasil dikirim!');
        _selfieImage = null;
        _loadTodayStatus();
      }
    } catch (e) {
      if (mounted) {
        final errStr = e.toString().toLowerCase();
        final isNetworkError = errStr.contains('socketexception') ||
            errStr.contains('connectionerror') ||
            errStr.contains('connecttimeout') ||
            errStr.contains('periksa koneksi');

        if (isNetworkError) {
          final offlineService = OfflineSyncService();
          await offlineService.saveOfflineAttendance(
            jenis: activeType.name,
            latitude: _position!.latitude,
            longitude: _position!.longitude,
            fotoPath: _selfieImage!.path,
            isMocked: _position!.isMocked,
          );
          _showSuccess('⚠️ Tersimpan di Antrean Offline. Akan disinkronkan otomatis saat ada koneksi.');
          _selfieImage = null;
        } else {
          _showError(_extractError(e));
        }
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '✅ $msg',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppTheme.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '❌ $msg',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppTheme.danger,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  String _extractError(dynamic e) {
    try {
      return e.response?.data?['message'] ?? 'Terjadi kesalahan sistem';
    } catch (_) {
      return 'Periksa koneksi internet';
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeType = _getActiveAttendanceType();
    final isDone = activeType != null && _isDone(activeType.name);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Presensi Kehadiran',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      _formatDate(),
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                _buildGlassIconButton(
                  icon: Icons.history_rounded,
                  onTap: () {},
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Today Status Summary (Glass)
            _buildGlassCard(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: AttendanceType.values.map((t) {
                  final done = _isDone(t.name);
                  final att = _todayAttendances
                      .cast<Map<String, dynamic>>()
                      .where((a) => a['jenis'] == t.name)
                      .firstOrNull;
                  return Column(
                    children: [
                      Text(t.icon, style: const TextStyle(fontSize: 18)),
                      const SizedBox(height: 6),
                      Text(
                        t.label,
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[400],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        done
                            ? (att?['waktu'] as String?)?.substring(0, 5) ?? '✓'
                            : '--:--',
                        style: TextStyle(
                          fontSize: 12,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.w900,
                          color: done ? AppTheme.teal500 : Colors.white24,
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 24),

            // Active Slot Display
            _sectionHeader('Sesi Presensi Aktif'),
            const SizedBox(height: 12),
            _buildActiveSlotCard(),
            const SizedBox(height: 24),

            // Selfie & Location
            _sectionHeader('Selfie & Lokasi'),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Take Selfie
                Expanded(
                  flex: 2,
                  child: GestureDetector(
                    onTap: (activeType == null || isDone) ? null : _takeSelfie,
                    child: Container(
                      height: 150,
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(10),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withAlpha(20)),
                        image: _selfieImage != null
                            ? DecorationImage(
                                image: FileImage(File(_selfieImage!.path)),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: _selfieImage == null
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_a_photo_rounded,
                                  color: Colors.grey[600],
                                  size: 32,
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Ambil Selfie',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            )
                          : const SizedBox(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Location Details
                Expanded(
                  flex: 3,
                  child: Column(
                    children: [
                      _buildLocationInfoCard(),
                      const SizedBox(height: 12),
                      _buildRadiusCard(),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Submit Button
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed:
                    (activeType != null &&
                        _position != null &&
                        _selfieImage != null &&
                        !_isSubmitting &&
                        !isDone &&
                        _isInRadius)
                    ? _submitPresensi
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.teal500,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.white.withAlpha(5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'KIRIM PRESENSI SEKARANG',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveSlotCard() {
    final activeType = _getActiveAttendanceType();
    if (activeType == null) {
      return _buildGlassCard(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.withAlpha(30),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.history_toggle_off_rounded,
                color: Colors.grey,
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Text(
                'Belum ada sesi presensi aktif\n(Presensi dimulai pukul 06:00)',
                style: TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final isDone = _isDone(activeType.name);

    return _buildGlassCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: (isDone ? Colors.grey : AppTheme.teal500).withAlpha(30),
              shape: BoxShape.circle,
            ),
            child: Text(activeType.icon, style: const TextStyle(fontSize: 28)),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activeType.label.toUpperCase(),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: isDone ? Colors.grey : Colors.white,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Batas Waktu: ${_getActiveSlotTimeRange(activeType)}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isDone ? Colors.grey : AppTheme.teal500,
                  ),
                ),
                if (isDone)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check_circle_rounded,
                          color: AppTheme.success,
                          size: 14,
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'Telah Disubmit',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.success,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationInfoCard() {
    return _buildGlassCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _locationStatus == 'ok'
                    ? Icons.location_on
                    : Icons.location_off,
                size: 14,
                color: _locationStatus == 'ok'
                    ? AppTheme.success
                    : AppTheme.danger,
              ),
              const SizedBox(width: 6),
              const Text(
                'STATUS GPS',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            _locationText,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildRadiusCard() {
    return _buildGlassCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _isInRadius ? Icons.verified_user : Icons.gpp_bad_rounded,
                size: 14,
                color: _isInRadius ? AppTheme.success : AppTheme.danger,
              ),
              const SizedBox(width: 6),
              const Text(
                'RADIUS KANTOR',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            _isInRadius ? 'Anda di lokasi' : 'Luar jangkauan',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: _isInRadius ? AppTheme.success : AppTheme.danger,
            ),
          ),
          if (_distance != null)
            Text(
              'Jarak: ${_distance!.toStringAsFixed(0)}m',
              style: const TextStyle(fontSize: 9, color: Colors.grey),
            ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w900,
        color: AppTheme.teal500,
        letterSpacing: 1,
      ),
    );
  }

  Widget _buildGlassIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(10),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withAlpha(20)),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }

  Widget _buildGlassCard({required Widget child, EdgeInsetsGeometry? padding}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(10),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withAlpha(20)),
          ),
          child: child,
        ),
      ),
    );
  }

  String _formatDate() {
    final now = DateTime.now();
    final months = [
      '',
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    return '${now.day} ${months[now.month]} ${now.year}';
  }
}

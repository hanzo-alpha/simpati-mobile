import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';

class MonitoringMapScreen extends StatefulWidget {
  const MonitoringMapScreen({super.key});

  @override
  State<MonitoringMapScreen> createState() => _MonitoringMapScreenState();
}

class _MonitoringMapScreenState extends State<MonitoringMapScreen> {
  final ApiService _api = ApiService();
  final MapController _mapController = MapController();
  List<dynamic> _liveLocations = [];
  bool _isLoading = true;
  LatLng _initialCenter = const LatLng(
    -4.3422,
    120.0123,
  ); // Default Kab. Soppeng
  double _officeRadius = 150.0;
  String? _officeName;

  @override
  void initState() {
    super.initState();
    _loadLiveLocations();
  }

  Future<void> _loadLiveLocations() async {
    setState(() => _isLoading = true);
    try {
      final res = await _api.getSupervisionLiveLocations();
      final List data = res.data['live_locations'] ?? [];

      LatLng center = _initialCenter;
      double radius = 150.0;
      String? officeName;

      if (data.isNotEmpty) {
        final firstOffice = data.first['user']?['office'];
        if (firstOffice != null &&
            firstOffice['latitude'] != null &&
            firstOffice['longitude'] != null) {
          center = LatLng(
            double.parse(firstOffice['latitude'].toString()),
            double.parse(firstOffice['longitude'].toString()),
          );
          radius = double.parse(
            (firstOffice['radius_meters'] ?? 150).toString(),
          );
          officeName = firstOffice['opd_name'] ?? firstOffice['name'];
        }
      }

      if (mounted) {
        setState(() {
          _liveLocations = data;
          _initialCenter = center;
          _officeRadius = radius;
          _officeName = officeName;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Color _getStatusColor(String? status, String? jenis) {
    final s = (status ?? '').toLowerCase();
    final j = (jenis ?? '').toLowerCase();

    if (j == 'dinas_luar' || j == 'wfh') {
      return AppTheme.info;
    }
    if (s == 'tepat_waktu') {
      return AppTheme.success;
    }
    if (s == 'terlambat') {
      return AppTheme.warning;
    }
    if (s == 'sangat_terlambat') {
      return AppTheme.danger;
    }
    return AppTheme.teal500;
  }

  String _getStatusLabel(String? status, String? jenis) {
    final s = (status ?? '').toLowerCase();
    final j = (jenis ?? '').toLowerCase();

    if (j == 'dinas_luar') return 'Dinas Luar';
    if (j == 'wfh') return 'WFH';
    if (s == 'tepat_waktu') return 'Tepat Waktu';
    if (s == 'terlambat') return 'Terlambat';
    if (s == 'sangat_terlambat') return 'Sangat Terlambat';
    return status?.toUpperCase() ?? 'HADIR';
  }

  void _showSubordinateDetail(Map<String, dynamic> loc) {
    final user = loc['user'] ?? {};
    final profile = user['profile'] ?? {};
    final statusColor = _getStatusColor(loc['status'], loc['jenis']);
    final statusLabel = _getStatusLabel(loc['status'], loc['jenis']);
    final fotoPath = loc['foto_selfie_path'];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.navy800,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(color: Colors.white.withAlpha(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: AppTheme.teal500.withAlpha(40),
                  child: Text(
                    (user['name'] ?? 'P')
                        .toString()
                        .split(' ')
                        .map((n) => n.isNotEmpty ? n[0] : '')
                        .take(2)
                        .join()
                        .toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user['name'] ?? 'Pegawai ASN',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'NIP: ${user['nip'] ?? '-'}',
                        style: TextStyle(color: Colors.grey[400], fontSize: 12),
                      ),
                      Text(
                        profile['jabatan'] ?? 'Aparatur Sipil Negara',
                        style: const TextStyle(
                          color: AppTheme.teal400,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withAlpha(40),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(color: Colors.white12, height: 28),
            Row(
              children: [
                const Icon(
                  Icons.access_time_rounded,
                  size: 16,
                  color: Colors.white70,
                ),
                const SizedBox(width: 8),
                Text(
                  'Waktu Presensi: ${loc['waktu'] ?? '-'} WITA',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.my_location_rounded,
                  size: 16,
                  color: Colors.white70,
                ),
                const SizedBox(width: 8),
                Text(
                  'Koordinat: ${loc['latitude'] ?? 0}, ${loc['longitude'] ?? 0}',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  loc['in_radius'] == true || loc['in_radius'] == 1
                      ? Icons.check_circle_outline
                      : Icons.error_outline,
                  size: 16,
                  color: loc['in_radius'] == true || loc['in_radius'] == 1
                      ? AppTheme.success
                      : AppTheme.danger,
                ),
                const SizedBox(width: 8),
                Text(
                  loc['in_radius'] == true || loc['in_radius'] == 1
                      ? 'Berada di Dalam Geofence Kantor'
                      : 'Di Luar Radius Geofence Kantor',
                  style: TextStyle(
                    color: loc['in_radius'] == true || loc['in_radius'] == 1
                        ? AppTheme.success
                        : AppTheme.danger,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            if (fotoPath != null && fotoPath.toString().isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Foto Selfie Presensi:',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  height: 140,
                  width: double.infinity,
                  color: Colors.black26,
                  child: Image.network(
                    '${''}${fotoPath.startsWith('http') ? fotoPath : '/storage/$fotoPath'}',
                    fit: BoxFit.cover,
                    errorBuilder: (ctx, _, _) => const Center(
                      child: Icon(
                        Icons.person,
                        size: 48,
                        color: Colors.white30,
                      ),
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isSupervisor = auth.isSupervisor;

    return Scaffold(
      backgroundColor: AppTheme.navy900,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Peta Monitoring Bawahan',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              _officeName ?? 'Monitoring Presensi Realtime OPD',
              style: TextStyle(fontSize: 11, color: Colors.grey[400]),
            ),
          ],
        ),
        backgroundColor: AppTheme.navy900,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadLiveLocations,
          ),
        ],
      ),
      body: !isSupervisor
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.map_outlined,
                      size: 64,
                      color: AppTheme.teal500,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Akses Monitoring Khusus Atasan',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Halaman ini hanya dapat diakses oleh Kepala OPD atau Atasan Langsung untuk memantau sebaran lokasi presensi bawahan.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[400], fontSize: 13),
                    ),
                  ],
                ),
              ),
            )
          : Stack(
              children: [
                // MAP LAYER
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _initialCenter,
                    initialZoom: 15.5,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
                      subdomains: const ['a', 'b', 'c', 'd'],
                    ),
                    // Office Geofence Circle
                    CircleLayer(
                      circles: [
                        CircleMarker(
                          point: _initialCenter,
                          radius: _officeRadius,
                          useRadiusInMeter: true,
                          color: AppTheme.teal500.withAlpha(35),
                          borderColor: AppTheme.teal500,
                          borderStrokeWidth: 2,
                        ),
                      ],
                    ),
                    // Subordinate Location Markers
                    MarkerLayer(
                      markers: [
                        // Office Center Marker
                        Marker(
                          point: _initialCenter,
                          width: 40,
                          height: 40,
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppTheme.navy900.withAlpha(200),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppTheme.teal500,
                                width: 2,
                              ),
                            ),
                            child: const Icon(
                              Icons.account_balance,
                              color: AppTheme.teal400,
                              size: 20,
                            ),
                          ),
                        ),
                        // Subordinates Markers
                        ..._liveLocations.map((loc) {
                          final lat =
                              double.tryParse(loc['latitude'].toString()) ?? 0;
                          final lng =
                              double.tryParse(loc['longitude'].toString()) ?? 0;
                          if (lat == 0 && lng == 0) return null;

                          final color = _getStatusColor(
                            loc['status'],
                            loc['jenis'],
                          );
                          final name = loc['user']?['name'] ?? 'ASN';

                          return Marker(
                            point: LatLng(lat, lng),
                            width: 50,
                            height: 50,
                            child: GestureDetector(
                              onTap: () {
                                _mapController.move(LatLng(lat, lng), 17);
                                _showSubordinateDetail(loc);
                              },
                              child: Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: color,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: color.withAlpha(120),
                                          blurRadius: 8,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.person_pin_circle,
                                      color: Colors.white,
                                      size: 22,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppTheme.navy900.withAlpha(220),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      name.split(' ').first,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).whereType<Marker>(),
                      ],
                    ),
                  ],
                ),

                // LOADING OVERLAY
                if (_isLoading)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black45,
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: AppTheme.teal500,
                        ),
                      ),
                    ),
                  ),

                // BOTTOM SHEET LIST SUMMARY
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 20,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.navy800.withAlpha(235),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withAlpha(20)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(100),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Presensi Bawahan Hari Ini (${_liveLocations.length})',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            GestureDetector(
                              onTap: () =>
                                  _mapController.move(_initialCenter, 15.5),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.teal500.withAlpha(30),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(
                                      Icons.center_focus_strong,
                                      size: 12,
                                      color: AppTheme.teal400,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'Reset Peta',
                                      style: TextStyle(
                                        color: AppTheme.teal400,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        _liveLocations.isEmpty
                            ? Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                child: Text(
                                  'Belum ada data presensi bawahan hari ini',
                                  style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 12,
                                  ),
                                ),
                              )
                            : SizedBox(
                                height: 70,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: _liveLocations.length,
                                  itemBuilder: (ctx, idx) {
                                    final loc = _liveLocations[idx];
                                    final user = loc['user'] ?? {};
                                    final color = _getStatusColor(
                                      loc['status'],
                                      loc['jenis'],
                                    );

                                    return GestureDetector(
                                      onTap: () {
                                        final lat =
                                            double.tryParse(
                                              loc['latitude'].toString(),
                                            ) ??
                                            0;
                                        final lng =
                                            double.tryParse(
                                              loc['longitude'].toString(),
                                            ) ??
                                            0;
                                        if (lat != 0 && lng != 0) {
                                          _mapController.move(
                                            LatLng(lat, lng),
                                            17,
                                          );
                                          _showSubordinateDetail(loc);
                                        }
                                      },
                                      child: Container(
                                        width: 150,
                                        margin: const EdgeInsets.only(
                                          right: 10,
                                        ),
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withAlpha(12),
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          border: Border.all(
                                            color: color.withAlpha(80),
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              user['name'] ?? 'ASN',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                Container(
                                                  width: 8,
                                                  height: 8,
                                                  decoration: BoxDecoration(
                                                    color: color,
                                                    shape: BoxShape.circle,
                                                  ),
                                                ),
                                                const SizedBox(width: 6),
                                                Text(
                                                  loc['waktu'] ?? '--:--',
                                                  style: TextStyle(
                                                    color: Colors.grey[300],
                                                    fontSize: 11,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/navigation_provider.dart';
import '../../services/api_service.dart';
import '../../config/enums.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeHeader;
  late Animation<double> _fadeGeofence;
  late Animation<double> _fadeMap;
  late Animation<double> _fadeStats;
  late Animation<double> _fadeQuickActions;
  late Animation<double> _fadeAttendance;
  final ApiService _api = ApiService();
  List<dynamic> _todayAttendances = [];
  List<dynamic> _announcements = [];
  Map<String, dynamic>? _office;
  Map<String, dynamic> _stats = {'hadir': '0', 'terlambat': '0', 'alpha': '0'};
  Map<String, dynamic>? _tppSummary;
  Position? _currentPosition;
  double? _distanceToOffice;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadData();
  }

  void _setupAnimations() {
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _fadeHeader = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );
    _fadeGeofence = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.1, 0.5, curve: Curves.easeOut),
      ),
    );
    _fadeMap = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.2, 0.6, curve: Curves.easeOut),
      ),
    );
    _fadeStats = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.3, 0.7, curve: Curves.easeOut),
      ),
    );
    _fadeQuickActions = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.4, 0.8, curve: Curves.easeOut),
      ),
    );
    _fadeAttendance = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
      ),
    );

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final response = await _api.getTodayAttendance();
      try {
        final annRes = await _api.getAnnouncements();
        _announcements = annRes.data['announcements'] ?? [];
      } catch (_) {}

      try {
        final statsRes = await _api.getStatistics();
        _tppSummary = statsRes.data['tpp_summary'];
      } catch (_) {}

      if (!mounted) return;
      setState(() {
        _todayAttendances = response.data['attendances'] ?? [];
        _office = response.data['office'];
        final s = response.data['stats'] ?? {};
        _stats = {
          'hadir': (s['hadir'] ?? 0).toString(),
          'terlambat': (s['terlambat'] ?? 0).toString(),
          'alpha': (s['alpha'] ?? 0).toString(),
        };
        isLoading = false;
      });
      _determinePosition();
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  Future<void> _determinePosition() async {
    try {
      final position = await Geolocator.getCurrentPosition();
      if (!mounted) return;
      setState(() => _currentPosition = position);
      _calculateDistance();
    } catch (e) {
      debugPrint('Error determining position: $e');
    }
  }

  void _calculateDistance() {
    if (_currentPosition != null && _office != null) {
      final distance = Geolocator.distanceBetween(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        double.parse(_office!['latitude'].toString()),
        double.parse(_office!['longitude'].toString()),
      );
      setState(() => _distanceToOffice = distance);
    }
  }

  bool get _isInRadius {
    if (_distanceToOffice == null || _office == null) return false;
    return _distanceToOffice! <=
        double.parse(_office!['radius_meters'].toString());
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppTheme.bgPrimary(context),
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: AppTheme.teal500,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // SLIVER HEADER (Premium & Animated)
            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: _fadeHeader,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, -0.2),
                    end: Offset.zero,
                  ).animate(_fadeHeader),
                  child: Stack(
                    children: [
                      Container(
                        height: 180,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: AppTheme.headerGradient(context),
                          ),
                        ),
                      ),
                      Positioned(
                        top: -50,
                        right: -50,
                        child: Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.teal500.withAlpha(15),
                          ),
                        ),
                      ),
                      SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppTheme.teal500.withAlpha(100),
                                    width: 2,
                                  ),
                                ),
                                child: CircleAvatar(
                                  radius: 28,
                                  backgroundColor: AppTheme.isDark(context)
                                      ? AppTheme.navy700
                                      : AppTheme.teal800,
                                  child: Text(
                                    auth.userName
                                        .split(' ')
                                        .map((n) => n.isNotEmpty ? n[0] : '')
                                        .take(2)
                                        .join()
                                        .toUpperCase(),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _getGreeting(),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.white70,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      auth.userName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0.5,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                onPressed: () => Navigator.pushNamed(
                                  context,
                                  '/notification',
                                ),
                                icon: const Icon(
                                  Icons.notifications_none_rounded,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: 10),

                  if (_announcements.isNotEmpty) _buildAnnouncementBanner(),

                  // GEOFENCING CARD (Glassmorphism & Animated)
                  FadeTransition(
                    opacity: _fadeGeofence,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.1),
                        end: Offset.zero,
                      ).animate(_fadeGeofence),
                      child: _buildGlassCard(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.location_on_outlined,
                                      color: AppTheme.teal500,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Status Geofencing',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.textPrimary(context),
                                      ),
                                    ),
                                  ],
                                ),
                                if (_distanceToOffice != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          (_isInRadius
                                                  ? AppTheme.success
                                                  : AppTheme.danger)
                                              .withAlpha(30),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      _distanceToOffice! < 1000
                                          ? '${_distanceToOffice!.toStringAsFixed(0)}m'
                                          : '${(_distanceToOffice! / 1000).toStringAsFixed(1)}km',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: _isInRadius
                                            ? AppTheme.success
                                            : AppTheme.danger,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            if (_office != null)
                              FadeTransition(
                                opacity: _fadeMap,
                                child: ScaleTransition(
                                  scale: Tween<double>(
                                    begin: 0.95,
                                    end: 1.0,
                                  ).animate(_fadeMap),
                                  child: Container(
                                    height: 180,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withAlpha(30),
                                          blurRadius: 10,
                                          offset: const Offset(0, 5),
                                        ),
                                      ],
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(20),
                                      child: FlutterMap(
                                        options: MapOptions(
                                          initialCenter: LatLng(
                                            double.parse(
                                              _office!['latitude'].toString(),
                                            ),
                                            double.parse(
                                              _office!['longitude'].toString(),
                                            ),
                                          ),
                                          initialZoom: 16,
                                        ),
                                        children: [
                                          TileLayer(
                                            urlTemplate:
                                                'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
                                            subdomains: const [
                                              'a',
                                              'b',
                                              'c',
                                              'd',
                                            ],
                                          ),
                                          CircleLayer(
                                            circles: [
                                              CircleMarker(
                                                point: LatLng(
                                                  double.parse(
                                                    _office!['latitude']
                                                        .toString(),
                                                  ),
                                                  double.parse(
                                                    _office!['longitude']
                                                        .toString(),
                                                  ),
                                                ),
                                                radius: double.parse(
                                                  _office!['radius_meters']
                                                      .toString(),
                                                ),
                                                useRadiusInMeter: true,
                                                color: AppTheme.teal500
                                                    .withAlpha(40),
                                                borderColor: AppTheme.teal500,
                                                borderStrokeWidth: 2,
                                              ),
                                            ],
                                          ),
                                          MarkerLayer(
                                            markers: [
                                              Marker(
                                                point: LatLng(
                                                  double.parse(
                                                    _office!['latitude']
                                                        .toString(),
                                                  ),
                                                  double.parse(
                                                    _office!['longitude']
                                                        .toString(),
                                                  ),
                                                ),
                                                width: 40,
                                                height: 40,
                                                child: const Icon(
                                                  Icons.location_on,
                                                  color: AppTheme.danger,
                                                  size: 30,
                                                ),
                                              ),
                                              if (_currentPosition != null)
                                                Marker(
                                                  point: LatLng(
                                                    _currentPosition!.latitude,
                                                    _currentPosition!.longitude,
                                                  ),
                                                  width: 40,
                                                  height: 40,
                                                  child: const Icon(
                                                    Icons.person_pin_circle,
                                                    color: AppTheme.teal500,
                                                    size: 30,
                                                  ),
                                                ),
                                              // Office Name Label Marker
                                              Marker(
                                                point: LatLng(
                                                  double.parse(
                                                    _office!['latitude']
                                                        .toString(),
                                                  ),
                                                  double.parse(
                                                    _office!['longitude']
                                                        .toString(),
                                                  ),
                                                ),
                                                width: 150,
                                                height: 30,
                                                alignment: Alignment.topCenter,
                                                child: Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 10,
                                                        vertical: 4,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color:
                                                        AppTheme.isDark(context)
                                                        ? AppTheme.navy800
                                                              .withAlpha(200)
                                                        : Colors.white
                                                              .withAlpha(230),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          20,
                                                        ),
                                                    border: Border.all(
                                                      color: AppTheme.teal500
                                                          .withAlpha(100),
                                                    ),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: Colors.black
                                                            .withAlpha(50),
                                                        blurRadius: 10,
                                                      ),
                                                    ],
                                                  ),
                                                  child: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      const Icon(
                                                        Icons.business,
                                                        color: AppTheme.teal500,
                                                        size: 12,
                                                      ),
                                                      const SizedBox(width: 6),
                                                      Flexible(
                                                        child: Text(
                                                          _office!['opd_name'] ??
                                                              _office!['name'] ??
                                                              'Kantor',
                                                          style: TextStyle(
                                                            color:
                                                                AppTheme.isDark(
                                                                  context,
                                                                )
                                                                ? Colors.white
                                                                : AppTheme
                                                                      .navy900,
                                                            fontSize: 10,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _isInRadius
                                        ? AppTheme.success
                                        : AppTheme.danger,
                                    boxShadow: [
                                      BoxShadow(
                                        color:
                                            (_isInRadius
                                                    ? AppTheme.success
                                                    : AppTheme.danger)
                                                .withAlpha(100),
                                        blurRadius: 8,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  _isInRadius
                                      ? 'Dalam Radius Kantor'
                                      : 'Di Luar Radius Kantor',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: _isInRadius
                                        ? AppTheme.success
                                        : AppTheme.danger,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Divider(
                              color: AppTheme.dividerColor(context),
                              height: 1,
                            ),
                            const SizedBox(height: 16),
                            FadeTransition(
                              opacity: _fadeAttendance,
                              child: SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(0.1, 0),
                                  end: Offset.zero,
                                ).animate(_fadeAttendance),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Presensi Hari Ini',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white70,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    ..._buildStatusRows(),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // QUICK ACTIONS (Pengajuan Menu)
                  FadeTransition(
                    opacity: _fadeQuickActions,
                    child: ScaleTransition(
                      scale: Tween<double>(begin: 0.95, end: 1.0).animate(
                        CurvedAnimation(
                          parent: _fadeQuickActions,
                          curve: Curves.easeOutBack,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 4, bottom: 12),
                            child: Text(
                              'Layanan Mandiri',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.textPrimary(context),
                              ),
                            ),
                          ),
                          _buildQuickActions(context),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // STATISTICS
                  FadeTransition(
                    opacity: _fadeStats,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.1),
                        end: Offset.zero,
                      ).animate(_fadeStats),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildTppSummaryCard(),
                          Padding(
                            padding: const EdgeInsets.only(left: 4, bottom: 12),
                            child: Text(
                              'Statistik Bulan Ini',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.textPrimary(context),
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              _buildStatCard(
                                'Hadir',
                                _stats['hadir']!,
                                AppTheme.success,
                                Icons.check_circle_outline,
                              ),
                              const SizedBox(width: 12),
                              _buildStatCard(
                                'Terlambat',
                                _stats['terlambat']!,
                                AppTheme.warning,
                                Icons.history_toggle_off,
                              ),
                              const SizedBox(width: 12),
                              _buildStatCard(
                                'Alpha',
                                _stats['alpha']!,
                                AppTheme.danger,
                                Icons.cancel_outlined,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 120),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTppSummaryCard() {
    final performanceScore = _tppSummary?['skor_kinerja_persen'] ?? 100;
    final totalDeduction = _tppSummary?['total_potongan_persen'] ?? 0;
    final breakdown = _tppSummary?['potongan_breakdown'] ?? {};

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.navy800,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.teal500.withAlpha(60)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.teal500.withAlpha(20),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.teal500.withAlpha(30),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.account_balance_wallet_rounded, color: AppTheme.teal500, size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Estimasi Performa TPP',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      Text(
                        'Tambahan Penghasilan Pegawai',
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: (totalDeduction > 0 ? AppTheme.warning : AppTheme.success).withAlpha(30),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: totalDeduction > 0 ? AppTheme.warning : AppTheme.success,
                  ),
                ),
                child: Text(
                  '$performanceScore%',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                    color: totalDeduction > 0 ? AppTheme.warning : AppTheme.success,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(color: Colors.white12, height: 1),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Estimasi Potongan: -$totalDeduction%',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: totalDeduction > 0 ? AppTheme.danger : AppTheme.success,
                ),
              ),
              Text(
                'Terlambat: ${breakdown['terlambat_sedang'] ?? 0}x | Alpha: ${breakdown['alpha'] ?? 0}x',
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGlassCard({required Widget child, EdgeInsetsGeometry? padding}) {
    final dark = AppTheme.isDark(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: dark
                ? Colors.white.withAlpha(10)
                : Colors.white.withAlpha(200),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: dark
                  ? Colors.white.withAlpha(20)
                  : Colors.black.withAlpha(8),
            ),
            gradient: dark
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withAlpha(15),
                      Colors.white.withAlpha(5),
                    ],
                  )
                : null,
            boxShadow: dark
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withAlpha(15),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isSupervisor = auth.isSupervisor;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                context,
                'Peringkat',
                'Klasemen ASN',
                Icons.emoji_events_rounded,
                AppTheme.warning,
                () => Navigator.pushNamed(context, '/peringkat'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildActionCard(
                context,
                'Pusat Bantuan',
                'FAQ & Info',
                Icons.support_agent_rounded,
                AppTheme.info,
                () => Navigator.pushNamed(context, '/help_center'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (isSupervisor)
          _buildActionCard(
            context,
            'Persetujuan Izin & Cuti',
            'Review & Approval Subordinat',
            Icons.approval_rounded,
            AppTheme.teal500,
            () => Navigator.pushNamed(context, '/approval'),
          )
        else
          _buildActionCard(
            context,
            'Layanan Izin & Cuti',
            'Pengajuan & Riwayat Saya',
            Icons.description_rounded,
            AppTheme.teal500,
            () {
              context.read<NavigationProvider>().setIndex(3);
            },
          ),
        const SizedBox(height: 12),
        _buildActionCard(
          context,
          'Layanan Tukar Shift ASN',
          'Pengajuan & Pertukaran Jadwal Shift',
          Icons.swap_horiz_rounded,
          AppTheme.teal400,
          () => Navigator.pushNamed(context, '/shift_swap'),
        ),
      ],
    );
  }

  Widget _buildActionCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: _buildGlassCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary(context),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.textMuted(context),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 10) return 'Selamat Pagi 👋';
    if (hour < 15) return 'Selamat Siang 👋';
    if (hour < 18) return 'Selamat Sore 👋';
    return 'Selamat Malam 👋';
  }

  List<Widget> _buildStatusRows() {
    return AttendanceType.values.map((t) {
      final att = _todayAttendances
          .cast<Map<String, dynamic>>()
          .where((a) => a['jenis'] == t.name)
          .firstOrNull;
      final time = att != null
          ? (att['waktu'] as String).substring(0, 5)
          : '--:--';

      final cutoffMap = {
        'masuk': '08:00',
        'istirahat': '12:00',
        'kembali': '13:30',
        'pulang': '17:00',
      };
      final cutoff = cutoffMap[t.name] ?? '-';

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (att != null ? AppTheme.teal500 : Colors.grey)
                        .withAlpha(30),
                    shape: BoxShape.circle,
                  ),
                  child: Text(t.icon, style: const TextStyle(fontSize: 14)),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary(context),
                      ),
                    ),
                    Text(
                      'Batas: $cutoff',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[500],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Text(
              time,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                fontFamily: 'monospace',
                color: att != null
                    ? AppTheme.teal500
                    : AppTheme.textMuted(context).withAlpha(60),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildStatCard(
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Expanded(
      child: _buildGlassCard(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          children: [
            Icon(icon, color: color.withAlpha(150), size: 20),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnnouncementBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F766E), Color(0xFF134E4A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.teal500.withAlpha(40),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(40),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  (_announcements[0]['kategori'] ?? 'informasi').toString().toUpperCase(),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'PENGUMUMAN RESMI OPD',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.white70,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _announcements[0]['judul'] ?? '',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _announcements[0]['konten'] ?? '',
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white70,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../services/api_service.dart';

class RiwayatScreen extends StatefulWidget {
  const RiwayatScreen({super.key});

  @override
  State<RiwayatScreen> createState() => _RiwayatScreenState();
}

class _RiwayatScreenState extends State<RiwayatScreen> {
  final ApiService _api = ApiService();
  int _year = DateTime.now().year;
  int _month = DateTime.now().month;
  Map<String, List<dynamic>> _groupedAttendances = {};
  Map<String, dynamic>? _tppSummary;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final response = await _api.getAttendanceHistory(
        year: _year,
        month: _month,
      );

      final rawData = response.data['attendances'];
      final Map<String, dynamic> data = (rawData is Map)
          ? Map<String, dynamic>.from(rawData)
          : {};

      // Load TPP statistics summary
      try {
        final statsResponse = await _api.getStatistics(
          year: _year,
          month: _month,
        );
        _tppSummary = statsResponse.data['tpp_summary'];
      } catch (_) {}

      setState(() {
        _groupedAttendances = data.map(
          (key, value) => MapEntry(key, List<dynamic>.from(value)),
        );
        _isLoading = false;
      });
    } catch (e) {
      if (kDebugMode) debugPrint('Error loading history: $e');
      setState(() => _isLoading = false);
    }
  }

  void _changeMonth(int delta) {
    setState(() {
      final newDate = DateTime(_year, _month + delta);
      _month = newDate.month;
      _year = newDate.year;
    });
    _loadData();
  }

  Future<void> _selectMonth() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(_year, _month),
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
      helpText: 'PILIH BULAN & TAHUN',
    );
    if (picked != null) {
      setState(() {
        _year = picked.year;
        _month = picked.month;
      });
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final monthName = DateFormat(
      'MMMM yyyy',
      'id_ID',
    ).format(DateTime(_year, _month));

    return Scaffold(
      backgroundColor: AppTheme.bgPrimary(context),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Riwayat Kehadiran',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                      color: AppTheme.textPrimary(context),
                    ),
                  ),
                  _buildGlassIconButton(
                    icon: Icons.filter_alt_outlined,
                    onTap: () {},
                  ),
                ],
              ),
            ),

            // Month Navigation
            Padding(
              padding: const EdgeInsets.all(20),
              child: _buildGlassCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.chevron_left,
                        color: AppTheme.teal500,
                      ),
                      onPressed: () => _changeMonth(-1),
                    ),
                    InkWell(
                      onTap: _selectMonth,
                      child: Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_rounded,
                            size: 16,
                            color: AppTheme.teal500,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            monthName.toUpperCase(),
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                              letterSpacing: 1,
                              color: AppTheme.textPrimary(context),
                            ),
                          ),
                          const Icon(
                            Icons.arrow_drop_down,
                            color: AppTheme.teal500,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.chevron_right,
                        color: AppTheme.teal500,
                      ),
                      onPressed: () => _changeMonth(1),
                    ),
                  ],
                ),
              ),
            ),

            if (_tppSummary != null) _buildTppCard(),

            // List
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppTheme.teal500),
                    )
                  : _groupedAttendances.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      onRefresh: _loadData,
                      color: AppTheme.teal500,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                        itemCount: _groupedAttendances.length,
                        itemBuilder: (context, index) {
                          final date = _groupedAttendances.keys.elementAt(
                            index,
                          );
                          final attendances = _groupedAttendances[date]!;
                          return _DayCard(date: date, attendances: attendances);
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final dark = AppTheme.isDark(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: dark ? Colors.white.withAlpha(10) : Colors.black.withAlpha(8),
          shape: BoxShape.circle,
          border: Border.all(
            color: dark
                ? Colors.white.withAlpha(20)
                : Colors.black.withAlpha(10),
          ),
        ),
        child: Icon(icon, color: AppTheme.textSecondary(context), size: 20),
      ),
    );
  }

  Widget _buildGlassCard({required Widget child, EdgeInsetsGeometry? padding}) {
    final dark = AppTheme.isDark(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: dark
                ? Colors.white.withAlpha(10)
                : Colors.white.withAlpha(200),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: dark
                  ? Colors.white.withAlpha(20)
                  : Colors.black.withAlpha(8),
            ),
            boxShadow: dark
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withAlpha(10),
                      blurRadius: 15,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_busy_rounded,
            size: 80,
            color: AppTheme.textMuted(context).withAlpha(60),
          ),
          const SizedBox(height: 16),
          Text(
            'Belum ada riwayat pada bulan ini',
            style: TextStyle(
              color: AppTheme.textSecondary(context),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTppCard() {
    final totalDeduction = _tppSummary?['total_deduction_percent'] ?? 0.0;
    final performanceScore = _tppSummary?['performance_score_percent'] ?? 100.0;
    final breakdown = _tppSummary?['breakdown'] ?? {};

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.teal500.withAlpha(20),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.teal500.withAlpha(50)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.teal500.withAlpha(30),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.account_balance_wallet_outlined,
              color: AppTheme.teal500,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kalkulasi TPP Pemda',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[400],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Performa: $performanceScore%',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Est. Potongan: -$totalDeduction% (${breakdown['terlambat_sedang'] ?? 0}x Terlambat, ${breakdown['alpha'] ?? 0}x Alpha)',
                  style: TextStyle(
                    fontSize: 11,
                    color: totalDeduction > 0 ? AppTheme.danger : AppTheme.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DayCard extends StatelessWidget {
  final String date;
  final List<dynamic> attendances;

  const _DayCard({required this.date, required this.attendances});

  @override
  Widget build(BuildContext context) {
    final dark = AppTheme.isDark(context);
    final dateObj = DateTime.parse(date);
    final dayName = DateFormat('EEEE', 'id_ID').format(dateObj);
    final dateStr = DateFormat('d MMMM', 'id_ID').format(dateObj);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: dark ? Theme.of(context).cardColor.withAlpha(150) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: dark ? Colors.white.withAlpha(10) : Colors.black.withAlpha(8),
        ),
        boxShadow: dark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withAlpha(10),
                  blurRadius: 15,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dayName,
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                            color: AppTheme.textPrimary(context),
                          ),
                        ),
                        Text(
                          dateStr,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary(context),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    Icon(
                      Icons.more_vert,
                      color: AppTheme.textMuted(context),
                      size: 20,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Divider(color: AppTheme.dividerColor(context), height: 1),
                const SizedBox(height: 16),
                ...attendances.map((att) => _buildAttendaceRow(context, att)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAttendaceRow(BuildContext context, dynamic att) {
    final jenis = att['jenis'] as String;
    final waktu = (att['waktu'] as String).substring(0, 5);
    final status = att['status'] as String;
    final isLate = status != 'tepat_waktu' && jenis == 'masuk';

    final labelMap = {
      'masuk': ('Masuk', Icons.login_rounded, AppTheme.teal500),
      'istirahat': ('Istirahat', Icons.coffee_rounded, AppTheme.warning),
      'kembali': ('Kembali', Icons.keyboard_return_rounded, AppTheme.info),
      'pulang': ('Pulang', Icons.logout_rounded, AppTheme.danger),
    };

    final info =
        labelMap[jenis] ?? ('Lainnya', Icons.help_outline, Colors.grey);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: info.$3.withAlpha(30),
              shape: BoxShape.circle,
            ),
            child: Icon(info.$2, size: 14, color: info.$3),
          ),
          const SizedBox(width: 12),
          Text(
            info.$1,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary(context),
            ),
          ),
          const Spacer(),
          Text(
            waktu,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              fontFamily: 'monospace',
              color: AppTheme.textPrimary(context),
            ),
          ),
          if (jenis == 'masuk') ...[
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: (isLate ? AppTheme.danger : AppTheme.success).withAlpha(
                  30,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                isLate ? 'TERLAMBAT' : 'TEPAT WAKTU',
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                  color: isLate ? AppTheme.danger : AppTheme.success,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

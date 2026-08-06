import 'dart:ui';
import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../services/api_service.dart';

class PeringkatScreen extends StatefulWidget {
  const PeringkatScreen({super.key});

  @override
  State<PeringkatScreen> createState() => _PeringkatScreenState();
}

class _PeringkatScreenState extends State<PeringkatScreen> {
  final ApiService _api = ApiService();

  int _selectedTab = 0;
  final _tabs = ['Bulan Ini', 'Triwulan', 'Tahunan'];

  bool _isLoading = true;
  String _errorMessage = '';

  Map<String, dynamic> _myRank = {
    'rank': 0,
    'score': 0.0,
    'totalAsn': 0,
    'badge': '-',
  };
  List<dynamic> _rankings = [];

  @override
  void initState() {
    super.initState();
    _fetchRanking();
  }

  Future<void> _fetchRanking() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final now = DateTime.now();
      int? month = now.month;

      if (_selectedTab == 1) {
        // Mock Triwulan
      } else if (_selectedTab == 2) {
        month = null;
      }

      final response = await _api.getRanking(
        scope: 'opd',
        month: month,
        year: now.year,
      );

      final data = response.data['leaderboard'] as List<dynamic>;

      setState(() {
        _rankings = data;
        if (data.isNotEmpty) {
          _myRank = {
            'rank': data[0]['rank'] ?? 1,
            'score': data[0]['score']?.toDouble() ?? 0.0,
            'totalAsn': data.length,
            'badge': data[0]['badge'] ?? '-',
          };
        }
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Gagal memuat data peringkat.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          margin: const EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(20),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.arrow_back_ios_new,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                      const Text(
                        'Peringkat ASN',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  _buildGlassIconButton(
                    icon: Icons.auto_graph_rounded,
                    onTap: () {},
                  ),
                ],
              ),
            ),

            // Period Selection (Glass)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: List.generate(_tabs.length, (i) {
                  final isActive = _selectedTab == i;
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: i == _tabs.length - 1 ? 0 : 8,
                      ),
                      child: GestureDetector(
                        onTap: () {
                          setState(() => _selectedTab = i);
                          _fetchRanking();
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: isActive
                                ? AppTheme.teal500
                                : Colors.white.withAlpha(10),
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                              color: isActive
                                  ? AppTheme.teal500
                                  : Colors.white.withAlpha(20),
                            ),
                            boxShadow: isActive
                                ? [
                                    BoxShadow(
                                      color: AppTheme.teal500.withAlpha(100),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ]
                                : [],
                          ),
                          child: Center(
                            child: Text(
                              _tabs[i],
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                color: isActive
                                    ? Colors.white
                                    : Colors.grey[500],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),

            if (_isLoading)
              const Expanded(
                child: Center(
                  child: CircularProgressIndicator(color: AppTheme.teal500),
                ),
              )
            else if (_errorMessage.isNotEmpty)
              Expanded(
                child: Center(
                  child: Text(
                    _errorMessage,
                    style: const TextStyle(color: AppTheme.danger),
                  ),
                ),
              )
            else ...[
              // TOP 3 PODIUM
              if (_rankings.length >= 3) _buildPodium(),

              // MY RANK MINI CARD
              _buildMyMiniRank(),

              // LEADERBOARD LIST
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: _rankings.length,
                  itemBuilder: (context, index) {
                    final person = _rankings[index];
                    return _buildRankingItem(person, index);
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPodium() {
    return Container(
      height: 180,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _buildPodiumSpot(_rankings[1], 2, 140),
          _buildPodiumSpot(_rankings[0], 1, 170),
          _buildPodiumSpot(_rankings[2], 3, 130),
        ],
      ),
    );
  }

  Widget _buildPodiumSpot(dynamic person, int rank, double height) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          CircleAvatar(
            radius: rank == 1 ? 32 : 28,
            backgroundColor: rank == 1 ? AppTheme.teal500 : AppTheme.navy700,
            child: Text(
              _initials(person['name']),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: rank == 1 ? 18 : 16,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            height: height - 100,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.white.withAlpha(20), Colors.white.withAlpha(5)],
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              border: Border.all(color: Colors.white.withAlpha(10)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  rank == 1 ? '🥇' : (rank == 2 ? '🥈' : '🥉'),
                  style: const TextStyle(fontSize: 20),
                ),
                const SizedBox(height: 4),
                Text(
                  '${person['score']}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    color: AppTheme.teal500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyMiniRank() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: _buildGlassCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.stars_rounded, color: AppTheme.warning, size: 24),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Peringkat Anda',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '#${_myRank['rank']} dari ${_myRank['totalAsn']} ASN',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const Spacer(),
            _buildScoreCircle(_myRank['score'] as double, size: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildRankingItem(dynamic person, int index) {
    final int rank = index + 1;
    final bool isTop3 = rank <= 3;

    // Define special styles for Top 3
    Color borderColor = Colors.white.withAlpha(10);
    Color bgColor = Theme.of(context).cardColor.withAlpha(150);
    Widget rankWidget = Text(
      '$rank',
      style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.grey),
    );

    if (rank == 1) {
      borderColor = AppTheme.warning;
      bgColor = AppTheme.warning.withAlpha(20);
      rankWidget = const Text('🥇', style: TextStyle(fontSize: 16));
    } else if (rank == 2) {
      borderColor = Colors.grey[400]!;
      bgColor = Colors.grey[400]!.withAlpha(20);
      rankWidget = const Text('🥈', style: TextStyle(fontSize: 16));
    } else if (rank == 3) {
      borderColor = const Color(0xFFCD7F32); // Bronze
      bgColor = const Color(0xFFCD7F32).withAlpha(20);
      rankWidget = const Text('🥉', style: TextStyle(fontSize: 16));
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: isTop3 ? 1.5 : 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _showScoreDetails(person, rank),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 30,
                  alignment: Alignment.center,
                  child: rankWidget,
                ),
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppTheme.navy700,
                  child: Text(
                    _initials(person['name']),
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        person['name'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        person['opd_name'],
                        style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${person['score']}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        color: AppTheme.teal500,
                      ),
                    ),
                    _buildBadge(person['badge'], small: true),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showScoreDetails(dynamic person, int rank) {
    final criteria = person['details'] ?? {};
    final metrics = [
      {
        'label': 'Kehadiran (40%)',
        'value': criteria['kehadiran'] ?? 0,
        'icon': Icons.calendar_today_rounded,
        'color': AppTheme.info,
      },
      {
        'label': 'Ketepatan Waktu (30%)',
        'value': criteria['ketepatan_waktu'] ?? 0,
        'icon': Icons.timer_rounded,
        'color': AppTheme.success,
      },
      {
        'label': 'Kelengkapan Atribut (15%)',
        'value': criteria['kelengkapan'] ?? 0,
        'icon': Icons.check_circle_outline_rounded,
        'color': AppTheme.warning,
      },
      {
        'label': 'Durasi Kerja (15%)',
        'value': criteria['durasi'] ?? 0,
        'icon': Icons.access_time_filled_rounded,
        'color': AppTheme.teal500,
      },
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppTheme.navy700,
                    child: Text(
                      _initials(person['name']),
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          person['name'],
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          person['opd_name'],
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildBadge(person['badge']),
                ],
              ),
              const SizedBox(height: 24),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Rincian Skor',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ...metrics.map((m) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: (m['color'] as Color).withAlpha(15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: (m['color'] as Color).withAlpha(30),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(m['icon'] as IconData, color: m['color'] as Color),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          m['label'] as String,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      Text(
                        '${m['value']}',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          color: m['color'] as Color,
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.navy900,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Skor',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${person['score']}',
                      style: const TextStyle(
                        color: AppTheme.teal500,
                        fontWeight: FontWeight.w900,
                        fontSize: 20,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScoreCircle(double score, {double size = 60}) {
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppTheme.teal500, width: 2),
      ),
      child: Center(
        child: Text(
          score.toStringAsFixed(0),
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: size * 0.3),
        ),
      ),
    );
  }

  Widget _buildBadge(String badge, {bool small = false}) {
    final List<Color> colors =
        {
          'Teladan': [AppTheme.warning.withAlpha(40), AppTheme.warning],
          'Baik': [AppTheme.teal500.withAlpha(40), AppTheme.teal500],
        }[badge] ??
        [Colors.grey.withAlpha(40), Colors.grey];

    return Container(
      padding: EdgeInsets.symmetric(horizontal: small ? 6 : 8, vertical: 2),
      decoration: BoxDecoration(
        color: colors[0],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        badge,
        style: TextStyle(
          fontSize: small ? 7 : 9,
          fontWeight: FontWeight.w900,
          color: colors[1],
        ),
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

  String _initials(String name) => name
      .split(' ')
      .map((n) => n.isNotEmpty ? n[0] : '')
      .take(2)
      .join()
      .toUpperCase();
}

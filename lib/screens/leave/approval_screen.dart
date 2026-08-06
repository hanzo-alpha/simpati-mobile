import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../services/api_service.dart';

class ApprovalScreen extends StatefulWidget {
  const ApprovalScreen({super.key});

  @override
  State<ApprovalScreen> createState() => _ApprovalScreenState();
}

class _ApprovalScreenState extends State<ApprovalScreen> {
  final ApiService _api = ApiService();
  List<dynamic> _requests = [];
  bool _isLoading = true;
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  String _formatIndoDate(String? rawDate) {
    if (rawDate == null || rawDate.isEmpty) return '-';
    try {
      final dt = DateTime.parse(rawDate);
      final monthsIndo = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'Mei',
        'Jun',
        'Jul',
        'Agu',
        'Sep',
        'Okt',
        'Nov',
        'Des'
      ];
      final day = dt.day.toString().padLeft(2, '0');
      final month = monthsIndo[dt.month - 1];
      final year = dt.year;
      return '$day $month $year';
    } catch (_) {
      return rawDate;
    }
  }

  String _getTypeLabel(String? rawType) {
    if (rawType == null) return 'Pengajuan';
    switch (rawType.toLowerCase()) {
      case 'cuti':
        return 'Cuti Tahunan';
      case 'sakit':
        return 'Izin Sakit';
      case 'dinas_luar':
      case 'dinas luar':
        return 'Dinas Luar (DL)';
      case 'dinas_dalam':
      case 'dinas dalam':
        return 'Dinas Dalam (DD)';
      default:
        return rawType;
    }
  }

  Future<void> _loadRequests() async {
    setState(() => _isLoading = true);
    try {
      final response = await _api.getSubordinateLeaveRequests(
        status: _selectedFilter == 'all' ? null : _selectedFilter,
      );
      if (mounted) {
        final List data = response.data['data'] ?? response.data ?? [];
        setState(() {
          _requests = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _processRequest(int id, String status) async {
    final noteController = TextEditingController();
    final isApprove = status == 'disetujui';

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.navy800,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          isApprove ? 'Setujui Pengajuan' : 'Tolak Pengajuan',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Apakah Anda yakin ingin ${isApprove ? 'menyetujui' : 'menolak'} pengajuan ini?',
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: noteController,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Catatan tambahan (opsional)...',
                hintStyle: TextStyle(color: Colors.grey[600], fontSize: 12),
                filled: true,
                fillColor: Colors.white.withAlpha(15),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Batal', style: TextStyle(color: Colors.grey[400])),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: isApprove ? AppTheme.success : AppTheme.danger,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(isApprove ? 'Ya, Setujui' : 'Ya, Tolak'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _api.updateLeaveRequestStatus(
          id,
          status: status,
          catatanApproval: noteController.text.trim(),
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '✅ Pengajuan berhasil ${isApprove ? 'disetujui' : 'ditolak'}',
              ),
              backgroundColor: isApprove ? AppTheme.success : AppTheme.danger,
            ),
          );
          _loadRequests();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Gagal memproses pengajuan'),
              backgroundColor: AppTheme.danger,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.navy900,
      appBar: AppBar(
        title: const Text(
          'Persetujuan Izin & Cuti',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: AppTheme.navy900,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadRequests,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('Semua', 'all'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Menunggu', 'menunggu'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Disetujui', 'disetujui'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Ditolak', 'ditolak'),
                ],
              ),
            ),
          ),

          // List Body
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppTheme.teal500),
                  )
                : _requests.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.assignment_turned_in_outlined,
                          size: 64,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Tidak ada pengajuan bawahan untuk ditinjau',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadRequests,
                    color: AppTheme.teal500,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _requests.length,
                      itemBuilder: (context, index) {
                        final req = _requests[index];
                        return _buildCard(req);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedFilter = value);
        _loadRequests();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.teal500 : Colors.white.withAlpha(15),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[400],
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> req) {
    final user = req['user'] ?? {};
    final status = (req['status'] ?? 'menunggu').toString().toLowerCase();
    final isPending = status == 'menunggu';

    Color statusColor;
    if (status == 'disetujui') {
      statusColor = AppTheme.success;
    } else if (status == 'ditolak') {
      statusColor = AppTheme.danger;
    } else {
      statusColor = Colors.orange;
    }

    final startDateStr = _formatIndoDate(req['tanggal_mulai']);
    final endDateStr = _formatIndoDate(req['tanggal_selesai']);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withAlpha(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  user['name'] ?? 'Pegawai ASN',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
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
                  border: Border.all(color: statusColor.withAlpha(100)),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'NIP: ${user['nip'] ?? '-'} • ${user['office']?['name'] ?? '-'}',
            style: TextStyle(color: Colors.grey[400], fontSize: 11),
          ),
          const Divider(color: Colors.white12, height: 20),
          Row(
            children: [
              const Icon(Icons.category_outlined, size: 14, color: AppTheme.teal500),
              const SizedBox(width: 6),
              Text(
                _getTypeLabel(req['type']),
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              const Icon(Icons.date_range, size: 14, color: AppTheme.teal500),
              const SizedBox(width: 6),
              Text(
                '$startDateStr s/d $endDateStr',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Alasan: ${req['alasan'] ?? '-'}',
            style: TextStyle(color: Colors.grey[300], fontSize: 12),
          ),
          if (isPending) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _processRequest(req['id'], 'ditolak'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.danger,
                      side: const BorderSide(color: AppTheme.danger),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('TOLAK', style: TextStyle(fontSize: 12)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _processRequest(req['id'], 'disetujui'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.success,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'SETUJUI',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

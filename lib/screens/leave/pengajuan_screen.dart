import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import '../../config/theme.dart';
import '../../services/api_service.dart';

class PengajuanScreen extends StatefulWidget {
  const PengajuanScreen({super.key});

  @override
  State<PengajuanScreen> createState() => _PengajuanScreenState();
}

class _PengajuanScreenState extends State<PengajuanScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  final ApiService _api = ApiService();

  // Form state
  String _selectedType = 'Cuti';
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();
  final _reasonController = TextEditingController();
  PlatformFile? _attachment;
  bool _isSubmitting = false;

  // History state
  List<dynamic> _history = [];
  bool _isLoadingHistory = true;
  int _sisaCuti = 12;

  final List<String> _types = ['Cuti', 'Sakit', 'Dinas Luar', 'Dinas Dalam'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadHistory();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final res = await _api.getProfile();
      final user = res.data['user'] ?? res.data;
      if (user != null && user['profile'] != null) {
        final cutiVal = user['profile']['sisa_cuti_tahunan'];
        if (cutiVal != null && mounted) {
          setState(() {
            _sisaCuti = int.tryParse(cutiVal.toString()) ?? 12;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading profile leave quota: $e');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoadingHistory = true);
    try {
      final response = await _api.getLeaveRequests();
      if (!mounted) return;
      final List data = response.data['data'] ?? response.data ?? [];
      setState(() {
        _history = data;
        _isLoadingHistory = false;
      });
    } catch (e) {
      debugPrint('Error loading leave history: $e');
      if (!mounted) return;
      setState(() => _isLoadingHistory = false);
    }
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      );
      if (result != null) {
        setState(() => _attachment = result.files.first);
      }
    } catch (e) {
      debugPrint('Error picking file: $e');
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final typeMap = {
        'Cuti': 'cuti',
        'Sakit': 'sakit',
        'Dinas Luar': 'dinas_luar',
        'Dinas Dalam': 'dinas_dalam',
      };
      final apiType = typeMap[_selectedType] ?? 'cuti';
      final startDateStr = DateFormat('yyyy-MM-dd').format(_startDate);
      final endDateStr = DateFormat('yyyy-MM-dd').format(_endDate);

      await _api.submitLeaveRequest(
        type: apiType,
        tanggalMulai: startDateStr,
        tanggalSelesai: endDateStr,
        alasan: _reasonController.text,
        lampiranPath: _attachment?.path,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Pengajuan izin/cuti berhasil dikirim!'),
          backgroundColor: AppTheme.success,
        ),
      );
      _reasonController.clear();
      setState(() {
        _attachment = null;
      });
      _tabController.animateTo(1); // Auto switch to Riwayat Tab
      _loadHistory();
    } catch (e) {
      if (!mounted) return;
      final errStr = e.toString();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Gagal mengirim pengajuan: $errStr'),
          backgroundColor: AppTheme.danger,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
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
        'Des',
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
        return 'Tugas Dinas Luar (DL)';
      case 'dinas_dalam':
      case 'dinas dalam':
        return 'Tugas Dinas Dalam (DD)';
      default:
        return rawType;
    }
  }

  String _getStatusLabel(String? rawStatus) {
    if (rawStatus == null) return 'Menunggu';
    switch (rawStatus.toLowerCase()) {
      case 'disetujui':
      case 'approved':
        return 'Disetujui';
      case 'ditolak':
      case 'rejected':
        return 'Ditolak';
      default:
        return 'Menunggu Approval';
    }
  }

  Color _getStatusColor(String? rawStatus) {
    if (rawStatus == null) return AppTheme.warning;
    switch (rawStatus.toLowerCase()) {
      case 'disetujui':
      case 'approved':
        return AppTheme.success;
      case 'ditolak':
      case 'rejected':
        return AppTheme.danger;
      default:
        return AppTheme.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Layanan Izin & Cuti',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.teal500,
          labelColor: AppTheme.teal500,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'Form Pengajuan'),
            Tab(text: 'Riwayat Saya'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildFormTab(), _buildHistoryTab()],
      ),
    );
  }

  Widget _buildLeaveQuotaCard() {
    final daysSelected = _endDate.difference(_startDate).inDays + 1;
    final isExceeding = _selectedType == 'Cuti' && daysSelected > _sisaCuti;

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            isExceeding
                ? Colors.red.withAlpha(40)
                : AppTheme.teal500.withAlpha(40),
            isExceeding
                ? Colors.red.withAlpha(15)
                : AppTheme.teal500.withAlpha(15),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isExceeding
              ? Colors.red.withAlpha(80)
              : AppTheme.teal500.withAlpha(80),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isExceeding
                  ? Colors.red.withAlpha(40)
                  : AppTheme.teal500.withAlpha(40),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isExceeding ? Icons.warning_rounded : Icons.event_available_rounded,
              color: isExceeding ? Colors.red : AppTheme.teal500,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Sisa Kuota Cuti Tahunan',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Durasi: $daysSelected Hari',
                      style: TextStyle(
                        fontSize: 11,
                        color: isExceeding ? Colors.red : Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  isExceeding
                      ? '$_sisaCuti Hari (Durasi Pengajuan Melebihi Kuota!)'
                      : '$_sisaCuti Hari Tersedia',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.extrabold,
                    color: isExceeding ? Colors.red : AppTheme.teal500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLeaveQuotaCard(),
            _buildLabel('Jenis Pengajuan'),
            DropdownButtonFormField<String>(
              initialValue: _selectedType,
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyLarge?.color,
                fontWeight: FontWeight.bold,
              ),
              dropdownColor: Theme.of(context).cardColor,
              decoration: InputDecoration(
                filled: true,
                fillColor: Theme.of(context).cardColor,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Theme.of(context).dividerColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Theme.of(context).dividerColor),
                ),
              ),
              items: _types
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _selectedType = v);
              },
            ),
            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('Tanggal Mulai'),
                      _buildDatePicker(
                        _startDate,
                        (d) => setState(() => _startDate = d),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('Tanggal Selesai'),
                      _buildDatePicker(
                        _endDate,
                        (d) => setState(() => _endDate = d),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            _buildLabel('Alasan / Keterangan'),
            TextFormField(
              controller: _reasonController,
              maxLines: 4,
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
              decoration: InputDecoration(
                hintText: 'Tuliskan alasan pengajuan secara detail...',
                hintStyle: TextStyle(color: Theme.of(context).hintColor),
                filled: true,
                fillColor: Theme.of(context).cardColor,
                contentPadding: const EdgeInsets.all(16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Theme.of(context).dividerColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Theme.of(context).dividerColor),
                ),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Alasan harus diisi' : null,
            ),
            const SizedBox(height: 20),

            _buildLabel('Dokumen Lampiran (Opsional)'),
            GestureDetector(
              onTap: _pickFile,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.attach_file, color: AppTheme.teal500),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _attachment?.name ??
                            'Pilih Berkas Lampiran (PDF/Gambar)',
                        style: TextStyle(
                          color: _attachment != null
                              ? Theme.of(context).textTheme.bodyLarge?.color
                              : Colors.grey,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    if (_attachment != null)
                      IconButton(
                        icon: const Icon(
                          Icons.close,
                          size: 18,
                          color: AppTheme.danger,
                        ),
                        onPressed: () => setState(() => _attachment = null),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.teal500,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'KIRIM PENGAJUAN',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryTab() {
    if (_isLoadingHistory) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.teal500),
      );
    }

    if (_history.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadHistory,
        color: AppTheme.teal500,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.6,
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history_rounded, size: 64, color: Colors.grey[700]),
                const SizedBox(height: 16),
                const Text(
                  'Belum ada riwayat pengajuan izin/cuti',
                  style: TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadHistory,
      color: AppTheme.teal500,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _history.length,
        itemBuilder: (context, index) {
          final item = _history[index];
          return _buildHistoryItem(item);
        },
      ),
    );
  }

  Widget _buildHistoryItem(dynamic item) {
    final typeStr = _getTypeLabel(item['type']?.toString());
    final statusStr = _getStatusLabel(item['status']?.toString());
    final statusColor = _getStatusColor(item['status']?.toString());

    final startDateStr = _formatIndoDate(
      item['tanggal_mulai'] ?? item['start'],
    );
    final endDateStr = _formatIndoDate(item['tanggal_selesai'] ?? item['end']);
    final reasonStr = item['alasan'] ?? item['reason'] ?? '-';
    final noteStr = item['catatan_approval'];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  typeStr,
                  style: const TextStyle(
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
                  color: statusColor.withAlpha(30),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  statusStr,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.date_range, size: 14, color: AppTheme.teal500),
              const SizedBox(width: 6),
              Text(
                '$startDateStr  s.d.  $endDateStr',
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            reasonStr,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ),
          if (item['lampiran_url'] != null && item['lampiran_url'].toString().isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.teal500.withAlpha(20),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.teal500.withAlpha(40)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.attach_file, size: 14, color: AppTheme.teal500),
                  const SizedBox(width: 6),
                  const Text(
                    'Lampiran Berkas Terunggah',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.teal500,
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (noteStr != null && noteStr.toString().trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.amber.withAlpha(20),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.note_alt_outlined,
                    size: 14,
                    color: Colors.amber,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Catatan Atasan: $noteStr',
                      style: const TextStyle(fontSize: 11, color: Colors.amber),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: AppTheme.teal500,
        ),
      ),
    );
  }

  Widget _buildDatePicker(DateTime date, Function(DateTime) onPicked) {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime.now().subtract(const Duration(days: 30)),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (picked != null) onPicked(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _formatIndoDate(DateFormat('yyyy-MM-dd').format(date)),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const Icon(Icons.calendar_today, size: 16, color: AppTheme.teal500),
          ],
        ),
      ),
    );
  }
}

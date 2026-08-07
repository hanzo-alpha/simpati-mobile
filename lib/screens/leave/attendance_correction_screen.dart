import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';

class AttendanceCorrectionScreen extends StatefulWidget {
  const AttendanceCorrectionScreen({super.key});

  @override
  State<AttendanceCorrectionScreen> createState() =>
      _AttendanceCorrectionScreenState();
}

class _AttendanceCorrectionScreenState
    extends State<AttendanceCorrectionScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiService _api = ApiService();

  List<dynamic> _myCorrections = [];
  List<dynamic> _subordinateCorrections = [];
  bool _isLoading = true;
  bool _isSubmitting = false;

  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = const TimeOfDay(hour: 7, minute: 30);
  String _selectedJenis = 'masuk';
  final _reasonController = TextEditingController();
  String? _lampiranPath;
  String? _lampiranName;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    final tabLength = auth.isSupervisor ? 3 : 2;
    _tabController = TabController(length: tabLength, vsync: this);
    _loadCorrections();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _loadCorrections() async {
    setState(() => _isLoading = true);
    final auth = context.read<AuthProvider>();

    try {
      final res = await _api.getAttendanceCorrections();
      final List data = res.data['corrections'] ?? res.data['data'] ?? res.data ?? [];

      List subData = [];
      if (auth.isSupervisor) {
        try {
          final subRes = await _api.getSubordinateAttendanceCorrections();
          subData = subRes.data['corrections'] ?? subRes.data['data'] ?? subRes.data ?? [];
        } catch (_) {}
      }

      if (mounted) {
        setState(() {
          _myCorrections = data;
          _subordinateCorrections = subData;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading attendance corrections: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickAttachment() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
    );
    if (result != null && result.files.single.path != null) {
      setState(() {
        _lampiranPath = result.files.single.path;
        _lampiranName = result.files.single.name;
      });
    }
  }

  Future<void> _submitCorrection() async {
    if (_reasonController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Mohon isi alasan pengajuan koreksi presensi.'),
          backgroundColor: AppTheme.warning,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final hour = _selectedTime.hour.toString().padLeft(2, '0');
      final minute = _selectedTime.minute.toString().padLeft(2, '0');
      final timeStr = '$hour:$minute';

      await _api.submitAttendanceCorrection(
        tanggal: dateStr,
        jenis: _selectedJenis,
        jamKoreksi: timeStr,
        alasan: _reasonController.text.trim(),
        lampiranPath: _lampiranPath,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Permohonan koreksi presensi berhasil diajukan!'),
          backgroundColor: AppTheme.success,
        ),
      );
      _reasonController.clear();
      setState(() {
        _lampiranPath = null;
        _lampiranName = null;
      });
      _tabController.animateTo(1);
      _loadCorrections();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Gagal mengirim pengajuan: $e'),
          backgroundColor: AppTheme.danger,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _processCorrectionStatus(int id, String status) async {
    final noteController = TextEditingController();
    final isApprove = status == 'disetujui';

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.navy800,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          isApprove ? 'Setujui Koreksi Presensi' : 'Tolak Koreksi Presensi',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
                hintText: 'Catatan approval (opsional)...',
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
            ),
            child: Text(isApprove ? 'Ya, Setujui' : 'Ya, Tolak'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _api.updateAttendanceCorrectionStatus(
          id: id,
          status: status,
          catatanApproval: noteController.text.trim(),
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              status == 'disetujui'
                  ? '✅ Koreksi presensi disetujui!'
                  : '❌ Koreksi presensi ditolak.',
            ),
            backgroundColor: status == 'disetujui' ? AppTheme.success : AppTheme.danger,
          ),
        );
        _loadCorrections();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memproses status: $e'),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isSupervisor = auth.isSupervisor;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Koreksi Presensi / Lupa Absen',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.teal500,
          labelColor: AppTheme.teal500,
          unselectedLabelColor: Colors.grey,
          tabs: [
            const Tab(text: 'Pengajuan Koreksi'),
            const Tab(text: 'Riwayat Saya'),
            if (isSupervisor) const Tab(text: 'Approval Bawahan'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCreateTab(),
          _buildMyListTab(),
          if (isSupervisor) _buildSubordinateListTab(),
        ],
      ),
    );
  }

  Widget _buildCreateTab() {
    final dateStr = DateFormat('dd MMMM yyyy').format(_selectedDate);
    final timeStr =
        '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')} WITA';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.teal500.withAlpha(20),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.teal500.withAlpha(40)),
            ),
            child: const Row(
              children: [
                Icon(Icons.edit_calendar_rounded, color: AppTheme.teal500, size: 28),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Form Koreksi Presensi',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Gunakan form ini jika Anda tidak dapat melalukan presensi karena kendala teknis/HP mati/dinas khusus.',
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tanggal Presensi',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate,
                          firstDate: DateTime.now().subtract(const Duration(days: 30)),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          setState(() => _selectedDate = picked);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Theme.of(context).dividerColor),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(dateStr, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            const Icon(Icons.calendar_month, color: AppTheme.teal500, size: 16),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Jam Seharusnya',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: _selectedTime,
                        );
                        if (picked != null) {
                          setState(() => _selectedTime = picked);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Theme.of(context).dividerColor),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(timeStr, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            const Icon(Icons.access_time, color: AppTheme.teal500, size: 16),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          const Text(
            'Jenis Presensi',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _selectedJenis,
            decoration: InputDecoration(
              filled: true,
              fillColor: Theme.of(context).cardColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Theme.of(context).dividerColor),
              ),
            ),
            items: const [
              DropdownMenuItem(value: 'masuk', child: Text('Presensi Masuk (Pagi)')),
              DropdownMenuItem(value: 'istirahat', child: Text('Presensi Istirahat')),
              DropdownMenuItem(value: 'kembali', child: Text('Presensi Kembali Istirahat')),
              DropdownMenuItem(value: 'pulang', child: Text('Presensi Pulang (Sore)')),
            ],
            onChanged: (val) {
              if (val != null) setState(() => _selectedJenis = val);
            },
          ),
          const SizedBox(height: 16),

          const Text(
            'Alasan Lengkap Kendala Presensi',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _reasonController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Tuliskan alasan kenapa tidak bisa melakukan presensi online...',
              filled: true,
              fillColor: Theme.of(context).cardColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Theme.of(context).dividerColor),
              ),
            ),
          ),
          const SizedBox(height: 16),

          const Text(
            'Unggah Bukti Dokumen / Surat Tugas (Opsional)',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _pickAttachment,
            icon: const Icon(Icons.attach_file, color: AppTheme.teal500),
            label: Text(
              _lampiranName ?? 'Pilih File Lampiran (JPG/PNG/PDF max 5MB)',
              style: const TextStyle(fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              side: BorderSide(color: Theme.of(context).dividerColor),
            ),
          ),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _isSubmitting ? null : _submitCorrection,
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.send_rounded),
              label: Text(
                _isSubmitting ? 'MENGIRIM...' : 'KIRIM PERMOHONAN KOREKSI',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.teal500,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyListTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.teal500));
    }

    if (_myCorrections.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadCorrections,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.6,
            alignment: Alignment.center,
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.edit_calendar_rounded, size: 64, color: Colors.grey),
                SizedBox(height: 12),
                Text(
                  'Belum ada riwayat pengajuan koreksi presensi.',
                  style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadCorrections,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _myCorrections.length,
        itemBuilder: (context, index) {
          final item = _myCorrections[index];
          return _buildCorrectionCard(item, isSubordinateView: false);
        },
      ),
    );
  }

  Widget _buildSubordinateListTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.teal500));
    }

    if (_subordinateCorrections.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadCorrections,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.6,
            alignment: Alignment.center,
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.assignment_turned_in_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 12),
                Text(
                  'Belum ada permohonan koreksi presensi bawahan.',
                  style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadCorrections,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _subordinateCorrections.length,
        itemBuilder: (context, index) {
          final item = _subordinateCorrections[index];
          return _buildCorrectionCard(item, isSubordinateView: true);
        },
      ),
    );
  }

  Widget _buildCorrectionCard(Map<String, dynamic> item, {required bool isSubordinateView}) {
    final status = item['status']?.toString().toLowerCase() ?? 'menunggu';
    final user = item['user'] ?? {};
    final isPending = status == 'menunggu';

    Color statusColor = AppTheme.warning;
    if (status == 'disetujui') statusColor = AppTheme.success;
    if (status == 'ditolak') statusColor = AppTheme.danger;

    final jenisLabel = (item['jenis'] ?? 'masuk').toString().toUpperCase();
    final jamKoreksi = (item['jam_koreksi'] ?? '--:--').toString().substring(0, 5);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
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
                  'Tgl: ${item['tanggal'] ?? '-'} • Jam: $jamKoreksi WITA',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withAlpha(30),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  status.toUpperCase(),
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
          if (isSubordinateView) ...[
            Text(
              'Pegawai: ${user['name'] ?? 'ASN'} (NIP: ${user['nip'] ?? '-'})',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.teal400),
            ),
            const SizedBox(height: 4),
          ],
          Text(
            'Jenis: $jenisLabel | Alasan: ${item['alasan'] ?? '-'}',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          if (item['catatan_approval'] != null) ...[
            const SizedBox(height: 6),
            Text(
              'Catatan Atasan: ${item['catatan_approval']}',
              style: const TextStyle(fontSize: 11, color: Colors.white70, fontStyle: FontStyle.italic),
            ),
          ],
          if (isSubordinateView && isPending) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () => _processCorrectionStatus(item['id'], 'ditolak'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('TOLAK', style: TextStyle(fontSize: 11)),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _processCorrectionStatus(item['id'], 'disetujui'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.teal500,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('SETUJUI', style: TextStyle(fontSize: 11)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

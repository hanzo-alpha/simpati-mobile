import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';

class ShiftSwapScreen extends StatefulWidget {
  const ShiftSwapScreen({super.key});

  @override
  State<ShiftSwapScreen> createState() => _ShiftSwapScreenState();
}

class _ShiftSwapScreenState extends State<ShiftSwapScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiService _api = ApiService();

  List<dynamic> _myShiftSwaps = [];
  List<dynamic> _subordinateShiftSwaps = [];
  bool _isLoading = true;
  DateTime _selectedDate = DateTime.now();
  final _reasonController = TextEditingController();
  final _targetUserIdController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    final tabLength = auth.isSupervisor ? 3 : 2;
    _tabController = TabController(length: tabLength, vsync: this);
    _loadShiftSwaps();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _reasonController.dispose();
    _targetUserIdController.dispose();
    super.dispose();
  }

  Future<void> _loadShiftSwaps() async {
    setState(() => _isLoading = true);
    final auth = context.read<AuthProvider>();

    try {
      final res = await _api.getShiftSwaps();
      final List data = res.data['shift_swaps'] ?? res.data['data'] ?? res.data ?? [];

      List subData = [];
      if (auth.isSupervisor) {
        try {
          final subRes = await _api.getSubordinateShiftSwaps();
          subData = subRes.data['shift_swaps'] ?? subRes.data['data'] ?? subRes.data ?? [];
        } catch (_) {}
      }

      if (mounted) {
        setState(() {
          _myShiftSwaps = data;
          _subordinateShiftSwaps = subData;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading shift swaps: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submitRequest() async {
    if (_reasonController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Mohon isi alasan pengajuan tukar shift.'),
          backgroundColor: AppTheme.warning,
        ),
      );
      return;
    }

    final targetId = int.tryParse(_targetUserIdController.text.trim());
    if (targetId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Mohon isi ID pegawai pengganti.'),
          backgroundColor: AppTheme.warning,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
      await _api.createShiftSwap(
        targetUserId: targetId,
        tanggalShift: dateStr,
        alasan: _reasonController.text.trim(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Permohonan tukar shift berhasil diajukan!'),
          backgroundColor: AppTheme.success,
        ),
      );
      _reasonController.clear();
      _targetUserIdController.clear();
      _tabController.animateTo(1);
      _loadShiftSwaps();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Gagal membuat permohonan: $e'),
          backgroundColor: AppTheme.danger,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _updateStatus(int id, String status) async {
    try {
      await _api.updateShiftSwapStatus(id: id, status: status);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            status == 'disetujui'
                ? '✅ Tukar shift disetujui!'
                : '❌ Tukar shift ditolak.',
          ),
          backgroundColor:
              status == 'disetujui' ? AppTheme.success : AppTheme.danger,
        ),
      );
      _loadShiftSwaps();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memperbarui status: $e'),
          backgroundColor: AppTheme.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isSupervisor = auth.isSupervisor;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Layanan Tukar Shift ASN',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.teal500,
          labelColor: AppTheme.teal500,
          unselectedLabelColor: Colors.grey,
          tabs: [
            const Tab(text: 'Pengajuan Baru'),
            const Tab(text: 'Daftar Saya'),
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
                Icon(Icons.swap_horiz_rounded, color: AppTheme.teal500, size: 28),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tukar Jadwal Shift Kerja',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Layanan pertukaran jam kerja shift bagi pegawai RSUD/Puskesmas/Satpol PP.',
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          const Text(
            'Tanggal Shift Yang Ditukar',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime.now().subtract(const Duration(days: 7)),
                lastDate: DateTime.now().add(const Duration(days: 60)),
              );
              if (picked != null) {
                setState(() => _selectedDate = picked);
              }
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
                    dateStr,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const Icon(Icons.calendar_month, color: AppTheme.teal500, size: 18),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          const Text(
            'ID / NIP Pegawai Pengganti',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _targetUserIdController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: 'Ketik ID Pegawai Pengganti...',
              filled: true,
              fillColor: Theme.of(context).cardColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Theme.of(context).dividerColor),
              ),
              prefixIcon: const Icon(Icons.person_search, color: AppTheme.teal500),
            ),
          ),
          const SizedBox(height: 16),

          const Text(
            'Alasan Pertukaran Shift',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _reasonController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Ketik alasan pertukaran shift...',
              filled: true,
              fillColor: Theme.of(context).cardColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Theme.of(context).dividerColor),
              ),
            ),
          ),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _isSubmitting ? null : _submitRequest,
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.send_rounded),
              label: Text(
                _isSubmitting ? 'MENGIRIM...' : 'KIRIM PERMOHONAN TUKAR SHIFT',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.teal500,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
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

    if (_myShiftSwaps.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadShiftSwaps,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.6,
            alignment: Alignment.center,
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.swap_calls_rounded, size: 64, color: Colors.grey),
                SizedBox(height: 12),
                Text(
                  'Belum ada permohonan tukar shift.',
                  style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadShiftSwaps,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _myShiftSwaps.length,
        itemBuilder: (context, index) {
          final item = _myShiftSwaps[index];
          return _buildShiftSwapCard(item, isSubordinateView: false);
        },
      ),
    );
  }

  Widget _buildSubordinateListTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.teal500));
    }

    if (_subordinateShiftSwaps.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadShiftSwaps,
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
                  'Belum ada permohonan tukar shift bawahan.',
                  style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadShiftSwaps,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _subordinateShiftSwaps.length,
        itemBuilder: (context, index) {
          final item = _subordinateShiftSwaps[index];
          return _buildShiftSwapCard(item, isSubordinateView: true);
        },
      ),
    );
  }

  Widget _buildShiftSwapCard(Map<String, dynamic> item, {required bool isSubordinateView}) {
    final status = item['status']?.toString().toLowerCase() ?? 'menunggu';
    final requester = item['requester'] ?? {};
    final targetUser = item['target_user'] ?? {};

    Color statusColor = AppTheme.warning;
    if (status == 'disetujui') statusColor = AppTheme.success;
    if (status == 'ditolak') statusColor = AppTheme.danger;

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
                  'Shift Tanggal: ${item['tanggal_shift'] ?? '-'}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
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
            Row(
              children: [
                const Icon(Icons.person, size: 14, color: AppTheme.teal500),
                const SizedBox(width: 6),
                Text(
                  'Pengaju: ${requester['name'] ?? '-'} (NIP: ${requester['nip'] ?? '-'})',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 4),
          ],
          Row(
            children: [
              const Icon(Icons.swap_horiz, size: 14, color: AppTheme.teal400),
              const SizedBox(width: 6),
              Text(
                'Pengganti: ${targetUser['name'] ?? 'ID #${item['target_user_id'] ?? '-'}'}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Alasan: ${item['alasan'] ?? '-'}',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          if (status == 'menunggu') ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () => _updateStatus(item['id'], 'ditolak'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('TOLAK', style: TextStyle(fontSize: 11)),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _updateStatus(item['id'], 'disetujui'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.teal500,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
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

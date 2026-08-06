import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import '../../config/theme.dart';

class PengajuanScreen extends StatefulWidget {
  const PengajuanScreen({super.key});

  @override
  State<PengajuanScreen> createState() => _PengajuanScreenState();
}

class _PengajuanScreenState extends State<PengajuanScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();

  // Form state
  String? _selectedType = 'Sakit';
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();
  final _reasonController = TextEditingController();
  PlatformFile? _attachment;
  bool _isSubmitting = false;

  // History state
  List<dynamic> _history = [];
  bool _isLoadingHistory = true;

  final List<String> _types = [
    'Cuti',
    'Sakit',
    'Ijin',
    'Dinas Luar',
    'Dinas Dalam',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadHistory();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    try {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;
      setState(() {
        _history = [
          {
            'type': 'Sakit',
            'start': '2026-03-01',
            'end': '2026-03-03',
            'status': 'Disetujui',
            'reason': 'Demam tinggi dan butuh istirahat total.',
          },
          {
            'type': 'Cuti',
            'start': '2026-04-10',
            'end': '2026-04-12',
            'status': 'Menunggu',
            'reason': 'Urusan keluarga di kampung.',
          },
        ];
        _isLoadingHistory = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingHistory = false);
    }
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles();
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
      // Mock submission for now
      await Future.delayed(const Duration(seconds: 2));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pengajuan berhasil dikirim'),
          backgroundColor: AppTheme.success,
        ),
      );
      _tabController.animateTo(1); // Go to history
      _loadHistory();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.danger),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Pengajuan Layanan'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.teal500,
          labelColor: AppTheme.teal500,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'Form Pengajuan'),
            Tab(text: 'Riwayat'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildFormTab(), _buildHistoryTab()],
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
            _buildLabel('Jenis Pengajuan'),
            DropdownButtonFormField<String>(
              initialValue: _selectedType,
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyLarge?.color,
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
              onChanged: (v) => setState(() => _selectedType = v),
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
                  v == null || v.isEmpty ? 'Alasan harus diisi' : null,
            ),
            const SizedBox(height: 20),

            _buildLabel('Lampiran (Opsional)'),
            GestureDetector(
              onTap: _pickFile,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.attach_file, color: AppTheme.teal500),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _attachment?.name ?? 'Pilih File (PDF/Image)',
                        style: TextStyle(
                          color: _attachment != null
                              ? Theme.of(context).textTheme.bodyLarge?.color
                              : Colors.grey,
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

            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                child: _isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('KIRIM PENGAJUAN'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryTab() {
    if (_isLoadingHistory) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_history.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history_rounded, size: 64, color: Colors.grey[800]),
            const SizedBox(height: 16),
            const Text(
              'Belum ada riwayat pengajuan',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _history.length,
      itemBuilder: (context, index) {
        final item = _history[index];
        return _buildHistoryItem(item);
      },
    );
  }

  Widget _buildHistoryItem(dynamic item) {
    Color statusColor = item['status'] == 'Disetujui'
        ? AppTheme.success
        : AppTheme.warning;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                item['type'],
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withAlpha(30),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  item['status'],
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${DateFormat('dd MMM').format(DateTime.parse(item['start']))} - ${DateFormat('dd MMM yyyy').format(DateTime.parse(item['end']))}',
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 12),
          Text(
            item['reason'],
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, height: 1.4),
          ),
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
          fontSize: 14,
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
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(DateFormat('dd/MM/yyyy').format(date)),
            const Icon(Icons.calendar_today, size: 16, color: AppTheme.teal500),
          ],
        ),
      ),
    );
  }
}

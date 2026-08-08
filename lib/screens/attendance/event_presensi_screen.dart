import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import 'qr_scanner_screen.dart';

class EventPresensiScreen extends StatefulWidget {
  const EventPresensiScreen({super.key});

  @override
  State<EventPresensiScreen> createState() => _EventPresensiScreenState();
}

class _EventPresensiScreenState extends State<EventPresensiScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _tokenController = TextEditingController();

  List<dynamic> _events = [];
  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _scanQrWithCamera() async {
    final scannedCode = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => const QrScannerScreen()),
    );

    if (scannedCode != null && scannedCode.isNotEmpty) {
      _tokenController.text = scannedCode;
      _submitToken(scannedCode);
    }
  }

  void _showMyQrDialog() {
    final auth = context.read<AuthProvider>();
    final nip = auth.userNip.isNotEmpty
        ? auth.userNip
        : (auth.user?['id']?.toString() ?? 'ASN-SOPPENG');
    final name = auth.userName;
    final opd = auth.userOpdName;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Column(
          children: [
            const Icon(Icons.qr_code_2, size: 44, color: Color(0xFF0D9488)),
            const SizedBox(height: 8),
            const Text(
              'Kartu QR Presensi ASN',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              name,
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(20),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: QrImageView(
                data: nip,
                version: QrVersions.auto,
                size: 200.0,
                backgroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.teal.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Text(
                    'NIP: $nip',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal.shade900,
                    ),
                  ),
                  Text(
                    opd,
                    style: TextStyle(fontSize: 11, color: Colors.teal.shade800),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tunjukkan QR Code ini ke Operator / Admin Apel untuk di-scan.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  Future<void> _loadEvents() async {
    setState(() => _isLoading = true);
    try {
      final res = await _apiService.getActiveEvents();
      if (res.statusCode == 200 && res.data['success'] == true) {
        setState(() {
          _events = res.data['events'] ?? [];
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat event presensi: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submitToken(String token) async {
    final cleanToken = token.trim();
    if (cleanToken.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan masukkan Kode Token Event!')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      Position? pos;
      try {
        pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
          ),
        );
      } catch (_) {}

      final res = await _apiService.scanEventQr(
        qrToken: cleanToken,
        latitude: pos?.latitude,
        longitude: pos?.longitude,
      );

      if (mounted && res.statusCode == 200 && res.data['success'] == true) {
        _tokenController.clear();
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green),
                SizedBox(width: 8),
                Text('Presensi Event Berhasil', style: TextStyle(fontSize: 16)),
              ],
            ),
            content: Text(res.data['message'] ?? 'Presensi berhasil dicatat!'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  _loadEvents();
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Presensi gagal: ${e.toString()}'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Presensi Apel & Upacara',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadEvents,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Token Input Card
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.qr_code_scanner, color: Color(0xFF0D9488)),
                                SizedBox(width: 8),
                                Text(
                                  'Pindai / Input Token QR Event',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Gunakan kamera HP untuk scan QR Code di lokasi/proyektor, atau tunjukkan Kartu QR NIP ke Petugas Apel.',
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                            const SizedBox(height: 14),

                            // Main Action: Scan Kamera QR
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _scanQrWithCamera,
                                icon: const Icon(Icons.camera_alt, size: 20),
                                label: const Text(
                                  'Pindai QR Code dengan Kamera',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0D9488),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 10),

                            // Action 2: Tampilkan Kartu QR Saya
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: _showMyQrDialog,
                                icon: const Icon(Icons.qr_code_2, color: Color(0xFF0D9488)),
                                label: const Text(
                                  'Tampilkan Kartu QR NIP Saya',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0D9488),
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Color(0xFF0D9488)),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ),

                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Row(
                                children: [
                                  Expanded(child: Divider()),
                                  Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 8),
                                    child: Text(
                                      'ATAU INPUT TOKEN MANUAL',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                  Expanded(child: Divider()),
                                ],
                              ),
                            ),

                            TextField(
                              controller: _tokenController,
                              textCapitalization: TextCapitalization.characters,
                              decoration: InputDecoration(
                                hintText: 'Contoh: SIMPATI-EVT-A1B2C3D4',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 12,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _isSubmitting
                                    ? null
                                    : () => _submitToken(_tokenController.text),
                                icon: _isSubmitting
                                    ? const SizedBox(
                                        height: 18,
                                        width: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(Icons.send),
                                label: Text(_isSubmitting ? 'Memproses...' : 'Kirim Token Manual'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0F172A),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),
                    const Text(
                      'Daftar Kegiatan Presensi Hari Ini',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 10),

                    if (_events.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 40),
                          child: Column(
                            children: [
                              Icon(Icons.event_busy, size: 48, color: Colors.grey.shade400),
                              const SizedBox(height: 8),
                              const Text(
                                'Belum ada jadwal kegiatan presensi / apel hari ini.',
                                style: TextStyle(color: Colors.grey, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _events.length,
                        itemBuilder: (ctx, i) {
                          final evt = _events[i];
                          final bool isAttended = evt['is_attended'] == true;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          evt['nama_kegiatan'] ?? 'Kegiatan Presensi',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isAttended
                                              ? Colors.green.shade50
                                              : (evt['is_expired'] == true || evt['status'] == 'selesai')
                                                  ? Colors.grey.shade100
                                                  : evt['status'] == 'mendatang'
                                                      ? Colors.blue.shade50
                                                      : Colors.orange.shade50,
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(
                                            color: isAttended
                                                ? Colors.green.shade300
                                                : (evt['is_expired'] == true || evt['status'] == 'selesai')
                                                    ? Colors.grey.shade300
                                                    : evt['status'] == 'mendatang'
                                                        ? Colors.blue.shade300
                                                        : Colors.orange.shade300,
                                          ),
                                        ),
                                        child: Text(
                                          isAttended
                                              ? 'SUDAH PRESENSI'
                                              : (evt['is_expired'] == true || evt['status'] == 'selesai')
                                                  ? 'EVENT SELESAI'
                                                  : evt['status'] == 'mendatang'
                                                      ? 'BELUM DIMULAI'
                                                      : 'BELUM PRESENSI',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: isAttended
                                                ? Colors.green.shade700
                                                : (evt['is_expired'] == true || evt['status'] == 'selesai')
                                                    ? Colors.grey.shade700
                                                    : evt['status'] == 'mendatang'
                                                        ? Colors.blue.shade800
                                                        : Colors.orange.shade800,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    evt['penyelenggara'] ?? 'Pemerintah Kab. Soppeng',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const Divider(height: 16),
                                  Row(
                                    children: [
                                      const Icon(Icons.access_time, size: 14, color: Colors.teal),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${evt['jam_mulai']} - ${evt['jam_selesai']} WITA',
                                        style: const TextStyle(fontSize: 11),
                                      ),
                                      const SizedBox(width: 12),
                                      const Icon(Icons.location_on, size: 14, color: Colors.red),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          evt['lokasi'] ?? '-',
                                          style: const TextStyle(fontSize: 11),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (!isAttended && evt['is_expired'] != true && evt['status'] != 'selesai') ...[
                                    const SizedBox(height: 10),
                                    SizedBox(
                                      width: double.infinity,
                                      child: OutlinedButton.icon(
                                        onPressed: () => _submitToken(evt['qr_token'] ?? ''),
                                        icon: const Icon(Icons.qr_code, size: 16),
                                        label: const Text('Presensi dengan Token Event Ini'),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: const Color(0xFF0D9488),
                                          side: const BorderSide(color: Color(0xFF0D9488)),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}

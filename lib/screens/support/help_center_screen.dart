import 'dart:ui';
import 'package:flutter/material.dart';
import '../../config/theme.dart';

class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({super.key});

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final List<Map<String, dynamic>> _categories = [
    {
      'title': 'Presensi & Lokasi',
      'icon': Icons.location_on_rounded,
      'faqs': [
        {
          'q': 'Mengapa saya tidak bisa absen?',
          'a':
              'Pastikan Anda berada dalam radius kantor (geofencing) dan GPS ponsel Anda aktif dengan akurasi tinggi.',
        },
        {
          'q': 'Bagaimana jika GPS tidak akurat?',
          'a':
              'Coba buka aplikasi Google Maps terlebih dahulu untuk mengkalibrasi lokasi Anda, lalu kembali ke aplikasi SIMPATI.',
        },
      ],
    },
    {
      'title': 'Akun & Keamanan',
      'icon': Icons.shield_rounded,
      'faqs': [
        {
          'q': 'Lupa password?',
          'a':
              'Silakan hubungi admin kepegawaian di instansi Anda untuk melakukan reset password.',
        },
        {
          'q': 'Cara ganti foto profil?',
          'a':
              'Anda dapat memperbarui foto profil melalui menu Profil > Edit Profil (segera hadir).',
        },
      ],
    },
    {
      'title': 'Pengajuan Layanan',
      'icon': Icons.description_rounded,
      'faqs': [
        {
          'q': 'Berapa lama approval cuti?',
          'a':
              'Proses persetujuan biasanya memakan waktu 1-3 hari kerja tergantung pada verifikasi atasan langsung.',
        },
        {
          'q': 'Format file lampiran?',
          'a':
              'Kami mendukung format PDF, JPG, dan PNG dengan ukuran maksimal 2MB.',
        },
      ],
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          // Header Glassmorphism
          SliverAppBar(
            expandedHeight: 180,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'Pusat Bantuan',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppTheme.navy800, AppTheme.navy900],
                      ),
                    ),
                  ),
                  Positioned(
                    top: -20,
                    right: -20,
                    child: Icon(
                      Icons.help_outline_rounded,
                      size: 200,
                      color: AppTheme.teal500.withAlpha(20),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Search & Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Search Bar
                  _buildGlassWrapper(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (v) => setState(() => _searchQuery = v),
                      decoration: InputDecoration(
                        hintText: 'Cari bantuan...',
                        prefixIcon: const Icon(
                          Icons.search,
                          color: AppTheme.teal500,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 15,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  const Text(
                    'Kategori Bantuan',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.teal500,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Categories & FAQs
                  ..._categories.map((cat) => _buildCategorySection(cat)),

                  const SizedBox(height: 40),

                  // Contact Support
                  const Text(
                    'Masih butuh bantuan?',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _buildContactCard(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySection(Map<String, dynamic> cat) {
    if (_searchQuery.isNotEmpty) {
      final faqs = (cat['faqs'] as List<Map<String, String>>)
          .where(
            (f) =>
                f['q']!.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                f['a']!.toLowerCase().contains(_searchQuery.toLowerCase()),
          )
          .toList();
      if (faqs.isEmpty) return const SizedBox.shrink();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCategoryHeader(cat),
          const SizedBox(height: 12),
          ...faqs.map((f) => _buildFaqItem(f['q']!, f['a']!)),
          const SizedBox(height: 24),
        ],
      );
    }

    return ExpansionTile(
      leading: Icon(cat['icon'], color: AppTheme.teal500),
      title: Text(
        cat['title'],
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      childrenPadding: const EdgeInsets.all(0),
      children: [
        ...(cat['faqs'] as List<Map<String, String>>).map(
          (f) => _buildFaqItem(f['q']!, f['a']!),
        ),
      ],
    );
  }

  Widget _buildCategoryHeader(Map<String, dynamic> cat) {
    return Row(
      children: [
        Icon(cat['icon'], color: AppTheme.teal500, size: 20),
        const SizedBox(width: 8),
        Text(
          cat['title'],
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildFaqItem(String q, String a) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _buildGlassWrapper(
        child: ExpansionTile(
          title: Text(q, style: const TextStyle(fontSize: 14)),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          expandedAlignment: Alignment.topLeft,
          children: [
            Text(
              a,
              style: const TextStyle(
                color: Colors.grey,
                height: 1.5,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassWrapper({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor.withAlpha(150),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: child,
        ),
      ),
    );
  }

  Widget _buildContactCard() {
    return _buildGlassWrapper(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.teal500.withAlpha(30),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.headset_mic_rounded,
                color: AppTheme.teal500,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Customer Service',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Hubungi via WhatsApp (24/7)',
                    style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.teal500,
                minimumSize: const Size(60, 36),
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              child: const Text(
                'Chat',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

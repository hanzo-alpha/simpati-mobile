import 'package:flutter/material.dart';
import '../../config/theme.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final List<Map<String, dynamic>> _notifications = [
    {
      'id': '1',
      'title': 'Pengingat Presensi Masuk',
      'body': 'Jangan lupa untuk melakukan presensi Masuk hari ini sebelum jam 07:30 WITA.',
      'time': '07:00 WITA',
      'icon': Icons.access_time_filled_rounded,
      'color': AppTheme.warning,
      'isRead': false,
      'route': '/home',
      'tabIndex': 1, // Presensi tab
    },
    {
      'id': '2',
      'title': 'Presensi Berhasil Recorded',
      'body': 'Presensi masuk Anda telah tercatat pada 07:45 WITA dengan lokasi terverifikasi.',
      'time': '07:45 WITA',
      'icon': Icons.check_circle_rounded,
      'color': AppTheme.success,
      'isRead': true,
      'route': '/home',
      'tabIndex': 2, // Riwayat tab
    },
    {
      'id': '3',
      'title': 'Pengajuan Cuti Disetujui',
      'body': 'Pengajuan cuti tahunan Anda selama 2 hari telah disetujui oleh Atasan Langsung.',
      'time': 'Kemarin',
      'icon': Icons.event_available_rounded,
      'color': AppTheme.teal500,
      'isRead': true,
      'route': '/pengajuan',
    },
    {
      'id': '4',
      'title': 'Permohonan Tukar Shift ASN',
      'body': 'Rekan kerja mengajukan permohonan pertukaran jadwal piket shift dengan Anda.',
      'time': '2 Hari Lalu',
      'icon': Icons.swap_horiz_rounded,
      'color': AppTheme.info,
      'isRead': false,
      'route': '/shift_swap',
    },
  ];

  void _handleNotificationTap(Map<String, dynamic> notif) {
    setState(() {
      notif['isRead'] = true;
    });

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AppTheme.navy800,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (notif['color'] as Color).withAlpha(30),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(notif['icon'], color: notif['color'], size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notif['title'],
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        notif['time'],
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(color: Colors.white12, height: 1),
            const SizedBox(height: 16),
            Text(
              notif['body'],
              style: const TextStyle(fontSize: 14, color: Colors.white70, height: 1.5),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  if (notif['route'] != null) {
                    Navigator.pushNamed(context, notif['route']);
                  }
                },
                icon: const Icon(Icons.open_in_new_rounded, size: 18),
                label: const Text('BUKA FITUR TERKAIT'),
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
      ),
    );
  }

  Widget _buildGlassCard({
    required Widget child,
    required bool isRead,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isRead
            ? Colors.white.withAlpha(5)
            : AppTheme.teal500.withAlpha(20),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isRead
              ? Colors.white.withAlpha(10)
              : AppTheme.teal500.withAlpha(50),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            child: Padding(padding: const EdgeInsets.all(16), child: child),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppTheme.navy900, AppTheme.navy800],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(20),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded),
                        color: Colors.white,
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Text(
                      'Notifikasi',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),

              // Notification List
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: _notifications.length,
                  itemBuilder: (context, index) {
                    final notif = _notifications[index];
                    return _buildGlassCard(
                      isRead: notif['isRead'],
                      onTap: () => _handleNotificationTap(notif),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: notif['color'].withAlpha(30),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(notif['icon'], color: notif['color']),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        notif['title'],
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: notif['isRead']
                                              ? Colors.white70
                                              : Colors.white,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      notif['time'],
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.white.withAlpha(100),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  notif['body'],
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: notif['isRead']
                                        ? Colors.grey
                                        : Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

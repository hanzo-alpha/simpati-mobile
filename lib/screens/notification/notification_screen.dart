import 'package:flutter/material.dart';
import '../../config/theme.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final List<Map<String, dynamic>> _dummyNotifications = [
    {
      'title': 'Pengingat Presensi',
      'body': 'Jangan lupa untuk melakukan presensi Masuk hari ini.',
      'time': '07:00 Pagi',
      'icon': Icons.access_time_filled_rounded,
      'color': AppTheme.warning,
      'isRead': false,
    },
    {
      'title': 'Presensi Berhasil',
      'body': 'Presensi masuk Anda telah tercatat pada 07:45.',
      'time': '07:45 Pagi',
      'icon': Icons.check_circle_rounded,
      'color': AppTheme.success,
      'isRead': true,
    },
    {
      'title': 'Pengajuan Cuti Disetujui',
      'body': 'Pengajuan cuti tahunan Anda telah disetujui oleh atasan.',
      'time': 'Kemarin',
      'icon': Icons.event_available_rounded,
      'color': AppTheme.teal500,
      'isRead': true,
    },
  ];

  Widget _buildGlassCard({required Widget child, required bool isRead}) {
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
        child: BackdropFilter(
          filter: ColorFilter.mode(
            Colors.black.withAlpha(10),
            BlendMode.srcOver,
          ),
          child: Padding(padding: const EdgeInsets.all(16), child: child),
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
                  itemCount: _dummyNotifications.length,
                  itemBuilder: (context, index) {
                    final notif = _dummyNotifications[index];
                    return _buildGlassCard(
                      isRead: notif['isRead'],
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

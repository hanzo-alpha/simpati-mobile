import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../config/theme.dart';
import '../../services/reminder_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final ReminderService _reminderService = ReminderService();
  bool _reminderEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final enabled = await _reminderService.isReminderEnabled();
    setState(() => _reminderEnabled = enabled);
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.themeMode == ThemeMode.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('Pengaturan'), elevation: 0),
      body: ListView(
        children: [
          const SizedBox(height: 12),
          _buildSectionHeader('Tampilan'),
          _buildSettingTile(
            title: 'Mode Gelap',
            subtitle: 'Gunakan tema gelap yang premium',
            trailing: Switch.adaptive(
              value: isDark,
              activeThumbColor: AppTheme.teal500,
              onChanged: (value) => themeProvider.toggleTheme(value),
            ),
            icon: Icons.dark_mode_outlined,
          ),
          const Divider(height: 1),
          _buildSectionHeader('Notifikasi & Alarm'),
          _buildSettingTile(
            title: 'Pengingat Presensi Otomatis',
            subtitle: 'Alarm 15m sebelum jam masuk (07.15) & pulang (15.45)',
            trailing: Switch.adaptive(
              value: _reminderEnabled,
              activeThumbColor: AppTheme.teal500,
              onChanged: (value) async {
                setState(() => _reminderEnabled = value);
                await _reminderService.setReminderEnabled(value);
              },
            ),
            icon: Icons.notifications_active_outlined,
          ),
          const Divider(height: 1),
          _buildSectionHeader('Informasi'),
          _buildSettingTile(
            title: 'Pusat Bantuan',
            subtitle: 'Butuh bantuan menggunakan aplikasi?',
            trailing: const Icon(Icons.chevron_right, size: 20),
            icon: Icons.help_outline_rounded,
            onTap: () {},
          ),
          _buildSettingTile(
            title: 'Tentang Aplikasi',
            subtitle: 'Versi 1.0.0',
            trailing: const Icon(Icons.chevron_right, size: 20),
            icon: Icons.info_outline_rounded,
            onTap: () {},
          ),
          const SizedBox(height: 40),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'SIMPATI v1.0.0\nBKPSDM Kabupaten Soppeng',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w900,
          color: AppTheme.teal500,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSettingTile({
    required String title,
    required String subtitle,
    required Widget trailing,
    required IconData icon,
    VoidCallback? onTap,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppTheme.teal500.withAlpha(20),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: AppTheme.teal500, size: 22),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 12, color: Colors.grey),
      ),
      trailing: trailing,
    );
  }
}

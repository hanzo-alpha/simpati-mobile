import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';

class ProfilScreen extends StatelessWidget {
  const ProfilScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final dark = AppTheme.isDark(context);

    return Scaffold(
      backgroundColor: AppTheme.bgPrimary(context),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Stack(
              children: [
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: AppTheme.headerGradient(context),
                    ),
                  ),
                ),
                SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Text(
                              'Profil Saya',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: dark ? Colors.white : Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildProfileCard(
                          context,
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppTheme.teal500.withAlpha(100),
                                    width: 2,
                                  ),
                                ),
                                child: CircleAvatar(
                                  radius: 35,
                                  backgroundColor: dark
                                      ? AppTheme.navy700
                                      : AppTheme.teal600,
                                  child: Text(
                                    _initials(auth.userName),
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 20),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                     SelectableText(
                                       auth.userName,
                                       style: TextStyle(
                                         fontSize: 18,
                                         fontWeight: FontWeight.w900,
                                         color: AppTheme.textPrimary(context),
                                         height: 1.2,
                                       ),
                                     ),
                                     const SizedBox(height: 6),
                                     SelectableText(
                                       auth.userNip.isEmpty ? '-' : 'NIP. ${auth.userNip}',
                                       style: TextStyle(
                                         fontSize: 12,
                                         fontFamily: 'monospace',
                                         fontWeight: FontWeight.w700,
                                         color: AppTheme.textSecondary(context),
                                         letterSpacing: 0.5,
                                       ),
                                     ),
                                     const SizedBox(height: 10),
                                     Container(
                                       padding: const EdgeInsets.symmetric(
                                         horizontal: 12,
                                         vertical: 5,
                                       ),
                                       decoration: BoxDecoration(
                                         color: AppTheme.teal500.withAlpha(30),
                                         borderRadius: BorderRadius.circular(20),
                                         border: Border.all(
                                           color: AppTheme.teal500.withAlpha(80),
                                         ),
                                       ),
                                       child: Text(
                                         auth.userRole.toUpperCase(),
                                         style: const TextStyle(
                                           fontSize: 10,
                                           fontWeight: FontWeight.w800,
                                           color: AppTheme.teal500,
                                           letterSpacing: 0.8,
                                         ),
                                       ),
                                     ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: 0),
                _buildModernSection(context, 'Informasi Kepegawaian', [
                  _InfoRow(
                    icon: Icons.work_outline_rounded,
                    label: 'Jabatan',
                    value: auth.userJabatan,
                  ),
                  _InfoRow(
                    icon: Icons.business_rounded,
                    label: 'Unit Kerja',
                    value: auth.userOpdName,
                  ),
                  _InfoRow(
                    icon: Icons.military_tech_rounded,
                    label: 'Pangkat/Gol',
                    value: auth.user?['profile']?['pangkat_golongan'] ?? '-',
                  ),
                  _InfoRow(
                    icon: Icons.event_available_rounded,
                    label: 'Sisa Cuti',
                    value: '${auth.sisaCuti} Hari',
                  ),
                ]),
                const SizedBox(height: 20),
                _buildModernSection(context, 'Kontak & Lokasi', [
                  _InfoRow(
                    icon: Icons.email_outlined,
                    label: 'Email',
                    value: auth.user?['email'] ?? '-',
                  ),
                  _InfoRow(
                    icon: Icons.phone_android_rounded,
                    label: 'No. HP',
                    value: auth.user?['profile']?['no_hp'] ?? '-',
                  ),
                  _InfoRow(
                    icon: Icons.location_on_outlined,
                    label: 'Kantor',
                    value: auth.user?['office']?['alamat'] ?? '-',
                  ),
                ]),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 12),
                  child: Text(
                    'Menu Utama',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.isDark(context)
                          ? AppTheme.teal500
                          : AppTheme.teal600,
                    ),
                  ),
                ),

                _buildModernMenuTile(
                  context,
                  Icons.settings_rounded,
                  'Pengaturan Aplikasi',
                  () {
                    Navigator.pushNamed(context, '/settings');
                  },
                ),
                _buildModernMenuTile(
                  context,
                  Icons.help_center_rounded,
                  'Pusat Bantuan',
                  () {
                    Navigator.pushNamed(context, '/help_center');
                  },
                ),

                const SizedBox(height: 32),
                SizedBox(
                  height: 55,
                  child: ElevatedButton.icon(
                    onPressed: () => _showLogoutDialog(context, auth),
                    icon: const Icon(Icons.logout_rounded, size: 20),
                    label: const Text('KELUAR DARI APLIKASI'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.danger.withAlpha(200),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                Center(
                  child: Text(
                    'SIMPATI v1.0.0\nBKPSDM Kabupaten Soppeng',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppTheme.textSecondary(context),
                      fontSize: 11,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 120),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard(
    BuildContext context, {
    required Widget child,
    EdgeInsetsGeometry? padding,
  }) {
    final dark = AppTheme.isDark(context);
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: dark ? AppTheme.navy800.withAlpha(200) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: dark
              ? AppTheme.teal500.withAlpha(40)
              : Colors.grey.withAlpha(30),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: dark
                ? Colors.black.withAlpha(40)
                : Colors.black.withAlpha(20),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildGlassCard(
    BuildContext context, {
    required Widget child,
    EdgeInsetsGeometry? padding,
  }) {
    final dark = AppTheme.isDark(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: dark
                ? Colors.white.withAlpha(10)
                : Colors.white.withAlpha(200),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: dark
                  ? Colors.white.withAlpha(20)
                  : Colors.black.withAlpha(8),
            ),
            gradient: dark
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withAlpha(15),
                      Colors.white.withAlpha(5),
                    ],
                  )
                : null,
            boxShadow: dark
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withAlpha(10),
                      blurRadius: 15,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildModernSection(
    BuildContext context,
    String title,
    List<Widget> children,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: AppTheme.isDark(context)
                  ? AppTheme.teal500
                  : AppTheme.teal600,
            ),
          ),
        ),
        _buildGlassCard(
          context,
          padding: const EdgeInsets.all(16),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildModernMenuTile(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onTap,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: onTap,
        child: _buildGlassCard(
          context,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.teal500.withAlpha(20),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppTheme.teal500, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary(context),
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: AppTheme.textMuted(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, AuthProvider auth) {
    final dark = AppTheme.isDark(context);
    showDialog(
      context: context,
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: AlertDialog(
          backgroundColor: dark ? AppTheme.navy800 : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Text('Keluar dari SIMPATI?'),
          content: const Text('Pastikan semua pekerjaan Anda telah tersimpan.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('BATAL', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await auth.logout();
                if (context.mounted) {
                  Navigator.pushReplacementNamed(context, '/login');
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
              child: const Text('KELUAR'),
            ),
          ],
        ),
      ),
    );
  }

  String _initials(String name) => name
      .split(' ')
      .map((n) => n.isNotEmpty ? n[0] : '')
      .take(2)
      .join()
      .toUpperCase();
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final displayValue = value.trim().isEmpty ? '-' : value;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.teal500.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: AppTheme.teal500),
              ),
              const SizedBox(width: 10),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary(context),
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 32),
            child: SelectableText(
              displayValue,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary(context),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/navigation_provider.dart';
import '../home/dashboard_screen.dart';
import '../attendance/riwayat_screen.dart';
import '../attendance/presensi_screen.dart';
import '../leave/pengajuan_screen.dart';
import '../profile/profil_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final List<Widget> _screens = const [
    DashboardScreen(),
    RiwayatScreen(),
    PresensiScreen(),
    PengajuanScreen(),
    ProfilScreen(),
  ];

  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nav = context.watch<NavigationProvider>();
    final currentIndex = nav.currentIndex;
    final goingForward = currentIndex > nav.previousIndex;

    return Scaffold(
      extendBody: true,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) {
          final slideIn = Tween<Offset>(
            begin: Offset(goingForward ? 0.05 : -0.05, 0),
            end: Offset.zero,
          ).animate(animation);
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(position: slideIn, child: child),
          );
        },
        child: KeyedSubtree(
          key: ValueKey<int>(currentIndex),
          child: _screens[currentIndex],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
            // Glassmorphic Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Container(
                  height: 68,
                  decoration: BoxDecoration(
                    color: AppTheme.navBarBg(context),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: AppTheme.bgGlassBorder(context),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(60),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      _buildNavItem(
                        context,
                        0,
                        Icons.home_outlined,
                        Icons.home_rounded,
                        'Home',
                      ),
                      _buildNavItem(
                        context,
                        1,
                        Icons.access_time_outlined,
                        Icons.access_time_filled,
                        'Riwayat',
                      ),
                      const SizedBox(width: 64), // Space for center button
                      _buildNavItem(
                        context,
                        3,
                        Icons.description_outlined,
                        Icons.description,
                        'Pengajuan',
                      ),
                      _buildNavItem(
                        context,
                        4,
                        Icons.person_outline_rounded,
                        Icons.person_rounded,
                        'Profil',
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Floating Center Button
            Positioned(top: -18, child: _buildCenterButton(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    int index,
    IconData icon,
    IconData activeIcon,
    String label,
  ) {
    final nav = context.read<NavigationProvider>();
    final isActive = nav.currentIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => nav.setIndex(index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isActive
                    ? AppTheme.teal500.withAlpha(25)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                isActive ? activeIcon : icon,
                size: isActive ? 24 : 22,
                color: isActive
                    ? AppTheme.teal400
                    : AppTheme.navBarInactiveIcon(context),
              ),
            ),
            const SizedBox(height: 2),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 250),
              style: TextStyle(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive
                    ? AppTheme.teal400
                    : AppTheme.navBarInactiveText(context),
              ),
              child: Text(label),
            ),
            const SizedBox(height: 3),
            // Active dot indicator
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              width: isActive ? 5 : 0,
              height: isActive ? 5 : 0,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.teal400,
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: AppTheme.teal400.withAlpha(120),
                          blurRadius: 6,
                        ),
                      ]
                    : [],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterButton(BuildContext context) {
    final nav = context.watch<NavigationProvider>();
    final isActive = nav.currentIndex == 2;

    return GestureDetector(
      onTap: () => context.read<NavigationProvider>().setIndex(2),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Pulsing outer ring
          if (isActive)
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Container(
                  width: 68 + (_pulseController.value * 8),
                  height: 68 + (_pulseController.value * 8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppTheme.teal500.withAlpha(
                        (40 - (_pulseController.value * 30)).toInt(),
                      ),
                      width: 2,
                    ),
                  ),
                );
              },
            ),
          // Main button
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: isActive ? 62 : 58,
            height: isActive ? 62 : 58,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isActive
                    ? [AppTheme.teal400, AppTheme.teal600]
                    : [AppTheme.teal500, AppTheme.teal800],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.teal500.withAlpha(isActive ? 140 : 70),
                  blurRadius: isActive ? 24 : 14,
                  offset: const Offset(0, 6),
                ),
                if (isActive)
                  BoxShadow(
                    color: AppTheme.teal400.withAlpha(40),
                    blurRadius: 30,
                    spreadRadius: 4,
                  ),
              ],
              border: Border.all(
                color: Colors.white.withAlpha(isActive ? 50 : 20),
                width: 2,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.fingerprint,
                  size: isActive ? 28 : 26,
                  color: Colors.white,
                ),
                if (isActive)
                  const Text(
                    'Presensi',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 7,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

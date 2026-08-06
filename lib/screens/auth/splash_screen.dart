import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/notification_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotateAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOutBack),
      ),
    );

    _rotateAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOutCubic),
      ),
    );

    _controller.forward();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;

    final auth = context.read<AuthProvider>();
    final isLoggedIn = await auth.checkAuth();

    if (mounted) {
      if (isLoggedIn) {
        NotificationService().scheduleAttendanceAlarms();
      }
      Navigator.pushReplacementNamed(context, isLoggedIn ? '/home' : '/login');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.navy900,
      body: Stack(
        children: [
          // Dynamic Background
          Positioned.fill(
            child: CustomPaint(painter: GlowPainter(animation: _controller)),
          ),

          // Glassmorphism overlay (subtle)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(color: AppTheme.navy900.withAlpha(50)),
            ),
          ),

          Center(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Logo Container
                        RotationTransition(
                          turns: _rotateAnimation,
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [AppTheme.teal500, AppTheme.teal700],
                              ),
                              borderRadius: BorderRadius.circular(32),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.teal500.withAlpha(80),
                                  blurRadius: 50,
                                  spreadRadius: 2,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.shield_rounded,
                              size: 60,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
                        // App Name
                        const Text(
                          'SIMPATI',
                          style: TextStyle(
                            fontSize: 42,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 8,
                            color: Colors.white,
                            shadows: [
                              Shadow(color: AppTheme.teal500, blurRadius: 20),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'SISTEM INFORMASI MANAJEMEN PRESENSI TERINTEGRASI',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.grey[400],
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.teal500.withAlpha(30),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppTheme.teal500.withAlpha(100),
                            ),
                          ),
                          child: const Text(
                            'KABUPATEN SOPPENG',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.teal500,
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Bottom Indicator
          Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: const Center(
                child: SizedBox(
                  width: 30,
                  height: 30,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.teal500),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class GlowPainter extends CustomPainter {
  final Animation<double> animation;

  GlowPainter({required this.animation}) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 60);

    // Drawing floating blobs
    final center = Offset(size.width / 2, size.height / 2);

    // Blob 1
    paint.color = AppTheme.teal500.withAlpha(25);
    canvas.drawCircle(
      Offset(
        center.dx + 50 * animation.value,
        center.dy - 100 * (1 - animation.value),
      ),
      120,
      paint,
    );

    // Blob 2
    paint.color = AppTheme.navy700.withAlpha(40);
    canvas.drawCircle(
      Offset(
        center.dx - 100 * (1 - animation.value),
        center.dy + 80 * animation.value,
      ),
      150,
      paint,
    );
  }

  @override
  bool shouldRepaint(GlowPainter oldDelegate) => true;
}

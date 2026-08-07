import 'dart:ui';
import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../services/biometric_service.dart';
import 'package:provider/provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _nipController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nipController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final auth = context.read<AuthProvider>();
    final success = await auth.login(
      _nipController.text.trim(),
      _passwordController.text.trim(),
    );

    if (success && mounted) {
      Navigator.pushReplacementNamed(context, '/home');
    } else if (mounted && auth.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.error!), backgroundColor: AppTheme.danger),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient & Glowing Blobs
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                color: AppTheme.navy900,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [AppTheme.navy900, AppTheme.navy800],
                ),
              ),
            ),
          ),

          // Bubbles/Blobs
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.teal500.withAlpha(20),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),

          Positioned(
            bottom: -50,
            left: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.teal500.withAlpha(15),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Official Logo Box (Premium Glassmorphism)
                    Container(
                      width: 96,
                      height: 96,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white.withAlpha(35),
                            Colors.white.withAlpha(12),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(26),
                        border: Border.all(
                          color: const Color(0xFF0D9488).withAlpha(140),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0D9488).withAlpha(70),
                            blurRadius: 30,
                            spreadRadius: 2,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Image.asset(
                        'assets/images/logo_clean.png',
                        fit: BoxFit.contain,
                        errorBuilder: (ctx, err, stack) => Image.asset(
                          'assets/images/logo.png',
                          fit: BoxFit.contain,
                          errorBuilder: (c, e, s) => const Icon(
                            Icons.shield_rounded,
                            size: 45,
                            color: Color(0xFF0D9488),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'SIMPATI',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Presensi Digital ASN Kabupaten Soppeng',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[400],
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 48),

                    // GLASSMORPHISM CARD
                    ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                        child: Container(
                          padding: const EdgeInsets.all(28),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(10),
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(
                              color: Colors.white.withAlpha(20),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Selamat Datang',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Silakan masuk ke akun Anda',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[400],
                                ),
                              ),
                              const SizedBox(height: 32),

                              // NIP
                              _buildInputField(
                                label: 'NIP',
                                controller: _nipController,
                                icon: Icons.person_outline_rounded,
                                keyboardType: TextInputType.number,
                              ),
                              const SizedBox(height: 20),

                              // Password
                              _buildInputField(
                                label: 'Password',
                                controller: _passwordController,
                                icon: Icons.lock_outline_rounded,
                                obscureText: _obscurePassword,
                                isPassword: true,
                              ),
                              const SizedBox(height: 32),

                              // Login Button
                              SizedBox(
                                width: double.infinity,
                                height: 56,
                                child: ElevatedButton(
                                  onPressed: auth.isLoading ? null : _login,
                                  style: ElevatedButton.styleFrom(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    elevation: 8,
                                    shadowColor: AppTheme.teal500.withAlpha(
                                      100,
                                    ),
                                  ),
                                  child: auth.isLoading
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Text(
                                          'MASUK SEKARANG',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 1.2,
                                          ),
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final bioService = BiometricService();
                              final messenger = ScaffoldMessenger.of(context);
                              final nav = Navigator.of(context);

                              final bool authenticated = await bioService.authenticate(
                                localizedReason: 'Verifikasi Sidik Jari / Face ID untuk Masuk SIMPATI',
                              );
                              if (authenticated && mounted) {
                                bool authOk = await auth.checkAuth();
                                if (!authOk && _nipController.text.isNotEmpty && _passwordController.text.isNotEmpty) {
                                  authOk = await auth.login(_nipController.text.trim(), _passwordController.text.trim());
                                }

                                if (!mounted) return;

                                if (authOk) {
                                  messenger.showSnackBar(
                                    const SnackBar(
                                      content: Text('✅ Autentikasi Biometrik Berhasil!'),
                                      backgroundColor: AppTheme.success,
                                    ),
                                  );
                                  nav.pushReplacementNamed('/home');
                                } else {
                                  messenger.showSnackBar(
                                    const SnackBar(
                                      content: Text('⚠️ Silakan ketik NIP & Password Anda untuk login pertama kali.'),
                                      backgroundColor: AppTheme.warning,
                                    ),
                                  );
                                }
                              }
                            },
                            icon: const Icon(Icons.fingerprint_rounded, color: AppTheme.teal500, size: 24),
                            label: const Text(
                              'Biometrik',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: BorderSide(color: AppTheme.teal500.withAlpha(80)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton(
                          onPressed: () {
                            // Demo Help
                          },
                          child: Text(
                            'Lupa Password?',
                            style: TextStyle(
                              color: AppTheme.teal500.withAlpha(200),
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        Text(
                          '•',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        TextButton(
                          onPressed: () => _showDeviceResetDialog(context),
                          child: const Text(
                            'Reset Perangkat HP',
                            style: TextStyle(
                              color: Colors.amber,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 40),
                    Text(
                      'Pemerintah Kabupaten Soppeng © 2026',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeviceResetDialog(BuildContext context) {
    final resetNipCtrl = TextEditingController(text: _nipController.text);
    final resetPassCtrl = TextEditingController(text: _passwordController.text);
    final resetReasonCtrl = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.phonelink_erase_rounded, color: Colors.amber),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Reset Binding HP',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Layanan mandiri reset kunci perangkat HP jika Anda berganti ponsel baru.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: resetNipCtrl,
                decoration: const InputDecoration(
                  labelText: 'NIP ASN',
                  prefixIcon: Icon(Icons.person, size: 18),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: resetPassCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password Akun',
                  prefixIcon: Icon(Icons.lock, size: 18),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: resetReasonCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Alasan Ganti Perangkat HP',
                  hintText: 'Contoh: Beli HP Baru / HP Lama Rusak',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: isSubmitting
                  ? null
                  : () async {
                      if (resetNipCtrl.text.trim().isEmpty ||
                          resetPassCtrl.text.trim().isEmpty ||
                          resetReasonCtrl.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('⚠️ Mohon lengkapi NIP, password, dan alasan.'),
                            backgroundColor: AppTheme.warning,
                          ),
                        );
                        return;
                      }

                      final messenger = ScaffoldMessenger.of(context);
                      setModalState(() => isSubmitting = true);
                      try {
                        final api = ApiService();
                        final res = await api.requestDeviceReset(
                          nip: resetNipCtrl.text.trim(),
                          password: resetPassCtrl.text.trim(),
                          alasan: resetReasonCtrl.text.trim(),
                        );
                        if (ctx.mounted) Navigator.pop(ctx);
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text('✅ ${res.data['message']}'),
                            backgroundColor: AppTheme.success,
                          ),
                        );
                      } catch (e) {
                        setModalState(() => isSubmitting = false);
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text('❌ Gagal reset perangkat: $e'),
                            backgroundColor: AppTheme.danger,
                          ),
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(isSubmitting ? 'MEMPROSES...' : 'PROSES RESET'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    bool obscureText = false,
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white70,
            ),
          ),
        ),
        TextField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white.withAlpha(15),
            prefixIcon: Icon(icon, size: 20, color: AppTheme.teal500),
            hintText: 'Ketik $label...',
            hintStyle: TextStyle(color: Colors.grey[600], fontSize: 13),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.white.withAlpha(15)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppTheme.teal500, width: 1.5),
            ),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      obscureText ? Icons.visibility_off : Icons.visibility,
                      color: Colors.grey[500],
                      size: 18,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  )
                : null,
          ),
        ),
      ],
    );
  }
}

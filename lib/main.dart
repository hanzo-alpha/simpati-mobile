import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'config/theme.dart';
import 'providers/auth_provider.dart';
import 'providers/navigation_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/splash_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/attendance/peringkat_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/support/help_center_screen.dart';
import 'screens/leave/approval_screen.dart';
import 'screens/leave/shift_swap_screen.dart';
import 'screens/notification/notification_screen.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize Locale
  await initializeDateFormatting('id_ID', null);
  Intl.defaultLocale = 'id_ID';

  // 2. Initialize Firebase
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
  }

  // 3. Initialize Notifications
  try {
    final notificationService = NotificationService();
    await notificationService.initialize();
  } catch (e) {
    debugPrint('Notification initialization failed: $e');
  }

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
      ],
      child: const SimpatiApp(),
    ),
  );
}

class SimpatiApp extends StatelessWidget {
  const SimpatiApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return MaterialApp(
      title: 'SIMPATI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode,
      home: const SplashScreen(),
      routes: {
        '/login': (_) => const LoginScreen(),
        '/home': (_) => const HomeScreen(),
        '/peringkat': (_) => const PeringkatScreen(),
        '/settings': (_) => const SettingsScreen(),
        '/help_center': (_) => const HelpCenterScreen(),
        '/notification': (_) => const NotificationScreen(),
        '/approval': (_) => const ApprovalScreen(),
        '/shift_swap': (_) => const ShiftSwapScreen(),
      },
    );
  }
}

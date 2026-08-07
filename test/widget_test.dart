import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:simpati_mobile/main.dart';
import 'package:simpati_mobile/providers/auth_provider.dart';
import 'package:simpati_mobile/providers/navigation_provider.dart';
import 'package:simpati_mobile/providers/theme_provider.dart';

void main() {
  testWidgets('App launches', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => NavigationProvider()),
        ],
        child: const SimpatiApp(),
      ),
    );
    await tester.pump(const Duration(seconds: 4));
    expect(find.byType(SimpatiApp), findsOneWidget);
  });
}

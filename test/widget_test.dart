import 'package:flutter_test/flutter_test.dart';
import 'package:simpati_mobile/main.dart';

void main() {
  testWidgets('App launches', (WidgetTester tester) async {
    await tester.pumpWidget(const SimpatiApp());
    expect(find.text('SIMPATI'), findsOneWidget);
  });
}

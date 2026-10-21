import 'package:flutter_test/flutter_test.dart';
import 'package:shekharsir_app/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ShekharSirClassesApp());
    expect(find.byType(ShekharSirClassesApp), findsOneWidget);
  });
}

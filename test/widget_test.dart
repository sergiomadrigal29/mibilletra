import 'package:flutter_test/flutter_test.dart';
import 'package:mibilletera/main.dart';

void main() {
  testWidgets('App loads without errors', (WidgetTester tester) async {
    await tester.pumpWidget(const MiBilleteraApp());
    expect(find.byType(MiBilleteraApp), findsOneWidget);
  });
}

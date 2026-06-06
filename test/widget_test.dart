import 'package:flutter_test/flutter_test.dart';

import 'package:shido_app/app/shido_app.dart';

void main() {
  testWidgets('Shido app shows bottom navigation labels', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ShidoApp());
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    expect(find.text('Dashboard'), findsWidgets);
  });
}

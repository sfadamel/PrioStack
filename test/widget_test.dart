import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:priostack/main.dart';

void main() {
  testWidgets('PrioStack smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: PrioStackApp()));
    expect(find.text('PrioStack'), findsWidgets);
  });
}

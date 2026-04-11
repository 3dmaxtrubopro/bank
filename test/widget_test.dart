import 'package:bank_ubs/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('app shell renders home screen', (WidgetTester tester) async {
    await tester.pumpWidget(const MobileBankApp());
    await tester.pumpAndSettle();

    expect(find.text('Wealth overview'), findsOneWidget);
    expect(find.text('BANK'), findsOneWidget);
  });
}

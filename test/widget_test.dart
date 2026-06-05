import 'package:dts_customer/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App cliente arranca', (tester) async {
    await tester.pumpWidget(const DtsCustomerApp());
    expect(find.text('DTS Cliente — iniciar con /fase-4'), findsOneWidget);
  });
}

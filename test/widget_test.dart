import 'package:dts_customer/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('app boots with provider scope', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: DtsCustomerApp()));
    await tester.pump();
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}

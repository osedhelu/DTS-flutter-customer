import 'package:dts_customer/core/di/providers.dart';
import 'package:dts_customer/features/stores/domain/entities/store.dart';
import 'package:dts_customer/features/stores/domain/usecases/get_stores_usecase.dart';
import 'package:dts_customer/features/stores/presentation/screens/store_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/test_providers.dart';

class MockGetStoresUseCase extends Mock implements GetStoresUseCase {}

void main() {
  late MockGetStoresUseCase getStoresUseCase;

  setUp(() {
    getStoresUseCase = MockGetStoresUseCase();
  });

  testWidgets('store_list_shows_stores_test', (tester) async {
    when(() => getStoresUseCase()).thenAnswer(
      (_) async => const [
        Store(id: 1, name: 'Café Central', address: 'Calle 10'),
        Store(id: 2, name: 'Pizza Norte'),
      ],
    );

    await tester.pumpWidget(
      buildTestApp(
        overrides: [
          getStoresUseCaseProvider.overrideWithValue(getStoresUseCase),
          storesListProvider.overrideWith(
            (ref) async => ref.watch(getStoresUseCaseProvider).call(),
          ),
        ],
        child: const MaterialApp(home: StoreListScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Café Central'), findsOneWidget);
    expect(find.text('Pizza Norte'), findsOneWidget);
    expect(find.byKey(const Key('store_tile_1')), findsOneWidget);
  });
}

import 'package:dts_customer/core/di/providers.dart';
import 'package:dts_customer/features/auth/domain/entities/auth_session.dart';
import 'package:dts_customer/features/auth/domain/usecases/login_usecase.dart';
import 'package:dts_customer/features/auth/presentation/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/test_providers.dart';

class MockLoginUseCase extends Mock implements LoginUseCase {}

void main() {
  late MockLoginUseCase loginUseCase;

  setUp(() {
    loginUseCase = MockLoginUseCase();
  });

  testWidgets('login_screen_widget_test', (tester) async {
    when(
      () => loginUseCase.call(
        username: any(named: 'username'),
        password: any(named: 'password'),
      ),
    ).thenAnswer(
      (_) async => const AuthSession(
        accessToken: 'a',
        refreshToken: 'r',
        role: 'customer',
        userId: 1,
      ),
    );

    final router = GoRouter(
      initialLocation: '/login',
      routes: [
        GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
        GoRoute(
          path: '/stores',
          builder: (_, __) => const Scaffold(body: Text('stores-page')),
        ),
      ],
    );

    await tester.pumpWidget(
      buildTestApp(
        overrides: [
          loginUseCaseProvider.overrideWithValue(loginUseCase),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('login_username')), 'ana');
    await tester.enterText(find.byKey(const Key('login_password')), 'secret');
    await tester.tap(find.byKey(const Key('login_submit')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    verify(
      () => loginUseCase.call(username: 'ana', password: 'secret'),
    ).called(1);
    expect(find.text('Credenciales inválidas'), findsNothing);
  });
}

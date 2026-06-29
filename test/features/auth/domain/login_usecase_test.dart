import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:dts_customer/features/auth/domain/entities/auth_session.dart';
import 'package:dts_customer/features/auth/domain/repositories/auth_repository.dart';
import 'package:dts_customer/features/auth/domain/usecases/login_usecase.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository repository;
  late LoginUseCase useCase;

  setUp(() {
    repository = MockAuthRepository();
    useCase = LoginUseCase(repository);
  });

  test('login_usecase_success_test', () async {
    const session = AuthSession(
      accessToken: 'access',
      refreshToken: 'refresh',
      role: 'customer',
      userId: 1,
    );

    when(
      () => repository.login(
        username: any(named: 'username'),
        password: any(named: 'password'),
      ),
    ).thenAnswer((_) async => session);

    final result = await useCase.call(
      username: 'ana',
      password: 'secret',
    );

    expect(result, session);
    verify(
      () => repository.login(username: 'ana', password: 'secret'),
    ).called(1);
  });

  test('login_usecase_failure_test', () async {
    when(
      () => repository.login(
        username: any(named: 'username'),
        password: any(named: 'password'),
      ),
    ).thenThrow(Exception('invalid credentials'));

    expect(
      () => useCase.call(username: 'ana', password: 'wrong'),
      throwsException,
    );
  });
}

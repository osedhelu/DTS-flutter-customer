import 'package:dts_customer/features/auth/domain/entities/auth_session.dart';
import 'package:dts_customer/features/auth/domain/repositories/auth_repository.dart';
import 'package:dts_customer/features/auth/domain/usecases/register_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository repository;

  setUp(() {
    repository = MockAuthRepository();
  });

  test('register_usecase_test', () async {
    const session = AuthSession(
      accessToken: 'a',
      refreshToken: 'r',
      role: 'customer',
      userId: 1,
    );
    final useCase = RegisterUseCase(repository);

    when(
      () => repository.register(
        username: any(named: 'username'),
        email: any(named: 'email'),
        password: any(named: 'password'),
        phone: any(named: 'phone'),
      ),
    ).thenAnswer((_) async => session);

    final result = await useCase.call(
      const RegisterCustomerParams(
        username: 'ana',
        email: 'ana@test.com',
        password: 'secret123',
        phone: '+573001112233',
      ),
    );

    expect(result, session);
  });

  test('google_sign_in_repository_test', () async {
    const session = AuthSession(
      accessToken: 'a',
      refreshToken: 'r',
      role: 'customer',
      userId: 2,
    );

    when(
      () => repository.signInWithGoogle(idToken: any(named: 'idToken')),
    ).thenAnswer((_) async => session);

    final result =
        await repository.signInWithGoogle(idToken: 'firebase-id-token');

    expect(result, session);
    verify(() => repository.signInWithGoogle(idToken: 'firebase-id-token'))
        .called(1);
  });
}

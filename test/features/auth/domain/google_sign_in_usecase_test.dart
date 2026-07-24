import 'package:dts_customer/features/auth/domain/entities/auth_session.dart';
import 'package:dts_customer/features/auth/domain/repositories/auth_repository.dart';
import 'package:dts_customer/features/auth/domain/usecases/google_sign_in_usecase.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockGoogleSignIn extends Mock implements GoogleSignIn {}

class MockGoogleSignInAccount extends Mock implements GoogleSignInAccount {}

class MockGoogleSignInAuthentication extends Mock
    implements GoogleSignInAuthentication {}

class MockFirebaseAuth extends Mock implements FirebaseAuth {}

class MockUserCredential extends Mock implements UserCredential {}

class MockUser extends Mock implements User {}

class FakeAuthCredential extends Fake implements AuthCredential {}

void main() {
  late MockAuthRepository repository;
  late MockGoogleSignIn googleSignIn;
  late MockGoogleSignInAccount account;
  late MockGoogleSignInAuthentication googleAuth;
  late MockFirebaseAuth firebaseAuth;
  late MockUser user;
  late GoogleSignInUseCase useCase;

  const session = AuthSession(
    accessToken: 'access',
    refreshToken: 'refresh',
    role: 'customer',
    userId: 42,
  );

  setUpAll(() {
    registerFallbackValue(FakeAuthCredential());
  });

  setUp(() {
    repository = MockAuthRepository();
    googleSignIn = MockGoogleSignIn();
    account = MockGoogleSignInAccount();
    googleAuth = MockGoogleSignInAuthentication();
    firebaseAuth = MockFirebaseAuth();
    user = MockUser();
    useCase = GoogleSignInUseCase(
      repository,
      googleSignIn: googleSignIn,
      firebaseAuth: firebaseAuth,
    );

    when(() => firebaseAuth.signOut()).thenAnswer((_) async {});
    when(() => googleSignIn.signOut()).thenAnswer((_) async => null);
  });

  test('falla si el usuario cancela el picker de Google', () async {
    when(() => googleSignIn.signIn()).thenAnswer((_) async => null);

    await expectLater(
      useCase.call(),
      throwsA(
        isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('cancelado'),
        ),
      ),
    );

    verifyNever(
      () => repository.signInWithGoogle(idToken: any(named: 'idToken')),
    );
  });

  test('falla si Google no devuelve idToken (OAuth / serverClientId)', () async {
    when(() => googleSignIn.signIn()).thenAnswer((_) async => account);
    when(() => account.authentication).thenAnswer((_) async => googleAuth);
    when(() => googleAuth.accessToken).thenReturn('access-token');
    when(() => googleAuth.idToken).thenReturn(null);

    await expectLater(
      useCase.call(),
      throwsA(
        isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('idToken'),
        ),
      ),
    );

    verifyNever(() => firebaseAuth.signInWithCredential(any()));
  });

  test('flujo feliz: Firebase + backend con idToken', () async {
    when(() => googleSignIn.signIn()).thenAnswer((_) async => account);
    when(() => account.authentication).thenAnswer((_) async => googleAuth);
    when(() => googleAuth.accessToken).thenReturn('access-token');
    when(() => googleAuth.idToken).thenReturn('google-id-token');
    when(() => firebaseAuth.signInWithCredential(any()))
        .thenAnswer((_) async => MockUserCredential());
    when(() => firebaseAuth.currentUser).thenReturn(user);
    when(() => user.getIdToken()).thenAnswer((_) async => 'firebase-id-token');
    when(
      () => repository.signInWithGoogle(idToken: 'firebase-id-token'),
    ).thenAnswer((_) async => session);

    final result = await useCase.call();

    expect(result, session);
    verify(() => firebaseAuth.signOut()).called(1);
    verify(() => googleSignIn.signOut()).called(1);
    verifyNever(() => googleSignIn.disconnect());
    verify(() => firebaseAuth.signInWithCredential(any())).called(1);
    verify(
      () => repository.signInWithGoogle(idToken: 'firebase-id-token'),
    ).called(1);
  });

  test('falla si Firebase Auth lanza FirebaseAuthException', () async {
    when(() => googleSignIn.signIn()).thenAnswer((_) async => account);
    when(() => account.authentication).thenAnswer((_) async => googleAuth);
    when(() => googleAuth.idToken).thenReturn('google-id-token');
    when(() => firebaseAuth.signInWithCredential(any())).thenThrow(
      FirebaseAuthException(
        code: 'unknown',
        message: 'An internal error has occurred',
      ),
    );

    await expectLater(
      useCase.call(),
      throwsA(
        isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('Firebase Auth falló'),
        ),
      ),
    );
  });

  test('falla si Firebase no entrega idToken tras credential', () async {
    when(() => googleSignIn.signIn()).thenAnswer((_) async => account);
    when(() => account.authentication).thenAnswer((_) async => googleAuth);
    when(() => googleAuth.accessToken).thenReturn('access-token');
    when(() => googleAuth.idToken).thenReturn('google-id-token');
    when(() => firebaseAuth.signInWithCredential(any()))
        .thenAnswer((_) async => MockUserCredential());
    when(() => firebaseAuth.currentUser).thenReturn(user);
    when(() => user.getIdToken()).thenAnswer((_) async => null);

    await expectLater(
      useCase.call(),
      throwsA(
        isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('token de Firebase'),
        ),
      ),
    );
  });
}

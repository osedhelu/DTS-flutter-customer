import '../../../../core/network/token_storage.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/auth_tokens_dto.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required AuthRemoteDataSource remoteDataSource,
    required TokenStorage tokenStorage,
  })  : _remoteDataSource = remoteDataSource,
        _tokenStorage = tokenStorage;

  final AuthRemoteDataSource _remoteDataSource;
  final TokenStorage _tokenStorage;

  @override
  Future<AuthSession> login({
    required String username,
    required String password,
  }) async {
    final dto = await _remoteDataSource.login(
      username: username,
      password: password,
    );
    return _persistSession(dto);
  }

  @override
  Future<AuthSession> register({
    required String username,
    required String email,
    required String password,
    required String phone,
  }) async {
    await _remoteDataSource.register(
      username: username,
      email: email,
      password: password,
      phone: phone,
    );
    return login(username: username, password: password);
  }

  @override
  Future<AuthSession> signInWithGoogle({required String idToken}) async {
    final dto = await _remoteDataSource.signInWithGoogle(idToken: idToken);
    return _persistSession(dto);
  }

  @override
  Future<AuthSession> signInWithApple({required String idToken}) async {
    final dto = await _remoteDataSource.signInWithApple(idToken: idToken);
    return _persistSession(dto);
  }

  Future<AuthSession> _persistSession(AuthTokensDto dto) async {
    final session = dto.toSession();
    await _tokenStorage.saveTokens(
      access: session.accessToken,
      refresh: session.refreshToken,
    );
    return session;
  }

  @override
  Future<void> logout() => _tokenStorage.clear();

  @override
  Future<bool> isAuthenticated() async {
    final token = await _tokenStorage.getAccessToken();
    return token != null && token.isNotEmpty;
  }
}

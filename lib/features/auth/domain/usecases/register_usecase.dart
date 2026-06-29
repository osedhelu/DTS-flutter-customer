import '../entities/auth_session.dart';
import '../repositories/auth_repository.dart';

class RegisterCustomerParams {
  const RegisterCustomerParams({
    required this.username,
    required this.email,
    required this.password,
    required this.phone,
  });

  final String username;
  final String email;
  final String password;
  final String phone;
}

class RegisterUseCase {
  const RegisterUseCase(this._repository);

  final AuthRepository _repository;

  Future<AuthSession> call(RegisterCustomerParams params) {
    return _repository.register(
      username: params.username,
      email: params.email,
      password: params.password,
      phone: params.phone,
    );
  }
}

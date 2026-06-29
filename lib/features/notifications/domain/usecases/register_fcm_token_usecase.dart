import '../repositories/device_token_repository.dart';

class RegisterFcmTokenUseCase {
  const RegisterFcmTokenUseCase(this._repository);

  final DeviceTokenRepository _repository;

  Future<void> call({required String token, required String platform}) {
    return _repository.registerToken(token: token, platform: platform);
  }
}

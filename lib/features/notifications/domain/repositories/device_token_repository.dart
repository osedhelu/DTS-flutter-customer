abstract class DeviceTokenRepository {
  Future<void> registerToken({
    required String token,
    required String platform,
  });
}

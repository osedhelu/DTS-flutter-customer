import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/firebase/firebase_service.dart';
import '../../../core/notifications/customer_fcm_registration.dart';
import '../../notifications/domain/usecases/register_fcm_token_usecase.dart';

class PostAuthService {
  const PostAuthService({
    required RegisterFcmTokenUseCase registerFcmTokenUseCase,
    required FirebaseService firebaseService,
  })  : _registerFcmTokenUseCase = registerFcmTokenUseCase,
        _firebaseService = firebaseService;

  final RegisterFcmTokenUseCase _registerFcmTokenUseCase;
  final FirebaseService _firebaseService;

  /// Marca sesión autenticada sin pasar por `loading` (evita race en Navigator).
  void complete(WidgetRef ref) {
    ref.read(authStateProvider.notifier).setAuthenticated(true);
    unawaited(ref.read(cartNotifierProvider.notifier).hydrate());
    unawaited(_registerPushInBackground());
  }

  Future<void> _registerPushInBackground() async {
    if (kIsWeb) return;

    final registration = CustomerFcmRegistration(
      firebaseService: _firebaseService,
      registerFcmTokenUseCase: _registerFcmTokenUseCase,
    );
    final ok = await registration.register();
    if (!ok) {
      debugPrint(
        'PostAuthService: no se pudo registrar FCM en login '
        '(se reintentará en bootstrap / refresh)',
      );
    }
  }
}

final postAuthServiceProvider = Provider<PostAuthService>((ref) {
  return PostAuthService(
    registerFcmTokenUseCase: ref.watch(registerFcmTokenUseCaseProvider),
    firebaseService: ref.watch(firebaseServiceProvider),
  );
});

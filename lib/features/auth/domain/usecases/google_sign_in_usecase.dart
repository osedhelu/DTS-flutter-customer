import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../entities/auth_session.dart';
import '../repositories/auth_repository.dart';

class GoogleSignInUseCase {
  GoogleSignInUseCase(
    this._repository, {
    GoogleSignIn? googleSignIn,
    FirebaseAuth? firebaseAuth,
  })  : _googleSignIn = googleSignIn ?? GoogleSignIn(scopes: const ['email']),
        _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  final AuthRepository _repository;
  final GoogleSignIn _googleSignIn;
  final FirebaseAuth _firebaseAuth;

  Future<AuthSession> call() async {
    // Solo signOut: disconnect() en iOS suele romper el siguiente signIn.
    await _firebaseAuth.signOut();
    await _googleSignIn.signOut();

    final account = await _googleSignIn.signIn();
    if (account == null) {
      throw StateError('Inicio de sesión con Google cancelado');
    }

    final googleAuth = await account.authentication;
    final googleIdToken = googleAuth.idToken;
    if (googleIdToken == null || googleIdToken.isEmpty) {
      throw StateError(
        'Google no devolvió idToken. Revisa serverClientId / OAuth en Firebase.',
      );
    }

    // Solo idToken: mezclar accessToken en iOS a menudo provoca
    // firebase_auth/unknown "An internal error has occurred".
    final credential = GoogleAuthProvider.credential(idToken: googleIdToken);

    try {
      await _firebaseAuth.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      final detail = [
        e.code,
        if (e.message != null && e.message!.isNotEmpty) e.message,
        if (e.plugin.isNotEmpty) e.plugin,
      ].join(' | ');
      throw StateError('Firebase Auth falló ($detail)');
    }

    final idToken = await _firebaseAuth.currentUser?.getIdToken();
    if (idToken == null || idToken.isEmpty) {
      throw StateError('No se pudo obtener el token de Firebase');
    }

    return _repository.signInWithGoogle(idToken: idToken);
  }
}

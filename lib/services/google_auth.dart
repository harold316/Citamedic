import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleSignInCanceled implements Exception {}

class GoogleAuthService {
  GoogleAuthService._();

  static final instance = GoogleAuthService._();

  GoogleAuthProvider get _provider => GoogleAuthProvider()
    ..addScope('email')
    ..addScope('profile')
    ..setCustomParameters({'prompt': 'select_account'});

  Future<UserCredential> signIn({
    User? anonymous,
    bool forceWeb = false,
  }) async {
    // El plugin nativo de Google (Credential Manager) falla en muchas
    // instalaciones de Play al leer la huella del paquete. Firebase Auth
    // abre el selector en el navegador y no depende de ese certificado.
    return _runProvider(anonymous);
  }

  Future<UserCredential> _runProvider(User? anonymous) async {
    try {
      return await _signInWithProvider(anonymous);
    } on GoogleSignInCanceled {
      rethrow;
    } on FirebaseAuthException catch (error) {
      if (_isCanceled(error.code, error.message)) {
        throw GoogleSignInCanceled();
      }
      throw StateError(_friendlyMessage(error));
    } on PlatformException catch (error) {
      if (_isCanceled(error.code, error.message)) {
        throw GoogleSignInCanceled();
      }
      throw StateError(_friendlyMessage(error));
    }
  }

  Future<UserCredential> _signInWithProvider(User? anonymous) async {
    final provider = _provider;
    if (anonymous != null && anonymous.isAnonymous) {
      try {
        return await anonymous.linkWithProvider(provider);
      } on FirebaseAuthException catch (error) {
        if (_canSwitchAccount(error)) {
          return FirebaseAuth.instance.signInWithProvider(provider);
        }
        rethrow;
      }
    }
    return FirebaseAuth.instance.signInWithProvider(provider);
  }

  Future<void> signOut() async {
    try {
      await GoogleSignIn.instance.signOut();
    } catch (error) {
      debugPrint('No se pudo cerrar Google: $error');
    }
  }

  bool _canSwitchAccount(FirebaseAuthException error) {
    return error.code == 'credential-already-in-use' ||
        error.code == 'account-exists-with-different-credential' ||
        error.code == 'provider-already-linked';
  }

  bool _isCanceled(String? code, String? message) {
    final text = '${code ?? ''} ${message ?? ''}'.toLowerCase();
    if (_looksLikeSystemGoogleFailure(text)) {
      return false;
    }
    return text.contains('cancel') ||
        text.contains('12501') ||
        text.contains('closed-by-user');
  }

  bool _looksLikeSystemGoogleFailure(String text) {
    return text.contains('reauth') ||
        text.contains('[16]') ||
        text.contains('16:') ||
        text.contains('developer') ||
        text.contains('10:') ||
        text.contains('api_exception: 10') ||
        text.contains('interrupted') ||
        text.contains('configuration') ||
        text.contains('certificate hash') ||
        text.contains('package certificate');
  }

  String _friendlyMessage(Object error) {
    final raw = error is StateError
        ? error.message
        : error is PlatformException
        ? '${error.code} ${error.message} ${error.details}'
        : error is FirebaseAuthException
        ? '${error.code} ${error.message}'
        : error.toString();
    final text = raw.toLowerCase();
    if (text.contains('certificate hash') ||
        text.contains('package certificate') ||
        text.contains('invalid_cert_hash')) {
      return 'Google rechazó la huella de esta instalación de Play. En Firebase, app Android com.citamedic.citamedic, agrega el SHA-1 24:E4:20:96:D4:9D:50:22:7F:34:A5:82:1D:88:DC:3F:3F:68:5C:57 y el SHA-256 32:E9:79:0A:C3:8B:A4:56:36:C2:EA:27:CC:6C:E3:50:36:44:C8:D4:A0:A2:6F:6D:92:0E:94:59:64:46:00:9F.';
    }
    if (text.contains('network') || text.contains('unavailable')) {
      return 'Sin conexión con Google. Revisa tu internet e inténtalo otra vez.';
    }
    if (error is FirebaseAuthException) {
      return error.message ?? 'No se pudo iniciar sesión con Google.';
    }
    return 'No se pudo iniciar sesión con Google.';
  }
}

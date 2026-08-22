import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../data/admin_config.dart';
import '../data/firestore_paths.dart';
import '../models/user_role.dart';
import '../services/in_app_messaging.dart';
import '../services/push_notifications.dart';

class AuthProvider extends ChangeNotifier {
  User? user;
  UserRole role = UserRole.patient;
  bool roleReady = true;
  bool _captureAuth = false;
  bool _holdAuthUi = false;
  bool _localGuest = false;
  bool _booting = true;
  StreamSubscription<User?>? _subscription;

  bool get isReady => Firebase.apps.isNotEmpty;
  bool get isBooting => _booting;
  bool get isLoggedIn => user != null || _localGuest;
  bool get isDoctor => role == UserRole.doctor;
  bool get isClinic => role == UserRole.clinic;
  bool get isAdmin => role == UserRole.admin;
  bool get isGuest => _localGuest || user?.isAnonymous == true;
  bool get canBook =>
      isLoggedIn && !isGuest && !isDoctor && !isClinic && !isAdmin;
  String get email => user?.email ?? '';
  String get uid => user?.uid ?? '';

  String get displayName {
    if (_localGuest) {
      return 'Invitado';
    }
    final fromAuth = UserRole.visibleName(user?.displayName);
    if (fromAuth != 'Usuario') {
      return fromAuth;
    }
    final mail = user?.email;
    if (mail != null && mail.contains('@')) {
      return mail.split('@').first;
    }
    return 'Usuario';
  }

  void start() {
    unawaited(_bootstrap());
  }

  Future<void> _bootstrap() async {
    if (!isReady) {
      user = null;
      role = UserRole.patient;
      roleReady = true;
      _booting = false;
      notifyListeners();
      return;
    }

    try {
      await FirebaseAuth.instance.signOut();
    } catch (error) {
      debugPrint('No se pudo cerrar la sesión previa: $error');
    }

    if (!_localGuest) {
      user = null;
      role = UserRole.patient;
      _captureAuth = false;
    }
    roleReady = true;
    _booting = false;
    notifyListeners();

    _subscription ??= FirebaseAuth.instance.authStateChanges().listen((value) {
      if (!_captureAuth || _holdAuthUi) {
        return;
      }
      if (value == null) {
        if (_localGuest) {
          return;
        }
        user = null;
        role = UserRole.patient;
        roleReady = true;
        notifyListeners();
        return;
      }
      _localGuest = false;
      user = value;
      unawaited(_loadProfile(value));
    });
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    _ensureReady();
    _captureAuth = true;
    _localGuest = false;
    roleReady = false;
    notifyListeners();
    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _normalizeEmail(email),
        password: password,
      );
      _applyUser(credential.user);
      final signedIn = credential.user ?? FirebaseAuth.instance.currentUser;
      if (signedIn != null) {
        await _loadProfile(signedIn);
      } else {
        _captureAuth = false;
        roleReady = true;
        notifyListeners();
      }
    } catch (error) {
      _captureAuth = false;
      user = null;
      roleReady = true;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
    required UserRole role,
    Future<void> Function(String uid)? afterCreate,
  }) async {
    _ensureReady();
    _captureAuth = true;
    _holdAuthUi = true;
    _localGuest = false;
    roleReady = false;
    notifyListeners();
    try {
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: _normalizeEmail(email),
            password: password,
          );
      await credential.user?.updateDisplayName(role.encodeName(name));
      await credential.user?.reload();
      final signedIn = FirebaseAuth.instance.currentUser;
      this.role = role;
      if (signedIn == null) {
        _captureAuth = false;
        _holdAuthUi = false;
        roleReady = true;
        notifyListeners();
        return;
      }
      try {
        await _saveProfile(signedIn, role: role, name: name.trim());
      } catch (error) {
        debugPrint('No se pudo guardar el perfil en Firestore: $error');
      }
      if (afterCreate != null) {
        try {
          await afterCreate(signedIn.uid);
        } catch (error) {
          debugPrint('No se pudo publicar la tarjeta médica: $error');
        }
      }
      _holdAuthUi = false;
      _applyUser(signedIn);
      await _loadProfile(signedIn);
    } catch (error) {
      _captureAuth = false;
      _holdAuthUi = false;
      user = null;
      roleReady = true;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> signInAsGuest() async {
    _captureAuth = false;
    _localGuest = true;
    user = null;
    role = UserRole.patient;
    roleReady = true;
    notifyListeners();
    unawaited(InAppMessagingService.instance.setUserRole('guest'));
    unawaited(
      InAppMessagingService.instance.trigger('guest_session', once: true),
    );
  }

  Future<void> signInWithGoogle() async {
    _ensureReady();
    _captureAuth = true;
    _localGuest = false;
    roleReady = false;
    notifyListeners();
    try {
      final provider = GoogleAuthProvider()
        ..addScope('email')
        ..setCustomParameters({'prompt': 'select_account'});
      final current = FirebaseAuth.instance.currentUser;
      late final UserCredential credential;
      if (current != null && current.isAnonymous) {
        try {
          credential = await current.linkWithProvider(provider);
        } on FirebaseAuthException catch (error) {
          if (error.code == 'credential-already-in-use' ||
              error.code == 'account-exists-with-different-credential' ||
              error.code == 'provider-already-linked') {
            credential = await FirebaseAuth.instance.signInWithProvider(
              provider,
            );
          } else {
            rethrow;
          }
        }
      } else {
        credential = await FirebaseAuth.instance.signInWithProvider(provider);
      }
      final signedIn = credential.user ?? FirebaseAuth.instance.currentUser;
      if (signedIn == null) {
        _captureAuth = false;
        roleReady = true;
        notifyListeners();
        return;
      }
      if (isAdminEmail(signedIn.email)) {
        role = UserRole.admin;
        final name = UserRole.visibleName(
          signedIn.displayName?.trim().isNotEmpty == true
              ? signedIn.displayName
              : signedIn.email,
        );
        try {
          await signedIn.updateDisplayName(UserRole.admin.encodeName(name));
          await signedIn.reload();
        } catch (error) {
          debugPrint('No se pudo actualizar el nombre de admin: $error');
        }
        await _loadProfile(FirebaseAuth.instance.currentUser ?? signedIn);
        return;
      }
      role = UserRole.patient;
      final name = UserRole.visibleName(
        signedIn.displayName?.trim().isNotEmpty == true
            ? signedIn.displayName
            : signedIn.email,
      );
      try {
        if (UserRole.fromDisplayName(signedIn.displayName) != UserRole.doctor &&
            UserRole.fromDisplayName(signedIn.displayName) != UserRole.clinic) {
          await signedIn.updateDisplayName(UserRole.patient.encodeName(name));
          await signedIn.reload();
        }
      } catch (error) {
        debugPrint('No se pudo actualizar el nombre de Google: $error');
      }
      await _loadProfile(FirebaseAuth.instance.currentUser ?? signedIn);
    } catch (error) {
      _captureAuth = false;
      roleReady = true;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> sendPasswordReset(String email) async {
    _ensureReady();
    await FirebaseAuth.instance.sendPasswordResetEmail(
      email: _normalizeEmail(email),
    );
  }

  Future<void> signOut() async {
    _captureAuth = false;
    _localGuest = false;
    await PushNotifications.instance.unbind();
    if (!isReady) {
      user = null;
      role = UserRole.patient;
      roleReady = true;
      notifyListeners();
      return;
    }
    await FirebaseAuth.instance.signOut();
    user = null;
    role = UserRole.patient;
    roleReady = true;
    notifyListeners();
  }

  String messageFor(Object error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'invalid-email':
          return 'El correo no es válido.';
        case 'user-disabled':
          return 'Esta cuenta está deshabilitada.';
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
        case 'INVALID_LOGIN_CREDENTIALS':
          return 'Correo o contraseña incorrectos. Si creaste el usuario en Firebase Console, restablece la contraseña.';
        case 'email-already-in-use':
          return 'Ese correo ya tiene cuenta. Inicia sesión o restablece la contraseña.';
        case 'weak-password':
          return 'La contraseña debe tener al menos 6 caracteres.';
        case 'network-request-failed':
          return 'Sin conexión. Revisa tu internet.';
        case 'too-many-requests':
          return 'Demasiados intentos. Espera un momento.';
        case 'operation-not-allowed':
          return 'Este método de acceso no está activado en Firebase Authentication.';
        case 'admin-restricted-operation':
          return 'Firebase no permite crear esta sesión. Usa Google o una cuenta de médico.';
        case 'account-exists-with-different-credential':
        case 'credential-already-in-use':
          return 'Ese correo de Google ya tiene cuenta. Inicia sesión con Google.';
        case 'canceled':
        case 'web-context-canceled':
        case 'popup-closed-by-user':
          return 'Cancelaste el acceso con Google.';
        case 'unknown':
        case 'unknown-error':
          return 'Firebase no pudo autenticar. Prueba en un emulador o celular Android, no en Windows.';
        default:
          return error.message ??
              'No se pudo completar la autenticación (${error.code}).';
      }
    }
    if (error is FirebaseException) {
      if (error.code == 'permission-denied' || error.code == 'unauthorized') {
        return 'Firebase rechazó el acceso. Activa Firestore y Storage, y publica las reglas.';
      }
      if (error.code == 'unavailable') {
        return 'No se pudo conectar a Firestore. Activa la base de datos en Firebase Console.';
      }
      return error.message ?? 'Error de Firestore (${error.code}).';
    }
    if (error is StateError) {
      return error.message;
    }
    return 'No se pudo completar la autenticación.';
  }

  Future<void> _loadProfile(User signedIn) async {
    if (isAdminEmail(signedIn.email)) {
      role = UserRole.admin;
    } else {
      role = UserRole.fromDisplayName(signedIn.displayName);
    }
    try {
      final doc = await FirebaseFirestore.instance
          .collection(FirestorePaths.users)
          .doc(signedIn.uid)
          .get();
      if (!isAdminEmail(signedIn.email) && doc.exists) {
        role = UserRole.fromId(doc.data()?['role']);
      }
      if (!signedIn.isAnonymous) {
        await _saveProfile(
          signedIn,
          role: role,
          name: UserRole.visibleName(signedIn.displayName),
        );
      }
    } catch (error) {
      debugPrint('No se pudo leer el perfil: $error');
    }
    user = signedIn;
    roleReady = true;
    notifyListeners();
    unawaited(
      PushNotifications.instance.bind(uid: signedIn.uid, role: role),
    );
    unawaited(InAppMessagingService.instance.setUserRole(role.id));
    unawaited(
      InAppMessagingService.instance.trigger('login_success', once: true),
    );
  }

  Future<void> _saveProfile(
    User signedIn, {
    required UserRole role,
    required String name,
  }) async {
    await FirebaseFirestore.instance
        .collection(FirestorePaths.users)
        .doc(signedIn.uid)
        .set({
          'role': role.id,
          'name': name,
          'email': signedIn.email ?? '',
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
  }

  void _applyUser(User? value) {
    user = value ?? FirebaseAuth.instance.currentUser;
    if (user != null) {
      _localGuest = false;
    }
    notifyListeners();
  }

  String _normalizeEmail(String email) => email.trim().toLowerCase();

  void _ensureReady() {
    if (!isReady) {
      throw StateError(
        'Firebase no está inicializado. Ejecuta la app en un emulador o celular Android (reinicio completo, no hot reload).',
      );
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

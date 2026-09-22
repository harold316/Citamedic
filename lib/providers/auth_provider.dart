import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../data/admin_config.dart';
import '../data/firestore_paths.dart';
import '../models/user_role.dart';
import '../services/firebase_economy.dart';
import '../services/google_auth.dart';
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
    final phone = user?.phoneNumber;
    if (phone != null && phone.isNotEmpty) {
      return phone;
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
  }

  Future<void> signInWithGoogle({
    UserRole intendedRole = UserRole.patient,
    String? displayName,
    Future<void> Function(String uid)? afterCreate,
    bool forceWeb = false,
  }) async {
    _ensureReady();
    _captureAuth = true;
    _localGuest = false;
    roleReady = false;
    notifyListeners();
    try {
      final credential = await GoogleAuthService.instance.signIn(
        anonymous: FirebaseAuth.instance.currentUser,
        forceWeb: forceWeb,
      );
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

      final existingRole = await _existingRoleFor(signedIn);
      if (intendedRole == UserRole.doctor) {
        if (existingRole == UserRole.patient ||
            existingRole == UserRole.clinic) {
          await GoogleAuthService.instance.signOut();
          await FirebaseAuth.instance.signOut();
          throw StateError(
            existingRole == UserRole.clinic
                ? 'Esa cuenta de Google ya está registrada como clínica.'
                : 'Esa cuenta de Google ya está registrada como paciente. Inicia sesión o usa otro correo.',
          );
        }
        role = UserRole.doctor;
        final name = (displayName?.trim().isNotEmpty == true
                ? displayName!.trim()
                : UserRole.visibleName(
                    signedIn.displayName?.trim().isNotEmpty == true
                        ? signedIn.displayName
                        : signedIn.email,
                  ));
        try {
          await signedIn.updateDisplayName(UserRole.doctor.encodeName(name));
          await signedIn.reload();
        } catch (error) {
          debugPrint('No se pudo actualizar el nombre de Google: $error');
        }
        final current = FirebaseAuth.instance.currentUser ?? signedIn;
        try {
          await _saveProfile(current, role: UserRole.doctor, name: name);
        } catch (error) {
          debugPrint('No se pudo guardar el perfil en Firestore: $error');
        }
        if (afterCreate != null && existingRole != UserRole.doctor) {
          try {
            await afterCreate(current.uid);
          } catch (error) {
            debugPrint('No se pudo publicar la tarjeta médica: $error');
          }
        }
        await _loadProfile(current);
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
    } on GoogleSignInCanceled {
      _captureAuth = false;
      roleReady = true;
      notifyListeners();
      rethrow;
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
    await GoogleAuthService.instance.signOut();
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

  Future<void> deleteOwnAccount() async {
    final signedIn = FirebaseAuth.instance.currentUser;
    if (signedIn == null || signedIn.isAnonymous) {
      throw StateError('Debes iniciar sesión para eliminar tu cuenta.');
    }
    if (isAdminEmail(signedIn.email)) {
      throw StateError('La cuenta de administrador no se puede eliminar aquí.');
    }
    final uid = signedIn.uid;
    var removedAuth = false;
    try {
      await FirebaseFunctions.instanceFor(region: 'us-central1')
          .httpsCallable('deleteOwnAccount')
          .call();
      removedAuth = true;
    } catch (error) {
      debugPrint('No se pudo borrar la cuenta por Functions: $error');
    }

    if (!removedAuth) {
      await _deleteOwnFirestoreData(uid);
      try {
        await signedIn.delete();
        removedAuth = true;
      } on FirebaseAuthException catch (error) {
        if (error.code == 'requires-recent-login') {
          throw StateError(
            'Por seguridad, cierra sesión, vuelve a entrar y elimina la cuenta de nuevo.',
          );
        }
        throw StateError(
          error.message ?? 'No se pudo eliminar la cuenta de acceso.',
        );
      }
    }

    _captureAuth = false;
    _localGuest = false;
    await PushNotifications.instance.unbind();
    await GoogleAuthService.instance.signOut();
    try {
      if (FirebaseAuth.instance.currentUser != null) {
        await FirebaseAuth.instance.signOut();
      }
    } catch (error) {
      debugPrint('Sesión ya cerrada al borrar la cuenta: $error');
    }
    user = null;
    role = UserRole.patient;
    roleReady = true;
    notifyListeners();
  }

  Future<void> _deleteOwnFirestoreData(String uid) async {
    final db = FirebaseFirestore.instance;
    for (final path in [
      FirestorePaths.doctors,
      FirestorePaths.clinics,
      FirestorePaths.users,
    ]) {
      try {
        await db.collection(path).doc(uid).delete();
      } catch (_) {}
    }
    try {
      final asPatient = await db
          .collection(FirestorePaths.appointments)
          .where('patientId', isEqualTo: uid)
          .get();
      final asDoctor = await db
          .collection(FirestorePaths.appointments)
          .where('doctorId', isEqualTo: uid)
          .get();
      for (final doc in [...asPatient.docs, ...asDoctor.docs]) {
        await doc.reference.delete();
      }
    } catch (error) {
      debugPrint('No se pudieron borrar las citas de $uid: $error');
    }
  }

  String messageFor(Object error) {
    if (error is GoogleSignInCanceled) {
      return 'Cancelaste el acceso con Google.';
    }
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
        case 'requires-recent-login':
          return 'Por seguridad, cierra sesión, vuelve a entrar y elimina la cuenta de nuevo.';
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

  Future<UserRole?> _existingRoleFor(User signedIn) async {
    final fromName = UserRole.fromDisplayName(signedIn.displayName);
    if (fromName == UserRole.doctor || fromName == UserRole.clinic) {
      return fromName;
    }
    try {
      final doc = await FirebaseEconomy.getDocument(
        FirebaseFirestore.instance
            .collection(FirestorePaths.users)
            .doc(signedIn.uid),
        preferCache: false,
      );
      if (!doc.exists) {
        return null;
      }
      return UserRole.fromId(doc.data()?['role']);
    } catch (error) {
      debugPrint('No se pudo leer el rol existente: $error');
      return fromName == UserRole.patient ? null : fromName;
    }
  }

  Future<void> _loadProfile(User signedIn) async {
    if (isAdminEmail(signedIn.email)) {
      role = UserRole.admin;
    } else {
      role = UserRole.fromDisplayName(signedIn.displayName);
    }
    try {
      final doc = await FirebaseEconomy.getDocument(
        FirebaseFirestore.instance
            .collection(FirestorePaths.users)
            .doc(signedIn.uid),
        preferCache: false,
      );
      if (!isAdminEmail(signedIn.email) && doc.exists) {
        role = UserRole.fromId(doc.data()?['role']);
      }
      if (!signedIn.isAnonymous) {
        final name = UserRole.visibleName(signedIn.displayName);
        final data = doc.data();
        final unchanged = doc.exists &&
            data?['role'] == role.id &&
            data?['name'] == name &&
            data?['email'] == (signedIn.email ?? '') &&
            data?['phone'] == (signedIn.phoneNumber ?? '');
        if (!unchanged) {
          await _saveProfile(signedIn, role: role, name: name);
        }
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
          'phone': signedIn.phoneNumber ?? '',
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

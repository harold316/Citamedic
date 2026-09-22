import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../data/firestore_paths.dart';
import '../firebase_options.dart';
import '../models/user_role.dart';
import '../providers/shell_tab_provider.dart';

const _channelId = 'citamedic_alerts';
const _channelName = 'Avisos CitaMedic';
const _channelDescription = 'Citas, perfiles y avisos de CitaMedic';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
}

class PushNotifications {
  PushNotifications._();
  static final instance = PushNotifications._();

  final _plugin = FlutterLocalNotificationsPlugin();
  StreamSubscription<String>? _tokenSub;
  StreamSubscription<RemoteMessage>? _foregroundSub;
  StreamSubscription<RemoteMessage>? _openedSub;
  String? _uid;
  String? _boundTopic;
  String? _savedToken;
  String? pendingType;
  Future<void>? _permissionRequest;
  Future<void>? _bindRequest;
  ShellTabProvider? _tabs;
  void Function(String title, String body, String? type)? onInboxMessage;
  final tokenListenable = ValueNotifier<String?>(null);
  final statusListenable = ValueNotifier<String>(
    'Obteniendo token de Firebase Messaging...',
  );

  String? get token => tokenListenable.value;

  bool get _supported {
    if (kIsWeb) {
      return false;
    }
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  String get _unsupportedReason {
    if (kIsWeb) {
      return 'Firebase Messaging no está configurado para web en esta app.';
    }
    if (defaultTargetPlatform == TargetPlatform.windows) {
      return 'FCM no genera token en Windows. Ejecuta la app en el emulador o un celular Android.';
    }
    return 'Esta plataforma no admite Firebase Cloud Messaging.';
  }

  void attachTabs(ShellTabProvider tabs) {
    _tabs = tabs;
  }

  Future<void> start() async {
    if (Firebase.apps.isEmpty) {
      statusListenable.value = 'Firebase no está inicializado.';
      return;
    }
    if (!_supported) {
      statusListenable.value = _unsupportedReason;
      return;
    }
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwin = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      settings: const InitializationSettings(android: android, iOS: darwin),
      onDidReceiveNotificationResponse: (response) {
        _handlePayload(response.payload);
      },
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            _channelId,
            _channelName,
            description: _channelDescription,
            importance: Importance.high,
          ),
        );
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );
    _foregroundSub ??= FirebaseMessaging.onMessage.listen(_onForeground);
    _openedSub ??= FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _handlePayload(_payloadFrom(message));
    });
    final launch = await FirebaseMessaging.instance.getInitialMessage();
    if (launch != null) {
      pendingType = launch.data['type'];
    }
    _tokenSub ??= FirebaseMessaging.instance.onTokenRefresh.listen(_saveToken);
  }

  Future<void> refreshToken() async {
    if (!_supported || Firebase.apps.isEmpty) {
      statusListenable.value = Firebase.apps.isEmpty
          ? 'Firebase no está inicializado.'
          : _unsupportedReason;
      return;
    }
    statusListenable.value = 'Obteniendo token de Firebase Messaging...';
    try {
      final token = await FirebaseMessaging.instance.getToken().timeout(
        const Duration(seconds: 20),
      );
      await _saveToken(token);
      if (token == null || token.isEmpty) {
        statusListenable.value =
            'Aún no hay token. Acepta las notificaciones y pulsa actualizar.';
      }
    } catch (error) {
      statusListenable.value = 'No se pudo leer el token FCM: $error';
      debugPrint('No se pudo leer el token FCM: $error');
    }
  }

  Future<void> bind({required String uid, required UserRole role}) async {
    if (!_supported || uid.isEmpty || Firebase.apps.isEmpty) {
      return;
    }
    final previous = _bindRequest;
    final current = () async {
      if (previous != null) {
        try {
          await previous;
        } catch (_) {}
      }
      await _bindInternal(uid: uid, role: role);
    }();
    _bindRequest = current;
    await current;
  }

  Future<void> _bindInternal({
    required String uid,
    required UserRole role,
  }) async {
    await _requestPermission();
    _uid = uid;
    final messaging = FirebaseMessaging.instance;
    if (_boundTopic != null && _boundTopic != 'user_$uid') {
      try {
        await messaging.unsubscribeFromTopic(_boundTopic!);
      } catch (error) {
        debugPrint('No se pudo salir del topic anterior: $error');
      }
    }
    _boundTopic = 'user_$uid';
    try {
      await messaging.subscribeToTopic(_boundTopic!);
      if (role == UserRole.admin) {
        await messaging.subscribeToTopic('admins');
      } else {
        await messaging.unsubscribeFromTopic('admins');
      }
      if (role == UserRole.doctor) {
        await messaging.subscribeToTopic('doctors');
      } else if (role == UserRole.clinic) {
        await messaging.subscribeToTopic('clinics');
      }
    } catch (error) {
      debugPrint('No se pudo suscribir a FCM: $error');
    }
    await refreshToken();
    _tokenSub?.cancel();
    _tokenSub = messaging.onTokenRefresh.listen(_saveToken);
  }

  Future<void> unbind() async {
    _tokenSub?.cancel();
    _tokenSub = null;
    if (!_supported || Firebase.apps.isEmpty) {
      _uid = null;
      tokenListenable.value = null;
      return;
    }
    final uid = _uid;
    _uid = null;
    tokenListenable.value = null;
    try {
      if (_boundTopic != null) {
        await FirebaseMessaging.instance.unsubscribeFromTopic(_boundTopic!);
      }
      await FirebaseMessaging.instance.unsubscribeFromTopic('admins');
      await FirebaseMessaging.instance.unsubscribeFromTopic('doctors');
      await FirebaseMessaging.instance.unsubscribeFromTopic('clinics');
    } catch (error) {
      debugPrint('No se pudo cancelar topics FCM: $error');
    }
    _boundTopic = null;
    if (uid == null || uid.isEmpty) {
      return;
    }
    _savedToken = null;
  }

  void consumeLaunch(ShellTabProvider tabs) {
    attachTabs(tabs);
    final type = pendingType;
    pendingType = null;
    if (type == 'appointment') {
      tabs.goTo(3);
    }
  }

  Future<void> showLocal({
    required String title,
    required String body,
    String? payload,
    int? id,
  }) async {
    onInboxMessage?.call(title, body, payload);
    if (!_supported) {
      return;
    }
    await _plugin.show(
      id: id ?? DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title: title,
      body: body,
      payload: payload,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }

  Future<void> _onForeground(RemoteMessage message) async {
    final title =
        message.notification?.title ??
        message.data['title'] ??
        'CitaMedic';
    final body =
        message.notification?.body ?? message.data['body'] ?? '';
    if (title.toString().trim().isEmpty && body.toString().trim().isEmpty) {
      return;
    }
    await showLocal(
      title: title.toString(),
      body: body.toString(),
      payload: _payloadFrom(message),
      id: (message.data['id'] ?? message.messageId ?? title).hashCode,
    );
  }

  Future<void> _requestPermission() async {
    final pending = _permissionRequest;
    if (pending != null) {
      await pending;
      return;
    }
    final request = _requestPermissionOnce();
    _permissionRequest = request;
    try {
      await request;
    } finally {
      if (identical(_permissionRequest, request)) {
        _permissionRequest = null;
      }
    }
  }

  Future<void> _requestPermissionOnce() async {
    final messaging = FirebaseMessaging.instance;
    try {
      final current = await messaging.getNotificationSettings();
      if (current.authorizationStatus == AuthorizationStatus.notDetermined) {
        await messaging.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );
      }
    } on FirebaseException catch (error) {
      if (!_isPermissionBusy(error)) {
        debugPrint('No se pudo pedir permiso FCM: $error');
      }
    } catch (error) {
      debugPrint('No se pudo pedir permiso FCM: $error');
    }
    try {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      final granted = await android?.areNotificationsEnabled();
      if (granted != true) {
        await android?.requestNotificationsPermission();
      }
    } catch (error) {
      if (!_isPermissionBusy(error)) {
        debugPrint('No se pudo pedir permiso local: $error');
      }
    }
  }

  bool _isPermissionBusy(Object error) {
    final text = error.toString().toLowerCase();
    return text.contains('already running') ||
        text.contains('please wait for it to finish');
  }

  Future<void> _saveToken(String? token) async {
    tokenListenable.value = token;
    if (token != null && token.isNotEmpty) {
      statusListenable.value = 'Token listo para Firebase Cloud Messaging.';
    }
    debugPrint('FCM token: $token');
    final uid = _uid;
    if (token == null || uid == null || uid.isEmpty || token == _savedToken) {
      return;
    }
    try {
      await FirebaseFirestore.instance
          .collection(FirestorePaths.users)
          .doc(uid)
          .set({
            'fcmToken': token,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
      _savedToken = token;
    } catch (error) {
      debugPrint('No se pudo guardar el token FCM: $error');
    }
  }

  String? _payloadFrom(RemoteMessage message) {
    final type = message.data['type'];
    if (type == null || type.isEmpty) {
      return null;
    }
    return type;
  }

  void _handlePayload(String? payload) {
    if (payload == null || payload.isEmpty) {
      return;
    }
    pendingType = payload;
    if (payload == 'appointment') {
      _tabs?.goTo(3);
    }
  }
}

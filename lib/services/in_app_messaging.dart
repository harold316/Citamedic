import 'dart:async';

import 'package:firebase_app_installations/firebase_app_installations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_in_app_messaging/firebase_in_app_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

class InAppMessagingService with WidgetsBindingObserver {
  InAppMessagingService._();
  static final instance = InAppMessagingService._();

  final installationId = ValueNotifier<String?>(null);
  final Set<String> _triggered = {};
  bool _observing = false;

  bool get _supported {
    if (kIsWeb) {
      return false;
    }
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  Future<void> start() async {
    if (!_supported || Firebase.apps.isEmpty) {
      return;
    }
    if (!_observing) {
      WidgetsBinding.instance.addObserver(this);
      _observing = true;
    }
    unawaited(_enable());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(trigger('on_foreground'));
      unawaited(
        Future<void>.delayed(const Duration(seconds: 4), () {
          return trigger('on_foreground');
        }),
      );
    }
  }

  Future<void> _enable() async {
    try {
      await FirebaseInAppMessaging.instance.setAutomaticDataCollectionEnabled(
        true,
      );
      await FirebaseInAppMessaging.instance.setMessagesSuppressed(false);
      final id = await FirebaseInstallations.instance.getId().timeout(
        const Duration(seconds: 15),
      );
      installationId.value = id;
      debugPrint('FIAM Installation ID: $id');
      await _triggerAfterFetch();
    } catch (error) {
      debugPrint('No se pudo iniciar In-App Messaging: $error');
    }
  }

  Future<void> _triggerAfterFetch() async {
    for (final delay in [
      const Duration(seconds: 6),
      const Duration(seconds: 12),
    ]) {
      await Future<void>.delayed(delay);
      await trigger('on_foreground');
      await trigger('app_open');
    }
  }

  Future<void> trigger(String eventName, {bool once = false}) async {
    if (!_supported || Firebase.apps.isEmpty) {
      return;
    }
    if (once && !_triggered.add(eventName)) {
      return;
    }
    try {
      await FirebaseInAppMessaging.instance.triggerEvent(eventName);
      debugPrint('FIAM evento: $eventName');
    } catch (error) {
      debugPrint('No se pudo disparar el evento $eventName: $error');
    }
  }

  Future<void> setUserRole(String role) async {
    if (!_supported || Firebase.apps.isEmpty || role.isEmpty) {
      return;
    }
  }
}

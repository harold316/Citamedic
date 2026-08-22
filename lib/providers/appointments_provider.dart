import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';

import '../data/firestore_paths.dart';
import '../models/appointment.dart';
import '../services/push_notifications.dart';

class AppointmentsProvider extends ChangeNotifier {
  final List<Appointment> _appointments = [];
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _subscription;
  String? _watchingUid;
  bool? _watchingAsDoctor;
  bool _watchingAll = false;
  bool _hydrated = false;

  List<Appointment> get appointments {
    final items = [..._appointments];
    items.sort((a, b) => a.dateTime.compareTo(b.dateTime));
    return List.unmodifiable(items);
  }

  List<Appointment> get upcoming {
    final now = DateTime.now();
    return appointments
        .where((item) => !item.dateTime.isBefore(now))
        .toList();
  }

  void watch({required String uid, required bool asDoctor}) {
    if (uid.isEmpty || Firebase.apps.isEmpty) {
      stop();
      return;
    }
    if (!_watchingAll &&
        _watchingUid == uid &&
        _watchingAsDoctor == asDoctor) {
      return;
    }
    _watchingUid = uid;
    _watchingAsDoctor = asDoctor;
    _watchingAll = false;
    _hydrated = false;
    _subscription?.cancel();
    _subscription = FirebaseFirestore.instance
        .collection(FirestorePaths.appointments)
        .where(asDoctor ? 'doctorId' : 'patientId', isEqualTo: uid)
        .snapshots()
        .listen(
          (snapshot) {
            if (asDoctor) {
              _notifyNewAppointments(snapshot);
            }
            _appointments
              ..clear()
              ..addAll(
                snapshot.docs.map(
                  (doc) => Appointment.fromMap(doc.id, doc.data()),
                ),
              );
            notifyListeners();
          },
          onError: (error) {
            debugPrint('No se pudieron leer las citas: $error');
          },
        );
  }

  void watchAll() {
    if (Firebase.apps.isEmpty) {
      stop();
      return;
    }
    if (_watchingAll) {
      return;
    }
    _watchingAll = true;
    _watchingUid = null;
    _watchingAsDoctor = null;
    _subscription?.cancel();
    _subscription = FirebaseFirestore.instance
        .collection(FirestorePaths.appointments)
        .snapshots()
        .listen(
          (snapshot) {
            _appointments
              ..clear()
              ..addAll(
                snapshot.docs.map(
                  (doc) => Appointment.fromMap(doc.id, doc.data()),
                ),
              );
            notifyListeners();
          },
          onError: (error) {
            debugPrint('No se pudieron leer todas las citas: $error');
          },
        );
  }

  void stop() {
    _subscription?.cancel();
    _subscription = null;
    _watchingUid = null;
    _watchingAsDoctor = null;
    _watchingAll = false;
    _hydrated = false;
    _appointments.clear();
    notifyListeners();
  }

  void _notifyNewAppointments(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    if (!_hydrated) {
      _hydrated = true;
      return;
    }
    if (WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed) {
      return;
    }
    for (final change in snapshot.docChanges) {
      if (change.type != DocumentChangeType.added || change.doc.data() == null) {
        continue;
      }
      final appointment = Appointment.fromMap(
        change.doc.id,
        change.doc.data()!,
      );
      unawaited(
        PushNotifications.instance.showLocal(
          title: 'Nueva cita en CitaMedic',
          body: '${appointment.patientName} agendó ${appointment.serviceName}.',
          payload: 'appointment',
          id: appointment.id.hashCode,
        ),
      );
    }
  }

  Future<void> confirm(Appointment appointment) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.isAnonymous) {
      throw Exception('Los invitados no pueden agendar citas.');
    }
    _appointments.removeWhere((item) => item.id == appointment.id);
    _appointments.insert(0, appointment);
    notifyListeners();
    if (Firebase.apps.isEmpty) {
      return;
    }
    await FirebaseFirestore.instance
        .collection(FirestorePaths.appointments)
        .doc(appointment.id)
        .set(appointment.toMap());
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

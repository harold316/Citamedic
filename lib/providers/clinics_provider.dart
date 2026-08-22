import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../data/admin_config.dart';
import '../data/firestore_paths.dart';
import '../data/mock_data.dart';
import '../models/clinic.dart';
import '../models/clinic_photo_draft.dart';
import '../models/doctor_review_status.dart';
import '../models/user_location.dart';
import '../services/storage_upload.dart';

class ClinicsProvider extends ChangeNotifier {
  final List<Clinic> _catalog = List.of(mockClinics);
  List<Clinic> _registered = const [];
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _subscription;
  Clinic? registrationDraft;
  List<ClinicPhotoDraft> registrationPhotos = const [];

  List<Clinic> get publishedRegistered =>
      _registered.where((clinic) => clinic.published).toList();

  List<Clinic> get registeredClinics => List.unmodifiable(_registered);

  List<Clinic> get clinics {
    final publishedIds = publishedRegistered.map((clinic) => clinic.id).toSet();
    final publishedNames = publishedRegistered
        .map((clinic) => clinic.name.trim().toLowerCase())
        .toSet();
    return [
      ...publishedRegistered,
      ..._catalog.where(
        (clinic) =>
            !publishedIds.contains(clinic.id) &&
            !publishedNames.contains(clinic.name.trim().toLowerCase()),
      ),
    ];
  }

  void rememberRegistration({
    required Clinic profile,
    List<ClinicPhotoDraft>? photos,
  }) {
    registrationDraft = profile;
    if (photos != null) {
      registrationPhotos = List.of(photos);
    }
    notifyListeners();
  }

  void forgetRegistration() {
    if (registrationDraft == null && registrationPhotos.isEmpty) {
      return;
    }
    registrationDraft = null;
    registrationPhotos = const [];
    notifyListeners();
  }

  void start() {
    if (Firebase.apps.isEmpty) {
      return;
    }
    _subscription ??= FirebaseFirestore.instance
        .collection(FirestorePaths.clinics)
        .snapshots()
        .listen(
          (snapshot) {
            _registered = snapshot.docs
                .map((doc) => Clinic.fromMap(doc.id, doc.data()))
                .toList();
            notifyListeners();
          },
          onError: (error) {
            debugPrint('No se pudieron leer clínicas: $error');
          },
        );
  }

  Future<Clinic?> loadProfile(String uid) async {
    if (Firebase.apps.isEmpty || uid.isEmpty) {
      return null;
    }
    try {
      final doc = await FirebaseFirestore.instance
          .collection(FirestorePaths.clinics)
          .doc(uid)
          .get()
          .timeout(const Duration(seconds: 8));
      if (!doc.exists || doc.data() == null) {
        return null;
      }
      return Clinic.fromMap(doc.id, doc.data()!);
    } catch (error) {
      debugPrint('No se pudo cargar la clínica: $error');
      return null;
    }
  }

  Future<void> saveProfile(Clinic clinic) async {
    _ensureCanEdit(clinic.id);
    if (Firebase.apps.isEmpty) {
      throw StateError('Firebase no está inicializado.');
    }
    _registered = [
      clinic,
      ..._registered.where((item) => item.id != clinic.id),
    ];
    notifyListeners();
    try {
      await FirebaseFirestore.instance
          .collection(FirestorePaths.clinics)
          .doc(clinic.id)
          .set(clinic.toMap(), SetOptions(merge: true));
    } catch (error) {
      debugPrint('No se pudo guardar la clínica en Firestore: $error');
      rethrow;
    }
  }

  Future<String> uploadImage({
    required String uid,
    required String name,
    required XFile file,
  }) async {
    _ensureCanEdit(uid);
    if (Firebase.apps.isEmpty) {
      throw StateError('Firebase no está inicializado.');
    }
    final bytes = await file.readAsBytes();
    return StorageUpload.jpeg(
      path: 'clinics/$uid/$name.jpg',
      bytes: bytes,
    );
  }

  List<Clinic> nearby(UserLocation? location) {
    final all = clinics;
    if (location == null) {
      return all;
    }
    final exact = all
        .where((clinic) => clinic.matchesLocation(location))
        .toList();
    if (exact.isNotEmpty) {
      return exact;
    }
    final sameProvince = all
        .where(
          (clinic) =>
              clinic.country == location.country &&
              clinic.region == location.department &&
              clinic.provinceName == location.province,
        )
        .toList();
    if (sameProvince.isNotEmpty) {
      return sameProvince;
    }
    return all
        .where(
          (clinic) =>
              clinic.country == location.country &&
              clinic.region == location.department,
        )
        .toList();
  }

  Future<void> updateGpsLocation({
    required String clinicId,
    required String address,
    String? city,
    double? latitude,
    double? longitude,
  }) async {
    _ensureCanEdit(clinicId);
    final index = _registered.indexWhere((clinic) => clinic.id == clinicId);
    if (index >= 0) {
      _registered[index] = _registered[index].copyWith(
        address: address,
        city: city,
        latitude: latitude,
        longitude: longitude,
      );
    }
    notifyListeners();
    try {
      await FirebaseFirestore.instance
          .collection(FirestorePaths.clinics)
          .doc(clinicId)
          .set({
            'address': address,
            'city': city,
            'latitude': latitude,
            'longitude': longitude,
          }, SetOptions(merge: true));
    } catch (error) {
      debugPrint('No se pudo guardar el GPS de la clínica: $error');
      rethrow;
    }
  }

  Future<void> approveClinic(
    Clinic clinic, {
    required String adminEmail,
  }) async {
    await saveProfile(
      clinic.copyWith(
        published: true,
        reviewStatus: DoctorReviewStatus.approved,
        reviewedAt: DateTime.now(),
        reviewedBy: adminEmail,
        clearRejection: true,
      ),
    );
  }

  Future<void> rejectClinic(
    Clinic clinic, {
    required String reason,
    required String adminEmail,
  }) async {
    final trimmed = reason.trim();
    if (trimmed.isEmpty) {
      throw StateError('Escribe el motivo del rechazo.');
    }
    await saveProfile(
      clinic.copyWith(
        published: false,
        reviewStatus: DoctorReviewStatus.rejected,
        rejectionReason: trimmed,
        reviewedAt: DateTime.now(),
        reviewedBy: adminEmail,
      ),
    );
  }

  void _ensureCanEdit(String clinicId) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError(
        'Solo la clínica dueña de este perfil puede cambiar estos datos.',
      );
    }
    if (isAdminEmail(user.email) || user.uid == clinicId) {
      return;
    }
    throw StateError(
      'Solo la clínica dueña de este perfil puede cambiar estos datos.',
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

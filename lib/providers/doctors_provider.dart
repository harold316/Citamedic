import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../data/admin_config.dart';
import '../data/firestore_paths.dart';
import '../data/mock_data.dart';
import '../models/doctor.dart';
import '../models/doctor_review_status.dart';
import '../models/medical_service.dart';
import '../models/user_location.dart';
import '../services/firebase_economy.dart';
import '../services/storage_upload.dart';

class DoctorsProvider extends ChangeNotifier {
  final List<Doctor> _catalog = List.of(mockDoctors);
  List<Doctor> _registered = const [];
  final Set<String> _favoriteIds = {};
  String _query = '';
  String? _specialtyFilter;
  String? _departmentFilter;
  String? _provinceFilter;
  DateTime? _fetchedAt;
  bool _includeUnpublished = false;
  Future<void>? _refreshing;

  List<Doctor> get publishedRegistered =>
      _registered.where((doctor) => doctor.published).toList();

  List<Doctor> get doctors {
    final publishedIds = publishedRegistered.map((doctor) => doctor.id).toSet();
    return [
      ...publishedRegistered,
      ..._catalog.where((doctor) => !publishedIds.contains(doctor.id)),
    ];
  }

  String get query => _query;
  String? get specialtyFilter => _specialtyFilter;
  String? get departmentFilter => _departmentFilter;
  String? get provinceFilter => _provinceFilter;
  List<Doctor> get registeredDoctors => List.unmodifiable(_registered);
  Doctor? registrationDraft;
  Uint8List? registrationPhotoBytes;
  XFile? registrationPhotoFile;

  void rememberRegistration({
    required Doctor profile,
    Uint8List? photoBytes,
    XFile? photoFile,
  }) {
    registrationDraft = profile;
    if (photoBytes != null) {
      registrationPhotoBytes = photoBytes;
    }
    if (photoFile != null) {
      registrationPhotoFile = photoFile;
    }
    notifyListeners();
  }

  void forgetRegistration() {
    if (registrationDraft == null &&
        registrationPhotoBytes == null &&
        registrationPhotoFile == null) {
      return;
    }
    registrationDraft = null;
    registrationPhotoBytes = null;
    registrationPhotoFile = null;
    notifyListeners();
  }

  Future<void> refreshIfNeeded({
    bool includeUnpublished = false,
    bool force = false,
    String? alsoUid,
  }) {
    final missingOwn =
        alsoUid != null &&
        alsoUid.isNotEmpty &&
        !_registered.any((doctor) => doctor.id == alsoUid);
    final stale =
        _fetchedAt == null ||
        DateTime.now().difference(_fetchedAt!) > FirebaseEconomy.catalogTtl;
    final needsScope = includeUnpublished && !_includeUnpublished;
    if (!force &&
        !stale &&
        !needsScope &&
        !missingOwn &&
        _registered.isNotEmpty) {
      return Future.value();
    }
    return refresh(
      includeUnpublished: includeUnpublished || _includeUnpublished,
      alsoUid: alsoUid,
      force: force,
    );
  }

  Future<void> refresh({
    bool includeUnpublished = false,
    String? alsoUid,
    bool force = false,
  }) {
    return _refreshing ??= _loadCatalog(
      includeUnpublished: includeUnpublished,
      alsoUid: alsoUid,
      force: force,
    ).whenComplete(() => _refreshing = null);
  }

  Future<void> _loadCatalog({
    required bool includeUnpublished,
    String? alsoUid,
    required bool force,
  }) async {
    if (Firebase.apps.isEmpty) {
      return;
    }
    try {
      Query<Map<String, dynamic>> query = FirebaseFirestore.instance
          .collection(FirestorePaths.doctors);
      if (!includeUnpublished) {
        query = query.where('published', isEqualTo: true);
      }
      final key = FirebaseEconomy.catalogKey(
        collection: FirestorePaths.doctors,
        includeUnpublished: includeUnpublished,
      );
      final cached = await FirebaseEconomy.cachedQuery(query);
      if (cached != null) {
        await _applyCatalog(
          cached,
          includeUnpublished: includeUnpublished,
          alsoUid: alsoUid,
        );
        if (!force && await FirebaseEconomy.isCatalogFresh(key)) {
          return;
        }
      }
      final snapshot = await FirebaseEconomy.serverQuery(query);
      await _applyCatalog(
        snapshot,
        includeUnpublished: includeUnpublished,
        alsoUid: alsoUid,
      );
      await FirebaseEconomy.markCatalogFresh(key);
    } catch (error) {
      debugPrint('No se pudieron leer médicos publicados: $error');
    }
  }

  Future<void> _applyCatalog(
    QuerySnapshot<Map<String, dynamic>> snapshot, {
    required bool includeUnpublished,
    String? alsoUid,
  }) async {
    var items = snapshot.docs
        .map((doc) => Doctor.fromMap(doc.id, doc.data()))
        .toList();
    if (alsoUid != null &&
        alsoUid.isNotEmpty &&
        !items.any((doctor) => doctor.id == alsoUid)) {
      final own = await loadProfile(alsoUid);
      if (own != null) {
        items = [own, ...items];
      }
    }
    _registered = items;
    _includeUnpublished = includeUnpublished;
    _fetchedAt = DateTime.now();
    notifyListeners();
  }

  Future<Doctor?> loadProfile(String uid) async {
    if (Firebase.apps.isEmpty || uid.isEmpty) {
      return null;
    }
    try {
      final doc = await FirebaseEconomy.getDocument(
        FirebaseFirestore.instance.collection(FirestorePaths.doctors).doc(uid),
      ).timeout(const Duration(seconds: 8));
      if (!doc.exists || doc.data() == null) {
        return null;
      }
      return Doctor.fromMap(doc.id, doc.data()!);
    } catch (error) {
      debugPrint('No se pudo cargar el perfil médico: $error');
      return null;
    }
  }

  Future<void> saveProfile(Doctor doctor) async {
    _ensureCanEdit(doctor.id);
    if (Firebase.apps.isEmpty) {
      throw StateError('Firebase no está inicializado.');
    }
    _registered = [
      doctor,
      ..._registered.where((item) => item.id != doctor.id),
    ];
    notifyListeners();
    try {
      await FirebaseFirestore.instance
          .collection(FirestorePaths.doctors)
          .doc(doctor.id)
          .set(doctor.toMap(), SetOptions(merge: true));
    } catch (error) {
      debugPrint('No se pudo guardar el médico en Firestore: $error');
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
    return StorageUpload.jpeg(path: 'doctors/$uid/$name.jpg', bytes: bytes);
  }

  bool isFavorite(String doctorId) => _favoriteIds.contains(doctorId);

  Doctor? findById(String id) {
    if (id.isEmpty) {
      return null;
    }
    for (final doctor in doctors) {
      if (doctor.id == id) {
        return doctor;
      }
    }
    for (final doctor in _registered) {
      if (doctor.id == id) {
        return doctor;
      }
    }
    return null;
  }

  Doctor byId(String id) {
    final doctor = findById(id);
    if (doctor != null) {
      return doctor;
    }
    throw StateError('Médico no encontrado: $id');
  }

  List<Doctor> get favorites =>
      doctors.where((doctor) => _favoriteIds.contains(doctor.id)).toList();

  List<Doctor> nearby(UserLocation? location) {
    return _nearbyStrict(location);
  }

  List<Doctor> _nearbyStrict(UserLocation? location) {
    final all = doctors;
    if (location == null) {
      return all;
    }
    return all
        .where((doctor) => doctor.matchesLocation(location))
        .toList();
  }

  List<Doctor> bySpecialty(String specialty, [UserLocation? location]) {
    return nearby(
      location,
    ).where((doctor) => doctor.specialty == specialty).toList();
  }

  List<Doctor> byHospital(String hospital) {
    return doctors.where((doctor) => doctor.hospital == hospital).toList();
  }

  Future<void> updateOfficeLocation({
    required String doctorId,
    required String officeAddress,
    String? city,
    double? latitude,
    double? longitude,
  }) async {
    _ensureCanEdit(doctorId);
    final index = _catalog.indexWhere((doctor) => doctor.id == doctorId);
    if (index >= 0) {
      _catalog[index] = _catalog[index].copyWith(
        officeAddress: officeAddress,
        city: city,
        latitude: latitude,
        longitude: longitude,
      );
    }
    final publishedIndex = _registered.indexWhere(
      (doctor) => doctor.id == doctorId,
    );
    if (publishedIndex >= 0) {
      _registered[publishedIndex] = _registered[publishedIndex].copyWith(
        officeAddress: officeAddress,
        city: city,
        latitude: latitude,
        longitude: longitude,
      );
    }
    notifyListeners();
    try {
      await FirebaseFirestore.instance
          .collection(FirestorePaths.doctors)
          .doc(doctorId)
          .set({
            'officeAddress': officeAddress,
            'city': city,
            'latitude': latitude,
            'longitude': longitude,
          }, SetOptions(merge: true));
    } catch (error) {
      debugPrint('No se pudo guardar la ubicación: $error');
    }
  }

  void _ensureCanEdit(String doctorId) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError(
        'Solo el médico dueño de esta tarjeta puede cambiar estos datos.',
      );
    }
    if (isAdminEmail(user.email) || user.uid == doctorId) {
      return;
    }
    throw StateError(
      'Solo el médico dueño de esta tarjeta puede cambiar estos datos.',
    );
  }

  Future<void> approveDoctor(
    Doctor doctor, {
    required String adminEmail,
  }) async {
    final updated = doctor.copyWith(
      published: true,
      reviewStatus: DoctorReviewStatus.approved,
      reviewedAt: DateTime.now(),
      reviewedBy: adminEmail,
      clearRejection: true,
    );
    await saveProfile(updated);
  }

  Future<void> rejectDoctor(
    Doctor doctor, {
    required String reason,
    required String adminEmail,
  }) async {
    final trimmed = reason.trim();
    if (trimmed.isEmpty) {
      throw StateError('Escribe el motivo del rechazo.');
    }
    final updated = doctor.copyWith(
      published: false,
      reviewStatus: DoctorReviewStatus.rejected,
      rejectionReason: trimmed,
      reviewedAt: DateTime.now(),
      reviewedBy: adminEmail,
    );
    await saveProfile(updated);
  }

  Future<void> unpublishDoctor(
    Doctor doctor, {
    required String adminEmail,
  }) async {
    final updated = doctor.copyWith(
      published: false,
      reviewStatus: DoctorReviewStatus.pending,
      reviewedAt: DateTime.now(),
      reviewedBy: adminEmail,
    );
    await saveProfile(updated);
  }

  Future<void> deleteDoctor(String doctorId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || !isAdminEmail(user.email)) {
      throw StateError('Solo un administrador puede eliminar un perfil.');
    }
    if (doctorId.isEmpty) {
      throw StateError('No se encontró el perfil a eliminar.');
    }
    if (Firebase.apps.isEmpty) {
      throw StateError('Firebase no está inicializado.');
    }

    final db = FirebaseFirestore.instance;
    await db.collection(FirestorePaths.doctors).doc(doctorId).delete();
    try {
      await db.collection(FirestorePaths.users).doc(doctorId).delete();
    } catch (error) {
      debugPrint('No se pudo borrar users/$doctorId: $error');
    }
    try {
      final appointments = await db
          .collection(FirestorePaths.appointments)
          .where('doctorId', isEqualTo: doctorId)
          .get();
      for (final doc in appointments.docs) {
        await doc.reference.delete();
      }
    } catch (error) {
      debugPrint('No se pudieron borrar citas de $doctorId: $error');
    }

    try {
      await FirebaseFunctions.instanceFor(region: 'us-central1')
          .httpsCallable('deleteDoctorAccount')
          .call(<String, dynamic>{'uid': doctorId});
    } catch (error) {
      debugPrint('No se pudo borrar Auth de $doctorId: $error');
    }

    _registered = _registered.where((item) => item.id != doctorId).toList();
    notifyListeners();
  }

  List<Doctor> filteredIn(UserLocation? location) {
    return doctors.where((doctor) {
      final matchesCountry =
          location == null || doctor.country == location.country;
      final department = _departmentFilter;
      final matchesDepartment =
          department == null || doctor.region == department;
      final matchesSpecialty =
          _specialtyFilter == null || doctor.specialty == _specialtyFilter;
      final matchesProvince =
          _provinceFilter == null || doctor.provinceName == _provinceFilter;
      final haystack =
          '${doctor.name} ${doctor.specialty} ${doctor.hospital} ${doctor.officeAddress ?? ''} ${doctor.city} ${doctor.provinceName} ${doctor.region}'
              .toLowerCase();
      final matchesQuery = haystack.contains(_query.toLowerCase());
      return matchesCountry &&
          matchesDepartment &&
          matchesSpecialty &&
          matchesProvince &&
          matchesQuery;
    }).toList();
  }

  List<({Doctor doctor, MedicalService service})> servicesForSpecialty(
    String specialty, [
    UserLocation? location,
  ]) {
    final items = <({Doctor doctor, MedicalService service})>[];
    for (final doctor in bySpecialty(specialty, location)) {
      for (final service in doctor.services) {
        items.add((doctor: doctor, service: service));
      }
    }
    return items;
  }

  void toggleFavorite(String doctorId) {
    if (!_favoriteIds.add(doctorId)) {
      _favoriteIds.remove(doctorId);
    }
    notifyListeners();
  }

  void setQuery(String value) {
    _query = value;
    notifyListeners();
  }

  void setSpecialtyFilter(String? specialty) {
    _specialtyFilter = specialty;
    notifyListeners();
  }

  void setDepartmentFilter(String? department) {
    _departmentFilter = department;
    _provinceFilter = null;
    notifyListeners();
  }

  void setProvinceFilter(String? province) {
    _provinceFilter = province;
    notifyListeners();
  }

}

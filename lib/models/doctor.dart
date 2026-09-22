import 'package:cloud_firestore/cloud_firestore.dart';

import '../data/locations.dart';
import 'doctor_review_status.dart';
import 'medical_service.dart';
import 'user_location.dart';

const defaultDoctorPhoto =
    'https://images.unsplash.com/photo-1612349317150-e413f6a5b16d?auto=format&fit=crop&w=800';

class Doctor {
  final String id;
  final String name;
  final String credentials;
  final String specialty;
  final String photoUrl;
  final double rating;
  final int reviewCount;
  final int yearsExperience;
  final int patientsCount;
  final String workingHours;
  final String about;
  final String hospital;
  final String city;
  final String country;
  final String phone;
  final String? department;
  final String? province;
  final List<MedicalService> services;
  final String? officeAddress;
  final double? latitude;
  final double? longitude;
  final bool published;
  final String? medicalCardUrl;
  final DoctorReviewStatus reviewStatus;
  final String? rejectionReason;
  final DateTime? submittedAt;
  final DateTime? reviewedAt;
  final String? reviewedBy;

  const Doctor({
    required this.id,
    required this.name,
    required this.credentials,
    required this.specialty,
    required this.photoUrl,
    required this.rating,
    required this.reviewCount,
    required this.yearsExperience,
    required this.patientsCount,
    required this.workingHours,
    required this.about,
    required this.hospital,
    required this.city,
    required this.services,
    this.phone = '',
    this.country = defaultCountry,
    this.department,
    this.province,
    this.officeAddress,
    this.latitude,
    this.longitude,
    this.published = true,
    this.medicalCardUrl,
    this.reviewStatus = DoctorReviewStatus.approved,
    this.rejectionReason,
    this.submittedAt,
    this.reviewedAt,
    this.reviewedBy,
  });

  String get region => department ?? departmentForCity(city);

  String get provinceName => province ?? provinceForCity(city);

  bool get hasOfficeLocation =>
      (officeAddress != null && officeAddress!.trim().isNotEmpty) ||
      (latitude != null && longitude != null);

  String get whatsappNumber => phone.replaceAll(RegExp(r'\D'), '');

  bool get hasWhatsApp => whatsappNumber.length >= 8;

  String get locationLabel {
    if (officeAddress != null && officeAddress!.trim().isNotEmpty) {
      return officeAddress!;
    }
    return '$hospital, $city';
  }

  bool get hasCustomPhoto {
    final url = photoUrl.trim();
    return url.isNotEmpty && url != defaultDoctorPhoto;
  }

  List<({String label, bool ok})> get profileChecks => [
    (label: 'Nombre profesional', ok: name.trim().isNotEmpty),
    (label: 'Credenciales / exequátur', ok: credentials.trim().isNotEmpty),
    (label: 'Foto de perfil', ok: hasCustomPhoto),
    (label: 'Lugar de trabajo', ok: hospital.trim().isNotEmpty),
    (label: 'Contacto', ok: hasWhatsApp),
    (label: 'Descripción', ok: about.trim().length >= 20),
    (label: 'Servicios', ok: services.isNotEmpty),
    (label: 'Ubicación', ok: city.trim().isNotEmpty),
  ];

  int get profileScore {
    if (profileChecks.isEmpty) {
      return 0;
    }
    final ok = profileChecks.where((item) => item.ok).length;
    return ((ok / profileChecks.length) * 100).round();
  }

  List<String> get missingProfileItems =>
      profileChecks.where((item) => !item.ok).map((item) => item.label).toList();

  bool matchesLocation(
    UserLocation location, {
    bool sameDepartment = false,
    bool sameProvince = false,
  }) {
    if (country != location.country || region != location.department) {
      return false;
    }
    if (sameDepartment) {
      return true;
    }
    if (provinceName != location.province) {
      return false;
    }
    if (sameProvince) {
      return true;
    }
    return city == location.city;
  }

  MedicalService serviceById(String serviceId) {
    return services.firstWhere((service) => service.id == serviceId);
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'credentials': credentials,
      'specialty': specialty,
      'photoUrl': photoUrl,
      'rating': rating,
      'reviewCount': reviewCount,
      'yearsExperience': yearsExperience,
      'patientsCount': patientsCount,
      'workingHours': workingHours,
      'about': about,
      'hospital': hospital,
      'phone': phone,
      'city': city,
      'country': country,
      'department': department,
      'province': province,
      'officeAddress': officeAddress,
      'latitude': latitude,
      'longitude': longitude,
      'published': published,
      'medicalCardUrl': medicalCardUrl,
      'reviewStatus': reviewStatus.id,
      'rejectionReason': rejectionReason,
      'submittedAt': submittedAt == null
          ? null
          : Timestamp.fromDate(submittedAt!),
      'reviewedAt': reviewedAt == null ? null : Timestamp.fromDate(reviewedAt!),
      'reviewedBy': reviewedBy,
      'services': services.map((service) => service.toMap()).toList(),
    };
  }

  factory Doctor.fromMap(String id, Map<String, dynamic> data) {
    final rawServices = data['services'];
    final published = data['published'] as bool? ?? false;
    return Doctor(
      id: id,
      name: data['name'] as String? ?? 'Médico',
      credentials: data['credentials'] as String? ?? '',
      specialty: data['specialty'] as String? ?? 'Medicina general',
      photoUrl: (data['photoUrl'] as String?)?.trim().isNotEmpty == true
          ? data['photoUrl'] as String
          : defaultDoctorPhoto,
      rating: (data['rating'] as num?)?.toDouble() ?? 5,
      reviewCount: (data['reviewCount'] as num?)?.toInt() ?? 0,
      yearsExperience: (data['yearsExperience'] as num?)?.toInt() ?? 1,
      patientsCount: (data['patientsCount'] as num?)?.toInt() ?? 0,
      workingHours: data['workingHours'] as String? ?? 'Lun a Vie, 9:00 - 18:00',
      about: data['about'] as String? ?? '',
      hospital: data['hospital'] as String? ?? '',
      phone: data['phone'] as String? ?? '',
      city: data['city'] as String? ?? defaultCity,
      country: data['country'] as String? ?? defaultCountry,
      department: data['department'] as String?,
      province: data['province'] as String?,
      officeAddress: data['officeAddress'] as String?,
      latitude: (data['latitude'] as num?)?.toDouble(),
      longitude: (data['longitude'] as num?)?.toDouble(),
      published: published,
      medicalCardUrl: data['medicalCardUrl'] as String?,
      reviewStatus: DoctorReviewStatus.fromId(
        data['reviewStatus'],
        published: published,
      ),
      rejectionReason: data['rejectionReason'] as String?,
      submittedAt: _dateFrom(data['submittedAt']),
      reviewedAt: _dateFrom(data['reviewedAt']),
      reviewedBy: data['reviewedBy'] as String?,
      services: rawServices is List
          ? rawServices
                .whereType<Map>()
                .map(
                  (item) =>
                      MedicalService.fromMap(Map<String, dynamic>.from(item)),
                )
                .toList()
          : const [],
    );
  }

  static DateTime? _dateFrom(Object? raw) {
    if (raw is Timestamp) {
      return raw.toDate();
    }
    if (raw is DateTime) {
      return raw;
    }
    if (raw is String) {
      return DateTime.tryParse(raw);
    }
    return null;
  }

  Doctor copyWith({
    String? name,
    String? credentials,
    String? specialty,
    String? photoUrl,
    int? yearsExperience,
    String? workingHours,
    String? about,
    String? hospital,
    String? phone,
    String? city,
    String? country,
    String? department,
    String? province,
    List<MedicalService>? services,
    String? officeAddress,
    double? latitude,
    double? longitude,
    bool? published,
    String? medicalCardUrl,
    DoctorReviewStatus? reviewStatus,
    String? rejectionReason,
    DateTime? submittedAt,
    DateTime? reviewedAt,
    String? reviewedBy,
    bool clearRejection = false,
  }) {
    return Doctor(
      id: id,
      name: name ?? this.name,
      credentials: credentials ?? this.credentials,
      specialty: specialty ?? this.specialty,
      photoUrl: photoUrl ?? this.photoUrl,
      rating: rating,
      reviewCount: reviewCount,
      yearsExperience: yearsExperience ?? this.yearsExperience,
      patientsCount: patientsCount,
      workingHours: workingHours ?? this.workingHours,
      about: about ?? this.about,
      hospital: hospital ?? this.hospital,
      phone: phone ?? this.phone,
      city: city ?? this.city,
      country: country ?? this.country,
      department: department ?? this.department,
      province: province ?? this.province,
      services: services ?? this.services,
      officeAddress: officeAddress ?? this.officeAddress,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      published: published ?? this.published,
      medicalCardUrl: medicalCardUrl ?? this.medicalCardUrl,
      reviewStatus: reviewStatus ?? this.reviewStatus,
      rejectionReason: clearRejection
          ? null
          : (rejectionReason ?? this.rejectionReason),
      submittedAt: submittedAt ?? this.submittedAt,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      reviewedBy: reviewedBy ?? this.reviewedBy,
    );
  }

  Doctor withId(String newId) {
    if (newId == id) {
      return this;
    }
    return Doctor(
      id: newId,
      name: name,
      credentials: credentials,
      specialty: specialty,
      photoUrl: photoUrl,
      rating: rating,
      reviewCount: reviewCount,
      yearsExperience: yearsExperience,
      patientsCount: patientsCount,
      workingHours: workingHours,
      about: about,
      hospital: hospital,
      phone: phone,
      city: city,
      country: country,
      department: department,
      province: province,
      services: services,
      officeAddress: officeAddress,
      latitude: latitude,
      longitude: longitude,
      published: published,
      medicalCardUrl: medicalCardUrl,
      reviewStatus: reviewStatus,
      rejectionReason: rejectionReason,
      submittedAt: submittedAt,
      reviewedAt: reviewedAt,
      reviewedBy: reviewedBy,
    );
  }

  static String _filled(String current, String fallback) {
    return current.trim().isNotEmpty ? current : fallback;
  }

  Doctor mergeWithDraft(Doctor draft) {
    return copyWith(
      name: _filled(name, draft.name),
      credentials: _filled(credentials, draft.credentials),
      specialty: specialty.trim().isNotEmpty && specialty != 'Medicina general'
          ? specialty
          : draft.specialty,
      photoUrl: hasCustomPhoto ? photoUrl : draft.photoUrl,
      about: _filled(about, draft.about),
      hospital: _filled(hospital, draft.hospital),
      phone: _filled(phone, draft.phone),
      workingHours: _filled(workingHours, draft.workingHours),
      city: _filled(city, draft.city),
      country: _filled(country, draft.country),
      department: department ?? draft.department,
      province: province ?? draft.province,
      officeAddress: (officeAddress ?? '').trim().isNotEmpty
          ? officeAddress
          : draft.officeAddress,
      services: services.isNotEmpty ? services : draft.services,
      reviewStatus: reviewStatus,
    );
  }
}

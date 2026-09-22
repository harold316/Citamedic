import 'package:cloud_firestore/cloud_firestore.dart';

import '../data/locations.dart';
import 'doctor_review_status.dart';
import 'medical_service.dart';
import 'user_location.dart';

const defaultClinicPhoto =
    'https://images.unsplash.com/photo-1519494026892-80bbd2d6fd0d?auto=format&fit=crop&w=800';

class Clinic {
  final String id;
  final String name;
  final String city;
  final String address;
  final String photoUrl;
  final List<String> photoUrls;
  final double rating;
  final String country;
  final String? department;
  final String? province;
  final String phone;
  final String about;
  final List<MedicalService> services;
  final double? latitude;
  final double? longitude;
  final bool published;
  final DoctorReviewStatus reviewStatus;
  final String? rejectionReason;
  final DateTime? submittedAt;
  final DateTime? reviewedAt;
  final String? reviewedBy;

  const Clinic({
    required this.id,
    required this.name,
    required this.city,
    required this.address,
    required this.photoUrl,
    required this.rating,
    this.photoUrls = const [],
    this.country = defaultCountry,
    this.department,
    this.province,
    this.phone = '',
    this.about = '',
    this.services = const [],
    this.latitude,
    this.longitude,
    this.published = true,
    this.reviewStatus = DoctorReviewStatus.approved,
    this.rejectionReason,
    this.submittedAt,
    this.reviewedAt,
    this.reviewedBy,
  });

  String get region => department ?? departmentForCity(city);

  String get provinceName => province ?? provinceForCity(city);

  String get locationLabel {
    if (address.trim().isNotEmpty) {
      return '$address, $city';
    }
    return '$city, $region';
  }

  List<String> get gallery {
    if (photoUrls.isNotEmpty) {
      return photoUrls.take(10).toList();
    }
    if (hasCustomPhoto) {
      return [photoUrl];
    }
    return const [];
  }

  bool get hasGpsLocation => latitude != null && longitude != null;

  bool get hasCustomPhoto {
    final url = photoUrl.trim();
    return url.isNotEmpty && url != defaultClinicPhoto;
  }

  bool matchesLocation(UserLocation location) {
    return country == location.country &&
        region == location.department &&
        provinceName == location.province &&
        city == location.city;
  }

  Map<String, dynamic> toMap() {
    final photos = gallery;
    return {
      'name': name,
      'city': city,
      'address': address,
      'photoUrl': photos.isNotEmpty ? photos.first : photoUrl,
      'photoUrls': photos,
      'rating': rating,
      'country': country,
      'department': department,
      'province': province,
      'phone': phone,
      'about': about,
      'services': services.map((item) => item.toMap()).toList(),
      'latitude': latitude,
      'longitude': longitude,
      'published': published,
      'reviewStatus': reviewStatus.id,
      'rejectionReason': rejectionReason,
      'submittedAt': submittedAt == null
          ? null
          : Timestamp.fromDate(submittedAt!),
      'reviewedAt': reviewedAt == null ? null : Timestamp.fromDate(reviewedAt!),
      'reviewedBy': reviewedBy,
    };
  }

  factory Clinic.fromMap(String id, Map<String, dynamic> data) {
    final published = data['published'] as bool? ?? false;
    final cover = (data['photoUrl'] as String?)?.trim().isNotEmpty == true
        ? data['photoUrl'] as String
        : defaultClinicPhoto;
    final rawPhotos = data['photoUrls'];
    final photos = rawPhotos is List
        ? rawPhotos
              .whereType<String>()
              .map((item) => item.trim())
              .where((item) => item.isNotEmpty)
              .take(8)
              .toList()
        : <String>[];
    if (photos.isEmpty && cover != defaultClinicPhoto) {
      photos.add(cover);
    }
    final rawServices = data['services'];
    return Clinic(
      id: id,
      name: data['name'] as String? ?? 'Clínica',
      city: data['city'] as String? ?? defaultCity,
      address: data['address'] as String? ?? '',
      photoUrl: photos.isNotEmpty ? photos.first : cover,
      photoUrls: photos,
      rating: (data['rating'] as num?)?.toDouble() ?? 5,
      country: data['country'] as String? ?? defaultCountry,
      department: data['department'] as String?,
      province: data['province'] as String?,
      phone: data['phone'] as String? ?? '',
      about: data['about'] as String? ?? '',
      services: rawServices is List
          ? rawServices
                .whereType<Map>()
                .map(
                  (item) =>
                      MedicalService.fromMap(Map<String, dynamic>.from(item)),
                )
                .toList()
          : const [],
      latitude: (data['latitude'] as num?)?.toDouble(),
      longitude: (data['longitude'] as num?)?.toDouble(),
      published: published,
      reviewStatus: DoctorReviewStatus.fromId(
        data['reviewStatus'],
        published: published,
      ),
      rejectionReason: data['rejectionReason'] as String?,
      submittedAt: _dateFrom(data['submittedAt']),
      reviewedAt: _dateFrom(data['reviewedAt']),
      reviewedBy: data['reviewedBy'] as String?,
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

  Clinic copyWith({
    String? name,
    String? city,
    String? address,
    String? photoUrl,
    List<String>? photoUrls,
    double? rating,
    String? country,
    String? department,
    String? province,
    String? phone,
    String? about,
    List<MedicalService>? services,
    double? latitude,
    double? longitude,
    bool? published,
    DoctorReviewStatus? reviewStatus,
    String? rejectionReason,
    DateTime? submittedAt,
    DateTime? reviewedAt,
    String? reviewedBy,
    bool clearRejection = false,
  }) {
    return Clinic(
      id: id,
      name: name ?? this.name,
      city: city ?? this.city,
      address: address ?? this.address,
      photoUrl: photoUrl ?? this.photoUrl,
      photoUrls: photoUrls ?? this.photoUrls,
      rating: rating ?? this.rating,
      country: country ?? this.country,
      department: department ?? this.department,
      province: province ?? this.province,
      phone: phone ?? this.phone,
      about: about ?? this.about,
      services: services ?? this.services,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      published: published ?? this.published,
      reviewStatus: reviewStatus ?? this.reviewStatus,
      rejectionReason: clearRejection
          ? null
          : (rejectionReason ?? this.rejectionReason),
      submittedAt: submittedAt ?? this.submittedAt,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      reviewedBy: reviewedBy ?? this.reviewedBy,
    );
  }

  Clinic withId(String newId) {
    if (newId == id) {
      return this;
    }
    return Clinic(
      id: newId,
      name: name,
      city: city,
      address: address,
      photoUrl: photoUrl,
      photoUrls: photoUrls,
      rating: rating,
      country: country,
      department: department,
      province: province,
      phone: phone,
      about: about,
      services: services,
      latitude: latitude,
      longitude: longitude,
      published: published,
      reviewStatus: reviewStatus,
      rejectionReason: rejectionReason,
      submittedAt: submittedAt,
      reviewedAt: reviewedAt,
      reviewedBy: reviewedBy,
    );
  }
}

enum UserRole {
  patient,
  doctor,
  clinic,
  admin;

  static const marker = '::';

  String get id => name;

  String get label {
    switch (this) {
      case UserRole.doctor:
        return 'Médico';
      case UserRole.clinic:
        return 'Clínica';
      case UserRole.admin:
        return 'Administrador';
      case UserRole.patient:
        return 'Paciente';
    }
  }

  String encodeName(String name) => '$id$marker${name.trim()}';

  static UserRole fromId(Object? value) {
    if (value == UserRole.admin.id) {
      return UserRole.admin;
    }
    if (value == UserRole.doctor.id) {
      return UserRole.doctor;
    }
    if (value == UserRole.clinic.id) {
      return UserRole.clinic;
    }
    return UserRole.patient;
  }

  static UserRole fromDisplayName(String? value) {
    if (value != null && value.startsWith('${UserRole.admin.id}$marker')) {
      return UserRole.admin;
    }
    if (value != null && value.startsWith('${UserRole.doctor.id}$marker')) {
      return UserRole.doctor;
    }
    if (value != null && value.startsWith('${UserRole.clinic.id}$marker')) {
      return UserRole.clinic;
    }
    return UserRole.patient;
  }

  static String visibleName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Usuario';
    }
    final index = value.indexOf(marker);
    if (index >= 0) {
      final name = value.substring(index + marker.length).trim();
      return name.isEmpty ? 'Usuario' : name;
    }
    return value.trim();
  }
}

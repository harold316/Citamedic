class Patient {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String password;

  const Patient({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.password,
  });

  Patient copyWith({
    String? name,
    String? email,
    String? phone,
    String? password,
  }) {
    return Patient(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      password: password ?? this.password,
    );
  }
}

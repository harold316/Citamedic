class UserLocation {
  final String country;
  final String department;
  final String province;
  final String city;

  const UserLocation({
    required this.country,
    required this.department,
    required this.province,
    required this.city,
  });

  String get label => '$city, $province';

  String get fullLabel => '$city, $province, $department, $country';

  @override
  bool operator ==(Object other) {
    return other is UserLocation &&
        other.country == country &&
        other.department == department &&
        other.province == province &&
        other.city == city;
  }

  @override
  int get hashCode => Object.hash(country, department, province, city);
}

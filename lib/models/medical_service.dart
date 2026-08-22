class MedicalService {
  final String id;
  final String name;
  final double price;
  final int durationMinutes;

  const MedicalService({
    required this.id,
    required this.name,
    required this.price,
    required this.durationMinutes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'durationMinutes': durationMinutes,
    };
  }

  factory MedicalService.fromMap(Map<String, dynamic> data) {
    return MedicalService(
      id: data['id'] as String? ?? '',
      name: data['name'] as String? ?? 'Consulta',
      price: (data['price'] as num?)?.toDouble() ?? 0,
      durationMinutes: (data['durationMinutes'] as num?)?.toInt() ?? 30,
    );
  }
}

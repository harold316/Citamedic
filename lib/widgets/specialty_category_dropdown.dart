import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../data/specialty_icons.dart';
import 'medical_specialty_icon.dart';

class SpecialtyCategoryDropdown extends StatelessWidget {
  const SpecialtyCategoryDropdown({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final String value;
  final ValueChanged<String> onChanged;

  static const _specialties = 'Especialidades médicas';
  static const _services = 'Servicios médicos';

  bool get _isService => medicalServiceCategories.contains(value);

  List<String> get _options =>
      _isService ? medicalServiceCategories : medicalSpecialties;

  String get _group => _isService ? _services : _specialties;

  @override
  Widget build(BuildContext context) {
    final selected = allCategories.contains(value) ? value : defaultSpecialty;
    return Column(
      children: [
        _Dropdown(
          label: 'Área',
          value: _group,
          items: const [_specialties, _services],
          onChanged: (group) {
            if (group == _group) {
              return;
            }
            onChanged(
              group == _services
                  ? medicalServiceCategories.first
                  : medicalSpecialties.first,
            );
          },
        ),
        const SizedBox(height: 12),
        _Dropdown(
          label: _isService ? 'Servicio' : 'Especialidad',
          value: selected,
          items: _options,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _Dropdown extends StatelessWidget {
  const _Dropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<String> items;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final selected = items.contains(value) ? value : items.first;
    return InputDecorator(
      decoration: InputDecoration(labelText: label),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: selected,
          items: [
            for (final item in items)
              DropdownMenuItem(
                value: item,
                child: Row(
                  children: [
                    MedicalSpecialtyIcon(
                      name: item,
                      color: iconColorFor(item),
                      size: 26,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(item, overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
              ),
          ],
          onChanged: (item) {
            if (item != null) {
              onChanged(item);
            }
          },
        ),
      ),
    );
  }
}

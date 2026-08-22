import 'package:flutter/material.dart';

import '../data/locations.dart';

class LocationSelectors extends StatelessWidget {
  const LocationSelectors({
    super.key,
    required this.country,
    required this.department,
    required this.province,
    required this.city,
    required this.onCountryChanged,
    required this.onDepartmentChanged,
    required this.onProvinceChanged,
    required this.onCityChanged,
  });

  final String country;
  final String department;
  final String province;
  final String city;
  final ValueChanged<String> onCountryChanged;
  final ValueChanged<String> onDepartmentChanged;
  final ValueChanged<String> onProvinceChanged;
  final ValueChanged<String> onCityChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _Dropdown(
          label: 'País',
          value: country,
          items: locationCatalog.keys.toList(),
          onChanged: onCountryChanged,
        ),
        const SizedBox(height: 12),
        _Dropdown(
          label: 'Departamento',
          value: department,
          items: catalogDepartments(country),
          onChanged: onDepartmentChanged,
        ),
        const SizedBox(height: 12),
        _Dropdown(
          label: 'Provincia',
          value: province,
          items: catalogProvinces(country, department),
          onChanged: onProvinceChanged,
        ),
        const SizedBox(height: 12),
        _Dropdown(
          label: 'Ciudad',
          value: city,
          items: catalogCities(country, department, province),
          onChanged: onCityChanged,
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
    final selected = items.contains(value) ? value : null;
    return DropdownButtonFormField<String>(
      key: ValueKey('$label-$value'),
      initialValue: selected,
      decoration: InputDecoration(labelText: label),
      items: [
        for (final item in items)
          DropdownMenuItem(value: item, child: Text(item)),
      ],
      onChanged: (value) {
        if (value != null) {
          onChanged(value);
        }
      },
    );
  }
}

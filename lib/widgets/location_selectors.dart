import 'package:flutter/material.dart';

import '../data/locations.dart';
import '../theme/app_theme.dart';

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
        if (locationCatalog.length > 1) ...[
          _CountryField(country: country, onChanged: onCountryChanged),
          const SizedBox(height: 12),
        ],
        _Dropdown(
          label: regionLabel(country),
          value: department,
          items: catalogDepartments(country),
          onChanged: onDepartmentChanged,
        ),
        const SizedBox(height: 12),
        _Dropdown(
          label: subregionLabel(country),
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

class _CountryField extends StatelessWidget {
  const _CountryField({required this.country, required this.onChanged});

  final String country;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: const InputDecoration(labelText: 'País'),
      child: InkWell(
        onTap: () => _pick(context),
        child: Row(
          children: [
            CountryFlag(country: country, width: 52, height: 34),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                country,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down,
              color: AppColors.of(context).muted,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pick(BuildContext context) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 4, 20, 8),
                child: Text(
                  'Elige un país',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                ),
              ),
              for (final item in locationCatalog.keys)
                ListTile(
                  leading: CountryFlag(country: item, width: 56, height: 38),
                  title: Text(
                    item,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  trailing: item == country
                      ? const Icon(Icons.check, color: AppColors.primary)
                      : null,
                  onTap: () => Navigator.pop(context, item),
                ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
    if (selected != null && selected != country) {
      onChanged(selected);
    }
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
      key: ValueKey('$label-$selected'),
      initialValue: selected,
      isExpanded: true,
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

class CountryFlag extends StatelessWidget {
  const CountryFlag({
    super.key,
    required this.country,
    this.width = 52,
    this.height = 34,
  });

  final String country;
  final double width;
  final double height;

  String? get _asset {
    switch (country) {
      case 'Bolivia':
        return 'assets/flags/bolivia.png';
      case 'Argentina':
        return 'assets/flags/argentina.png';
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final asset = _asset;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.black26),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: asset == null
          ? ColoredBox(color: Colors.grey.shade300)
          : Image.asset(
              asset,
              width: width,
              height: height,
              fit: BoxFit.cover,
              filterQuality: FilterQuality.high,
            ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/locations.dart';
import '../models/user_location.dart';
import '../providers/session_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/location_selectors.dart';
import '../widgets/primary_pill_button.dart';

class ChangeLocationScreen extends StatefulWidget {
  const ChangeLocationScreen({super.key});

  @override
  State<ChangeLocationScreen> createState() => _ChangeLocationScreenState();
}

class _ChangeLocationScreenState extends State<ChangeLocationScreen> {
  late String _country;
  late String _department;
  late String _province;
  late String _city;

  @override
  void initState() {
    super.initState();
    final current = context.read<SessionProvider>().location;
    _country = current?.country ?? defaultCountry;
    _department = current?.department ?? defaultDepartment;
    _province = current?.province ?? defaultProvince;
    _city = current?.city ?? defaultCity;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Cambiar ubicación'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          Text(
            'Elige país, región y ciudad para ver profesionales cerca de ti.',
            style: TextStyle(color: AppColors.of(context).muted),
          ),
          const SizedBox(height: 18),
          LocationSelectors(
            country: _country,
            department: _department,
            province: _province,
            city: _city,
            onCountryChanged: _onCountryChanged,
            onDepartmentChanged: _onDepartmentChanged,
            onProvinceChanged: _onProvinceChanged,
            onCityChanged: (value) => setState(() => _city = value),
          ),
          const SizedBox(height: 28),
          PrimaryPillButton(
            label: 'Usar esta ubicación',
            onPressed: () {
              context.read<SessionProvider>().updateLocation(
                UserLocation(
                  country: _country,
                  department: _department,
                  province: _province,
                  city: _city,
                ),
              );
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  void _onCountryChanged(String value) {
    final department = catalogDepartments(value).first;
    final province = catalogProvinces(value, department).first;
    setState(() {
      _country = value;
      _department = department;
      _province = province;
      _city = catalogCities(value, department, province).first;
    });
  }

  void _onDepartmentChanged(String value) {
    final province = catalogProvinces(_country, value).first;
    setState(() {
      _department = value;
      _province = province;
      _city = catalogCities(_country, value, province).first;
    });
  }

  void _onProvinceChanged(String value) {
    setState(() {
      _province = value;
      _city = catalogCities(_country, _department, value).first;
    });
  }
}

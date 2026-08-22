import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/locations.dart';
import '../models/user_location.dart';
import '../providers/auth_provider.dart';
import '../providers/session_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/location_selectors.dart';
import '../widgets/notifications_bell_button.dart';
import '../widgets/primary_pill_button.dart';
import '../widgets/theme_toggle_button.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  String _country = defaultCountry;
  String _department = defaultDepartment;
  String _province = defaultProvince;
  String _city = defaultCity;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
          children: [
            const Align(
              alignment: Alignment.centerRight,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  NotificationsBellButton(),
                  ThemeToggleButton(),
                ],
              ),
            ),
            Center(
              child: Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 40),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'CitaMedic',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: AppColors.of(context).text,
              ),
            ),
            Text(
              'Hola, ${auth.displayName}. Elige dónde buscar profesionales.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.of(context).muted),
            ),
            const SizedBox(height: 28),
            Text(
              '¿Dónde quieres localizar a los profesionales?',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: AppColors.of(context).text,
              ),
            ),
            const SizedBox(height: 12),
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
            PrimaryPillButton(label: 'Continuar', onPressed: _continue),
          ],
        ),
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

  void _continue() {
    final auth = context.read<AuthProvider>();
    context.read<SessionProvider>().enter(
      name: auth.displayName,
      email: auth.email,
      location: UserLocation(
        country: _country,
        department: _department,
        province: _province,
        city: _city,
      ),
    );
  }
}

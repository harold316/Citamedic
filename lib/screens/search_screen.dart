import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/locations.dart';
import '../data/mock_data.dart';
import '../providers/doctors_provider.dart';
import '../providers/session_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/doctor_result_card.dart';
import '../widgets/notifications_bell_button.dart';
import 'doctor_profile_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DoctorsProvider>();
    final location = context.watch<SessionProvider>().location;
    final results = provider.filteredIn(location);
    final departments = location == null
        ? <String>[]
        : catalogDepartments(location.country);
    final selectedDepartment =
        provider.departmentFilter ?? location?.department;
    final provinces = location == null || selectedDepartment == null
        ? <String>[]
        : catalogProvinces(location.country, selectedDepartment);

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 8, 0),
            child: Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Text(
                      'Buscar',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: AppColors.of(context).text,
                      ),
                    ),
                  ),
                ),
                const NotificationsBellButton(),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
            child: TextField(
              controller: _controller,
              onChanged: provider.setQuery,
              decoration: const InputDecoration(
                hintText: 'Buscar doctor, departamento, provincia o ciudad',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: const Text('Todas'),
                    selected: provider.specialtyFilter == null,
                    selectedColor: AppColors.of(context).primarySoft,
                    onSelected: (_) => provider.setSpecialtyFilter(null),
                  ),
                ),
                for (final specialty in allCategories)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(specialty),
                      selected: provider.specialtyFilter == specialty,
                      selectedColor: AppColors.of(context).primarySoft,
                      onSelected: (selected) {
                        provider.setSpecialtyFilter(selected ? specialty : null);
                      },
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          if (departments.isNotEmpty)
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: const Text('Todo el país'),
                      selected: provider.departmentFilter == null,
                      selectedColor: AppColors.of(context).primarySoft,
                      onSelected: (_) => provider.setDepartmentFilter(null),
                    ),
                  ),
                  for (final department in departments)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(department),
                        selected: provider.departmentFilter == department,
                        selectedColor: AppColors.of(context).primarySoft,
                        onSelected: (selected) {
                          provider.setDepartmentFilter(
                            selected ? department : null,
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          if (provinces.isNotEmpty)
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: const Text('Toda provincia'),
                      selected: provider.provinceFilter == null,
                      selectedColor: AppColors.of(context).primarySoft,
                      onSelected: (_) => provider.setProvinceFilter(null),
                    ),
                  ),
                  for (final province in provinces)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(province),
                        selected: provider.provinceFilter == province,
                        selectedColor: AppColors.of(context).primarySoft,
                        onSelected: (selected) {
                          provider.setProvinceFilter(
                            selected ? province : null,
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          Expanded(
            child: results.isEmpty
                ? const Center(child: Text('No hay resultados'))
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    itemCount: results.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final doctor = results[index];
                      return DoctorResultCard(
                        doctor: doctor,
                        isFavorite: provider.isFavorite(doctor.id),
                        onFavorite: () => provider.toggleFavorite(doctor.id),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  DoctorProfileScreen(doctorId: doctor.id),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/doctors_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/doctor_result_card.dart';
import '../widgets/notifications_bell_button.dart';
import 'doctor_profile_screen.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DoctorsProvider>();
    final favorites = provider.favorites;

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
            child: Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Text(
                      'Favoritos',
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
          Expanded(
            child: favorites.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.favorite_border,
                          size: 48,
                          color: AppColors.danger,
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Marca un doctor con el corazón para verlo aquí.',
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    itemCount: favorites.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final doctor = favorites[index];
                      return DoctorResultCard(
                        doctor: doctor,
                        isFavorite: true,
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

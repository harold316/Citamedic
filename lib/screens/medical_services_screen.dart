import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../data/specialty_icons.dart';
import '../widgets/notifications_bell_button.dart';
import '../widgets/specialty_card.dart';
import 'specialists_screen.dart';

class MedicalServicesScreen extends StatelessWidget {
  const MedicalServicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Servicios médicos'),
        actions: const [NotificationsBellButton()],
      ),
      body: GridView.builder(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.15,
        ),
        itemCount: medicalServices.length,
        itemBuilder: (context, index) {
          final service = medicalServices[index];
          return SpecialtyCard(
            title: service,
            icon: specialtyIcons[service] ?? Icons.medical_services,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SpecialistsScreen(specialty: service),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import 'doctor_home_screen.dart';

class DoctorPanelScreen extends StatelessWidget {
  const DoctorPanelScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (!auth.isDoctor) {
      return Scaffold(
        appBar: AppBar(title: const Text('Panel médico')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Esta sección es solo para médicos. Como paciente puedes ver las tarjetas, pero no cambiarlas.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.of(context).muted),
            ),
          ),
        ),
      );
    }

    return const DoctorHomeScreen();
  }
}

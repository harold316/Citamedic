import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/appointments_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/clinics_provider.dart';
import '../providers/doctors_provider.dart';
import '../providers/session_provider.dart';
import '../providers/shell_tab_provider.dart';
import '../services/push_notifications.dart';
import '../theme/app_theme.dart';
import 'admin_dashboard_screen.dart';
import 'clinic_home_screen.dart';
import 'doctor_home_screen.dart';
import 'login_screen.dart';
import 'main_shell.dart';
import 'welcome_screen.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  String? _syncedKey;

  void _syncSession(AuthProvider auth) {
    final appointments = context.read<AppointmentsProvider>();
    if (!auth.isLoggedIn) {
      if (_syncedKey == 'out') {
        return;
      }
      _syncedKey = 'out';
      appointments.stop();
      final session = context.read<SessionProvider>();
      if (session.location != null || session.patient != null) {
        session.clear();
      }
      return;
    }

    final key = '${auth.uid}|${auth.role.id}|${auth.isGuest}';
    if (_syncedKey == key || !auth.roleReady) {
      return;
    }
    _syncedKey = key;

    if (auth.isAdmin) {
      unawaited(appointments.loadAll());
    } else if (!auth.isClinic && auth.uid.isNotEmpty) {
      appointments.watch(uid: auth.uid, asDoctor: auth.isDoctor);
    } else {
      appointments.stop();
    }

    unawaited(
      context.read<DoctorsProvider>().refreshIfNeeded(
        includeUnpublished: auth.isAdmin,
        alsoUid: auth.isDoctor ? auth.uid : null,
      ),
    );
    unawaited(
      context.read<ClinicsProvider>().refreshIfNeeded(
        includeUnpublished: auth.isAdmin,
        alsoUid: auth.isClinic ? auth.uid : null,
      ),
    );
    PushNotifications.instance.consumeLaunch(context.read<ShellTabProvider>());
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final session = context.watch<SessionProvider>();

    if (auth.isBooting) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _syncSession(auth);
      }
    });

    if (!auth.isLoggedIn) {
      return const LoginScreen();
    }

    if (!auth.roleReady) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (auth.isAdmin) {
      return const AdminDashboardScreen();
    }

    if (auth.isDoctor) {
      return const DoctorHomeScreen();
    }

    if (auth.isClinic) {
      return const ClinicHomeScreen();
    }

    if (session.location == null) {
      return const WelcomeScreen();
    }
    return const MainShell();
  }
}

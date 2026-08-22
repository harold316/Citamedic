import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/appointments_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/session_provider.dart';
import '../providers/shell_tab_provider.dart';
import '../services/in_app_messaging.dart';
import '../services/push_notifications.dart';
import '../theme/app_theme.dart';
import 'admin_dashboard_screen.dart';
import 'clinic_home_screen.dart';
import 'doctor_home_screen.dart';
import 'login_screen.dart';
import 'main_shell.dart';
import 'welcome_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final session = context.watch<SessionProvider>();
    final appointments = context.read<AppointmentsProvider>();

    if (auth.isBooting) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (!auth.isLoggedIn) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) {
          return;
        }
        appointments.stop();
        if (session.location != null || session.patient != null) {
          context.read<SessionProvider>().clear();
        }
      });
      return const LoginScreen();
    }

    if (!auth.roleReady) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) {
        return;
      }
      if (auth.isAdmin) {
        appointments.watchAll();
      } else {
        appointments.watch(uid: auth.uid, asDoctor: auth.isDoctor);
      }
      PushNotifications.instance.consumeLaunch(
        context.read<ShellTabProvider>(),
      );
      if (auth.isAdmin) {
        unawaited(
          InAppMessagingService.instance.trigger('admin_home', once: true),
        );
      } else if (auth.isDoctor) {
        unawaited(
          InAppMessagingService.instance.trigger('doctor_home', once: true),
        );
      } else if (auth.isClinic) {
        unawaited(
          InAppMessagingService.instance.trigger('clinic_home', once: true),
        );
      } else if (auth.isGuest) {
        unawaited(
          InAppMessagingService.instance.trigger('guest_session', once: true),
        );
      } else {
        unawaited(
          InAppMessagingService.instance.trigger('patient_home', once: true),
        );
      }
    });

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

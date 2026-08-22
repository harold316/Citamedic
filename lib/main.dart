import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'providers/appointments_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/clinics_provider.dart';
import 'providers/doctors_provider.dart';
import 'providers/notifications_provider.dart';
import 'providers/session_provider.dart';
import 'providers/shell_tab_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/auth_gate.dart';
import 'services/in_app_messaging.dart';
import 'services/push_notifications.dart';
import 'theme/app_theme.dart';
import 'widgets/app_navigator.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es');
  Intl.defaultLocale = 'es';
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    await PushNotifications.instance.start();
    await InAppMessagingService.instance.start();
  } catch (error, stack) {
    debugPrint('Firebase no se pudo inicializar: $error\n$stack');
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) {
            final doctors = DoctorsProvider();
            doctors.start();
            return doctors;
          },
        ),
        ChangeNotifierProvider(
          create: (_) {
            final clinics = ClinicsProvider();
            clinics.start();
            return clinics;
          },
        ),
        ChangeNotifierProvider(create: (_) => AppointmentsProvider()),
        ChangeNotifierProvider(create: (_) => NotificationsProvider()),
        ChangeNotifierProvider(
          create: (_) {
            final tabs = ShellTabProvider();
            PushNotifications.instance.attachTabs(tabs);
            return tabs;
          },
        ),
        ChangeNotifierProvider(create: (_) => SessionProvider()),
        ChangeNotifierProvider(
          create: (_) {
            final auth = AuthProvider();
            auth.start();
            return auth;
          },
        ),
        ChangeNotifierProvider(
          create: (_) {
            final theme = ThemeProvider();
            theme.load();
            return theme;
          },
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, theme, _) {
          return MaterialApp(
            navigatorKey: AppNavigator.key,
            title: 'CitaMedic',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: theme.mode,
            builder: (context, child) {
              final brightness = Theme.of(context).brightness;
              return AnnotatedRegion<SystemUiOverlayStyle>(
                value: brightness == Brightness.dark
                    ? SystemUiOverlayStyle.light
                    : SystemUiOverlayStyle.dark,
                child: child ?? const SizedBox.shrink(),
              );
            },
            locale: const Locale('es'),
            supportedLocales: const [Locale('es')],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: const AuthGate(),
          );
        },
      ),
    );
  }
}

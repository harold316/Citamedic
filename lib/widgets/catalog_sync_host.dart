import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/clinics_provider.dart';
import '../providers/doctors_provider.dart';

class CatalogSyncHost extends StatefulWidget {
  const CatalogSyncHost({super.key, required this.child});

  final Widget child;

  @override
  State<CatalogSyncHost> createState() => _CatalogSyncHostState();
}

class _CatalogSyncHostState extends State<CatalogSyncHost>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed || !mounted) {
      return;
    }
    _syncCatalogs();
  }

  void _syncCatalogs() {
    final auth = context.read<AuthProvider>();
    if (!auth.isLoggedIn) {
      return;
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
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';

bool blockGuestBooking(BuildContext context) {
  if (!context.read<AuthProvider>().isGuest) {
    return false;
  }
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text(
        'En modo invitado solo puedes ver. Crea una cuenta o inicia sesión para agendar citas.',
      ),
    ),
  );
  return true;
}

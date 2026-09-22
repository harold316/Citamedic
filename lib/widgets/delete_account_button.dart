import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/session_provider.dart';
import '../theme/app_theme.dart';

class DeleteAccountButton extends StatefulWidget {
  const DeleteAccountButton({
    super.key,
    this.onBeforeDelete,
  });

  final Future<void> Function()? onBeforeDelete;

  @override
  State<DeleteAccountButton> createState() => _DeleteAccountButtonState();
}

class _DeleteAccountButtonState extends State<DeleteAccountButton> {
  bool _working = false;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: _working ? null : _confirm,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.danger,
      ),
      icon: const Icon(Icons.delete_outline),
      label: Text(_working ? 'Eliminando...' : 'Eliminar cuenta'),
    );
  }

  Future<void> _confirm() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Eliminar cuenta'),
          content: const Text(
            'Se borrará tu cuenta, tu perfil y tus citas. Esta acción no se puede deshacer.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: AppColors.danger),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !mounted) {
      return;
    }

    final auth = context.read<AuthProvider>();
    setState(() => _working = true);
    try {
      await widget.onBeforeDelete?.call();
      if (!mounted) return;
      context.read<SessionProvider>().clear();
      await auth.deleteOwnAccount();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(auth.messageFor(error))),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _working = false);
      }
    }
  }
}

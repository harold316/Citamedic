import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/app_notification.dart';
import '../providers/notifications_provider.dart';
import '../providers/shell_tab_provider.dart';
import '../theme/app_theme.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      context.read<NotificationsProvider>().markAllRead();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final items = context.watch<NotificationsProvider>().items;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificaciones'),
        actions: [
          if (items.isNotEmpty)
            IconButton(
              tooltip: 'Borrar todas',
              onPressed: () => context.read<NotificationsProvider>().clear(),
              icon: const Icon(Icons.delete_outline),
            ),
        ],
      ),
      body: items.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.notifications_none_rounded,
                      size: 56,
                      color: AppColors.primary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No tienes notificaciones',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                        color: colors.text,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Aquí verás citas nuevas, avisos de perfiles y mensajes de CitaMedic.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: colors.muted, height: 1.35),
                    ),
                  ],
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                return _NotificationTile(notification: items[index]);
              },
            ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.notification});

  final AppNotification notification;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final time = DateFormat('d MMM, HH:mm', 'es').format(notification.createdAt);
    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () {
          if (notification.type == 'appointment' && context.mounted) {
            context.read<ShellTabProvider>().goTo(3);
            Navigator.pop(context);
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  notification.type == 'appointment'
                      ? Icons.event_available_outlined
                      : Icons.notifications_none_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: colors.text,
                      ),
                    ),
                    if (notification.body.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        notification.body,
                        style: TextStyle(color: colors.muted, height: 1.35),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Text(
                      time,
                      style: TextStyle(color: colors.muted, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

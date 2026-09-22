import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/notifications_provider.dart';
import '../screens/notifications_screen.dart';
import '../theme/app_theme.dart';

class NotificationsBellButton extends StatelessWidget {
  const NotificationsBellButton({super.key});

  @override
  Widget build(BuildContext context) {
    final unread = context.watch<NotificationsProvider>().unreadCount;
    return IconButton(
      tooltip: 'Notificaciones',
      visualDensity: VisualDensity.compact,
      style: IconButton.styleFrom(
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        minimumSize: const Size(40, 40),
        padding: const EdgeInsets.all(6),
      ),
      onPressed: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const NotificationsScreen(),
          ),
        );
      },
      icon: Badge(
        isLabelVisible: unread > 0,
        backgroundColor: AppColors.danger,
        textColor: Colors.white,
        label: Text(unread > 9 ? '9+' : '$unread'),
        child: const Icon(
          Icons.notifications_none_rounded,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

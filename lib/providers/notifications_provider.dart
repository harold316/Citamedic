import 'package:flutter/foundation.dart';

import '../models/app_notification.dart';
import '../services/push_notifications.dart';

class NotificationsProvider extends ChangeNotifier {
  NotificationsProvider() {
    PushNotifications.instance.onInboxMessage = addFromPush;
  }

  final List<AppNotification> _items = [];

  List<AppNotification> get items => List.unmodifiable(_items);

  int get unreadCount => _items.where((item) => !item.read).length;

  void addFromPush(String title, String body, String? type) {
    add(title: title, body: body, type: type);
  }

  void add({
    required String title,
    required String body,
    String? type,
  }) {
    final trimmedTitle = title.trim();
    final trimmedBody = body.trim();
    if (trimmedTitle.isEmpty && trimmedBody.isEmpty) {
      return;
    }
    _items.insert(
      0,
      AppNotification(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        title: trimmedTitle.isEmpty ? 'CitaMedic' : trimmedTitle,
        body: trimmedBody,
        createdAt: DateTime.now(),
        type: type,
      ),
    );
    if (_items.length > 50) {
      _items.removeRange(50, _items.length);
    }
    notifyListeners();
  }

  void markAllRead() {
    if (unreadCount == 0) {
      return;
    }
    for (var i = 0; i < _items.length; i++) {
      if (!_items[i].read) {
        _items[i] = _items[i].copyWith(read: true);
      }
    }
    notifyListeners();
  }

  void clear() {
    if (_items.isEmpty) {
      return;
    }
    _items.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    if (identical(PushNotifications.instance.onInboxMessage, addFromPush)) {
      PushNotifications.instance.onInboxMessage = null;
    }
    super.dispose();
  }
}

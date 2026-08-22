import 'package:flutter/foundation.dart';

class ShellTabProvider extends ChangeNotifier {
  int index = 0;

  void goTo(int value) {
    if (index == value) {
      return;
    }
    index = value;
    notifyListeners();
  }
}

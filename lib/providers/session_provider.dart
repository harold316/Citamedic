import 'package:flutter/foundation.dart';

import '../models/patient.dart';
import '../models/user_location.dart';

class SessionProvider extends ChangeNotifier {
  Patient? patient;
  UserLocation? location;
  final List<UserLocation> _favoriteLocations = [];

  bool get isReady => patient != null && location != null;

  String get firstName => patient?.name.split(' ').first ?? 'Usuario';

  List<UserLocation> get favoriteLocations =>
      List.unmodifiable(_favoriteLocations);

  bool isFavoriteLocation(UserLocation value) {
    return _favoriteLocations.contains(value);
  }

  void enter({
    required String name,
    required UserLocation location,
    String email = '',
    String phone = '',
  }) {
    patient = Patient(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name.trim(),
      email: email.trim(),
      phone: phone.trim(),
      password: '',
    );
    this.location = location;
    _addFavorite(location);
    notifyListeners();
  }

  void clear() {
    patient = null;
    location = null;
    _favoriteLocations.clear();
    notifyListeners();
  }

  void updateLocation(UserLocation value) {
    location = value;
    notifyListeners();
  }

  void toggleFavoriteLocation(UserLocation value) {
    if (!_favoriteLocations.remove(value)) {
      _favoriteLocations.add(value);
    }
    notifyListeners();
  }

  void _addFavorite(UserLocation value) {
    if (!_favoriteLocations.contains(value)) {
      _favoriteLocations.add(value);
    }
  }
}

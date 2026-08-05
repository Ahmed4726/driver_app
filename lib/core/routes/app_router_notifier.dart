import 'package:flutter/foundation.dart';

class AppRouterNotifier extends ChangeNotifier {
  bool _loggedIn = false;

  bool get loggedIn => _loggedIn;

  void setLoggedIn(bool value) {
    if (_loggedIn == value) return;

    _loggedIn = value;

    notifyListeners();
  }
}
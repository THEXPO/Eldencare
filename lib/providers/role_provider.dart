import 'package:flutter/foundation.dart';

import '../models/enums.dart';

/// Demo-only role switch. This is not authentication or access control.
class RoleProvider extends ChangeNotifier {
  AppRole? _role;

  AppRole? get role => _role;

  bool get hasRole => _role != null;

  void select(AppRole role) {
    _role = role;
    notifyListeners();
  }

  void clear() {
    _role = null;
    notifyListeners();
  }
}

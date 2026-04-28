import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:guardgrey/features/auth/models/app_role.dart';
import 'package:guardgrey/features/auth/screens/login_screen.dart';
import 'package:guardgrey/features/auth/services/auth_role_service.dart';
import 'package:guardgrey/modules/admin/navigation/screens/main_navigation_screen.dart';
import 'package:guardgrey/modules/manager/navigation/screens/manager_navigation_screen.dart';

class RouteGuard {
  RouteGuard._();

  static Widget requireSignedIn(Widget child) {
    if (FirebaseAuth.instance.currentUser == null) {
      return const LoginScreen();
    }
    return child;
  }

  static Widget homeForRole(AppRole role) {
    switch (role) {
      case AppRole.manager:
        return const ManagerNavigationScreen();
      case AppRole.admin:
        return const AdminNavigationScreen();
    }
  }

  static Future<AppRole> resolveRole(User user) {
    return AuthRoleService.instance.resolveRole(user);
  }
}

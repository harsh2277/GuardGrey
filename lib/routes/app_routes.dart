import 'package:flutter/material.dart';

import '../modules/admin/screens/branches_screen.dart';
import '../modules/admin/screens/login_screen.dart';
import '../modules/admin/screens/profile_screen.dart';
import '../screens/main_navigation.dart';
import '../screens/more/managers_list_screen.dart';
import '../screens/more/notifications_screen.dart';
import '../screens/more/reports_screen.dart';
import '../screens/more/settings_screen.dart';

class AppRoutes {
  AppRoutes._();

  static const String login = '/';
  static const String main = '/main';
  static const String managers = '/more/managers';
  static const String branches = '/more/branches';
  static const String reports = '/more/reports';
  static const String profile = '/more/profile';
  static const String settings = '/more/settings';
  static const String notifications = '/more/notifications';

  static Route<dynamic> onGenerateRoute(RouteSettings routeSettings) {
    switch (routeSettings.name) {
      case login:
        return MaterialPageRoute<void>(
          builder: (_) => const LoginScreen(),
          settings: routeSettings,
        );
      case main:
        return MaterialPageRoute<void>(
          builder: (_) => const MainNavigation(),
          settings: routeSettings,
        );
      case managers:
        return MaterialPageRoute<void>(
          builder: (_) => const ManagersListScreen(),
          settings: routeSettings,
        );
      case branches:
        return MaterialPageRoute<void>(
          builder: (_) => const BranchesScreen(),
          settings: routeSettings,
        );
      case reports:
        return MaterialPageRoute<void>(
          builder: (_) => const ReportsScreen(),
          settings: routeSettings,
        );
      case profile:
        return MaterialPageRoute<void>(
          builder: (_) => const ProfileScreen(),
          settings: routeSettings,
        );
      case settings:
        return MaterialPageRoute<void>(
          builder: (_) => const SettingsScreen(),
          settings: routeSettings,
        );
      case notifications:
        return MaterialPageRoute<void>(
          builder: (_) => const NotificationsScreen(),
          settings: routeSettings,
        );
      default:
        return MaterialPageRoute<void>(
          builder: (_) => const LoginScreen(),
          settings: routeSettings,
        );
    }
  }
}

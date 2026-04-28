import 'package:flutter/material.dart';

import 'package:guardgrey/features/auth/screens/auth_gate_screen.dart';
import 'package:guardgrey/features/auth/screens/login_screen.dart';
import 'package:guardgrey/features/auth/screens/onboarding_screen.dart';
import 'package:guardgrey/features/auth/screens/splash_screen.dart';
import 'package:guardgrey/features/notifications/screens/notifications_screen.dart';
import 'package:guardgrey/modules/admin/branches/screens/branches_screen.dart';
import 'package:guardgrey/modules/admin/managers/screens/managers_list_screen.dart';
import 'package:guardgrey/modules/admin/navigation/screens/main_navigation_screen.dart';
import 'package:guardgrey/modules/admin/profile/screens/profile_screen.dart';
import 'package:guardgrey/modules/admin/reports/screens/reports_screen.dart';
import 'package:guardgrey/modules/admin/settings/screens/settings_screen.dart';
import 'package:guardgrey/modules/manager/navigation/screens/manager_navigation_screen.dart';
import 'package:guardgrey/modules/manager/notifications/screens/manager_notifications_screen.dart';
import 'package:guardgrey/modules/manager/visits/screens/manager_visits_screen.dart';
import 'package:guardgrey/routes/route_guard.dart';

class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String authGate = '/auth-gate';
  static const String login = '/login';

  static const String adminMain = '/admin';
  static const String adminManagers = '/admin/managers';
  static const String adminBranches = '/admin/branches';
  static const String adminReports = '/admin/reports';
  static const String adminProfile = '/admin/profile';
  static const String adminSettings = '/admin/settings';
  static const String adminNotifications = '/admin/notifications';

  static const String managerMain = '/manager';
  static const String managerNotifications = '/manager/notifications';
  static const String managerVisits = '/manager/visits';

  static Route<dynamic> onGenerateRoute(RouteSettings routeSettings) {
    switch (routeSettings.name) {
      case splash:
        return MaterialPageRoute<void>(
          builder: (_) => const SplashScreen(),
          settings: routeSettings,
        );
      case onboarding:
        return MaterialPageRoute<void>(
          builder: (_) => const OnboardingScreen(),
          settings: routeSettings,
        );
      case authGate:
        return MaterialPageRoute<void>(
          builder: (_) => const AuthGateScreen(),
          settings: routeSettings,
        );
      case login:
        return MaterialPageRoute<void>(
          builder: (_) => const LoginScreen(),
          settings: routeSettings,
        );
      case adminMain:
        return MaterialPageRoute<void>(
          builder: (_) =>
              RouteGuard.requireSignedIn(const AdminNavigationScreen()),
          settings: routeSettings,
        );
      case adminManagers:
        return MaterialPageRoute<void>(
          builder: (_) =>
              RouteGuard.requireSignedIn(const ManagersListScreen()),
          settings: routeSettings,
        );
      case adminBranches:
        return MaterialPageRoute<void>(
          builder: (_) => RouteGuard.requireSignedIn(const BranchesScreen()),
          settings: routeSettings,
        );
      case adminReports:
        return MaterialPageRoute<void>(
          builder: (_) => RouteGuard.requireSignedIn(const ReportsScreen()),
          settings: routeSettings,
        );
      case adminProfile:
        return MaterialPageRoute<void>(
          builder: (_) => RouteGuard.requireSignedIn(const ProfileScreen()),
          settings: routeSettings,
        );
      case adminSettings:
        return MaterialPageRoute<void>(
          builder: (_) => RouteGuard.requireSignedIn(const SettingsScreen()),
          settings: routeSettings,
        );
      case adminNotifications:
        return MaterialPageRoute<void>(
          builder: (_) =>
              RouteGuard.requireSignedIn(const NotificationsScreen()),
          settings: routeSettings,
        );
      case managerMain:
        return MaterialPageRoute<void>(
          builder: (_) =>
              RouteGuard.requireSignedIn(const ManagerNavigationScreen()),
          settings: routeSettings,
        );
      case managerNotifications:
        return MaterialPageRoute<void>(
          builder: (_) =>
              RouteGuard.requireSignedIn(const ManagerNotificationsScreen()),
          settings: routeSettings,
        );
      case managerVisits:
        return MaterialPageRoute<void>(
          builder: (_) =>
              RouteGuard.requireSignedIn(const ManagerVisitsScreen()),
          settings: routeSettings,
        );
      default:
        return MaterialPageRoute<void>(
          builder: (_) => const SplashScreen(),
          settings: routeSettings,
        );
    }
  }
}

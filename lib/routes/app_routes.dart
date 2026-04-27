import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../modules/admin/screens/branches_screen.dart';
import '../modules/admin/screens/auth_gate_screen.dart';
import '../modules/admin/screens/login_screen.dart';
import '../modules/admin/screens/onboarding_screen.dart';
import '../modules/admin/screens/profile_screen.dart';
import '../modules/admin/screens/splash_screen.dart';
import '../screens/main_navigation.dart';
import '../screens/more/managers_list_screen.dart';
import '../screens/more/notifications_screen.dart';
import '../screens/more/reports_screen.dart';
import '../screens/more/settings_screen.dart';

class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String authGate = '/auth-gate';
  static const String login = '/login';
  static const String main = '/main';
  static const String managers = '/more/managers';
  static const String branches = '/more/branches';
  static const String reports = '/more/reports';
  static const String profile = '/more/profile';
  static const String settings = '/more/settings';
  static const String notifications = '/more/notifications';

  static Widget _guardedScreen(Widget child) {
    if (FirebaseAuth.instance.currentUser == null) {
      return const LoginScreen();
    }
    return child;
  }

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
      case main:
        return MaterialPageRoute<void>(
          builder: (_) => _guardedScreen(const MainNavigation()),
          settings: routeSettings,
        );
      case managers:
        return MaterialPageRoute<void>(
          builder: (_) => _guardedScreen(const ManagersListScreen()),
          settings: routeSettings,
        );
      case branches:
        return MaterialPageRoute<void>(
          builder: (_) => _guardedScreen(const BranchesScreen()),
          settings: routeSettings,
        );
      case reports:
        return MaterialPageRoute<void>(
          builder: (_) => _guardedScreen(const ReportsScreen()),
          settings: routeSettings,
        );
      case profile:
        return MaterialPageRoute<void>(
          builder: (_) => _guardedScreen(const ProfileScreen()),
          settings: routeSettings,
        );
      case settings:
        return MaterialPageRoute<void>(
          builder: (_) => _guardedScreen(const SettingsScreen()),
          settings: routeSettings,
        );
      case notifications:
        return MaterialPageRoute<void>(
          builder: (_) => _guardedScreen(const NotificationsScreen()),
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

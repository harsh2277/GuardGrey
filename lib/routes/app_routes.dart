import 'package:flutter/material.dart';

import 'package:guardgrey/features/auth/screens/auth_gate_screen.dart';
import 'package:guardgrey/features/auth/screens/login_screen.dart';
import 'package:guardgrey/features/notifications/screens/notifications_screen.dart';
import 'package:guardgrey/modules/admin/branches/screens/branches_screen.dart';
import 'package:guardgrey/modules/admin/clients/screens/clients_screen.dart';
import 'package:guardgrey/modules/admin/live_tracking/screens/live_tracking_screen.dart';
import 'package:guardgrey/modules/admin/leave/screens/admin_leave_screen.dart';
import 'package:guardgrey/modules/admin/managers/screens/managers_list_screen.dart';
import 'package:guardgrey/modules/admin/navigation/screens/main_navigation_screen.dart';
import 'package:guardgrey/modules/admin/profile/screens/profile_screen.dart';
import 'package:guardgrey/modules/admin/reports/screens/reports_screen.dart';
import 'package:guardgrey/modules/admin/settings/screens/settings_screen.dart';
import 'package:guardgrey/modules/manager/field_visits/screens/field_visit_list_screen.dart';
import 'package:guardgrey/modules/manager/field_visits/screens/manager_field_visit_screen.dart';
import 'package:guardgrey/modules/manager/navigation/screens/manager_navigation_screen.dart';
import 'package:guardgrey/modules/manager/visits/screens/manager_visits_screen.dart';
import 'package:guardgrey/routes/route_guard.dart';

class AppRoutes {
  AppRoutes._();

  static const String authGate = '/';
  static const String login = '/login';

  static const String adminMain = '/admin';
  static const String adminManagers = '/admin/managers';
  static const String adminBranches = '/admin/branches';
  static const String adminClients = '/admin/clients';
  static const String adminReports = '/admin/reports';
  static const String adminLeaves = '/admin/leaves';
  static const String adminFieldVisits = '/field-visits';
  static const String adminLiveTracking = '/admin/live-tracking';
  static const String adminProfile = '/admin/profile';
  static const String adminSettings = '/admin/settings';
  static const String adminNotifications = '/admin/notifications';

  static const String managerMain = '/manager';
  static const String managerVisits = '/manager/visits';
  static const String managerFieldVisits = '/manager/field-visits';

  static Route<dynamic> onGenerateRoute(RouteSettings routeSettings) {
    switch (routeSettings.name) {
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
      case adminClients:
        return MaterialPageRoute<void>(
          builder: (_) => RouteGuard.requireSignedIn(const ClientsScreen()),
          settings: routeSettings,
        );
      case adminReports:
        return MaterialPageRoute<void>(
          builder: (_) => RouteGuard.requireSignedIn(const ReportsScreen()),
          settings: routeSettings,
        );
      case adminLeaves:
        return MaterialPageRoute<void>(
          builder: (_) => RouteGuard.requireSignedIn(const AdminLeaveScreen()),
          settings: routeSettings,
        );
      case adminFieldVisits:
        return MaterialPageRoute<void>(
          builder: (_) =>
              RouteGuard.requireSignedIn(const FieldVisitListScreen()),
          settings: routeSettings,
        );
      case adminLiveTracking:
        return MaterialPageRoute<void>(
          builder: (_) =>
              RouteGuard.requireSignedIn(const LiveTrackingScreen()),
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
      case managerVisits:
        return MaterialPageRoute<void>(
          builder: (_) =>
              RouteGuard.requireSignedIn(const ManagerVisitsScreen()),
          settings: routeSettings,
        );
      case managerFieldVisits:
        return MaterialPageRoute<void>(
          builder: (_) =>
              RouteGuard.requireSignedIn(const ManagerFieldVisitScreen()),
          settings: routeSettings,
        );
      default:
        return MaterialPageRoute<void>(
          builder: (_) => const AuthGateScreen(),
          settings: routeSettings,
        );
    }
  }
}

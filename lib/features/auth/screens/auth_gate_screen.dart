import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:guardgrey/core/theme/app_colors.dart';
import 'package:guardgrey/core/theme/app_text_styles.dart';
import 'package:guardgrey/features/auth/models/app_role.dart';
import 'package:guardgrey/features/notifications/services/notification_module.dart';
import 'package:guardgrey/features/permissions/services/permission_service.dart';
import 'package:guardgrey/modules/manager/common/services/manager_live_location_sync_service.dart';
import 'package:guardgrey/modules/manager/common/services/manager_session_service.dart';
import 'package:guardgrey/routes/route_guard.dart';
import 'login_screen.dart';

class AuthGateScreen extends StatelessWidget {
  const AuthGateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          debugPrint('Auth state error: ${snapshot.error}');
          return Scaffold(
            backgroundColor: AppColors.backgroundLight,
            body: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'Unable to verify login state.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.neutral500,
                  ),
                ),
              ),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: AppColors.backgroundLight,
            body: Center(
              child: CircularProgressIndicator(color: AppColors.primary600),
            ),
          );
        }

        if (snapshot.hasData) {
          return FutureBuilder<AppRole>(
            future: RouteGuard.resolveRole(snapshot.data!),
            builder: (context, roleSnapshot) {
              if (roleSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  backgroundColor: AppColors.backgroundLight,
                  body: Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primary600,
                    ),
                  ),
                );
              }

              if (roleSnapshot.hasError) {
                return Scaffold(
                  backgroundColor: AppColors.backgroundLight,
                  body: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        'Unable to resolve the account role. Please sign in again.',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: AppColors.neutral500,
                        ),
                      ),
                    ),
                  ),
                );
              }

              final role = roleSnapshot.data;
              if (role == null) {
                return const Scaffold(
                  backgroundColor: AppColors.backgroundLight,
                  body: Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primary600,
                    ),
                  ),
                );
              }

              return _AppBootstrap(
                role: role,
                child: RouteGuard.homeForRole(role),
              );
            },
          );
        }

        return const LoginScreen();
      },
    );
  }
}

class _AppBootstrap extends StatefulWidget {
  const _AppBootstrap({required this.role, required this.child});

  final AppRole role;
  final Widget child;

  @override
  State<_AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends State<_AppBootstrap>
    with WidgetsBindingObserver {
  bool _handledPermissions = false;
  bool _isSyncingManagerLocation = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_handledPermissions) {
      return;
    }
    _handledPermissions = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) {
        return;
      }
      await PermissionService.instance.handleAppPermissions(context);
      await NotificationModule.pushNotificationService
          .syncPushNotificationState();
      await _syncManagerLocationIfNeeded();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) {
        return;
      }
      await NotificationModule.pushNotificationService
          .syncPushNotificationState();
      await _syncManagerLocationIfNeeded();
    });
  }

  Future<void> _syncManagerLocationIfNeeded() async {
    if (widget.role != AppRole.manager || _isSyncingManagerLocation) {
      return;
    }

    _isSyncingManagerLocation = true;
    try {
      final manager = await ManagerSessionService.instance
          .fetchCurrentManager();
      if (manager == null) {
        return;
      }
      await ManagerLiveLocationSyncService.instance.syncCurrentManagerLocation(
        manager,
      );
    } catch (error) {
      debugPrint('Manager live location sync skipped: $error');
    } finally {
      _isSyncingManagerLocation = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

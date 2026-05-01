import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:guardgrey/core/theme/app_colors.dart';
import 'package:guardgrey/core/theme/app_text_styles.dart';
import 'package:guardgrey/features/auth/models/app_role.dart';
import 'package:guardgrey/features/permissions/services/permission_service.dart';
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

              return _PermissionBootstrap(child: RouteGuard.homeForRole(role));
            },
          );
        }

        return const LoginScreen();
      },
    );
  }
}

class _PermissionBootstrap extends StatefulWidget {
  const _PermissionBootstrap({required this.child});

  final Widget child;

  @override
  State<_PermissionBootstrap> createState() => _PermissionBootstrapState();
}

class _PermissionBootstrapState extends State<_PermissionBootstrap> {
  bool _handledPermissions = false;

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
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

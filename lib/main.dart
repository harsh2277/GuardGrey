import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:guardgrey/core/theme/app_theme.dart';
import 'package:guardgrey/features/notifications/services/notification_module.dart';
import 'package:guardgrey/firebase_options.dart';
import 'package:guardgrey/routes/app_routes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await NotificationModule.initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'GuardGrey',
      theme: AppTheme.lightTheme,
      themeMode: ThemeMode.light,
      initialRoute: AppRoutes.authGate,
      onGenerateRoute: AppRoutes.onGenerateRoute,
    );
  }
}

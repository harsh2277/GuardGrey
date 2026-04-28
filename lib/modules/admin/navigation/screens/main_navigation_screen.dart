import 'package:flutter/material.dart';

import 'package:guardgrey/core/theme/app_colors.dart';
import 'package:guardgrey/core/utils/filter_resettable.dart';
import 'package:guardgrey/core/widgets/bottom_nav_bar.dart';
import 'package:guardgrey/modules/admin/attendance/screens/attendance_screen.dart';
import 'package:guardgrey/modules/admin/clients/screens/clients_screen.dart';
import 'package:guardgrey/modules/admin/dashboard/screens/dashboard_screen.dart';
import 'package:guardgrey/modules/admin/settings/screens/more_screen.dart';
import 'package:guardgrey/modules/admin/sites/screens/sites_screen.dart';

class AdminNavigationScreen extends StatefulWidget {
  const AdminNavigationScreen({super.key});

  static void switchToTab(BuildContext context, int index) {
    final navigation = context
        .findAncestorStateOfType<_AdminNavigationScreenState>();
    navigation?.goToTab(index);
  }

  @override
  State<AdminNavigationScreen> createState() => _AdminNavigationScreenState();
}

class _AdminNavigationScreenState extends State<AdminNavigationScreen> {
  int _selectedIndex = 0;

  late final List<GlobalKey<State<StatefulWidget>>> _screenKeys =
      List<GlobalKey<State<StatefulWidget>>>.generate(
        5,
        (_) => GlobalKey<State<StatefulWidget>>(),
      );

  late final List<Widget> _screens = [
    DashboardScreen(key: _screenKeys[0]),
    SitesScreen(key: _screenKeys[1]),
    AttendanceScreen(key: _screenKeys[2]),
    ClientsScreen(key: _screenKeys[3]),
    MoreScreen(key: _screenKeys[4]),
  ];

  void _resetTabFilters(int index) {
    final state = _screenKeys[index].currentState;
    if (state is FilterResettable) {
      (state as FilterResettable).resetFilters();
    }
  }

  void _onItemTapped(int index) {
    if (_selectedIndex == index) {
      return;
    }

    _resetTabFilters(_selectedIndex);
    setState(() {
      _selectedIndex = index;
    });
  }

  void goToTab(int index) {
    _onItemTapped(index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      extendBody: false,
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: BottomNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}

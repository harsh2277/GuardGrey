import 'package:flutter/material.dart';

import 'package:guardgrey/core/theme/app_colors.dart';
import 'package:guardgrey/core/utils/filter_resettable.dart';
import 'package:guardgrey/core/widgets/bottom_nav_bar.dart';
import 'package:guardgrey/modules/manager/attendance/screens/manager_attendance_screen.dart';
import 'package:guardgrey/modules/manager/dashboard/screens/manager_dashboard_screen.dart';
import 'package:guardgrey/modules/manager/profile/screens/manager_profile_screen.dart';
import 'package:guardgrey/modules/manager/sites/screens/manager_sites_screen.dart';

class ManagerNavigationScreen extends StatefulWidget {
  const ManagerNavigationScreen({super.key});

  @override
  State<ManagerNavigationScreen> createState() =>
      _ManagerNavigationScreenState();
}

class _ManagerNavigationScreenState extends State<ManagerNavigationScreen> {
  int _selectedIndex = 0;

  late final List<GlobalKey<State<StatefulWidget>>> _screenKeys =
      List<GlobalKey<State<StatefulWidget>>>.generate(
        4,
        (_) => GlobalKey<State<StatefulWidget>>(),
      );

  late final List<Widget> _screens = [
    ManagerDashboardScreen(key: _screenKeys[0]),
    ManagerSitesScreen(key: _screenKeys[1]),
    ManagerAttendanceScreen(key: _screenKeys[2]),
    ManagerProfileScreen(key: _screenKeys[3]),
  ];

  void _resetTabFilters(int index) {
    final state = _screenKeys[index].currentState;
    if (state is FilterResettable) {
      final resettable = state as FilterResettable;
      resettable.resetFilters();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: BottomNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}

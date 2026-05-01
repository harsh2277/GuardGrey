import 'package:flutter/material.dart';

import 'package:guardgrey/core/theme/app_colors.dart';
import 'package:guardgrey/core/theme/app_text_styles.dart';
import 'package:guardgrey/modules/manager/attendance/screens/manager_attendance_screen.dart';
import 'package:guardgrey/modules/manager/dashboard/screens/manager_dashboard_screen.dart';
import 'package:guardgrey/modules/manager/more/screens/manager_more_screen.dart';
import 'package:guardgrey/modules/manager/sites/screens/manager_sites_screen.dart';
import 'package:guardgrey/modules/manager/visits/screens/manager_visits_screen.dart';

class ManagerNavigationScreen extends StatefulWidget {
  const ManagerNavigationScreen({super.key});

  @override
  State<ManagerNavigationScreen> createState() =>
      _ManagerNavigationScreenState();
}

class _ManagerNavigationScreenState extends State<ManagerNavigationScreen> {
  int _selectedIndex = 0;

  late final List<Widget> _screens = const [
    ManagerDashboardScreen(),
    ManagerSitesScreen(),
    ManagerVisitsScreen(),
    ManagerAttendanceScreen(),
    ManagerMoreScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: _ManagerBottomNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: (index) => setState(() => _selectedIndex = index),
      ),
    );
  }
}

class _ManagerBottomNavBar extends StatelessWidget {
  const _ManagerBottomNavBar({
    required this.selectedIndex,
    required this.onItemTapped,
  });

  final int selectedIndex;
  final ValueChanged<int> onItemTapped;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.neutral300, width: 1),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(34),
          topRight: Radius.circular(34),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 28,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          8,
          12,
          8,
          bottomInset > 0 ? bottomInset : 10,
        ),
        child: Row(
          children: [
            _ManagerNavItem(
              index: 0,
              selectedIndex: selectedIndex,
              onTap: onItemTapped,
              label: 'Dashboard',
              icon: Icons.dashboard_outlined,
              activeIcon: Icons.dashboard_rounded,
            ),
            _ManagerNavItem(
              index: 1,
              selectedIndex: selectedIndex,
              onTap: onItemTapped,
              label: 'Sites',
              icon: Icons.location_on_outlined,
              activeIcon: Icons.location_on_rounded,
            ),
            _ManagerNavItem(
              index: 2,
              selectedIndex: selectedIndex,
              onTap: onItemTapped,
              label: 'Visits',
              icon: Icons.route_outlined,
              activeIcon: Icons.route_rounded,
            ),
            _ManagerNavItem(
              index: 3,
              selectedIndex: selectedIndex,
              onTap: onItemTapped,
              label: 'Attendance',
              icon: Icons.fact_check_outlined,
              activeIcon: Icons.fact_check_rounded,
            ),
            _ManagerNavItem(
              index: 4,
              selectedIndex: selectedIndex,
              onTap: onItemTapped,
              label: 'More',
              icon: Icons.menu_rounded,
              activeIcon: Icons.menu_open_rounded,
            ),
          ].map((item) => Expanded(child: item)).toList(growable: false),
        ),
      ),
    );
  }
}

class _ManagerNavItem extends StatelessWidget {
  const _ManagerNavItem({
    required this.index,
    required this.selectedIndex,
    required this.onTap,
    required this.label,
    required this.icon,
    required this.activeIcon,
  });

  final int index;
  final int selectedIndex;
  final ValueChanged<int> onTap;
  final String label;
  final IconData icon;
  final IconData activeIcon;

  @override
  Widget build(BuildContext context) {
    final bool isSelected = selectedIndex == index;

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => onTap(index),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected ? AppColors.primary600 : AppColors.neutral500,
              size: 28,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodySmall.copyWith(
                fontSize: 12,
                color: isSelected ? AppColors.primary600 : AppColors.neutral500,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

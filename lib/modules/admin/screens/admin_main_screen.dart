import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import 'branches_screen.dart';
import 'dashboard_screen.dart';
import 'sites_screen.dart';
import 'managers_screen.dart';
import 'profile_screen.dart';

class AdminMainScreen extends StatefulWidget {
  const AdminMainScreen({super.key});

  @override
  State<AdminMainScreen> createState() => _AdminMainScreenState();
}

class _AdminMainScreenState extends State<AdminMainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const BranchesScreen(),
    const SitesScreen(),
    const ManagersScreen(),
    const ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      extendBody: true,
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildBottomNavigationBar() {
    return SafeArea(
      top: false,
      child: SizedBox(
        height: 130,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: AppColors.neutral300, width: 1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(34),
                    topRight: Radius.circular(34),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 28,
                      offset: const Offset(0, -6),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildNavItem(
                          index: 0,
                          label: 'Dashboard',
                          icon: Icons.dashboard_outlined,
                          activeIcon: Icons.dashboard_rounded,
                        ),
                      ),
                      Expanded(
                        child: _buildNavItem(
                          index: 1,
                          label: 'Branches',
                          icon: Icons.account_tree_outlined,
                          activeIcon: Icons.account_tree_rounded,
                        ),
                      ),
                      Expanded(
                        child: _buildNavItem(
                          index: 2,
                          label: 'Sites',
                          icon: Icons.location_on_outlined,
                          activeIcon: Icons.location_on_rounded,
                        ),
                      ),
                      Expanded(
                        child: _buildNavItem(
                          index: 3,
                          label: 'Managers',
                          icon: Icons.people_outline_rounded,
                          activeIcon: Icons.people_rounded,
                        ),
                      ),
                      Expanded(
                        child: _buildNavItem(
                          index: 4,
                          label: 'Profile',
                          icon: Icons.person_outline_rounded,
                          activeIcon: Icons.person_rounded,
                          useAvatar: true,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: -30,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(28),
                  onTap: () {},
                  child: Container(
                    height: 56,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    decoration: BoxDecoration(
                      color: AppColors.neutral900,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.16),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.fact_check_outlined,
                          color: Colors.white,
                          size: 22,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          "Today's Attendance",
                          style: AppTextStyles.bodyLarge.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required String label,
    required IconData icon,
    required IconData activeIcon,
    bool useAvatar = false,
  }) {
    final bool isSelected = _selectedIndex == index;
    final Color activeColor = AppColors.primary600;
    final Color inactiveColor = AppColors.neutral500;

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => _onItemTapped(index),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 1),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (useAvatar)
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary100
                      : AppColors.neutral100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isSelected ? activeIcon : icon,
                  color: isSelected ? activeColor : inactiveColor,
                  size: 20,
                ),
              )
            else
              Icon(
                isSelected ? activeIcon : icon,
                color: isSelected ? activeColor : inactiveColor,
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
                color: isSelected ? activeColor : inactiveColor,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import 'package:guardgrey/core/theme/app_colors.dart';
import 'package:guardgrey/core/theme/app_text_styles.dart';

class BottomNavBar extends StatelessWidget {
  const BottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
  });

  final int selectedIndex;
  final ValueChanged<int> onItemTapped;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.neutral800 : AppColors.neutral200,
            width: 1,
          ),
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(34),
          topRight: Radius.circular(34),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.06),
            blurRadius: 24,
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
            Expanded(
              child: _NavItem(
                index: 0,
                selectedIndex: selectedIndex,
                onTap: onItemTapped,
                label: 'Dashboard',
                icon: Icons.dashboard_outlined,
                activeIcon: Icons.dashboard_rounded,
              ),
            ),
            Expanded(
              child: _NavItem(
                index: 1,
                selectedIndex: selectedIndex,
                onTap: onItemTapped,
                label: 'Sites',
                icon: Icons.location_on_outlined,
                activeIcon: Icons.location_on_rounded,
              ),
            ),
            Expanded(
              child: _NavItem(
                index: 2,
                selectedIndex: selectedIndex,
                onTap: onItemTapped,
                label: 'Attendance',
                icon: Icons.fact_check_outlined,
                activeIcon: Icons.fact_check_rounded,
              ),
            ),
            Expanded(
              child: _NavItem(
                index: 3,
                selectedIndex: selectedIndex,
                onTap: onItemTapped,
                label: 'Reports',
                icon: Icons.assessment_outlined,
                activeIcon: Icons.assessment_rounded,
              ),
            ),
            Expanded(
              child: _NavItem(
                index: 4,
                selectedIndex: selectedIndex,
                onTap: onItemTapped,
                label: 'More',
                icon: Icons.menu_rounded,
                activeIcon: Icons.menu_open_rounded,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final Color activeColor = isDark ? AppColors.primary300 : AppColors.primary600;
    final Color inactiveColor = isDark ? AppColors.neutral400 : AppColors.neutral500;
    final Color pillColor = isDark 
        ? AppColors.primary300.withValues(alpha: 0.15) 
        : AppColors.primary500.withValues(alpha: 0.08);

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      splashColor: activeColor.withValues(alpha: 0.1),
      highlightColor: activeColor.withValues(alpha: 0.05),
      onTap: () => onTap(index),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? pillColor : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                isSelected ? activeIcon : icon,
                color: isSelected ? activeColor : inactiveColor,
                size: 24,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodySmall.copyWith(
                fontSize: 11,
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

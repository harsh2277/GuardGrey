import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';

class ActionBottomSheetItem {
  const ActionBottomSheetItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.textColor = AppColors.neutral900,
    this.iconColor = AppColors.neutral700,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color textColor;
  final Color iconColor;
}

class ActionBottomSheet {
  ActionBottomSheet._();

  static Future<void> show(
    BuildContext context, {
    required List<ActionBottomSheetItem> items,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return SafeArea(
          top: false,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (int index = 0; index < items.length; index++) ...[
                  _ActionSheetTile(
                    item: items[index],
                    onTap: () {
                      Navigator.pop(sheetContext);
                      items[index].onTap();
                    },
                  ),
                  if (index != items.length - 1) const SizedBox(height: 12),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ActionSheetTile extends StatelessWidget {
  const _ActionSheetTile({
    required this.item,
    required this.onTap,
  });

  final ActionBottomSheetItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.neutral50,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.neutral200),
          ),
          child: Row(
            children: [
              Icon(item.icon, size: 20, color: item.iconColor),
              const SizedBox(width: 12),
              Text(
                item.label,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: item.textColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

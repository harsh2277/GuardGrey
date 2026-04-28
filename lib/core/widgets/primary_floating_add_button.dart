import 'package:flutter/material.dart';

import 'package:guardgrey/core/theme/app_colors.dart';

class PrimaryFloatingAddButton extends StatelessWidget {
  const PrimaryFloatingAddButton({
    super.key,
    required this.onPressed,
    this.heroTag,
    this.icon = Icons.add_rounded,
    this.tooltip,
  });

  final VoidCallback onPressed;
  final Object? heroTag;
  final IconData icon;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8, bottom: 8),
      child: SizedBox(
        width: 64,
        height: 64,
        child: FloatingActionButton(
          onPressed: onPressed,
          heroTag: heroTag,
          tooltip: tooltip,
          backgroundColor: AppColors.primary500,
          foregroundColor: Colors.white,
          elevation: 6,
          highlightElevation: 8,
          shape: const CircleBorder(),
          child: Icon(icon, size: 30),
        ),
      ),
    );
  }
}

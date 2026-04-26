import 'package:flutter/material.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_colors.dart';

class ManagerDashboard extends StatelessWidget {
  const ManagerDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.neutral50,
      appBar: AppBar(
        title: Text('Manager Dashboard', style: AppTextStyles.title),
        backgroundColor: AppColors.backgroundLight,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.neutral900),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Shift Management',
              style: AppTextStyles.headingSmall,
            ),
            const SizedBox(height: 24),
            _buildActionCard(
              'Assigned Guards',
              'Currently 42 guards on duty.',
              Icons.people,
              AppColors.primary500,
            ),
            const SizedBox(height: 16),
            _buildActionCard(
              'Site Check-ins',
              '15 check-ins pending verification.',
              Icons.verified_user,
              AppColors.success,
            ),
            const SizedBox(height: 16),
            _buildActionCard(
              'Incident Logs',
              '2 incidents reported in the last 24h.',
              Icons.history_edu,
              AppColors.warning,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(String title, String subtitle, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.neutral200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600)),
                Text(subtitle, style: AppTextStyles.bodySmall),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.neutral400),
        ],
      ),
    );
  }
}

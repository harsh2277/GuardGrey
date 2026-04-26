import 'package:flutter/material.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_colors.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.neutral50,
      appBar: AppBar(
        title: Text('Admin Dashboard', style: AppTextStyles.title),
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
              'System Overview',
              style: AppTextStyles.headingSmall,
            ),
            const SizedBox(height: 24),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _buildStatCard(
                  'Total Guards',
                  '128',
                  Icons.security,
                  AppColors.primary500,
                ),
                _buildStatCard(
                  'Active Sites',
                  '12',
                  Icons.location_on,
                  AppColors.success,
                ),
                _buildStatCard(
                  'Pending Alerts',
                  '5',
                  Icons.warning,
                  AppColors.error,
                ),
                _buildStatCard(
                  'Reports',
                  '48',
                  Icons.assessment,
                  AppColors.warning,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.neutral200.withOpacity(0.5),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 28),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: AppTextStyles.headingSmall.copyWith(color: color),
              ),
              Text(
                title,
                style: AppTextStyles.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

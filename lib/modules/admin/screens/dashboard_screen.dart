import 'package:flutter/material.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_colors.dart';
import '../widgets/kpi_card.dart';
import '../widgets/admin_search_bar.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTopHeader(),
                const SizedBox(height: 20),
                _buildSearchBar(),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader('Overview'),
                  const SizedBox(height: 16),
                  _buildKPIGrid(),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSectionHeader('Attendance Summary'),
                      _buildViewAllButton(),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildAttendanceSummary(),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSectionHeader('Active Managers'),
                      _buildViewAllButton(),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildActiveManagersList(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dashboard',
              style: AppTextStyles.headingMedium.copyWith(
                fontWeight: FontWeight.w900,
                color: AppColors.neutral900,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Welcome back, Admin',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.neutral500,
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.neutral200),
          ),
          child: Stack(
            children: [
              const Icon(
                Icons.notifications_none_rounded,
                color: AppColors.neutral700,
                size: 24,
              ),
              Positioned(
                right: 2,
                top: 2,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.error,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return const AdminSearchBar(
      hintText: 'Search site, manager...',
    );
  }

  Widget _buildKPIGrid() {
    const items = [
      KPICard(
        title: 'Total Clients',
        value: '12',
        icon: Icons.business_outlined,
        iconColor: AppColors.primary600,
      ),
      KPICard(
        title: 'Total Sites',
        value: '25',
        icon: Icons.location_on_outlined,
        iconColor: Color(0xFFF59E0B),
      ),
      KPICard(
        title: 'Active Managers',
        value: '08',
        icon: Icons.people_outline,
        iconColor: Color(0xFF10B981),
      ),
      KPICard(
        title: 'Today\'s Visits',
        value: '24',
        icon: Icons.calendar_today_outlined,
        iconColor: Color(0xFF8B5CF6),
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 12,
        mainAxisExtent: 70,
      ),
      itemBuilder: (context, index) => items[index],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: AppTextStyles.bodyMedium.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppColors.neutral900,
      ),
    );
  }

  Widget _buildViewAllButton() {
    return TextButton(
      onPressed: () {},
      child: Text(
        'View All',
        style: AppTextStyles.bodySmall.copyWith(
          color: AppColors.primary600,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildAttendanceSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.neutral200),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildAttendanceMetric(
                  'Present',
                  '186',
                  AppColors.success,
                ),
              ),
              Container(
                width: 1,
                height: 42,
                color: AppColors.neutral200,
              ),
              Expanded(
                child: _buildAttendanceMetric(
                  'Absent',
                  '12',
                  AppColors.error,
                ),
              ),
              Container(
                width: 1,
                height: 42,
                color: AppColors.neutral200,
              ),
              Expanded(
                child: _buildAttendanceMetric(
                  'Late',
                  '07',
                  AppColors.warning,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.neutral50,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Morning shift attendance',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.neutral700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  '91%',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.successDark,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceMetric(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: AppTextStyles.headingSmall.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
            height: 1,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.neutral500,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildActiveManagersList() {
    final List<Map<String, String>> managers = [
      {'name': 'John Doe', 'site': 'Crystal Plaza', 'status': 'On-Duty'},
      {'name': 'Jane Smith', 'site': 'Block A Center', 'status': 'On-Duty'},
      {'name': 'Robert Brown', 'site': 'Metro Station', 'status': 'Active'},
    ];

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: managers.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final manager = managers[index];
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.neutral200),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.primary50,
                child: Text(
                  manager['name']![0],
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.primary600,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      manager['name']!,
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      manager['site']!,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.neutral500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  manager['status']!,
                  style: AppTextStyles.caption.copyWith(
                    color: const Color(0xFF10B981),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

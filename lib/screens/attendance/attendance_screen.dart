import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../modules/admin/data/admin_dummy_data.dart';
import '../../modules/admin/models/visit_model.dart';
import '../../modules/admin/widgets/admin_search_bar.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  String _searchQuery = '';

  List<VisitModel> get _filteredVisits {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) {
      return AdminDummyData.visits;
    }

    return AdminDummyData.visits.where((visit) {
      final siteName = AdminDummyData.getSitesByIds([visit.siteId])
          .map((site) => site.name.toLowerCase())
          .join(' ');

      return visit.managerName.toLowerCase().contains(query) ||
          visit.status.toLowerCase().contains(query) ||
          visit.date.toLowerCase().contains(query) ||
          siteName.contains(query);
    }).toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final visits = _filteredVisits;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundLight,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Attendance',
          style: AppTextStyles.title.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          children: [
            AdminSearchBar(
              height: 50,
              hintText: 'Search attendance...',
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
            const SizedBox(height: 16),
            Expanded(
              child: visits.isEmpty
                  ? _buildEmptyState()
                  : ListView.separated(
                      itemCount: visits.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final visit = visits[index];
                        final site = AdminDummyData.getSitesByIds([visit.siteId]);
                        final siteName =
                            site.isNotEmpty ? site.first.name : 'Unknown Site';

                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: AppColors.neutral200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      visit.managerName,
                                      style: AppTextStyles.bodyLarge.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.neutral900,
                                      ),
                                    ),
                                  ),
                                  _StatusChip(status: visit.status),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                siteName,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.neutral600,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: _InfoText(
                                      icon: Icons.calendar_today_outlined,
                                      text: visit.date,
                                    ),
                                  ),
                                  Expanded(
                                    child: _InfoText(
                                      icon: Icons.schedule_outlined,
                                      text: visit.time,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.primary50,
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(
              Icons.fact_check_outlined,
              color: AppColors.primary600,
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No attendance records found',
            style: AppTextStyles.title.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            'Attendance data will appear here once records are available.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.neutral500,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor;

    switch (status) {
      case 'Completed':
        backgroundColor = AppColors.successLight;
        textColor = AppColors.successDark;
        break;
      case 'In Progress':
        backgroundColor = AppColors.primary50;
        textColor = AppColors.primary700;
        break;
      default:
        backgroundColor = AppColors.warningLight;
        textColor = AppColors.warningDark;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status,
        style: AppTextStyles.bodySmall.copyWith(
          color: textColor,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _InfoText extends StatelessWidget {
  const _InfoText({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: AppColors.neutral500,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.neutral600,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

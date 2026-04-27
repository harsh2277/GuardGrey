import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../modules/admin/data/admin_dummy_data.dart';
import '../../modules/admin/models/attendance_record.dart';
import '../../modules/admin/widgets/admin_search_bar.dart';
import '../../modules/admin/widgets/attendance_table.dart';
import '../../modules/admin/widgets/kpi_card.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  String _searchQuery = '';

  List<AttendanceRecord> get _filteredRecords {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) {
      return AdminDummyData.attendanceRecords;
    }

    return AdminDummyData.attendanceRecords.where((record) {
      return record.name.toLowerCase().contains(query) ||
          record.status.toLowerCase().contains(query) ||
          record.date.toLowerCase().contains(query) ||
          record.checkIn.toLowerCase().contains(query) ||
          record.checkOut.toLowerCase().contains(query);
    }).toList(growable: false);
  }

  int get _presentCount => AdminDummyData.attendanceRecords
      .where((record) => record.status == 'Present')
      .length;

  int get _absentCount => AdminDummyData.attendanceRecords
      .where((record) => record.status == 'Absent')
      .length;

  @override
  Widget build(BuildContext context) {
    final records = _filteredRecords;

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
        child: records.isEmpty
            ? Column(
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
                  Row(
                    children: [
                      Expanded(
                        child: KPICard(
                          title: 'Today\'s Present',
                          value: _presentCount.toString().padLeft(2, '0'),
                          icon: Icons.check_circle_outline_rounded,
                          iconColor: AppColors.success,
                          height: 96,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: KPICard(
                          title: 'Today\'s Absent',
                          value: _absentCount.toString().padLeft(2, '0'),
                          icon: Icons.highlight_off_rounded,
                          iconColor: AppColors.error,
                          height: 96,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Expanded(child: _buildEmptyState()),
                ],
              )
            : ListView(
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
                  Row(
                    children: [
                      Expanded(
                        child: KPICard(
                          title: 'Today\'s Present',
                          value: _presentCount.toString().padLeft(2, '0'),
                          icon: Icons.check_circle_outline_rounded,
                          iconColor: AppColors.success,
                          height: 96,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: KPICard(
                          title: 'Today\'s Absent',
                          value: _absentCount.toString().padLeft(2, '0'),
                          icon: Icons.highlight_off_rounded,
                          iconColor: AppColors.error,
                          height: 96,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  AttendanceTable(records: records),
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

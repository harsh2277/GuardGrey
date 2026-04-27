import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../modules/admin/models/attendance_record.dart';
import '../../modules/admin/services/firestore_admin_repository.dart';
import '../../modules/admin/widgets/admin_search_bar.dart';
import '../../modules/admin/widgets/attendance_table.dart';
import '../../modules/admin/widgets/kpi_card.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final FirestoreAdminRepository _repository = FirestoreAdminRepository.instance;
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
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
        child: StreamBuilder<List<AttendanceRecord>>(
          stream: _repository.watchAttendance(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return _buildErrorState();
            }

            final allRecords = snapshot.data ?? const <AttendanceRecord>[];
            final records = _filterRecords(allRecords);
            final presentCount = allRecords
                .where((record) => record.status == 'Present')
                .length;
            final absentCount = allRecords
                .where((record) => record.status == 'Absent')
                .length;

            return records.isEmpty
                ? Column(
                    children: [
                      _buildSearchBar(),
                      const SizedBox(height: 16),
                      _buildKpiRow(presentCount, absentCount),
                      const SizedBox(height: 24),
                      Expanded(child: _buildEmptyState()),
                    ],
                  )
                : ListView(
                    children: [
                      _buildSearchBar(),
                      const SizedBox(height: 16),
                      _buildKpiRow(presentCount, absentCount),
                      const SizedBox(height: 16),
                      AttendanceTable(records: records),
                    ],
                  );
          },
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return AdminSearchBar(
      height: 50,
      hintText: 'Search attendance...',
      onChanged: (value) {
        setState(() {
          _searchQuery = value;
        });
      },
    );
  }

  Widget _buildKpiRow(int presentCount, int absentCount) {
    return Row(
      children: [
        Expanded(
          child: KPICard(
            title: 'Today\'s Present',
            value: presentCount.toString().padLeft(2, '0'),
            icon: Icons.check_circle_outline_rounded,
            iconColor: AppColors.success,
            height: 96,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: KPICard(
            title: 'Today\'s Absent',
            value: absentCount.toString().padLeft(2, '0'),
            icon: Icons.highlight_off_rounded,
            iconColor: AppColors.error,
            height: 96,
          ),
        ),
      ],
    );
  }

  List<AttendanceRecord> _filterRecords(List<AttendanceRecord> records) {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) {
      return records;
    }

    return records.where((record) {
      return record.name.toLowerCase().contains(query) ||
          record.status.toLowerCase().contains(query) ||
          record.date.toLowerCase().contains(query) ||
          record.checkIn.toLowerCase().contains(query) ||
          record.checkOut.toLowerCase().contains(query);
    }).toList(growable: false);
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
            'No data available',
            style: AppTextStyles.title.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            'Attendance records will appear here once data is available.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.neutral500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Text(
        'Unable to load attendance.',
        style: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.neutral500,
        ),
      ),
    );
  }
}

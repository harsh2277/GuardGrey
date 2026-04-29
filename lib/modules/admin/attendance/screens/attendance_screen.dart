import 'package:flutter/material.dart';

import 'package:guardgrey/core/theme/app_colors.dart';
import 'package:guardgrey/core/theme/app_text_styles.dart';
import 'package:guardgrey/core/utils/filter_resettable.dart';
import 'package:guardgrey/core/widgets/admin_search_bar.dart';
import 'package:guardgrey/core/widgets/attendance_table.dart';
import 'package:guardgrey/core/widgets/list_filter_bottom_sheet.dart';
import 'package:guardgrey/core/widgets/surface_icon_button.dart';
import 'package:guardgrey/data/models/attendance_record.dart';
import 'package:guardgrey/data/models/manager_model.dart';
import 'package:guardgrey/data/repositories/guard_grey_repository.dart';
import 'package:guardgrey/modules/admin/dashboard/widgets/kpi_card.dart';
import 'package:guardgrey/modules/admin/managers/screens/manager_detail_screen.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen>
    implements FilterResettable {
  final GuardGreyRepository _repository = GuardGreyRepository.instance;
  late final TextEditingController _searchController;
  String _searchQuery = '';
  String? _selectedStatus;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openFilters() async {
    final filters = await ListFilterBottomSheet.show(
      context,
      title: 'Filter Attendance',
      searchHint: 'Refine by name, check-in, check-out...',
      initialSearchQuery: _searchQuery,
      statusOptions: const ['Present', 'Absent', 'Late'],
      initialStatus: _selectedStatus,
      initialDate: _selectedDate,
      showDateFilter: true,
    );

    if (filters == null) {
      return;
    }

    _searchController.text = filters.searchQuery;
    setState(() {
      _searchQuery = filters.searchQuery;
      _selectedStatus = filters.status;
      _selectedDate = filters.date;
    });
  }

  @override
  void resetFilters() {
    if (_searchQuery.isEmpty &&
        _selectedStatus == null &&
        _selectedDate == null &&
        _searchController.text.isEmpty) {
      return;
    }

    setState(() {
      _searchQuery = '';
      _selectedStatus = null;
      _selectedDate = null;
      _searchController.clear();
    });
  }

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

            return StreamBuilder<List<ManagerModel>>(
              stream: _repository.watchManagers(),
              builder: (context, managersSnapshot) {
                final managers =
                    managersSnapshot.data ?? const <ManagerModel>[];
                final managerImageById = {
                  for (final manager in managers)
                    manager.id: manager.profileImage,
                };
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
                          const SizedBox(height: 18),
                          _buildKpiRow(presentCount, absentCount),
                          const SizedBox(height: 24),
                          Expanded(child: _buildEmptyState()),
                        ],
                      )
                    : ListView(
                        children: [
                          _buildSearchBar(),
                          const SizedBox(height: 18),
                          _buildKpiRow(presentCount, absentCount),
                          const SizedBox(height: 18),
                          AttendanceTable(
                            records: records,
                            profileImageForRecord: (record) =>
                                managerImageById[record.managerId] ?? '',
                            onManagerTap: (record) =>
                                _openManagerFromAttendance(record, managers),
                          ),
                        ],
                      );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Row(
      children: [
        Expanded(
          child: AdminSearchBar(
            controller: _searchController,
            height: 50,
            hintText: 'Search attendance...',
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
        ),
        const SizedBox(width: 12),
        SurfaceIconButton(
          icon: Icons.tune_rounded,
          onTap: _openFilters,
          backgroundColor: AppColors.primary600,
          borderColor: AppColors.primary600,
          iconColor: Colors.white,
          borderRadius: 25,
        ),
      ],
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
    if (query.isEmpty && _selectedStatus == null && _selectedDate == null) {
      return records;
    }

    return records
        .where((record) {
          final matchesQuery =
              query.isEmpty ||
              record.name.toLowerCase().contains(query) ||
              record.status.toLowerCase().contains(query) ||
              record.date.toLowerCase().contains(query) ||
              record.checkIn.toLowerCase().contains(query) ||
              record.checkOut.toLowerCase().contains(query);
          final matchesStatus =
              _selectedStatus == null ||
              record.status.toLowerCase() == _selectedStatus!.toLowerCase();
          final matchesDate =
              _selectedDate == null ||
              record.date == GuardGreyRepository.formatDate(_selectedDate);
          return matchesQuery && matchesStatus && matchesDate;
        })
        .toList(growable: false);
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
        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.neutral500),
      ),
    );
  }

  void _openManagerFromAttendance(
    AttendanceRecord record,
    List<ManagerModel> managers,
  ) {
    ManagerModel? selectedManager;
    for (final manager in managers) {
      if (manager.id == record.managerId || manager.name == record.name) {
        selectedManager = manager;
        break;
      }
    }

    if (selectedManager == null) {
      return;
    }

    Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => ManagerDetailScreen(manager: selectedManager!),
      ),
    ).then((_) {
      if (mounted) {
        resetFilters();
      }
    });
  }
}

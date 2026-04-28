import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:guardgrey/core/theme/app_colors.dart';
import 'package:guardgrey/core/theme/app_text_styles.dart';
import 'package:guardgrey/core/utils/filter_resettable.dart';
import 'package:guardgrey/core/widgets/attendance_table.dart';
import 'package:guardgrey/core/widgets/list_filter_bottom_sheet.dart';
import 'package:guardgrey/core/widgets/surface_icon_button.dart';
import 'package:guardgrey/data/models/attendance_record.dart';
import 'package:guardgrey/data/models/manager_model.dart';
import 'package:guardgrey/data/repositories/guard_grey_repository.dart';

class ManagerAttendanceScreen extends StatefulWidget {
  const ManagerAttendanceScreen({super.key});

  @override
  State<ManagerAttendanceScreen> createState() =>
      _ManagerAttendanceScreenState();
}

class _ManagerAttendanceScreenState extends State<ManagerAttendanceScreen>
    implements FilterResettable {
  final GuardGreyRepository _repository = GuardGreyRepository.instance;
  String? _selectedStatus;
  DateTime? _selectedDate;

  @override
  void resetFilters() {
    setState(() {
      _selectedStatus = null;
      _selectedDate = null;
    });
  }

  Future<void> _openFilters() async {
    final filters = await ListFilterBottomSheet.show(
      context,
      title: 'Filter Attendance',
      searchHint: 'Refine attendance records...',
      initialSearchQuery: '',
      initialStatus: _selectedStatus,
      initialDate: _selectedDate,
      showDateFilter: true,
    );
    if (filters == null) {
      return;
    }
    setState(() {
      _selectedStatus = filters.status;
      _selectedDate = filters.date;
    });
  }

  @override
  Widget build(BuildContext context) {
    final email = FirebaseAuth.instance.currentUser?.email ?? '';

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundLight,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'My Attendance',
          style: AppTextStyles.title.copyWith(fontWeight: FontWeight.w700),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: SurfaceIconButton(
              icon: Icons.tune_rounded,
              onTap: _openFilters,
              backgroundColor: AppColors.primary600,
              borderColor: AppColors.primary600,
              iconColor: Colors.white,
              borderRadius: 25,
              size: 44,
            ),
          ),
        ],
      ),
      body: StreamBuilder<ManagerModel?>(
        stream: _repository.watchManagerByEmail(email),
        builder: (context, managerSnapshot) {
          final manager = managerSnapshot.data;
          if (managerSnapshot.connectionState == ConnectionState.waiting &&
              manager == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (manager == null) {
            return _buildMessage('Manager attendance is not available.');
          }

          return StreamBuilder<List<AttendanceRecord>>(
            stream: _repository.watchAttendance(),
            builder: (context, attendanceSnapshot) {
              final records =
                  (attendanceSnapshot.data ?? const <AttendanceRecord>[])
                      .where((record) => record.managerId == manager.id)
                      .where((record) {
                        if (_selectedStatus != null &&
                            _selectedStatus!.trim().isNotEmpty &&
                            record.status.toLowerCase() !=
                                _selectedStatus!.trim().toLowerCase()) {
                          return false;
                        }
                        if (_selectedDate != null &&
                            record.date !=
                                GuardGreyRepository.formatDate(_selectedDate)) {
                          return false;
                        }
                        return true;
                      })
                      .toList(growable: false);

              if (records.isEmpty) {
                return _buildMessage('No attendance records found.');
              }

              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                children: [AttendanceTable(records: records)],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildMessage(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyLarge.copyWith(color: AppColors.neutral500),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import 'package:guardgrey/core/theme/app_colors.dart';
import 'package:guardgrey/core/theme/app_text_styles.dart';
import 'package:guardgrey/core/utils/date_time_display.dart';
import 'package:guardgrey/data/models/manager_model.dart';
import 'package:guardgrey/features/location/services/current_location_service.dart';
import 'package:guardgrey/modules/manager/attendance/models/manager_attendance_entry.dart';
import 'package:guardgrey/modules/manager/attendance/repositories/manager_attendance_repository.dart';
import 'package:guardgrey/modules/manager/common/services/manager_session_service.dart';
import 'package:guardgrey/modules/manager/common/widgets/manager_ui.dart';

class ManagerAttendanceScreen extends StatefulWidget {
  const ManagerAttendanceScreen({super.key, this.showAppBar = false});

  final bool showAppBar;

  @override
  State<ManagerAttendanceScreen> createState() =>
      _ManagerAttendanceScreenState();
}

class _ManagerAttendanceScreenState extends State<ManagerAttendanceScreen> {
  final ManagerAttendanceRepository _repository =
      ManagerAttendanceRepository.instance;
  final CurrentLocationService _locationService =
      const CurrentLocationService();
  bool _isCheckingIn = false;
  bool _isCheckingOut = false;

  Future<void> _checkIn(ManagerModel manager) async {
    if (_isCheckingIn) {
      return;
    }
    setState(() {
      _isCheckingIn = true;
    });
    try {
      double? latitude;
      double? longitude;
      try {
        final position = await _locationService.getCurrentPosition();
        latitude = position.latitude;
        longitude = position.longitude;
      } catch (_) {
        latitude = null;
        longitude = null;
      }
      await _repository.checkIn(
        managerId: manager.id,
        managerName: manager.name,
        latitude: latitude,
        longitude: longitude,
      );
      if (!mounted) {
        return;
      }
      _showMessage('Check-in recorded.');
    } on StateError catch (error) {
      _showMessage(error.message, isError: true);
    } catch (_) {
      _showMessage('Unable to check in right now.', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingIn = false;
        });
      }
    }
  }

  Future<void> _checkOut(ManagerAttendanceEntry entry) async {
    if (_isCheckingOut) {
      return;
    }
    setState(() {
      _isCheckingOut = true;
    });
    try {
      await _repository.checkOut(entry);
      if (!mounted) {
        return;
      }
      _showMessage('Check-out recorded.');
    } on StateError catch (error) {
      _showMessage(error.message, isError: true);
    } catch (_) {
      _showMessage('Unable to check out right now.', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingOut = false;
        });
      }
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: isError ? AppColors.error : AppColors.success,
        content: Text(
          message,
          style: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ManagerModel?>(
      stream: ManagerSessionService.instance.watchCurrentManager(),
      builder: (context, managerSnapshot) {
        final manager = managerSnapshot.data;

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
          body: manager == null
              ? const ManagerEmptyState(
                  title: 'No manager workspace data',
                  message:
                      'Attendance will appear after the manager workspace syncs.',
                )
              : StreamBuilder<List<ManagerAttendanceEntry>>(
                  stream: _repository.watchAttendance(manager.id),
                  builder: (context, attendanceSnapshot) {
                    final entries =
                        attendanceSnapshot.data ??
                        const <ManagerAttendanceEntry>[];
                    final today = DateTime.now();
                    final current = entries
                        .where(
                          (entry) =>
                              entry.date.year == today.year &&
                              entry.date.month == today.month &&
                              entry.date.day == today.day,
                        )
                        .firstOrNull;

                    return ListView(
                      padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
                      children: [
                        if (widget.showAppBar) ...[
                          Text(
                            'Keep daily attendance fast, simple, and mobile friendly.',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.neutral500,
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            gradient: const LinearGradient(
                              colors: [
                                AppColors.primary600,
                                AppColors.primary700,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Today Status',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                current?.status ?? 'Not checked in',
                                style: AppTextStyles.headingMedium.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: _AttendanceStatTile(
                                      label: 'Check-in',
                                      value: current?.checkInAt == null
                                          ? '--'
                                          : formatTimeLabel(
                                              current!.checkInAt!,
                                            ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _AttendanceStatTile(
                                      label: 'Check-out',
                                      value: current?.checkOutAt == null
                                          ? '--'
                                          : formatTimeLabel(
                                              current!.checkOutAt!,
                                            ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        ManagerSurfaceCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Attendance Actions',
                                style: AppTextStyles.bodyLarge.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'You can check in once per day and check out after your shift ends.',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.neutral500,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: FilledButton(
                                      onPressed:
                                          current?.checkInAt != null ||
                                              _isCheckingIn
                                          ? null
                                          : () => _checkIn(manager),
                                      child: Text(
                                        _isCheckingIn
                                            ? 'Checking in...'
                                            : 'Check-in',
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed:
                                          current?.isCheckedIn == true &&
                                              !_isCheckingOut
                                          ? () => _checkOut(current!)
                                          : null,
                                      child: Text(
                                        _isCheckingOut
                                            ? 'Checking out...'
                                            : 'Check-out',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: AppColors.neutral50,
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: Text(
                                  current?.latitude == null ||
                                          current?.longitude == null
                                      ? 'Optional GPS was not captured for today.'
                                      : 'GPS: ${current!.latitude!.toStringAsFixed(5)}, ${current.longitude!.toStringAsFixed(5)}',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.neutral600,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          'Attendance History',
                          style: AppTextStyles.bodyLarge.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 10),
                        if (entries.isEmpty)
                          const ManagerEmptyState(
                            title: 'No attendance history yet',
                            message:
                                'Your attendance logs will appear after the first check-in.',
                          )
                        else
                          ...entries.map(
                            (entry) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: ManagerSurfaceCard(
                                child: Row(
                                  children: [
                                    Container(
                                      width: 46,
                                      height: 46,
                                      decoration: BoxDecoration(
                                        color: AppColors.primary50,
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: const Icon(
                                        Icons.fact_check_outlined,
                                        color: AppColors.primary700,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            formatDateLabel(entry.date),
                                            style: AppTextStyles.bodyLarge
                                                .copyWith(
                                                  fontWeight: FontWeight.w700,
                                                ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'In ${entry.checkInAt == null ? '--' : formatTimeLabel(entry.checkInAt!)} | Out ${entry.checkOutAt == null ? '--' : formatTimeLabel(entry.checkOutAt!)}',
                                            style: AppTextStyles.bodySmall
                                                .copyWith(
                                                  color: AppColors.neutral500,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    ManagerStatusChip(label: entry.status),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
        );
      },
    );
  }
}

class _AttendanceStatTile extends StatelessWidget {
  const _AttendanceStatTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: Colors.white70,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTextStyles.bodyLarge.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

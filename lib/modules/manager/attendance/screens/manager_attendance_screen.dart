import 'package:flutter/material.dart';

import 'package:guardgrey/core/theme/app_colors.dart';
import 'package:guardgrey/core/theme/app_text_styles.dart';
import 'package:guardgrey/core/utils/date_time_display.dart';
import 'package:guardgrey/modules/admin/dashboard/widgets/kpi_card.dart';
import 'package:guardgrey/data/models/manager_model.dart';
import 'package:guardgrey/data/models/site_model.dart';
import 'package:guardgrey/data/repositories/guard_grey_repository.dart';
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
  String? _selectedSiteId;

  Future<void> _checkIn(ManagerModel manager, List<SiteModel> sites) async {
    final site =
        sites.where((item) => item.id == _selectedSiteId).firstOrNull ??
        sites.firstOrNull;
    if (site == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.error,
          content: Text(
            'Assign a site before checking in.',
            style: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
          ),
        ),
      );
      return;
    }
    await _repository.checkIn(
      managerId: manager.id,
      managerName: manager.name,
      site: site,
    );
  }

  Future<void> _checkOut(ManagerAttendanceEntry entry) async {
    await _repository.checkOut(entry);
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
              : StreamBuilder<List<SiteModel>>(
                  stream: GuardGreyRepository.instance.watchSites(),
                  builder: (context, siteSnapshot) {
                    final sites = (siteSnapshot.data ?? const <SiteModel>[])
                        .where(
                          (site) =>
                              site.managerId == manager.id ||
                              manager.siteIds.contains(site.id),
                        )
                        .toList(growable: false);
                    _selectedSiteId ??= sites.firstOrNull?.id;

                    return StreamBuilder<List<ManagerAttendanceEntry>>(
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
                          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                          children: [
                            if (widget.showAppBar) ...[
                              Text(
                                'Check in once and keep daily logs in one place',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.neutral500,
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],
                            ManagerSurfaceCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          'Current Status',
                                          style: AppTextStyles.bodyLarge
                                              .copyWith(
                                                fontWeight: FontWeight.w700,
                                              ),
                                        ),
                                      ),
                                      ManagerStatusChip(
                                        label:
                                            current?.status ?? 'Not checked in',
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  DropdownButtonFormField<String>(
                                    initialValue: _selectedSiteId,
                                    decoration: const InputDecoration(
                                      labelText: 'Assigned Site',
                                    ),
                                    items: sites
                                        .map(
                                          (site) => DropdownMenuItem<String>(
                                            value: site.id,
                                            child: Text(site.name),
                                          ),
                                        )
                                        .toList(growable: false),
                                    onChanged: current?.isCheckedIn == true
                                        ? null
                                        : (value) {
                                            setState(() {
                                              _selectedSiteId = value;
                                            });
                                          },
                                  ),
                                  const SizedBox(height: 12),
                                  if (current?.checkInAt != null)
                                    Text(
                                      'Check-in: ${formatTimeLabel(current!.checkInAt!)}',
                                      style: AppTextStyles.bodyMedium.copyWith(
                                        color: AppColors.neutral500,
                                      ),
                                    ),
                                  if (current?.checkOutAt != null) ...[
                                    const SizedBox(height: 6),
                                    Text(
                                      'Check-out: ${formatTimeLabel(current!.checkOutAt!)}',
                                      style: AppTextStyles.bodyMedium.copyWith(
                                        color: AppColors.neutral500,
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 18),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: FilledButton(
                                          onPressed:
                                              current?.isCheckedIn == true
                                              ? null
                                              : () => _checkIn(manager, sites),
                                          child: const Text('Check-in'),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: OutlinedButton(
                                          onPressed:
                                              current?.isCheckedIn == true
                                              ? () => _checkOut(current!)
                                              : null,
                                          child: const Text('Check-out'),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 18),
                            Row(
                              children: [
                                Expanded(
                                  child: KPICard(
                                    title: 'Today Status',
                                    value: current == null ? '--' : '01',
                                    icon: Icons.check_circle_outline_rounded,
                                    iconColor:
                                        current?.status == 'Present' ||
                                            current?.status == 'Late'
                                        ? AppColors.success
                                        : AppColors.warningDark,
                                    height: 96,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: KPICard(
                                    title: 'Attendance Logs',
                                    value: entries.length.toString().padLeft(
                                      2,
                                      '0',
                                    ),
                                    icon: Icons.history_rounded,
                                    iconColor: AppColors.primary600,
                                    height: 96,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            Text(
                              'History',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.neutral500,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 12),
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
                                  child: ManagerListCard(
                                    title: formatDateLabel(entry.date),
                                    subtitle: entry.siteName,
                                    meta:
                                        'In: ${entry.checkInAt == null ? '-' : formatTimeLabel(entry.checkInAt!)}  •  Out: ${entry.checkOutAt == null ? '-' : formatTimeLabel(entry.checkOutAt!)}',
                                    status: entry.status,
                                    icon: Icons.fact_check_outlined,
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    );
                  },
                ),
        );
      },
    );
  }
}

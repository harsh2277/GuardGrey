import 'package:flutter/material.dart';

import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_colors.dart';
import '../models/attendance_record.dart';
import '../models/client_model.dart';
import '../models/manager_model.dart';
import '../models/site_model.dart';
import '../services/firestore_admin_repository.dart';
import '../../notifications/services/notification_module.dart';
import '../../../routes/app_routes.dart';
import '../widgets/kpi_card.dart';
import '../widgets/admin_search_bar.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  static final FirestoreAdminRepository _repository =
      FirestoreAdminRepository.instance;

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
                _buildTopHeader(context),
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

  Widget _buildTopHeader(BuildContext context) {
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
        Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: () => Navigator.pushNamed(context, AppRoutes.notifications),
            child: StreamBuilder<int>(
              stream: NotificationModule.repository.watchUnreadCount(),
              builder: (context, snapshot) {
                final unreadCount = snapshot.data ?? 0;
                return Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.neutral200),
                  ),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Icon(
                        Icons.notifications_none_rounded,
                        color: AppColors.neutral700,
                        size: 24,
                      ),
                      if (unreadCount > 0)
                        Positioned(
                          right: -1,
                          top: -1,
                          child: Container(
                            constraints: const BoxConstraints(
                              minWidth: 18,
                              minHeight: 18,
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: const BoxDecoration(
                              color: AppColors.error,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              unreadCount > 9 ? '9+' : '$unreadCount',
                              style: AppTextStyles.caption.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
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
    return StreamBuilder<List<ClientModel>>(
      stream: _repository.watchClients(),
      builder: (context, clientsSnapshot) {
        return StreamBuilder<List<SiteModel>>(
          stream: _repository.watchSites(),
          builder: (context, sitesSnapshot) {
            return StreamBuilder<List<ManagerModel>>(
              stream: _repository.watchManagers(),
              builder: (context, managersSnapshot) {
                return StreamBuilder<List<AttendanceRecord>>(
                  stream: _repository.watchAttendance(),
                  builder: (context, attendanceSnapshot) {
                    if (_hasDashboardError(
                      clientsSnapshot.error,
                      sitesSnapshot.error,
                      managersSnapshot.error,
                      attendanceSnapshot.error,
                    )) {
                      return _buildKpiGridWithValues(
                        clientCount: '-',
                        siteCount: '-',
                        managerCount: '-',
                        attendanceCount: '-',
                      );
                    }

                    final isLoading = !clientsSnapshot.hasData ||
                        !sitesSnapshot.hasData ||
                        !managersSnapshot.hasData ||
                        !attendanceSnapshot.hasData;

                    if (isLoading) {
                      return const SizedBox(
                        height: 152,
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    final todayCount = _todayAttendance(
                      attendanceSnapshot.data ?? const [],
                    ).length;

                    return _buildKpiGridWithValues(
                      clientCount:
                          '${(clientsSnapshot.data ?? const []).length}',
                      siteCount: '${(sitesSnapshot.data ?? const []).length}',
                      managerCount:
                          '${(managersSnapshot.data ?? const []).length}',
                      attendanceCount: '$todayCount',
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildKpiGridWithValues({
    required String clientCount,
    required String siteCount,
    required String managerCount,
    required String attendanceCount,
  }) {
    final items = [
      KPICard(
        title: 'Total Clients',
        value: clientCount,
        icon: Icons.business_outlined,
        iconColor: AppColors.primary600,
      ),
      KPICard(
        title: 'Total Sites',
        value: siteCount,
        icon: Icons.location_on_outlined,
        iconColor: const Color(0xFFF59E0B),
      ),
      KPICard(
        title: 'Total Managers',
        value: managerCount,
        icon: Icons.people_outline,
        iconColor: const Color(0xFF10B981),
      ),
      KPICard(
        title: 'Today\'s Attendance',
        value: attendanceCount,
        icon: Icons.calendar_today_outlined,
        iconColor: const Color(0xFF8B5CF6),
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
    return StreamBuilder<List<AttendanceRecord>>(
      stream: _repository.watchAttendance(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          print('Dashboard attendance summary error: ${snapshot.error}');
          return _buildSummaryContainer(
            child: _buildFallbackText('Unable to load attendance.'),
          );
        }

        if (!snapshot.hasData) {
          return _buildSummaryContainer(
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 28),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        final todayRecords = _todayAttendance(snapshot.data ?? const []);
        final presentCount = todayRecords
            .where((record) => record.status.toLowerCase() == 'present')
            .length;
        final absentCount = todayRecords
            .where((record) => record.status.toLowerCase() == 'absent')
            .length;
        final lateCount = todayRecords
            .where((record) => record.status.toLowerCase() == 'late')
            .length;
        final percentage = todayRecords.isEmpty
            ? '--'
            : '${((presentCount / todayRecords.length) * 100).round()}%';

        return _buildSummaryContainer(
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildAttendanceMetric(
                      'Present',
                      presentCount.toString().padLeft(2, '0'),
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
                      absentCount.toString().padLeft(2, '0'),
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
                      lateCount.toString().padLeft(2, '0'),
                      AppColors.warning,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.neutral50,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        todayRecords.isEmpty
                            ? 'No attendance recorded today'
                            : 'Today\'s attendance coverage',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.neutral700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      percentage,
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
      },
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
    return StreamBuilder<List<ManagerModel>>(
      stream: _repository.watchManagers(),
      builder: (context, managersSnapshot) {
        return StreamBuilder<List<SiteModel>>(
          stream: _repository.watchSites(),
          builder: (context, sitesSnapshot) {
            return StreamBuilder<List<AttendanceRecord>>(
              stream: _repository.watchAttendance(),
              builder: (context, attendanceSnapshot) {
                if (_hasDashboardError(
                  managersSnapshot.error,
                  sitesSnapshot.error,
                  attendanceSnapshot.error,
                )) {
                  return _buildFallbackText('Unable to load managers.');
                }

                if (!managersSnapshot.hasData ||
                    !sitesSnapshot.hasData ||
                    !attendanceSnapshot.hasData) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final managerCards = _buildManagerCards(
                  managers: managersSnapshot.data ?? const [],
                  sites: sitesSnapshot.data ?? const [],
                  attendanceRecords: attendanceSnapshot.data ?? const [],
                );

                if (managerCards.isEmpty) {
                  return _buildFallbackText('No data available');
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: managerCards.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final manager = managerCards[index];
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
                              manager.name.isEmpty
                                  ? '?'
                                  : manager.name.substring(0, 1),
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
                                  manager.name,
                                  style: AppTextStyles.bodyLarge.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  manager.siteName,
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.neutral500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: manager.statusBackground,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              manager.statusLabel,
                              style: AppTextStyles.caption.copyWith(
                                color: manager.statusColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildSummaryContainer({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.neutral200),
      ),
      child: child,
    );
  }

  Widget _buildFallbackText(String message) {
    return Center(
      child: Text(
        message,
        style: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.neutral500,
        ),
      ),
    );
  }

  bool _hasDashboardError(Object? a, Object? b, [Object? c, Object? d]) {
    final errors = [a, b, c, d].where((error) => error != null).toList();
    if (errors.isNotEmpty) {
      print('Dashboard stream error: ${errors.first}');
      return true;
    }
    return false;
  }

  List<AttendanceRecord> _todayAttendance(List<AttendanceRecord> records) {
    final todayLabel =
        FirestoreAdminRepository.formatDate(DateTime.now());
    return records
        .where((record) => record.date == todayLabel)
        .toList(growable: false);
  }

  List<_DashboardManagerCardData> _buildManagerCards({
    required List<ManagerModel> managers,
    required List<SiteModel> sites,
    required List<AttendanceRecord> attendanceRecords,
  }) {
    final todayRecords = _todayAttendance(attendanceRecords);
    final attendanceByManagerName = <String, AttendanceRecord>{
      for (final record in todayRecords) record.name: record,
    };

    final cards = managers.map((manager) {
      final assignedSites = sites
          .where(
            (site) =>
                site.managerId == manager.id || manager.siteIds.contains(site.id),
          )
          .toList(growable: false);
      final primarySiteName = assignedSites.isEmpty
          ? 'No assigned site'
          : assignedSites.first.name;
      final attendance = attendanceByManagerName[manager.name];
      final normalizedStatus = attendance?.status.toLowerCase() ?? '';

      late Color statusColor;
      late Color statusBackground;
      late String statusLabel;

      if (normalizedStatus == 'present') {
        statusLabel = 'Present';
        statusColor = const Color(0xFF10B981);
        statusBackground = const Color(0xFFECFDF5);
      } else if (normalizedStatus == 'absent') {
        statusLabel = 'Absent';
        statusColor = AppColors.error;
        statusBackground = const Color(0xFFFEF2F2);
      } else if (normalizedStatus == 'late') {
        statusLabel = 'Late';
        statusColor = const Color(0xFFD97706);
        statusBackground = const Color(0xFFFFF7ED);
      } else if (assignedSites.isNotEmpty) {
        statusLabel = 'Active';
        statusColor = AppColors.primary700;
        statusBackground = AppColors.primary50;
      } else {
        statusLabel = 'Idle';
        statusColor = AppColors.neutral600;
        statusBackground = AppColors.neutral100;
      }

      return _DashboardManagerCardData(
        name: manager.name,
        siteName: primarySiteName,
        statusLabel: statusLabel,
        statusColor: statusColor,
        statusBackground: statusBackground,
        priority: attendance != null ? 0 : (assignedSites.isNotEmpty ? 1 : 2),
      );
    }).toList(growable: false);

    cards.sort((a, b) {
      final priorityCompare = a.priority.compareTo(b.priority);
      if (priorityCompare != 0) {
        return priorityCompare;
      }
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });

    return cards.take(3).toList(growable: false);
  }
}

class _DashboardManagerCardData {
  const _DashboardManagerCardData({
    required this.name,
    required this.siteName,
    required this.statusLabel,
    required this.statusColor,
    required this.statusBackground,
    required this.priority,
  });

  final String name;
  final String siteName;
  final String statusLabel;
  final Color statusColor;
  final Color statusBackground;
  final int priority;
}

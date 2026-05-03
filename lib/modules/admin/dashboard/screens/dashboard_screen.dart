import 'package:flutter/material.dart';

import 'package:guardgrey/core/theme/app_colors.dart';
import 'package:guardgrey/core/theme/app_text_styles.dart';
import 'package:guardgrey/core/widgets/admin_search_bar.dart';
import 'package:guardgrey/data/models/attendance_record.dart';
import 'package:guardgrey/data/models/client_model.dart';
import 'package:guardgrey/data/models/manager_model.dart';
import 'package:guardgrey/data/models/site_model.dart';
import 'package:guardgrey/data/repositories/guard_grey_repository.dart';
import 'package:guardgrey/features/notifications/services/notification_module.dart';
import 'package:guardgrey/routes/app_routes.dart';
import 'package:guardgrey/modules/admin/attendance/screens/attendance_screen.dart';
import 'package:guardgrey/modules/admin/clients/screens/client_detail_screen.dart';
import 'package:guardgrey/modules/admin/clients/screens/clients_screen.dart';
import 'package:guardgrey/modules/admin/dashboard/widgets/kpi_card.dart';
import 'package:guardgrey/modules/admin/managers/screens/manager_detail_screen.dart';
import 'package:guardgrey/modules/admin/managers/screens/managers_list_screen.dart';
import 'package:guardgrey/modules/admin/navigation/screens/main_navigation_screen.dart';
import 'package:guardgrey/modules/admin/sites/screens/site_detail_screen.dart';
import 'package:guardgrey/modules/admin/sites/screens/sites_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final GuardGreyRepository _repository = GuardGreyRepository.instance;
  late final TextEditingController _searchController;
  String _dashboardQuery = '';

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
                const SizedBox(height: 8),
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
                  const SizedBox(height: 8),
                  _buildKPIGrid(context),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSectionHeader('Attendance Summary'),
                      _buildViewAllButton(
                        onTap: () => _openAttendance(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildAttendanceSummary(context),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSectionHeader('On Duty Managers'),
                      _buildViewAllButton(onTap: () => _openManagers(context)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildActiveManagersList(context),
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
            onTap: () =>
                Navigator.pushNamed(context, AppRoutes.adminNotifications),
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
    return StreamBuilder<List<ClientModel>>(
      stream: _repository.watchClients(),
      builder: (context, clientsSnapshot) {
        return StreamBuilder<List<SiteModel>>(
          stream: _repository.watchSites(),
          builder: (context, sitesSnapshot) {
            return StreamBuilder<List<ManagerModel>>(
              stream: _repository.watchManagers(),
              builder: (context, managersSnapshot) {
                final suggestions = _buildSearchSuggestions(
                  clients: clientsSnapshot.data ?? const [],
                  sites: sitesSnapshot.data ?? const [],
                  managers: managersSnapshot.data ?? const [],
                );

                return Column(
                  children: [
                    AdminSearchBar(
                      controller: _searchController,
                      hintText: 'Search clients, sites, managers...',
                      onChanged: (value) {
                        setState(() {
                          _dashboardQuery = value;
                        });
                      },
                    ),
                    if (_dashboardQuery.trim().isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: AppColors.neutral200),
                        ),
                        child: suggestions.isEmpty
                            ? Padding(
                                padding: const EdgeInsets.all(16),
                                child: Text(
                                  'No matching clients, sites, or managers.',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: AppColors.neutral500,
                                  ),
                                ),
                              )
                            : Column(
                                children: suggestions
                                    .asMap()
                                    .entries
                                    .map((entry) {
                                      final suggestion = entry.value;
                                      return Column(
                                        children: [
                                          ListTile(
                                            leading: Icon(
                                              suggestion.icon,
                                              color: AppColors.primary600,
                                            ),
                                            title: Text(
                                              suggestion.title,
                                              style: AppTextStyles.bodyMedium
                                                  .copyWith(
                                                    color: AppColors.neutral900,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                            ),
                                            subtitle: Text(
                                              suggestion.subtitle,
                                              style: AppTextStyles.bodySmall
                                                  .copyWith(
                                                    color: AppColors.neutral500,
                                                  ),
                                            ),
                                            trailing: const Icon(
                                              Icons.chevron_right_rounded,
                                              color: AppColors.neutral400,
                                            ),
                                            onTap: () =>
                                                suggestion.onTap(context),
                                          ),
                                          if (entry.key !=
                                              suggestions.length - 1)
                                            const Divider(
                                              height: 1,
                                              color: AppColors.neutral200,
                                            ),
                                        ],
                                      );
                                    })
                                    .toList(growable: false),
                              ),
                      ),
                    ],
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildKPIGrid(BuildContext context) {
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
                        context: context,
                        clientCount: '-',
                        siteCount: '-',
                        managerCount: '-',
                        attendanceCount: '-',
                      );
                    }

                    final isLoading =
                        !clientsSnapshot.hasData ||
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
                      context: context,
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
    required BuildContext context,
    required String clientCount,
    required String siteCount,
    required String managerCount,
    required String attendanceCount,
  }) {
    final items = [
      _DashboardKpiItem(
        onTap: () => _openClients(context),
        child: KPICard(
          title: 'Total Clients',
          value: clientCount,
          icon: Icons.business_outlined,
          iconColor: AppColors.primary600,
        ),
      ),
      _DashboardKpiItem(
        onTap: () => _openSites(context),
        child: KPICard(
          title: 'Total Sites',
          value: siteCount,
          icon: Icons.location_on_outlined,
          iconColor: const Color(0xFFF59E0B),
        ),
      ),
      _DashboardKpiItem(
        onTap: () => _openManagers(context),
        child: KPICard(
          title: 'Total Managers',
          value: managerCount,
          icon: Icons.people_outline,
          iconColor: const Color(0xFF10B981),
        ),
      ),
      _DashboardKpiItem(
        onTap: () => _openAttendance(context),
        child: KPICard(
          title: 'Today\'s Attendance',
          value: attendanceCount,
          icon: Icons.calendar_today_outlined,
          iconColor: const Color(0xFF8B5CF6),
        ),
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

  Widget _buildViewAllButton({required VoidCallback onTap}) {
    return TextButton(
      onPressed: onTap,
      child: Text(
        'View All',
        style: AppTextStyles.bodySmall.copyWith(
          color: AppColors.primary600,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildAttendanceSummary(BuildContext context) {
    return StreamBuilder<List<AttendanceRecord>>(
      stream: _repository.watchAttendance(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          debugPrint('Dashboard attendance summary error: ${snapshot.error}');
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

        return InkWell(
          onTap: () => _openAttendance(context),
          borderRadius: BorderRadius.circular(18),
          child: _buildSummaryContainer(
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
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

  Widget _buildActiveManagersList(BuildContext context) {
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
                    return Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () =>
                            _openManagerDetail(context, manager.manager),
                        child: Container(
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
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  if (manager.statusLabel != 'Active')
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
                                  const SizedBox(height: 8),
                                  const Icon(
                                    Icons.chevron_right_rounded,
                                    color: AppColors.neutral400,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
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
        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.neutral500),
      ),
    );
  }

  bool _hasDashboardError(Object? a, Object? b, [Object? c, Object? d]) {
    final errors = [a, b, c, d].where((error) => error != null).toList();
    if (errors.isNotEmpty) {
      debugPrint('Dashboard stream error: ${errors.first}');
      return true;
    }
    return false;
  }

  List<AttendanceRecord> _todayAttendance(List<AttendanceRecord> records) {
    final todayLabel = GuardGreyRepository.formatDate(DateTime.now());
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

    final cards = managers
        .map((manager) {
          final assignedSites = sites
              .where(
                (site) =>
                    site.managerId == manager.id ||
                    manager.siteIds.contains(site.id),
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
            manager: manager,
            name: manager.name,
            siteName: primarySiteName,
            statusLabel: statusLabel,
            statusColor: statusColor,
            statusBackground: statusBackground,
            priority: attendance != null
                ? 0
                : (assignedSites.isNotEmpty ? 1 : 2),
          );
        })
        .toList(growable: false);

    cards.sort((a, b) {
      final priorityCompare = a.priority.compareTo(b.priority);
      if (priorityCompare != 0) {
        return priorityCompare;
      }
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });

    return cards.take(3).toList(growable: false);
  }

  void _openClients(BuildContext context) {
    _openTabOrPush(context, 3, const ClientsScreen());
  }

  void _openSites(BuildContext context) {
    _openTabOrPush(context, 1, const SitesScreen());
  }

  void _openAttendance(BuildContext context) {
    _openTabOrPush(context, 2, const AttendanceScreen());
  }

  void _openManagers(BuildContext context) {
    Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (_) => const ManagersListScreen()),
    );
  }

  void _openManagerDetail(BuildContext context, ManagerModel manager) {
    Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (_) => ManagerDetailScreen(manager: manager)),
    );
  }

  void _openTabOrPush(BuildContext context, int tabIndex, Widget fallbackPage) {
    final navigator = Navigator.of(context);
    if (context.findAncestorWidgetOfExactType<AdminNavigationScreen>() !=
        null) {
      AdminNavigationScreen.switchToTab(context, tabIndex);
      return;
    }

    navigator.push<void>(MaterialPageRoute(builder: (_) => fallbackPage));
  }

  List<_DashboardSearchSuggestion> _buildSearchSuggestions({
    required List<ClientModel> clients,
    required List<SiteModel> sites,
    required List<ManagerModel> managers,
  }) {
    final query = _dashboardQuery.trim().toLowerCase();
    if (query.isEmpty) {
      return const [];
    }

    final suggestions = <_DashboardSearchSuggestion>[
      ...clients
          .where((client) => client.name.toLowerCase().contains(query))
          .take(2)
          .map(
            (client) => _DashboardSearchSuggestion(
              title: client.name,
              subtitle: 'Client',
              icon: Icons.business_outlined,
              onTap: (context) {
                _searchController.clear();
                setState(() {
                  _dashboardQuery = '';
                });
                Navigator.push<void>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ClientDetailScreen(client: client),
                  ),
                );
              },
            ),
          ),
      ...sites
          .where((site) => site.name.toLowerCase().contains(query))
          .take(2)
          .map(
            (site) => _DashboardSearchSuggestion(
              title: site.name,
              subtitle: 'Site',
              icon: Icons.location_on_outlined,
              onTap: (context) {
                _searchController.clear();
                setState(() {
                  _dashboardQuery = '';
                });
                Navigator.push<void>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SiteDetailScreen(site: site),
                  ),
                );
              },
            ),
          ),
      ...managers
          .where((manager) => manager.name.toLowerCase().contains(query))
          .take(2)
          .map(
            (manager) => _DashboardSearchSuggestion(
              title: manager.name,
              subtitle: 'Manager',
              icon: Icons.groups_outlined,
              onTap: (context) {
                _searchController.clear();
                setState(() {
                  _dashboardQuery = '';
                });
                Navigator.push<void>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ManagerDetailScreen(manager: manager),
                  ),
                );
              },
            ),
          ),
    ];

    return suggestions.take(6).toList(growable: false);
  }
}

class _DashboardManagerCardData {
  const _DashboardManagerCardData({
    required this.manager,
    required this.name,
    required this.siteName,
    required this.statusLabel,
    required this.statusColor,
    required this.statusBackground,
    required this.priority,
  });

  final ManagerModel manager;
  final String name;
  final String siteName;
  final String statusLabel;
  final Color statusColor;
  final Color statusBackground;
  final int priority;
}

class _DashboardKpiItem extends StatelessWidget {
  const _DashboardKpiItem({required this.child, required this.onTap});

  final Widget child;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: child,
      ),
    );
  }
}

class _DashboardSearchSuggestion {
  const _DashboardSearchSuggestion({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final void Function(BuildContext context) onTap;
}

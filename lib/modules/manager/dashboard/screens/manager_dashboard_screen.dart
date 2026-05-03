import 'package:flutter/material.dart';

import 'package:guardgrey/core/theme/app_colors.dart';
import 'package:guardgrey/core/theme/app_text_styles.dart';
import 'package:guardgrey/core/utils/date_time_display.dart';
import 'package:guardgrey/data/models/manager_model.dart';
import 'package:guardgrey/data/models/site_model.dart';
import 'package:guardgrey/data/repositories/guard_grey_repository.dart';
import 'package:guardgrey/modules/manager/attendance/screens/manager_attendance_screen.dart';
import 'package:guardgrey/modules/manager/common/services/manager_session_service.dart';
import 'package:guardgrey/modules/manager/common/widgets/manager_ui.dart';
import 'package:guardgrey/modules/manager/field_visits/screens/manager_field_visit_screen.dart';
import 'package:guardgrey/modules/manager/notifications/screens/manager_notifications_screen.dart';
import 'package:guardgrey/modules/manager/sites/screens/manager_site_detail_screen.dart';
import 'package:guardgrey/modules/manager/sites/screens/manager_sites_screen.dart';
import 'package:guardgrey/modules/manager/visits/models/manager_visit_entry.dart';
import 'package:guardgrey/modules/manager/visits/repositories/manager_visit_repository.dart';
import 'package:guardgrey/modules/manager/visits/screens/manager_visit_form_screen.dart';
import 'package:guardgrey/modules/manager/visits/screens/manager_visits_screen.dart';

class ManagerDashboardScreen extends StatelessWidget {
  const ManagerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ManagerModel?>(
      stream: ManagerSessionService.instance.watchCurrentManager(),
      builder: (context, managerSnapshot) {
        final manager = managerSnapshot.data;
        if (managerSnapshot.connectionState == ConnectionState.waiting &&
            manager == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (manager == null) {
          return const Scaffold(
            body: ManagerEmptyState(
              title: 'No manager workspace data',
              message:
                  'Seed or sync the manager workspace to load dashboard activity.',
            ),
          );
        }
        return StreamBuilder<List<SiteModel>>(
          stream: GuardGreyRepository.instance.watchSites(),
          builder: (context, siteSnapshot) {
            final assignedSites = (siteSnapshot.data ?? const <SiteModel>[])
                .where(
                  (site) =>
                      site.managerId == manager.id ||
                      manager.siteIds.contains(site.id),
                )
                .toList(growable: false);
            return StreamBuilder<List<ManagerVisitEntry>>(
              stream: ManagerVisitRepository.instance.watchManagerVisits(
                manager.id,
              ),
              builder: (context, visitSnapshot) {
                final visits =
                    visitSnapshot.data ?? const <ManagerVisitEntry>[];
                final now = DateTime.now();
                final todayVisits = visits
                    .where(
                      (visit) =>
                          visit.scheduledAt.year == now.year &&
                          visit.scheduledAt.month == now.month &&
                          visit.scheduledAt.day == now.day,
                    )
                    .toList(growable: false);
                final pendingCount = visits
                    .where(
                      (visit) => visit.status.toLowerCase().contains('pending'),
                    )
                    .length;
                final completedCount = visits
                    .where(
                      (visit) =>
                          visit.status.toLowerCase().contains('complete'),
                    )
                    .length;

                return Scaffold(
                  backgroundColor: AppColors.backgroundLight,
                  appBar: AppBar(
                    backgroundColor: AppColors.backgroundLight,
                    elevation: 0,
                    scrolledUnderElevation: 0,
                    title: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Dashboard',
                          style: AppTextStyles.title.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          'Welcome back, ${manager.name.split(' ').first}',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.neutral500,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    actions: [
                      IconButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ManagerNotificationsScreen(),
                          ),
                        ),
                        icon: const Icon(Icons.notifications_none_rounded),
                        tooltip: 'Notifications',
                      ),
                    ],
                  ),
                  body: SafeArea(
                    bottom: false,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
                      children: [
                        const ManagerSectionTitle('Overview'),
                        const SizedBox(height: 8),
                        GridView(
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: 12,
                                crossAxisSpacing: 12,
                                mainAxisExtent: 92,
                              ),
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          children: [
                            _KpiCard(
                              label: 'Assigned Sites',
                              value: '${assignedSites.length}',
                              icon: Icons.location_on_outlined,
                              iconColor: AppColors.primary600,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const ManagerSitesScreen(
                                    showAppBar: true,
                                  ),
                                ),
                              ),
                            ),
                            _KpiCard(
                              label: 'Today\'s Visits',
                              value: '${todayVisits.length}',
                              icon: Icons.route_outlined,
                              iconColor: AppColors.primary600,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const ManagerVisitsScreen(
                                    showAppBar: true,
                                  ),
                                ),
                              ),
                            ),
                            _KpiCard(
                              label: 'Pending Visits',
                              value: '$pendingCount',
                              icon: Icons.pending_actions_outlined,
                              iconColor: AppColors.warningDark,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const ManagerVisitsScreen(
                                    showAppBar: true,
                                  ),
                                ),
                              ),
                            ),
                            _KpiCard(
                              label: 'Completed Visits',
                              value: '$completedCount',
                              icon: Icons.check_circle_outline_rounded,
                              iconColor: AppColors.success,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const ManagerVisitsScreen(
                                    showAppBar: true,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        const ManagerSectionTitle('Quick Actions'),
                        const SizedBox(height: 12),
                        Column(
                          children: [
                            _QuickAction(
                              label: 'Check-in',
                              subtitle: 'Update your attendance status',
                              icon: Icons.fact_check_outlined,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const ManagerAttendanceScreen(
                                    showAppBar: true,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            _QuickAction(
                              label: 'Add Visit',
                              subtitle: 'Create a new site visit record',
                              icon: Icons.add_business_outlined,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ManagerVisitFormScreen(
                                    manager: manager,
                                    sites: assignedSites,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            _QuickAction(
                              label: 'Field Visit',
                              subtitle:
                                  'Capture a surprise or inspection visit',
                              icon: Icons.pin_drop_outlined,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const ManagerFieldVisitScreen(),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        const ManagerSectionTitle('Assigned Sites Snapshot'),
                        const SizedBox(height: 12),
                        if (assignedSites.isEmpty)
                          const ManagerEmptyState(
                            title: 'No assigned sites',
                            message:
                                'Assigned sites will appear here when the manager workspace is synced.',
                          )
                        else
                          ...assignedSites
                              .take(3)
                              .map(
                                (site) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: ManagerListCard(
                                    title: site.name,
                                    subtitle: site.address.isEmpty
                                        ? site.location
                                        : site.address,
                                    meta: site.buildingFloor.isEmpty
                                        ? 'Site assigned'
                                        : site.buildingFloor,
                                    icon: Icons.location_city_rounded,
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ManagerSiteDetailScreen(
                                          site: site,
                                          managerId: manager.id,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                        const SizedBox(height: 6),
                        const ManagerSectionTitle('Today\'s Activity'),
                        const SizedBox(height: 12),
                        if (todayVisits.isEmpty)
                          const ManagerEmptyState(
                            title: 'No activity scheduled today',
                            message:
                                'Newly created visits and completed checks will appear here.',
                          )
                        else
                          ...todayVisits.map(
                            (visit) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: ManagerListCard(
                                title: visit.siteName,
                                subtitle: formatDateTimeLabel(
                                  visit.scheduledAt,
                                ),
                                meta:
                                    '${visit.visitType} | ${visit.notes.isEmpty ? 'No notes added' : visit.notes}',
                                status: visit.status,
                                icon: Icons.assignment_turned_in_outlined,
                                onTap: () {
                                  final site = assignedSites
                                      .where((item) => item.id == visit.siteId)
                                      .firstOrNull;
                                  if (site == null) {
                                    return;
                                  }
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ManagerSiteDetailScreen(
                                        site: site,
                                        managerId: manager.id,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.neutral200),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value.padLeft(2, '0'),
                    style: AppTextStyles.headingSmall.copyWith(
                      fontWeight: FontWeight.w800,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.neutral500,
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
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ManagerListCard(
      title: label,
      subtitle: subtitle,
      icon: icon,
      onTap: onTap,
    );
  }
}

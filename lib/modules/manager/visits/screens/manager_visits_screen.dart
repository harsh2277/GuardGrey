import 'package:flutter/material.dart';

import 'package:guardgrey/core/theme/app_colors.dart';
import 'package:guardgrey/core/theme/app_text_styles.dart';
import 'package:guardgrey/core/utils/date_time_display.dart';
import 'package:guardgrey/core/widgets/admin_search_bar.dart';
import 'package:guardgrey/core/widgets/list_filter_bottom_sheet.dart';
import 'package:guardgrey/core/widgets/primary_floating_add_button.dart';
import 'package:guardgrey/core/widgets/surface_icon_button.dart';
import 'package:guardgrey/data/models/manager_model.dart';
import 'package:guardgrey/data/models/site_model.dart';
import 'package:guardgrey/data/repositories/guard_grey_repository.dart';
import 'package:guardgrey/modules/manager/common/services/manager_session_service.dart';
import 'package:guardgrey/modules/manager/common/widgets/manager_ui.dart';
import 'package:guardgrey/modules/manager/visits/models/manager_visit_entry.dart';
import 'package:guardgrey/modules/manager/visits/repositories/manager_visit_repository.dart';
import 'package:guardgrey/modules/manager/visits/screens/manager_visit_detail_screen.dart';
import 'package:guardgrey/modules/manager/visits/screens/manager_visit_form_screen.dart';

class ManagerVisitsScreen extends StatefulWidget {
  const ManagerVisitsScreen({
    super.key,
    this.initialSiteId,
    this.initialSiteName,
    this.showAppBar = false,
  });

  final String? initialSiteId;
  final String? initialSiteName;
  final bool showAppBar;

  @override
  State<ManagerVisitsScreen> createState() => _ManagerVisitsScreenState();
}

class _ManagerVisitsScreenState extends State<ManagerVisitsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _statusFilter;
  String? _siteFilter;
  DateTime? _dateFilter;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openFilters(List<SiteModel> sites) async {
    final filters = await ListFilterBottomSheet.show(
      context,
      title: 'Filter Visits',
      initialDate: _dateFilter,
      initialStatus: _statusFilter,
      showDateFilter: true,
      statusOptions: const <String>['Pending', 'Completed', 'In Progress'],
      extraDropdowns: [
        ListFilterDropdownField(
          key: 'siteId',
          label: 'Site',
          options: sites.map((site) => site.name).toList(growable: false),
          initialValue: _siteFilter,
        ),
      ],
    );
    if (filters == null) {
      return;
    }
    setState(() {
      _statusFilter = filters.status;
      _siteFilter = filters.extraSelections['siteId'];
      _dateFilter = filters.date;
    });
  }

  Future<void> _openVisitForm({
    required ManagerModel manager,
    required List<SiteModel> sites,
    ManagerVisitEntry? existing,
  }) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ManagerVisitFormScreen(
          manager: manager,
          sites: sites,
          existing: existing,
          initialSiteId: widget.initialSiteId,
        ),
      ),
    );
    if (result == true) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.success,
          content: Text(
            existing == null
                ? 'Visit created successfully.'
                : 'Visit updated successfully.',
            style: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ManagerModel?>(
      stream: ManagerSessionService.instance.watchCurrentManager(),
      builder: (context, managerSnapshot) {
        final manager = managerSnapshot.data;
        final scaffold = manager == null
            ? const ManagerEmptyState(
                title: 'No manager workspace data',
                message:
                    'Visit records will appear after the manager workspace syncs.',
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

                  return StreamBuilder<List<ManagerVisitEntry>>(
                    stream: ManagerVisitRepository.instance.watchManagerVisits(
                      manager.id,
                    ),
                    builder: (context, visitSnapshot) {
                      final visits =
                          (visitSnapshot.data ?? const <ManagerVisitEntry>[])
                              .where((visit) {
                                if (widget.initialSiteId != null &&
                                    visit.siteId != widget.initialSiteId) {
                                  return false;
                                }
                                final query = _searchQuery.trim().toLowerCase();
                                if (query.isNotEmpty &&
                                    !visit.siteName.toLowerCase().contains(
                                      query,
                                    ) &&
                                    !visit.notes.toLowerCase().contains(
                                      query,
                                    )) {
                                  return false;
                                }
                                if (_statusFilter != null &&
                                    visit.status != _statusFilter) {
                                  return false;
                                }
                                if (_siteFilter != null &&
                                    visit.siteName != _siteFilter) {
                                  return false;
                                }
                                if (_dateFilter != null &&
                                    formatDateLabel(visit.scheduledAt) !=
                                        GuardGreyRepository.formatDate(
                                          _dateFilter,
                                        )) {
                                  return false;
                                }
                                return true;
                              })
                              .toList(growable: false);

                      return Padding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (widget.showAppBar) ...[
                              Text(
                                'Track and update all manager visits',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.neutral500,
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],
                            Row(
                              children: [
                                Expanded(
                                  child: AdminSearchBar(
                                    controller: _searchController,
                                    hintText: 'Search visits',
                                    onChanged: (value) =>
                                        setState(() => _searchQuery = value),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                SurfaceIconButton(
                                  icon: Icons.tune_rounded,
                                  onTap: () => _openFilters(sites),
                                  backgroundColor: AppColors.primary600,
                                  borderColor: AppColors.primary600,
                                  iconColor: Colors.white,
                                  borderRadius: 25,
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            Expanded(
                              child: visits.isEmpty
                                  ? const ManagerEmptyState(
                                      title: 'No visits found',
                                      message:
                                          'Scheduled manager visits will appear here after creation.',
                                    )
                                  : ListView.separated(
                                      padding: const EdgeInsets.only(
                                        bottom: 96,
                                      ),
                                      itemCount: visits.length,
                                      separatorBuilder: (context, index) =>
                                          const SizedBox(height: 12),
                                      itemBuilder: (context, index) {
                                        final visit = visits[index];
                                        return ManagerListCard(
                                          onTap: () async {
                                            final result =
                                                await Navigator.push<bool>(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (_) =>
                                                        ManagerVisitDetailScreen(
                                                          visit: visit,
                                                          onEdit: () {
                                                            Navigator.pop(
                                                              context,
                                                            );
                                                            _openVisitForm(
                                                              manager: manager,
                                                              sites: sites,
                                                              existing: visit,
                                                            );
                                                          },
                                                        ),
                                                  ),
                                                );
                                            if (result == true) {
                                              if (!mounted) {
                                                return;
                                              }
                                              ScaffoldMessenger.of(
                                                this.context,
                                              ).showSnackBar(
                                                SnackBar(
                                                  backgroundColor:
                                                      AppColors.success,
                                                  content: Text(
                                                    'Visit deleted.',
                                                    style: AppTextStyles
                                                        .bodyMedium
                                                        .copyWith(
                                                          color: Colors.white,
                                                        ),
                                                  ),
                                                ),
                                              );
                                            }
                                          },
                                          title: visit.siteName,
                                          subtitle: formatDateTimeLabel(
                                            visit.scheduledAt,
                                          ),
                                          meta: visit.notes.isEmpty
                                              ? 'No notes added.'
                                              : visit.notes,
                                          status: visit.status,
                                          icon: Icons
                                              .assignment_turned_in_outlined,
                                        );
                                      },
                                    ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              );

        return Scaffold(
          backgroundColor: AppColors.backgroundLight,
          appBar: AppBar(
            backgroundColor: AppColors.backgroundLight,
            elevation: 0,
            scrolledUnderElevation: 0,
            title: Text(
              'Visits',
              style: AppTextStyles.title.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          body: scaffold,
          floatingActionButton: manager == null
              ? null
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
                    return PrimaryFloatingAddButton(
                      heroTag: 'manager-visits-add',
                      tooltip: 'Add Visit',
                      onPressed: () =>
                          _openVisitForm(manager: manager, sites: sites),
                    );
                  },
                ),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';

import 'package:guardgrey/core/theme/app_colors.dart';
import 'package:guardgrey/core/theme/app_text_styles.dart';
import 'package:guardgrey/core/utils/date_time_display.dart';
import 'package:guardgrey/core/widgets/admin_search_bar.dart';
import 'package:guardgrey/core/widgets/primary_floating_add_button.dart';
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
  String? _siteFilterId;
  DateTime? _dateFilter;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
    if (result == true && mounted) {
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

  Future<void> _openFilters(List<SiteModel> sites) async {
    DateTime? tempDate = _dateFilter;
    String? tempSiteId = _siteFilterId;
    String? tempStatus = _statusFilter;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                18,
                18,
                18,
                24 + MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Filter Visits',
                    style: AppTextStyles.title.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () async {
                      final pickedDate = await showDatePicker(
                        context: context,
                        initialDate: tempDate ?? DateTime.now(),
                        firstDate: DateTime.now().subtract(
                          const Duration(days: 30),
                        ),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (pickedDate == null) {
                        return;
                      }
                      setModalState(() {
                        tempDate = pickedDate;
                      });
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Visit date',
                        suffixIcon: tempDate == null
                            ? const Icon(Icons.calendar_today_outlined)
                            : IconButton(
                                onPressed: () {
                                  setModalState(() {
                                    tempDate = null;
                                  });
                                },
                                icon: const Icon(Icons.close_rounded),
                              ),
                      ),
                      child: Text(
                        tempDate == null
                            ? 'All dates'
                            : GuardGreyRepository.formatDate(tempDate),
                        style: AppTextStyles.bodyMedium,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String?>(
                    initialValue: tempSiteId,
                    decoration: const InputDecoration(labelText: 'Site'),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('All sites'),
                      ),
                      ...sites.map(
                        (site) => DropdownMenuItem<String?>(
                          value: site.id,
                          child: Text(site.name),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      setModalState(() {
                        tempSiteId = value;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String?>(
                    initialValue: tempStatus,
                    decoration: const InputDecoration(labelText: 'Status'),
                    items: const [
                      DropdownMenuItem<String?>(
                        value: null,
                        child: Text('All status'),
                      ),
                      DropdownMenuItem<String?>(
                        value: 'Pending',
                        child: Text('Pending'),
                      ),
                      DropdownMenuItem<String?>(
                        value: 'Completed',
                        child: Text('Completed'),
                      ),
                      DropdownMenuItem<String?>(
                        value: 'In Progress',
                        child: Text('In Progress'),
                      ),
                    ],
                    onChanged: (value) {
                      setModalState(() {
                        tempStatus = value;
                      });
                    },
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() {
                              _dateFilter = null;
                              _siteFilterId = null;
                              _statusFilter = null;
                            });
                            Navigator.pop(context);
                          },
                          child: const Text('Clear'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: () {
                            setState(() {
                              _dateFilter = tempDate;
                              _siteFilterId = tempSiteId;
                              _statusFilter = tempStatus;
                            });
                            Navigator.pop(context);
                          },
                          child: const Text('Apply'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
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
                                if (_siteFilterId != null &&
                                    visit.siteId != _siteFilterId) {
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
                        padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
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
                                SizedBox(
                                  width: 50,
                                  height: 50,
                                  child: FilledButton(
                                    onPressed: () => _openFilters(sites),
                                    style: FilledButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                    ),
                                    child: const Icon(Icons.tune_rounded),
                                  ),
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
                                        return _VisitCard(
                                          visit: visit,
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
                                            if (result == true && mounted) {
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

class _VisitCard extends StatelessWidget {
  const _VisitCard({required this.visit, required this.onTap});

  final ManagerVisitEntry visit;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ManagerSurfaceCard(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary50,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.assignment_turned_in_outlined,
              color: AppColors.primary600,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  visit.siteName,
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.neutral900,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  formatDateTimeLabel(visit.scheduledAt),
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.neutral600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  visit.visitType,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.primary700,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (visit.notes.trim().isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    visit.notes,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.neutral500,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          const Icon(
            Icons.arrow_forward_ios_rounded,
            size: 16,
            color: AppColors.neutral400,
          ),
        ],
      ),
    );
  }
}

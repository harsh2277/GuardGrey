import 'package:flutter/material.dart';

import 'package:guardgrey/core/theme/app_colors.dart';
import 'package:guardgrey/core/theme/app_text_styles.dart';
import 'package:guardgrey/core/widgets/admin_search_bar.dart';
import 'package:guardgrey/data/models/branch_model.dart';
import 'package:guardgrey/data/models/manager_model.dart';
import 'package:guardgrey/data/models/site_model.dart';
import 'package:guardgrey/data/repositories/guard_grey_repository.dart';
import 'package:guardgrey/modules/manager/common/services/manager_session_service.dart';
import 'package:guardgrey/modules/manager/common/widgets/manager_ui.dart';
import 'package:guardgrey/modules/manager/sites/screens/manager_site_detail_screen.dart';
import 'package:guardgrey/modules/manager/visits/models/manager_visit_entry.dart';
import 'package:guardgrey/modules/manager/visits/repositories/manager_visit_repository.dart';

class ManagerSitesScreen extends StatefulWidget {
  const ManagerSitesScreen({super.key, this.showAppBar = false});

  final bool showAppBar;

  @override
  State<ManagerSitesScreen> createState() => _ManagerSitesScreenState();
}

class _ManagerSitesScreenState extends State<ManagerSitesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedBranchId;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openBranchFilter(List<BranchModel> branches) async {
    String? nextValue = _selectedBranchId;
    final applied = await showModalBottomSheet<String?>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Filter by Branch',
                    style: AppTextStyles.title.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String?>(
                    initialValue: nextValue,
                    decoration: const InputDecoration(labelText: 'Branch'),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('All branches'),
                      ),
                      ...branches.map(
                        (branch) => DropdownMenuItem<String?>(
                          value: branch.id,
                          child: Text(branch.name),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      setModalState(() {
                        nextValue = value;
                      });
                    },
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context, null),
                          child: const Text('Clear'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: () => Navigator.pop(context, nextValue),
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
    setState(() {
      _selectedBranchId = applied;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scaffold = StreamBuilder<ManagerModel?>(
      stream: ManagerSessionService.instance.watchCurrentManager(),
      builder: (context, managerSnapshot) {
        final manager = managerSnapshot.data;
        if (managerSnapshot.connectionState == ConnectionState.waiting &&
            manager == null) {
          return const Center(child: CircularProgressIndicator());
        }
        if (manager == null) {
          return const ManagerEmptyState(
            title: 'No manager workspace data',
            message:
                'Assigned sites will appear after the manager workspace syncs.',
          );
        }
        return StreamBuilder<List<BranchModel>>(
          stream: GuardGreyRepository.instance.watchBranches(),
          builder: (context, branchSnapshot) {
            final branches = branchSnapshot.data ?? const <BranchModel>[];
            return StreamBuilder<List<ManagerVisitEntry>>(
              stream: ManagerVisitRepository.instance.watchManagerVisits(
                manager.id,
              ),
              builder: (context, visitSnapshot) {
                final latestVisitBySite = <String, DateTime>{};
                for (final visit
                    in visitSnapshot.data ?? const <ManagerVisitEntry>[]) {
                  final existing = latestVisitBySite[visit.siteId];
                  if (existing == null || visit.scheduledAt.isAfter(existing)) {
                    latestVisitBySite[visit.siteId] = visit.scheduledAt;
                  }
                }

                return StreamBuilder<List<SiteModel>>(
                  stream: GuardGreyRepository.instance.watchSites(),
                  builder: (context, siteSnapshot) {
                    final branchNames = <String, String>{
                      for (final branch in branches) branch.id: branch.name,
                    };
                    final sites = (siteSnapshot.data ?? const <SiteModel>[])
                        .where(
                          (site) =>
                              site.managerId == manager.id ||
                              manager.siteIds.contains(site.id),
                        )
                        .where((site) {
                          final query = _searchQuery.trim().toLowerCase();
                          if (_selectedBranchId != null &&
                              site.branchId != _selectedBranchId) {
                            return false;
                          }
                          if (query.isEmpty) {
                            return true;
                          }
                          return site.name.toLowerCase().contains(query) ||
                              site.address.toLowerCase().contains(query) ||
                              site.location.toLowerCase().contains(query);
                        })
                        .toList(growable: false);

                    return Padding(
                      padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (widget.showAppBar) ...[
                            Text(
                              'Assigned sites',
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
                                  hintText: 'Search assigned sites',
                                  onChanged: (value) =>
                                      setState(() => _searchQuery = value),
                                ),
                              ),
                              const SizedBox(width: 12),
                              SizedBox(
                                width: 50,
                                height: 50,
                                child: FilledButton(
                                  onPressed: () => _openBranchFilter(branches),
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
                            child: sites.isEmpty
                                ? const ManagerEmptyState(
                                    title: 'No assigned sites found',
                                    message:
                                        'Assigned sites will appear here once they are linked to the manager.',
                                  )
                                : ListView.separated(
                                    itemCount: sites.length,
                                    separatorBuilder: (context, index) =>
                                        const SizedBox(height: 12),
                                    itemBuilder: (context, index) {
                                      final site = sites[index];
                                      final address = site.address.isEmpty
                                          ? site.location
                                          : site.address;
                                      final lastVisit =
                                          latestVisitBySite[site.id];
                                      final branchName =
                                          branchNames[site.branchId];
                                      return ManagerListCard(
                                        onTap: () => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                ManagerSiteDetailScreen(
                                                  site: site,
                                                  managerId: manager.id,
                                                ),
                                          ),
                                        ),
                                        title: site.name,
                                        subtitle: address,
                                        meta:
                                            'Last visit: ${lastVisit == null ? 'Not available' : GuardGreyRepository.formatDate(lastVisit)}${branchName?.isNotEmpty == true ? ' | $branchName' : ''}',
                                        icon: Icons.location_city_rounded,
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
          'Sites',
          style: AppTextStyles.title.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      body: scaffold,
    );
  }
}
